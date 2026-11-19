"""Scan a Nix closure and retain candidate findings with their triage evidence."""

import argparse
import csv
import datetime as dt
import hashlib
import json
import math
import os
import re
import shutil
import signal
import socket
import subprocess
import sys
import tempfile
import textwrap
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CVE = re.compile(r"CVE-\d{4}-\d+")


class Console:
    """Render scan progress and findings for a terminal."""

    RESET = "\033[0m"
    CYAN = "\033[0;36m"
    GREEN = "\033[0;32m"
    YELLOW = "\033[0;33m"
    RED = "\033[0;31m"
    MAGENTA = "\033[0;35m"

    def __init__(self):
        self.color = "NO_COLOR" not in os.environ and (
            sys.stdout.isatty() or os.environ.get("CLICOLOR_FORCE") == "1"
        )
        self.width = max(60, min(shutil.get_terminal_size((100, 24)).columns, 120))

    def paint(self, text, color):
        return f"{color}{text}{self.RESET}" if self.color else text

    def line(self, text="", color=None, file=None):
        print(self.paint(text, color) if color else text, file=file, flush=True)

    def info(self, text):
        self.line(f"➜ INFO: {text}", self.CYAN)

    def warning(self, text):
        self.line(f"➜ WARNING: {text}", self.YELLOW)

    def success(self, text):
        self.line(f"➜ SUCCESS: {text}", self.GREEN)

    def error(self, text):
        self.line(f"➜ ERROR: {text}", self.RED, sys.stderr)


CONSOLE = Console()


def write_json(path, value):
    temporary = path.with_suffix(f"{path.suffix}.tmp")
    temporary.write_text(json.dumps(value, indent=2) + "\n")
    temporary.replace(path)


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
                        elapsed = (
                            round(timeout - remaining) if timeout is not None else 0
                        )
                        CONSOLE.info(
                            f"{command[0]} is still running ({elapsed}s elapsed)"
                        )
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
            CONSOLE.warning(f"Suppression expired: {cve} / {pname} ({expiry})")
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


def finding_keys(report, status=None):
    return {
        (row["pname"], row["version"], row["cve"])
        for row in report["findings"]
        if status is None or row["status"] == status
    }


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
            old, new = finding_keys(previous), finding_keys(report)
            old_review = finding_keys(previous, "review")
            new_review = finding_keys(report, "review")
        except (OSError, ValueError, KeyError, TypeError):
            continue
        report["comparison"] = {
            "report": str(previous_path),
            "added": sorted(new - old),
            "removed": sorted(old - new),
            "review_added": sorted(new_review - old_review),
            "review_removed": sorted(old_review - new_review),
        }
        return


def severity(score):
    if score is None:
        return "Unknown"
    if score >= 9:
        return "Critical"
    if score >= 7:
        return "High"
    if score >= 4:
        return "Medium"
    if score > 0:
        return "Low"
    return "Unknown"


def score_text(score):
    return "unknown" if score is None else f"{score:g}"


def severity_color(score):
    if score is None or score >= 9:
        return CONSOLE.RED
    if score >= 7:
        return CONSOLE.YELLOW
    if score >= 4:
        return CONSOLE.MAGENTA
    return CONSOLE.CYAN


def comparison_counts(comparison):
    if not comparison:
        return None
    added = comparison.get("review_added", comparison.get("added", []))
    removed = comparison.get("review_removed", comparison.get("removed", []))
    return len(added), len(removed)


def comparison_changes(comparison):
    if not comparison:
        return set(), set()
    added = comparison.get("review_added", comparison.get("added", []))
    removed = comparison.get("review_removed", comparison.get("removed", []))
    return {tuple(item) for item in added}, {tuple(item) for item in removed}


def print_changes(label, changes):
    if not changes:
        return
    preview = sorted(changes)[:5]
    rendered = ", ".join(f"{pname} {version} {cve}" for pname, version, cve in preview)
    remainder = (
        f" (+{len(changes) - len(preview)} more)" if len(changes) > len(preview) else ""
    )
    CONSOLE.line(f"   {label}: {rendered}{remainder}")


def print_trace(trace):
    for line in trace.splitlines():
        CONSOLE.line(f"   │ {line}")


def trace_target(derivation, runtime_outputs):
    if runtime_outputs:
        return preferred_output(runtime_outputs)
    try:
        outputs = checked(["nix-store", "--query", "--outputs", derivation], 30)
    except (RuntimeError, TimeoutError):
        return None
    return preferred_output(outputs.splitlines())


def preferred_output(outputs):
    if not outputs:
        return None
    secondary = ("-bin", "-lib", "-data")
    ignored = ("-dev", "-doc", "-man", "-info", "-static", "-debug", "-devdoc")
    for candidate in outputs:
        if not candidate.endswith((*secondary, *ignored)):
            return candidate
    for suffix in secondary:
        for candidate in outputs:
            if candidate.endswith(suffix):
                return candidate
    return outputs[0]


def print_finding(row, final):
    branch = "└─" if final else "├─"
    continuation = "  " if final else "│ "
    score = row["cvss"]
    changed = " · NEW" if row.get("new") else ""
    label = f"{row['cve']}  CVSS {score_text(score)} · {severity(score)}{changed}"
    CONSOLE.line(f"   {branch} {CONSOLE.paint(label, severity_color(score))}")
    description = (
        " ".join(row["description"].split()) or "No short description available."
    )
    for line in textwrap.wrap(
        description,
        width=max(30, CONSOLE.width - 9),
        break_long_words=False,
        break_on_hyphens=False,
    ):
        CONSOLE.line(f"   {continuation}  {line}")
    CONSOLE.line(f"   {continuation}  https://nvd.nist.gov/vuln/detail/{row['cve']}")


def display(report, config, summary_only=False):
    rows = report["findings"]
    review = [row for row in rows if row["status"] == "review"]
    grouped = {}
    for row in review:
        grouped.setdefault(
            (row["pname"], row["version"], row["derivation"]), []
        ).append(row)
    groups = sorted(
        grouped.items(),
        key=lambda item: (
            -max(row["cvss"] if row["cvss"] is not None else 10 for row in item[1]),
            item[0][0],
            item[0][1],
        ),
    )
    suppressed = sum(row["status"] == "suppressed" for row in rows)
    below = sum(row["status"] == "below-threshold" for row in rows)
    distinct = len({row["cve"] for row in rows})
    review_distinct = len({row["cve"] for row in review})
    comparison = comparison_counts(report.get("comparison"))
    added, removed = comparison_changes(report.get("comparison"))
    identity_gaps = sum(not row["runtime_outputs"] for row in review)

    if review:
        CONSOLE.warning(
            f"{len(review)} entries across {len(groups)} package nodes require review "
            f"({review_distinct} distinct CVEs)"
        )
    else:
        CONSOLE.success("No unsuppressed findings meet the review policy")
    CONSOLE.line(
        f"   Scan totals: {len(rows)} entries · {distinct} distinct CVEs · "
        f"{below} below CVSS {config['minimum_cvss']:g} · {suppressed} suppressed"
    )
    if comparison:
        added_count, removed_count = comparison
        baseline = Path(report["comparison"]["report"]).parent.name
        if added_count or removed_count:
            CONSOLE.line(
                f"   Since {baseline}: {added_count} review entries added · "
                f"{removed_count} removed"
            )
        else:
            CONSOLE.line(f"   Since {baseline}: review findings unchanged")
        print_changes("Added", added)
        print_changes("Removed", removed)
    if identity_gaps:
        CONSOLE.warning(
            f"{identity_gaps} finding entries lack a directly matched runtime output; "
            "their dependency traces require review"
        )
    CONSOLE.line(
        "   Name/version matches require triage; closure membership alone does not prove exploitability."
    )
    if summary_only:
        return bool(review)

    for index, ((pname, version, derivation), group) in enumerate(groups, 1):
        maximum = max(row["cvss"] if row["cvss"] is not None else 10 for row in group)
        CONSOLE.line()
        heading = (
            f"➜ [{index}/{len(groups)}] {pname} {version} · {len(group)} "
            f"{'finding' if len(group) == 1 else 'findings'} · "
            f"max CVSS {score_text(maximum)} {severity(maximum)}"
        )
        CONSOLE.line(heading, severity_color(maximum))
        outputs = group[0]["runtime_outputs"]
        if outputs:
            suffix = f" (+{len(outputs) - 1} more)" if len(outputs) > 1 else ""
            CONSOLE.line(f"   Runtime: {preferred_output(outputs)}{suffix}")
        else:
            CONSOLE.line(
                "   Runtime: identity unavailable; finding retained for review"
            )
        CONSOLE.line(f"   Derivation: {derivation}")
        trace_requested = config["evidence"] == "always" or (
            config["evidence"] == "auto" and not outputs
        )
        target_output = trace_target(derivation, outputs) if trace_requested else None
        if trace_requested and target_output:
            try:
                trace = checked(
                    ["nix", "why-depends", report["store_path"], target_output],
                    config["trace_timeout"],
                )
                CONSOLE.line("   Trace:")
                print_trace(trace)
            except (RuntimeError, TimeoutError) as error:
                CONSOLE.line(f"   Trace unavailable: {error}")
        elif trace_requested:
            CONSOLE.line(
                "   Trace unavailable: derivation outputs are no longer present"
            )
        CONSOLE.line("   Vulnerabilities:")
        for finding_index, row in enumerate(group):
            shortened = dict(row)
            shortened["new"] = (row["pname"], row["version"], row["cve"]) in added
            description = " ".join(row["description"].split())
            if len(description) > config["description_length"]:
                description = description[: config["description_length"]].rstrip() + "…"
            shortened["description"] = description
            print_finding(shortened, finding_index == len(group) - 1)
    return bool(review)


def scan(config, directory):
    started_at = dt.datetime.now(dt.UTC)
    started = time.monotonic()
    rules = load_policy(
        config["policy_path"],
        dt.datetime.now(dt.UTC).date(),
        config["enforce_expiry"],
    )
    if config["target"] == "system":
        CONSOLE.info("Resolving the running system closure")
        target = Path("/run/current-system").resolve(strict=True)
    else:
        flake = f"path:{ROOT}/src#nixosConfigurations.{config['host']}.config.system.build.toplevel"
        CONSOLE.info(f"Building the configured system for {config['host']}")
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
    CONSOLE.info(f"Scanning {len(closure)} closure paths with vulnix")
    CONSOLE.line(f"   Target: {target}")
    CONSOLE.line(f"   Scope: {config['scope']}")
    CONSOLE.line(f"   Review threshold: CVSS {config['minimum_cvss']:g}")
    CONSOLE.line(f"   Suppressions: {config['policy_path']}")
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
        "created_at": started_at.isoformat(),
        "duration_seconds": round(time.monotonic() - started, 3),
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
    report["coverage"] = {
        "closure_paths": len(closure),
        "paths_without_available_deriver": len(report["unavailable_derivers"]),
        "findings_without_runtime_identity": sum(
            not row["runtime_outputs"] for row in report["findings"]
        ),
    }
    compare_previous(report, directory)
    write_json(directory / "report.json", report)
    needs_review = display(report, config, config["summary_only"])
    CONSOLE.line()
    CONSOLE.info(f"Report: {directory / 'report.json'}")
    if needs_review:
        if config["allow_failure"]:
            CONSOLE.info(
                "SECURITY_SCAN_ALLOW_FAILURE=1; continuing with findings awaiting review"
            )
            return 0
        CONSOLE.error("Security check requires review of the findings above")
        return 1
    return 0


def arguments():
    parser = argparse.ArgumentParser(
        description="Scan a NixOS closure with vulnix and retain triage evidence."
    )
    parser.add_argument(
        "--report",
        type=Path,
        metavar="REPORT",
        help="render an existing report.json or report directory without running a scan",
    )
    parser.add_argument(
        "--summary",
        action="store_true",
        help="show scan totals and changes without per-package details",
    )
    return parser.parse_args()


def report_path(path):
    resolved = path.resolve(strict=True)
    return resolved / "report.json" if resolved.is_dir() else resolved


def render_report(path, config, summary_only=False):
    path = report_path(path)
    report = json.loads(path.read_text())
    if report.get("status") != "complete" or not isinstance(
        report.get("findings"), list
    ):
        raise ValueError(f"{path} is not a completed security scan report")
    config = {
        **config,
        "minimum_cvss": report.get("minimum_cvss", config["minimum_cvss"]),
        "evidence": "never",
    }
    CONSOLE.info(
        f"Rendering saved report from {report.get('created_at', 'unknown time')}"
    )
    CONSOLE.line(f"   Host: {report.get('host', 'unknown')}")
    CONSOLE.line(f"   Target: {report.get('store_path', 'unknown')}")
    scanner = report.get("scanner", "unknown scanner")
    revision = report.get("toolchain_nixpkgs", {}).get("rev", "unknown")[:12]
    duration = report.get("duration_seconds")
    metadata = f"   Scanner: {scanner} · nixpkgs {revision}"
    if duration is not None:
        metadata += f" · {duration:g}s"
    CONSOLE.line(metadata)
    display(report, config, summary_only)
    CONSOLE.line()
    CONSOLE.info(f"Report: {path.resolve()}")
    return 1 if any(row["status"] == "review" for row in report["findings"]) else 0


def main():
    directory = None
    try:
        options = arguments()
        config = settings()
        if options.report:
            return render_report(options.report, config, options.summary)
        config["summary_only"] = options.summary
        config["report_dir"].mkdir(parents=True, exist_ok=True)
        stamp = dt.datetime.now(dt.UTC).strftime("%Y%m%d-%H%M%S")
        prefix = f"security-scan-{config['host']}-{config['target']}-{stamp}-"
        directory = Path(tempfile.mkdtemp(prefix=prefix, dir=config["report_dir"]))
        CONSOLE.info(f"Scan artifacts: {directory}")
        return scan(config, directory)
    except (OSError, ValueError, TypeError, RuntimeError, TimeoutError) as error:
        if directory:
            write_json(
                directory / "report.json",
                {"schema_version": 1, "status": "failed", "error": str(error)},
            )
        CONSOLE.error(f"Security scan failed: {error}")
        return 2
    except KeyboardInterrupt:
        if directory:
            write_json(
                directory / "report.json",
                {"schema_version": 1, "status": "interrupted"},
            )
        CONSOLE.error("Security scan interrupted")
        return 130


def interrupt(_signum, _frame):
    raise KeyboardInterrupt


if __name__ == "__main__":
    signal.signal(signal.SIGTERM, interrupt)
    sys.exit(main())
