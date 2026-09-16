import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "switch-workspace-group.sh"


class WorkspaceGroups(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.path = Path(self.directory.name)
        self.environment = dict(os.environ)
        for name in ("RVVEBER_FHUD_WORKSPACE_GROUPS", "RVVEBER_FHUD_WORKSPACES_PER_MONITOR"):
            self.environment.pop(name, None)
        self.environment.update(
            PATH=f"{self.path}:{os.environ['PATH']}",
            FHUD_TEST_DIR=str(self.path),
        )
        (self.path / "hyprctl").write_text(f"#!{sys.executable}\n" + """
import json, os, pathlib, sys
root = pathlib.Path(os.environ["FHUD_TEST_DIR"])
args = sys.argv[1:]
if args == ["monitors", "-j"]:
    print((root / "monitors.json").read_text())
elif args == ["cursorpos", "-j"]:
    print('{"x": 100.4, "y": 200.8}')
elif args == ["activewindow", "-j"]:
    print('{"workspace":{"id":24}}')
elif args[0] == "dispatch":
    with (root / "dispatches").open("a") as out:
        out.write(args[1] + "\\n")
else:
    sys.exit("Unexpected hyprctl call: " + repr(args))
""")
        (self.path / "hyprctl").chmod(0o755)
        self.monitors = [
            dict(name="eDP-1", activeWorkspace=dict(id=13), focused=False),
            dict(name="DP-1", activeWorkspace=dict(id=24), focused=True),
            dict(name="HDMI-A-1", activeWorkspace=dict(id=34), focused=False),
        ]

    def run_switch(self, *arguments, success=True):
        (self.path / "monitors.json").write_text(json.dumps(self.monitors))
        result = subprocess.run(
            ["bash", str(SCRIPT), *arguments], env=self.environment,
            capture_output=True, text=True, timeout=5,
        )
        self.assertEqual(result.returncode, 0 if success else 2, result.stderr)
        log = self.path / "dispatches"
        return log.read_text().splitlines() if log.exists() else []

    def test_keyboard_switches_synchronized_group_and_restores_focus(self):
        self.assertEqual(self.run_switch("4"), [
            'hl.dsp.focus({ monitor = "DP-1" })',
            'hl.dsp.focus({ workspace = "24" })',
            'hl.dsp.focus({ monitor = "HDMI-A-1" })',
            'hl.dsp.focus({ workspace = "34" })',
            'hl.dsp.focus({ monitor = "DP-1" })',
            'hl.dsp.cursor.move({ x = 100, y = 200 })',
        ])

    def test_explicit_lane_selects_its_group_and_preserves_keyboard_focus(self):
        calls = self.run_switch("0", "11")
        self.assertEqual(calls[:2], [
            'hl.dsp.focus({ monitor = "eDP-1" })',
            'hl.dsp.focus({ workspace = "20" })',
        ])
        self.assertEqual(calls[-2], 'hl.dsp.focus({ monitor = "DP-1" })')
        self.assertEqual(len(calls), 4)

    def test_configured_group_can_be_selected_from_another_monitor(self):
        self.environment["RVVEBER_FHUD_WORKSPACE_GROUPS"] = "11,31;21"
        calls = self.run_switch("2", "31")
        self.assertIn('hl.dsp.focus({ workspace = "12" })', calls)
        self.assertIn('hl.dsp.focus({ workspace = "32" })', calls)
        self.assertEqual(len(calls), 6)

    def test_unlisted_connected_monitor_forms_its_own_lane(self):
        self.environment["RVVEBER_FHUD_WORKSPACE_GROUPS"] = "21,31"
        calls = self.run_switch("3", "11")
        self.assertIn('hl.dsp.focus({ workspace = "13" })', calls)
        self.assertEqual(len(calls), 4)

    def test_move_stays_with_active_window(self):
        self.assertEqual(self.run_switch("move", "0"), [
            'hl.dsp.window.move({ workspace = "30", follow = false })',
        ])

    def test_invalid_or_disconnected_targets_leave_desktop_unchanged(self):
        for arguments in ((), ("11",), ("01",), ("2", "41"), ("move", "2", "11")):
            with self.subTest(arguments=arguments):
                self.assertEqual(self.run_switch(*arguments, success=False), [])

    def test_invalid_workspace_span_is_rejected_before_arithmetic(self):
        self.environment["RVVEBER_FHUD_WORKSPACES_PER_MONITOR"] = "invalid"
        self.assertEqual(self.run_switch("2", success=False), [])


if __name__ == "__main__":
    unittest.main()
