import datetime as dt
import importlib.util
import json
import os
import sys
import tempfile
import time
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location(
    "security_scan", ROOT / "lib/security_scan.py"
)
scan = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(scan)

PACKAGE = {
    "name": "git-2.55.0",
    "pname": "git",
    "version": "2.55.0",
    "derivation": "/nix/store/git.drv",
    "affected_by": ["CVE-2022-36882"],
    "cvssv3_basescore": {"CVE-2022-36882": 8.8},
    "description": {"CVE-2022-36882": "Jenkins Git Plugin"},
}


class SecurityScanTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.directory = Path(self.temp.name)

    def policy(self, text):
        path = self.directory / "suppressions.tsv"
        path.write_text(text)
        return scan.load_policy(path, dt.date(2026, 9, 16), True)

    def test_suppression_requires_exact_cve_package_and_version(self):
        rules = self.policy(
            "CVE-2022-36882\tgit\t2026-12-31\tJenkins plugin collision\t2.55.0\n"
        )
        self.assertEqual(
            scan.findings([PACKAGE], rules, 7, {})[0]["status"], "suppressed"
        )
        for field, value in [
            ("pname", "git-client"),
            ("version", "2.56.0"),
            ("affected_by", ["CVE-2026-12345"]),
        ]:
            package = dict(PACKAGE, **{field: value})
            self.assertEqual(
                scan.findings([package], rules, 7, {})[0]["status"], "review"
            )

    def test_expired_suppression_returns_to_review(self):
        rules = self.policy("CVE-2022-36882\tgit\t2026-09-15\tOld review\t2.55.0\n")
        self.assertEqual(scan.findings([PACKAGE], rules, 7, {})[0]["status"], "review")

    def test_bad_policy_fails_instead_of_silently_hiding_findings(self):
        for text in [
            "*\tgit\t2027-01-01\tblanket exclusion\n",
            "CVE-2022-36882\t*\t2027-01-01\tblanket exclusion\n",
            "CVE-2022-36882\tgit\t-\tindefinite\n",
            "CVE-2022-36882\tgit\t2027-01-01\t\n",
        ]:
            with self.subTest(text=text), self.assertRaises(ValueError):
                self.policy(text)

    def test_missing_score_is_reviewed_and_zero_is_preserved(self):
        missing = dict(PACKAGE, cvssv3_basescore={})
        zero = dict(PACKAGE, cvssv3_basescore={"CVE-2022-36882": 0})
        rows = scan.findings([missing, zero], [], 7, {})
        self.assertEqual(
            [(row["status"], row["cvss"]) for row in rows],
            [("review", None), ("below-threshold", 0)],
        )

    def test_unknown_runtime_identity_keeps_candidate(self):
        rows = scan.findings(
            [PACKAGE], [], 7, {"/nix/store/other": {"deriver": "/nix/store/other.drv"}}
        )
        self.assertEqual(rows[0]["status"], "review")
        self.assertEqual(rows[0]["runtime_outputs"], [])

    def test_distinct_derivations_retain_their_own_evidence(self):
        other = dict(PACKAGE, derivation="/nix/store/other.drv")
        closure = {"/nix/store/git": {"deriver": PACKAGE["derivation"]}}
        rows = scan.findings([PACKAGE, other], [], 7, closure)
        self.assertEqual(len(rows), 2)
        self.assertEqual(rows[0]["runtime_outputs"], ["/nix/store/git"])
        self.assertEqual(rows[1]["runtime_outputs"], [])

    def test_vulnix_exit_two_means_findings_only_with_a_valid_report(self):
        scan.validate_report([PACKAGE], 2)
        scan.validate_report([], 0)
        for report, code in [
            ([], 2),
            ([PACKAGE], 0),
            ([PACKAGE], 1),
            ([PACKAGE], 124),
            ({}, 0),
            (None, 0),
            ([{}], 2),
        ]:
            with (
                self.subTest(report=report, code=code),
                self.assertRaises((ValueError, TypeError)),
            ):
                scan.validate_report(report, code)

    def test_invalid_scores_are_scan_errors(self):
        for score in [float("nan"), float("inf"), -1, 11, "9.8", True]:
            package = dict(PACKAGE, cvssv3_basescore={"CVE-2022-36882": score})
            with self.subTest(score=score), self.assertRaises(ValueError):
                scan.validate_report([package], 2)

    def test_both_nix_path_info_json_formats(self):
        info = {"path": "/nix/store/git", "deriver": PACKAGE["derivation"]}
        expected = {info["path"]: info}
        self.assertEqual(scan.normalize_closure([info]), expected)
        self.assertEqual(scan.normalize_closure(expected), expected)
        for data in [[], {}, None]:
            with self.subTest(data=data), self.assertRaises(ValueError):
                scan.normalize_closure(data)

    def test_timeout_kills_scanner_descendants(self):
        marker = self.directory / "child-finished"
        child = f"import time; from pathlib import Path; time.sleep(1); Path({str(marker)!r}).touch()"
        parent = f"import subprocess,sys,time; subprocess.Popen([sys.executable,'-c',{child!r}]); time.sleep(10)"
        with self.assertRaises(TimeoutError):
            scan.run([sys.executable, "-c", parent], timeout=0.15)
        time.sleep(1.1)
        self.assertFalse(marker.exists())

    def test_failed_reports_and_other_scopes_are_not_comparison_baselines(self):
        current = {
            "host": "test",
            "target": "system",
            "scope": "runtime",
            "findings": scan.findings([PACKAGE], [], 7, {}),
        }
        previous = dict(current, status="complete", findings=[])
        for name, data in [
            ("1", previous),
            ("2", dict(previous, scope="build-and-runtime")),
            ("3", {"status": "failed"}),
        ]:
            directory = self.directory / name
            directory.mkdir()
            scan.write_json(directory / "report.json", data)
        scan.compare_previous(current, self.directory / "4")
        self.assertEqual(
            current["comparison"]["report"], str(self.directory / "1/report.json")
        )
        self.assertEqual(
            current["comparison"]["added"], [("git", "2.55.0", "CVE-2022-36882")]
        )

    def test_both_targets_use_explicit_runtime_scope(self):
        for target in ["system", "flake"]:
            with (
                self.subTest(target=target),
                patch.dict(os.environ, {"SECURITY_SCAN_TARGET": target}, clear=True),
            ):
                config = scan.settings()
                directory = self.directory / target
                directory.mkdir()
                commands = []

                def checked(command, timeout=900):
                    if command[1] == "build":
                        return "/nix/store/system"
                    if command[1] == "path-info":
                        return json.dumps(
                            {"/nix/store/git": {"deriver": PACKAGE["derivation"]}}
                        )
                    return "vulnix 1.12.5"

                def run(command, timeout, stdout, stderr, commands=commands):
                    commands.append(command)
                    json.dump([PACKAGE], stdout)
                    return 2, "", ""

                with (
                    patch.object(scan, "checked", side_effect=checked),
                    patch.object(scan, "run", side_effect=run),
                    patch.object(
                        scan.Path, "resolve", return_value=Path("/nix/store/system")
                    ),
                    patch.object(scan, "display", return_value=True),
                ):
                    self.assertEqual(scan.scan(config, directory), 1)
                self.assertEqual(
                    commands, [["vulnix", "--json", "--closure", "/nix/store/system"]]
                )

    def test_allow_failure_preserves_operational_failure(self):
        with (
            patch.dict(
                os.environ,
                {
                    "SECURITY_SCAN_ALLOW_FAILURE": "1",
                    "SECURITY_SCAN_REPORT_DIR": str(self.directory),
                },
                clear=True,
            ),
            patch.object(scan, "scan", side_effect=ValueError("broken JSON")),
        ):
            self.assertEqual(scan.main(), 2)
        reports = list(self.directory.glob("*/report.json"))
        self.assertEqual(json.loads(reports[0].read_text())["status"], "failed")


if __name__ == "__main__":
    unittest.main()
