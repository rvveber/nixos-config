import importlib.util
import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location(
    "periodic_scan",
    ROOT / "src/module/host/add/application/periodic-security-scan/scan.py",
)
scan = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(scan)

MATCH = {
    "artifact": {"type": "go-module", "name": "example/lib", "version": "1.0"},
    "vulnerability": {"namespace": "govulndb:language:go", "id": "GO-2026-1234"},
    "matchDetails": [{"type": "exact-direct-match"}],
}


class PeriodicScanTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.state = Path(self.temp.name)

    def test_comparison_identity_includes_ecosystem_version_and_advisory(self):
        other = dict(MATCH, artifact=dict(MATCH["artifact"], type="nix"))
        updated = dict(MATCH, artifact=dict(MATCH["artifact"], version="2.0"))
        identities, kinds = scan.findings({"matches": [MATCH, MATCH, other, updated]})
        self.assertEqual(len(identities), 3)
        self.assertEqual(kinds, {"exact-direct-match": 4})
        with self.assertRaises(TypeError):
            scan.findings({})

    def test_failed_scan_preserves_previous_success_as_baseline(self):
        success = {"status": "complete", "identities": [], "candidates": 0}
        with patch.object(scan, "scan", return_value=success):
            self.assertEqual(scan.perform_scan(self.state), 0)
        previous = scan.read_json(self.state / "latest/summary.json")
        with patch.object(scan, "scan", side_effect=RuntimeError("DB refresh failed")):
            self.assertEqual(scan.perform_scan(self.state), 1)
        failed = scan.read_json(self.state / "latest/summary.json")
        self.assertEqual(failed["status"], "failed")
        self.assertIn("DB refresh failed", failed["error"])
        with patch.object(scan, "scan", return_value=success.copy()) as execute:
            scan.perform_scan(self.state)
        self.assertEqual(execute.call_args.args[2], previous)

    def test_inventory_reused_but_grype_runs_each_time(self):
        target = "/nix/store/" + "a" * 32 + "-system"
        targets = [target]
        grype_calls = []

        def run(command, log, output=None, **kwargs):
            if command[:2] == ["nix-store", "--query"]:
                output.write(targets[0] + "\n")
            elif command[0] == "grype" and command[1].startswith("sbom:"):
                grype_calls.append(command)
                json.dump({"matches": [MATCH]}, output)

        def inventory(paths, target, output, log):
            json.dump({"artifacts": [{"name": "test"}]}, output)

        with (
            patch.object(scan, "run", side_effect=run),
            patch.object(scan, "inventory", side_effect=inventory) as catalog,
            patch.object(
                scan.Path, "resolve", side_effect=lambda **_: Path(targets[0])
            ),
        ):
            for attempt in range(3):
                directory = self.state / str(attempt)
                directory.mkdir()
                if attempt == 2:
                    targets[0] = target + "-updated"
                with tempfile.TemporaryFile(mode="w+") as log:
                    report = scan.scan(self.state, directory, None, log)
                self.assertEqual(report["inventory_reused"], attempt == 1)
                self.assertEqual(report["candidates"], 1)
            self.assertEqual(catalog.call_count, 2)
            self.assertEqual(len(grype_calls), 3)

    def test_notification_is_retried_until_delivered_and_deduplicated(self):
        directory = self.state / "report"
        directory.mkdir()
        (self.state / "latest").symlink_to(directory)
        scan.write_json(
            directory / "summary.json",
            {
                "status": "complete",
                "run": "test",
                "candidates": 1,
                "match_types": {"exact-direct-match": 1, "cpe-match": 2},
            },
        )
        user = self.state / "user"
        with (
            patch.object(
                scan.subprocess,
                "run",
                side_effect=subprocess.CalledProcessError(1, "notify-send"),
            ),
            self.assertRaises(subprocess.CalledProcessError),
        ):
            scan.notify(self.state, user)
        self.assertFalse((user / "notified").exists())
        with patch.object(scan.subprocess, "run") as send:
            scan.notify(self.state, user)
            scan.notify(self.state, user)
        send.assert_called_once()
        self.assertIn("exact-direct-match", send.call_args.args[0][-1])
        self.assertIn("cpe-match", send.call_args.args[0][-1])

    def test_clean_report_is_quiet_and_failure_is_notified(self):
        directory = self.state / "report"
        directory.mkdir()
        (self.state / "latest").symlink_to(directory)
        user = self.state / "user"
        with patch.object(scan.subprocess, "run") as send:
            scan.write_json(
                directory / "summary.json",
                {
                    "status": "complete",
                    "run": "clean",
                    "candidates": 0,
                },
            )
            scan.notify(self.state, user)
            send.assert_not_called()
            scan.write_json(
                directory / "summary.json", {"status": "failed", "run": "failed"}
            )
            scan.notify(self.state, user)
            send.assert_called_once()

    @unittest.skipUnless(
        os.environ.get("PERIODIC_SCAN_FIXTURE"),
        "requires the Nix boundary fixture and Syft/Bubblewrap",
    )
    def test_real_inventory_cannot_follow_links_outside_the_closure_view(self):
        fixture = os.environ["PERIODIC_SCAN_FIXTURE"]
        # /tmp contains a valid package on the host; only the fixture is mounted
        # into /scan. The fixture also links to a real, unrelated store package.
        with tempfile.TemporaryDirectory() as outside:
            Path(outside, "package.json").write_text(
                '{"name":"mutable-escape","version":"9.9.9"}'
            )
            with (
                tempfile.TemporaryFile(mode="w+") as output,
                tempfile.TemporaryFile(mode="w+") as log,
            ):
                try:
                    scan.inventory([fixture], fixture, output, log)
                except subprocess.CalledProcessError:
                    log.seek(0)
                    self.fail(log.read())
                output.seek(0)
                data = json.load(output)
        names = {item["name"] for item in data["artifacts"]}
        self.assertIn("inside-closure", names)
        self.assertNotIn("mutable-escape", names)
        self.assertNotIn("outside-closure", names)
        self.assertTrue(
            all(
                location["path"]
                .lstrip("/")
                .startswith(f"nix/store/{Path(fixture).name}/")
                for item in data["artifacts"]
                for location in item["locations"]
            )
        )


if __name__ == "__main__":
    unittest.main()
