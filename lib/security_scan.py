"""Scan a Nix closure and retain candidate findings with their triage evidence."""

import csv
import datetime as dt
import hashlib
import json
import math
import os
import re
import signal
import socket
import subprocess
import sys
import tempfile
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CVE = re.compile(r"CVE-\d{4}-\d+")


def write_json(path, value):
    path.write_text(json.dumps(value, indent=2) + "\n")


def run(command, timeout=900, stdout=None, stderr=None):
    with (
        tempfile.TemporaryFile(mode="w+") as out,
        tempfile.TemporaryFile(mode="w+") as err,
    ):
        process = subprocess.Popen(
            command, stdout=stdout or out, stderr=stderr or err, start_new_session=True
        )
        deadline = time.monotonic() + timeout if timeout is not None else math.inf
        try:
            while True:
                remaining = deadline - time.monotonic()
                if remaining <= 0:
                    raise TimeoutError(f"{command[0]} exceeded {timeout}s")
                try:
                    process.wait(timeout=min(30, remaining))
                    break
                except subprocess.TimeoutExpired:
                    if time.monotonic() < deadline:
                        print(f"Still running {command[0]}...", flush=True)
        except BaseException:
            try:
                os.killpg(process.pid, signal.SIGTERM)
            except ProcessLookupError:
                pass
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                pass
            finally:
                # Descendants can outlive the process that launched them.
                try:
                    os.killpg(process.pid, signal.SIGKILL)
                except ProcessLookupError:
                    pass
                process.wait()
            raise
        out.seek(0)
        err.seek(0)
        return process.returncode, out.read(), err.read()


def checked(command, timeout=900):
    code, out, err = run(command, timeout)
    if code:
        raise RuntimeError(f"{command[0]} exited {code}: {err.strip()}")
    return out.strip()


def boolean(name, default):
    value = os.environ.get(name, default)
    if value not in ("0", "1"):
        raise ValueError(f"{name} must be 0 or 1")
    return value == "1"


def positive_integer(name, default):
    value = int(os.environ.get(name, default))
    if value <= 0:
        raise ValueError(f"{name} must be positive")
    return value


def settings():
    target = os.environ.get("SECURITY_SCAN_TARGET", "flake")
    if target not in ("flake", "system"):
        raise ValueError("SECURITY_SCAN_TARGET must be flake or system")
    evidence = os.environ.get("SECURITY_SCAN_EVIDENCE_MODE", "auto")
    if evidence not in ("auto", "always", "never"):
        raise ValueError("SECURITY_SCAN_EVIDENCE_MODE must be auto, always or never")
    minimum = float(os.environ.get("SECURITY_SCAN_MIN_CVSS", "7"))
    if not math.isfinite(minimum) or not 0 <= minimum <= 10:
        raise ValueError("SECURITY_SCAN_MIN_CVSS must be between 0 and 10")
    host = os.environ.get("HOST_ATTR", socket.gethostname())
    if not re.fullmatch(r"[A-Za-z0-9_-]+", host):
        raise ValueError("HOST_ATTR must be a host attribute name")
    return {
        "host": host,
        "target": target,
        "scope": "runtime"
        if boolean("SECURITY_SCAN_EXCLUDE_BUILD_TIME_ONLY", "1")
        else "build-and-runtime",
        "minimum_cvss": minimum,
        "allow_failure": boolean("SECURITY_SCAN_ALLOW_FAILURE", "0"),
        "enforce_expiry": boolean("SECURITY_SCAN_SUPPRESSIONS_ENFORCE_EXPIRY", "1"),
        "timeout": positive_integer("SECURITY_SCAN_TIMEOUT_SECONDS", "900"),
        "trace_timeout": positive_integer("SECURITY_SCAN_TRACE_TIMEOUT_SECONDS", "30"),
        "description_length": positive_integer(
            "SECURITY_SCAN_DESCRIPTION_MAX_LEN", "500"
        ),
        "evidence": evidence,
        "policy_path": Path(
            os.environ.get(
                "SECURITY_SCAN_SUPPRESSIONS_FILE",
                ROOT / ".security-scan/suppressions.tsv",
            )
        ).resolve(),
        "report_dir": Path(
            os.environ.get("SECURITY_SCAN_REPORT_DIR", ROOT / ".security-scan/reports")
        ).resolve(),
    }


def load_policy(path, today, enforce_expiry):
    rules = []
    for number, row in enumerate(
        csv.reader(path.read_text().splitlines(), delimiter="\t"), 1
    ):
        if not row or row[0].startswith("#"):
            continue
        if len(row) not in (4, 5):
            raise ValueError(
                f"{path}:{number}: expected CVE, pname, expiry, reason, optional version"
            )
        cve, pname, expiry, reason = row[:4]
        if (
            not CVE.fullmatch(cve)
            or not pname
            or "*" in pname
            or not reason.strip()
            or (len(row) == 5 and (not row[4] or "*" in row[4]))
        ):
            raise ValueError(
                f"{path}:{number}: an exact CVE, package and reason are required"
            )
        until = dt.date.fromisoformat(expiry)
        rule = {
            "cve": cve,
            "pname": pname,
            "until": expiry,
            "reason": reason,
            "version": row[4] if len(row) == 5 else None,
            "expired": enforce_expiry and until < today,
        }
        if rule["expired"]:
            print(f"Expired suppression: {cve} / {pname} ({expiry})")
        rules.append(rule)
    return rules


def validate_report(data, exit_code):
    if exit_code not in (0, 2):
        raise ValueError(f"vulnix exited {exit_code}; see scanner.log")
    if not isinstance(data, list):
        raise TypeError("vulnix output must be a JSON array")
    count = 0
    for package in data:
        if not isinstance(package, dict):
            raise TypeError("invalid package in vulnix report")
        for key in ("name", "pname", "version", "derivation"):
            if not isinstance(package.get(key), str) or not package[key]:
                raise ValueError(f"missing {key} in vulnix report")
        cves = package.get("affected_by")
        if not isinstance(cves, list) or not all(
            isinstance(cve, str) and CVE.fullmatch(cve) for cve in cves
        ):
            raise ValueError("invalid affected_by in vulnix report")
        scores = package.get("cvssv3_basescore", {})
        descriptions = package.get("description", {})
        if not isinstance(scores, dict) or not isinstance(descriptions, dict):
            raise TypeError("invalid CVE metadata in vulnix report")
        for score in scores.values():
            if score is not None and (
                type(score) not in (int, float)
                or not math.isfinite(score)
                or not 0 <= score <= 10
            ):
                raise ValueError("invalid CVSS score in vulnix report")
        if not all(isinstance(text, str) for text in descriptions.values()):
            raise ValueError("invalid description in vulnix report")
        count += len(cves)
    # Vulnix also uses exit 2 for operational errors, which must never pass as an empty scan.
    if (exit_code == 2) != (count > 0):
        raise ValueError(
            "vulnix exit status disagrees with its report; see scanner.log"
        )


def normalize_closure(data):
    if isinstance(data, list) and data:
        if not all(
            isinstance(item, dict) and isinstance(item.get("path"), str)
            for item in data
        ):
            raise ValueError("invalid path metadata in runtime closure")
        data = {item["path"]: item for item in data}
    if (
        isinstance(data, dict)
        and data
        and all(isinstance(info, dict) for info in data.values())
    ):
        return data
    raise ValueError("Nix returned an empty or invalid runtime closure")


def findings(data, rules, minimum, closure):
    outputs = {}
    for path, info in closure.items():
        outputs.setdefault(info.get("deriver"), []).append(path)
    result = []
    for package in data:
        for cve in sorted(set(package["affected_by"])):
            score = package.get("cvssv3_basescore", {}).get(cve)
            rule = next(
                (
                    rule
                    for rule in rules
                    if not rule["expired"]
                    and rule["cve"] == cve
                    and rule["pname"] == package["pname"]
                    and (
                        rule["version"] is None or rule["version"] == package["version"]
                    )
                ),
                None,
            )
            status = (
                "suppressed"
                if rule
                else "review"
                if score is None or score >= minimum
                else "below-threshold"
            )
            result.append(
                {
                    "pname": package["pname"],
                    "version": package["version"],
                    "derivation": package["derivation"],
                    "cve": cve,
                    "cvss": score,
                    "description": package.get("description", {}).get(cve, ""),
                    "runtime_outputs": sorted(outputs.get(package["derivation"], [])),
                    "status": status,
                    "suppression": rule,
                }
            )
    return sorted(
        result,
        key=lambda row: (
            -(row["cvss"] if row["cvss"] is not None else 10),
            row["pname"],
            row["version"],
            row["cve"],
        ),
    )


def compare_previous(report, directory):
    identity = ("host", "target", "scope")
    for previous_path in sorted(directory.parent.glob("*/report.json"), reverse=True):
        if previous_path.parent == directory:
            continue
        try:
            previous = json.loads(previous_path.read_text())
            if previous.get("status") != "complete" or any(
                previous.get(key) != report[key] for key in identity
            ):
                continue
            keys = lambda value: {
                (row["pname"], row["version"], row["cve"]) for row in value["findings"]
            }
            old, new = keys(previous), keys(report)
        except (OSError, ValueError, KeyError, TypeError):
            continue
        report["comparison"] = {
            "report": str(previous_path),
            "added": sorted(new - old),
            "removed": sorted(old - new),
        }
        print(
            f"Candidate changes since {previous_path.parent.name}: {len(new - old)} added, {len(old - new)} removed"
        )
        return


def display(report, config):
    rows = report["findings"]
    review = [row for row in rows if row["status"] == "review"]
    print(
        f"{len(rows)} candidate package/CVE entries; {len({row['cve'] for row in rows})} distinct CVEs"
    )
    print(
        f"Review: {len(review)}; suppressed: {sum(row['status'] == 'suppressed' for row in rows)}; below threshold: {sum(row['status'] == 'below-threshold' for row in rows)}"
    )
    print(
        "These are name/version matches requiring review. Closure membership does not establish exploitability."
    )
    if report["unavailable_derivers"]:
        print(
            f"Coverage: {len(report['unavailable_derivers'])} closure paths lack locally available recorded derivations; see report.json"
        )
    grouped = {}
    for row in review:
        grouped.setdefault(
            (row["pname"], row["version"], row["derivation"]), []
        ).append(row)
    for (pname, version, derivation), group in grouped.items():
        print(f"\n{pname} {version}: {len(group)} candidates")
        print(f"  Derivation: {derivation}")
        outputs = group[0]["runtime_outputs"]
        if outputs:
            print(f"  Runtime output: {outputs[0]}")
        else:
            print(
                "  Runtime output identity unavailable; candidate retained for review"
            )
        if config["evidence"] == "always" and outputs:
            try:
                trace = checked(
                    ["nix", "why-depends", report["store_path"], outputs[0]],
                    config["trace_timeout"],
                )
                print(trace)
            except (RuntimeError, TimeoutError) as error:
                print(f"  Dependency trace unavailable: {error}")
        for row in group:
            score = (
                row["cvss"] if row["cvss"] is not None else "unknown; review required"
            )
            description = " ".join(row["description"].split())[
                : config["description_length"]
            ]
            print(f"  {row['cve']} (CVSS {score}): {description}")
            print(f"    https://nvd.nist.gov/vuln/detail/{row['cve']}")
    return bool(review)


def scan(config, directory):
    rules = load_policy(
        config["policy_path"],
        dt.datetime.now(dt.timezone.utc).date(),
        config["enforce_expiry"],
    )
    if config["target"] == "system":
        target = Path("/run/current-system").resolve(strict=True)
    else:
        flake = f"path:{ROOT}/src#nixosConfigurations.{config['host']}.config.system.build.toplevel"
        print(f"Building {flake}...", flush=True)
        target = Path(
            checked(
                [
                    "nix",
                    "build",
                    "--no-link",
                    "--print-out-paths",
                    "--no-write-lock-file",
                    flake,
                ],
                timeout=None,
            )
        )
    closure = normalize_closure(
        json.loads(
            checked(
                ["nix", "path-info", "--json", "-r", str(target)], config["timeout"]
            )
        )
    )
    write_json(directory / "closure.json", closure)
    command = ["vulnix", "--json"]
    if config["scope"] == "runtime":
        command.append("--closure")
    command.append(str(target))
    print(f"Scanning {target} ({config['scope']})...", flush=True)
    with (
        (directory / "raw.json").open("w") as out,
        (directory / "scanner.log").open("w") as err,
    ):
        code, _, _ = run(command, config["timeout"], out, err)
    raw = json.loads((directory / "raw.json").read_text())
    validate_report(raw, code)
    log = (directory / "scanner.log").read_text()
    if re.search(r"(?m)^(ERROR|CRITICAL|Traceback)", log):
        raise RuntimeError("vulnix reported an operational error; see scanner.log")
    report = {
        "schema_version": 1,
        "status": "complete",
        "created_at": dt.datetime.now(dt.timezone.utc).isoformat(),
        "host": config["host"],
        "target": config["target"],
        "scope": config["scope"],
        "store_path": str(target),
        "scanner": checked(["vulnix", "--version"], 30),
        "scanner_command": command,
        "scanner_exit_code": code,
        "toolchain_nixpkgs": json.loads((ROOT / "src/flake.lock").read_text())["nodes"][
            "nixpkgs"
        ]["locked"],
        "minimum_cvss": config["minimum_cvss"],
        "allow_failure": config["allow_failure"],
        "suppressions": {
            "path": str(config["policy_path"]),
            "sha256": hashlib.sha256(config["policy_path"].read_bytes()).hexdigest(),
            "rules": rules,
        },
        "unavailable_derivers": sorted(
            path
            for path, info in closure.items()
            if not info.get("deriver") or not Path(info["deriver"]).exists()
        ),
        "findings": findings(raw, rules, config["minimum_cvss"], closure),
    }
    compare_previous(report, directory)
    write_json(directory / "report.json", report)
    needs_review = display(report, config)
    print(f"\nReport: {directory / 'report.json'}")
    if needs_review:
        if config["allow_failure"]:
            print(
                "SECURITY_SCAN_ALLOW_FAILURE=1: continuing with candidates awaiting review."
            )
            return 0
        print("Security check requires review of the candidates above.")
        return 1
    print("No unsuppressed candidates meet the review policy.")
    return 0


def main():
    directory = None
    try:
        config = settings()
        config["report_dir"].mkdir(parents=True, exist_ok=True)
        stamp = dt.datetime.now(dt.timezone.utc).strftime("%Y%m%d-%H%M%S")
        prefix = f"security-scan-{config['host']}-{config['target']}-{stamp}-"
        directory = Path(tempfile.mkdtemp(prefix=prefix, dir=config["report_dir"]))
        print(f"Scan artifacts: {directory}", flush=True)
        return scan(config, directory)
    except (OSError, ValueError, TypeError, RuntimeError, TimeoutError) as error:
        if directory:
            write_json(
                directory / "report.json",
                {"schema_version": 1, "status": "failed", "error": str(error)},
            )
        print(f"Security scan failed: {error}", file=sys.stderr)
        return 2
    except KeyboardInterrupt:
        if directory:
            write_json(
                directory / "report.json",
                {"schema_version": 1, "status": "interrupted"},
            )
        print("Security scan interrupted.", file=sys.stderr)
        return 130


def interrupt(_signum, _frame):
    raise KeyboardInterrupt


if __name__ == "__main__":
    signal.signal(signal.SIGTERM, interrupt)
    sys.exit(main())
