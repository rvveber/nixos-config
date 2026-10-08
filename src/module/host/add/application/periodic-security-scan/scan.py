"""Inventory an immutable system closure, retain Grype evidence and notify users."""

import datetime as dt
import hashlib
import json
import os
import re
import shutil
import signal
import subprocess
import sys
import tempfile
from pathlib import Path


def write_json(path, data):
    temporary = path.with_suffix(".tmp")
    temporary.write_text(json.dumps(data, indent=2) + "\n")
    temporary.replace(path)


def read_json(path):
    return json.loads(path.read_text())


def run(command, log, output=None, **kwargs):
    subprocess.run(command, check=True, stdout=output or log, stderr=log, **kwargs)


def inventory(paths, target, output, log):
    # The execution store is outside /scan. Syft rebases absolute symlinks into
    # /scan, where only closure members exist; mutable host directories are absent.
    # Syft needs no /proc. Leave it absent: the service's ProtectKernelTunables
    # masks prevent mounting a fresh procfs inside an unprivileged user namespace.
    arguments = [
        "--unshare-all",
        "--die-with-parent",
        "--new-session",
        "--ro-bind",
        "/nix/store",
        "/nix/store",
        "--dev",
        "/dev",
        "--tmpfs",
        "/tmp",
        "--tmpfs",
        "/scan",
        "--dir",
        "/scan/nix/store",
        "--chdir",
        "/tmp",
        "--setenv",
        "HOME",
        "/tmp",
        "--setenv",
        "SYFT_CHECK_FOR_APP_UPDATE",
        "false",
    ]
    for path in paths:
        if not re.fullmatch(r"/nix/store/[0-9a-z]{32}-[^/\s]+", path):
            raise ValueError(f"Invalid closure path: {path}")
        arguments.extend(["--ro-bind", path, f"/scan{path}"])
    arguments.extend(["--remount-ro", "/scan"])
    # A descriptor avoids ARG_MAX for large closures.
    with tempfile.TemporaryFile() as args:
        args.write(b"\0".join(os.fsencode(arg) for arg in arguments) + b"\0")
        args.seek(0)
        run(
            [
                "bwrap",
                "--args",
                str(args.fileno()),
                "--",
                shutil.which("syft"),
                "scan",
                "dir:/scan",
                "--base-path",
                "/scan",
                "--source-name",
                target,
                "--override-default-catalogers",
                "image",
                "--parallelism",
                "2",
                "-o",
                "syft-json",
            ],
            log,
            output,
            pass_fds=(args.fileno(),),
        )


def findings(report):
    if not isinstance(report.get("matches"), list):
        raise TypeError("Grype report has no matches array")
    identities = set()
    types = {}
    for match in report["matches"]:
        package, advisory = match["artifact"], match["vulnerability"]
        identities.add(
            (
                package["type"],
                package["name"],
                package["version"],
                package.get("purl", ""),
                advisory["namespace"],
                advisory["id"],
            )
        )
        for kind in {detail["type"] for detail in match["matchDetails"]}:
            types[kind] = types.get(kind, 0) + 1
    return sorted(identities), types


def scan(state, directory, previous, log):
    target = str(Path("/run/current-system").resolve(strict=True))
    root = directory / "system"
    try:
        # Keep the snapshot alive if a rebuild and garbage collection overlap us.
        run(
            ["nix-store", "--add-root", str(root), "--indirect", "--realise", target],
            log,
        )
        with (directory / "closure.txt").open("w") as output:
            run(["nix-store", "--query", "--requisites", target], log, output)
        paths = (directory / "closure.txt").read_text().splitlines()
        if target not in paths:
            raise ValueError("The runtime closure is empty or missing its system root")
        key = hashlib.sha256(
            (
                target + str(Path(__file__).resolve()) + str(shutil.which("syft"))
            ).encode()
        ).hexdigest()
        cache = state / "inventory"
        cache.mkdir(exist_ok=True)
        metadata = cache / "key"
        reused = (
            metadata.exists()
            and metadata.read_text() == key
            and (cache / "sbom.json").exists()
        )
        if not reused:
            with (cache / "sbom.tmp").open("w") as output:
                inventory(paths, target, output, log)
            sbom = read_json(cache / "sbom.tmp")
            if not isinstance(sbom.get("artifacts"), list) or not sbom["artifacts"]:
                raise ValueError("Syft returned an empty or invalid inventory")
            # Invalidate the key before replacing data, so interruptions force a rescan.
            metadata.unlink(missing_ok=True)
            (cache / "sbom.tmp").replace(cache / "sbom.json")
            metadata.write_text(key)
        os.link(cache / "sbom.json", directory / "sbom.json")
    finally:
        root.unlink(missing_ok=True)

    with (directory / "versions.txt").open("w") as output:
        for tool in ("syft", "grype"):
            run([tool, "version"], log, output)
    with (directory / "grype.json").open("w") as output:
        run(["grype", f"sbom:{directory / 'sbom.json'}", "-o", "json"], log, output)
    report = read_json(directory / "grype.json")
    identities, types = findings(report)
    old = {tuple(item) for item in previous["identities"]} if previous else set()
    current = set(identities)
    return {
        "status": "complete",
        "system": target,
        "inventory_reused": reused,
        "closure_paths": len(paths),
        "matches": len(report["matches"]),
        "candidates": len(identities),
        "match_types": types,
        "identities": identities,
        "comparison": {
            "baseline": previous["run"] if previous else None,
            "added": sorted(current - old),
            "removed": sorted(old - current),
        },
    }


def perform_scan(state):
    runs = state / "runs"
    runs.mkdir(exist_ok=True)
    previous = None
    for path in sorted(runs.glob("*/summary.json"), reverse=True):
        summary = read_json(path)
        if summary["status"] == "complete":
            previous = summary
            break
    stamp = dt.datetime.now(dt.timezone.utc).strftime("%Y%m%dT%H%M%S.%fZ-")
    directory = Path(tempfile.mkdtemp(prefix=stamp, dir=runs))
    directory.chmod(0o755)
    summary = {"status": "running"}
    write_json(directory / "summary.json", {**summary, "run": directory.name})
    try:
        with (directory / "scanner.log").open("w") as log:
            summary = scan(state, directory, previous, log)
    except (
        OSError,
        ValueError,
        KeyError,
        TypeError,
        RuntimeError,
        subprocess.CalledProcessError,
    ) as error:
        summary = {"status": "failed", "error": str(error)}
        print(f"Security scan failed: {error}", file=sys.stderr)
    summary["run"] = directory.name
    write_json(directory / "summary.json", summary)
    temporary = state / "latest.tmp"
    temporary.unlink(missing_ok=True)
    temporary.symlink_to(directory.relative_to(state))
    temporary.replace(state / "latest")
    # Keep a week of attempts and the latest successful comparison baseline.
    retained = {directory.name}
    if previous:
        retained.add(previous["run"])
    for old in sorted(runs.iterdir(), reverse=True)[7:]:
        if old.name not in retained:
            shutil.rmtree(old)
    print(f"Scan {summary['status']}: {directory}", flush=True)
    return 0 if summary["status"] == "complete" else 1


def notify(state, user_state):
    latest = state / "latest"
    if not latest.exists():
        return
    directory = latest.resolve(strict=True)
    summary = read_json(directory / "summary.json")
    marker = user_state / "notified"
    if marker.exists() and marker.read_text() == summary["run"]:
        return
    if summary["status"] == "failed":
        title = "System security scan failed"
        body = f"See {directory}/scanner.log and summary.json"
    elif summary["status"] == "complete" and summary["candidates"]:
        title = "System security scan found candidates"
        kinds = ", ".join(
            f"{count} {kind}" for kind, count in sorted(summary["match_types"].items())
        )
        body = f"{summary['candidates']} package/advisory candidates require review.\n{kinds}\nReport: {directory}/grype.json"
    else:
        return
    subprocess.run(
        [
            "notify-send",
            "--app-name=System security scan",
            "--urgency=normal",
            title,
            body,
        ],
        check=True,
        timeout=20,
    )
    user_state.mkdir(parents=True, exist_ok=True)
    marker.write_text(summary["run"])


def interrupted(_signal, _frame):
    raise RuntimeError("Scan interrupted or timed out")


if __name__ == "__main__":
    mode, state_path = sys.argv[1:]
    if mode == "notify":
        notify(Path(state_path), Path(os.environ["STATE_DIRECTORY"]))
    elif mode == "scan":
        signal.signal(signal.SIGTERM, interrupted)
        sys.exit(perform_scan(Path(state_path)))
    else:
        raise ValueError(f"Unknown mode: {mode}")
