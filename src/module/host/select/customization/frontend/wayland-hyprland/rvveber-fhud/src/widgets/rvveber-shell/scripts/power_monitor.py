#!/usr/bin/env python3

import argparse
import json
import math
import os
import statistics
import time
from collections import defaultdict, deque
from pathlib import Path


SAMPLE_SECONDS = 5.0
WINDOW_SECONDS = 25.0 * 60.0
MAX_TIME_SECONDS = 24.0 * 60.0 * 60.0
MIN_ESTIMATE_SECONDS = 60.0
MIN_ESTIMATE_POWER_W = 1.0


def read_text(path):
    try:
        value = path.read_text().strip()
    except (FileNotFoundError, PermissionError, OSError):
        return None
    return value if value and value.lower() not in {"unknown", "n/a"} else None


def read_number(path):
    value = read_text(path)
    if value is None:
        return None
    try:
        number = float(value)
    except ValueError:
        return None
    return number if math.isfinite(number) else None


def rounded(value, digits=3):
    return round(value, digits) if value is not None and math.isfinite(value) else None


def first_number(path, names):
    for name in names:
        value = read_number(path / name)
        if value is not None:
            return value, name
    return None, None


def discover_supplies(root):
    supplies = []
    try:
        paths = sorted(path for path in root.iterdir() if path.is_dir())
    except (FileNotFoundError, PermissionError, OSError):
        return supplies
    for path in paths:
        supplies.append({
            "path": path,
            "name": path.name,
            "type": read_text(path / "type") or "Unknown",
        })
    return supplies


def battery_paths(supplies):
    batteries = [item["path"] for item in supplies if item["type"] == "Battery" and item["name"].upper().startswith("BAT")]
    if batteries:
        return batteries
    return [item["path"] for item in supplies if item["type"] == "Battery" and read_text(item["path"] / "scope") == "System"]


def external_power(supplies):
    external_types = {"Mains", "USB", "USB_C", "USB_PD"}
    candidates = [item for item in supplies if item["type"] in external_types or item["name"].upper().startswith(("AC", "ADP", "USB"))]
    online = [item["name"] for item in candidates if read_number(item["path"] / "online") == 1]
    return bool(online), online, [item["name"] for item in candidates]


def battery_values(path):
    voltage_uv, voltage_field = first_number(path, ("voltage_now", "voltage_avg", "voltage_min_design"))
    design_voltage_uv, _ = first_number(path, ("voltage_min_design", "voltage_now"))
    energy_now_uwh = read_number(path / "energy_now")
    energy_full_uwh = read_number(path / "energy_full")
    energy_design_uwh = read_number(path / "energy_full_design")
    charge_now_uah = read_number(path / "charge_now")
    charge_full_uah = read_number(path / "charge_full")
    charge_design_uah = read_number(path / "charge_full_design")

    energy_source = None
    if energy_now_uwh is not None:
        energy_now_wh = energy_now_uwh / 1_000_000.0
        energy_source = path.name + "/energy_now"
        energy_estimated = False
    elif charge_now_uah is not None and voltage_uv is not None:
        energy_now_wh = charge_now_uah * voltage_uv / 1_000_000_000_000.0
        energy_source = path.name + "/charge_now × " + path.name + "/" + voltage_field
        energy_estimated = True
    else:
        energy_now_wh = None
        energy_estimated = False

    if energy_full_uwh is not None:
        energy_full_wh = energy_full_uwh / 1_000_000.0
    elif charge_full_uah is not None and design_voltage_uv is not None:
        energy_full_wh = charge_full_uah * design_voltage_uv / 1_000_000_000_000.0
    else:
        energy_full_wh = None

    if energy_design_uwh is not None:
        energy_design_wh = energy_design_uwh / 1_000_000.0
    elif charge_design_uah is not None and design_voltage_uv is not None:
        energy_design_wh = charge_design_uah * design_voltage_uv / 1_000_000_000_000.0
    else:
        energy_design_wh = None

    power_uw = read_number(path / "power_now")
    current_ua = read_number(path / "current_now")
    if power_uw is not None:
        power_w = abs(power_uw) / 1_000_000.0
        power_source = path.name + "/power_now"
    elif current_ua is not None and voltage_uv is not None:
        power_w = abs(current_ua * voltage_uv) / 1_000_000_000_000.0
        power_source = "Calculated from " + path.name + "/current_now × " + path.name + "/" + voltage_field
    else:
        power_w = None
        power_source = "Unavailable"

    return {
        "path": path.name,
        "status": read_text(path / "status") or "Unknown",
        "capacity": read_number(path / "capacity"),
        "energyNowWh": energy_now_wh,
        "energyFullWh": energy_full_wh,
        "energyFullDesignWh": energy_design_wh,
        "energyEstimated": energy_estimated,
        "energySource": energy_source or "Unavailable",
        "powerW": power_w,
        "powerSource": power_source,
        "currentA": current_ua / 1_000_000.0 if current_ua is not None else None,
        "voltageV": voltage_uv / 1_000_000.0 if voltage_uv is not None else None,
        "timeToEmptySeconds": read_number(path / "time_to_empty_now"),
        "timeToFullSeconds": read_number(path / "time_to_full_now"),
        "chargeStartThreshold": read_number(path / "charge_control_start_threshold"),
        "chargeEndThreshold": read_number(path / "charge_control_end_threshold"),
    }


def aggregate_batteries(paths):
    values = [battery_values(path) for path in paths]
    if not values:
        return None

    def total(name):
        present = [item[name] for item in values if item[name] is not None]
        return sum(present) if present else None

    statuses = [item["status"] for item in values]
    status_order = ("Charging", "Discharging", "Not charging", "Full", "Unknown")
    status = next((candidate for candidate in status_order if candidate in statuses), statuses[0])
    energy_now = total("energyNowWh")
    energy_full = total("energyFullWh")
    capacity = 100.0 * energy_now / energy_full if energy_now is not None and energy_full and energy_full > 0 else None
    if capacity is None:
        available = [item["capacity"] for item in values if item["capacity"] is not None]
        capacity = sum(available) / len(available) if available else None
    power_values = [item["powerW"] for item in values if item["powerW"] is not None]
    power_w = sum(power_values) if power_values else None
    return {
        "path": ", ".join(item["path"] for item in values),
        "status": status,
        "capacity": rounded(capacity, 1),
        "energyNowWh": rounded(energy_now),
        "energyFullWh": rounded(energy_full),
        "energyFullDesignWh": rounded(total("energyFullDesignWh")),
        "energyEstimated": any(item["energyEstimated"] for item in values if item["energyNowWh"] is not None),
        "energySource": "; ".join(item["energySource"] for item in values),
        "powerW": rounded(power_w),
        "powerSource": "; ".join(item["powerSource"] for item in values),
        "currentA": rounded(total("currentA"), 6),
        "voltageV": rounded(values[0]["voltageV"], 6),
        "timeToEmptySeconds": rounded(max((item["timeToEmptySeconds"] or 0 for item in values), default=0)),
        "timeToFullSeconds": rounded(max((item["timeToFullSeconds"] or 0 for item in values), default=0)),
        "chargeStartThreshold": values[0]["chargeStartThreshold"],
        "chargeEndThreshold": values[0]["chargeEndThreshold"],
    }


class PowerHistory:
    def __init__(self, window_seconds=WINDOW_SECONDS):
        self.window_seconds = window_seconds
        self.samples = deque(maxlen=302)
        self.ema_w = None

    def add(self, now, kind, power_w):
        if power_w is not None and math.isfinite(power_w) and 0 <= power_w <= 250:
            self.samples.append((now, kind, power_w))
            self.ema_w = power_w if self.ema_w is None else 0.25 * power_w + 0.75 * self.ema_w
        cutoff = now - self.window_seconds
        while self.samples and self.samples[0][0] < cutoff:
            self.samples.popleft()

    def stable_power(self, now, kind):
        recent = [(stamp, power) for stamp, sample_kind, power in self.samples if sample_kind == kind and stamp >= now - 120]
        if len(recent) < 8 or recent[-1][0] - recent[0][0] < MIN_ESTIMATE_SECONDS:
            return None
        powers = [power for _, power in recent]
        mean = statistics.fmean(powers)
        if mean < MIN_ESTIMATE_POWER_W or statistics.pstdev(powers) / mean > 0.35:
            return None
        ema = powers[0]
        for power in powers[1:]:
            ema = 0.25 * power + 0.75 * ema
        return ema

    def summary(self, kind):
        samples = [(stamp, power) for stamp, sample_kind, power in self.samples if sample_kind == kind]
        if not samples:
            return {"averageW": None, "peakW": None, "energyWh": None, "durationSeconds": 0, "sampleCount": 0}
        energy_wh = 0.0
        duration = 0.0
        for previous, current in zip(samples, samples[1:]):
            delta = current[0] - previous[0]
            if 0 < delta <= SAMPLE_SECONDS * 2.5:
                duration += delta
                energy_wh += (previous[1] + current[1]) * 0.5 * delta / 3600.0
        average = energy_wh * 3600.0 / duration if duration > 0 else samples[-1][1]
        return {
            "averageW": rounded(average, 1),
            "peakW": rounded(max(power for _, power in samples), 1),
            "energyWh": rounded(energy_wh, 2),
            "durationSeconds": rounded(duration, 1),
            "sampleCount": len(samples),
        }


def parse_proc_stat(text):
    closing = text.rfind(")")
    opening = text.find("(")
    if opening < 0 or closing <= opening:
        return None
    try:
        fields = text[closing + 2:].split()
        return text[opening + 1:closing], int(fields[11]) + int(fields[12]), int(fields[19])
    except (ValueError, IndexError):
        return None


def proc_snapshot(proc_root):
    snapshot = {}
    try:
        paths = proc_root.iterdir()
    except (FileNotFoundError, PermissionError, OSError):
        return snapshot
    for path in paths:
        if not path.name.isdigit():
            continue
        text = read_text(path / "stat")
        parsed = parse_proc_stat(text) if text else None
        if parsed is None:
            continue
        name, ticks, starttime = parsed
        if name.startswith(".quickshell-"):
            name = "quickshell"
        elif name.startswith(".Hyprland-"):
            name = "Hyprland"
        elif name.startswith(".") and name.endswith("-wrapped"):
            name = name[1:-8]
        elif name.startswith(".") or name.endswith(("-wrap", "-wrapper")):
            try:
                name = Path(os.readlink(path / "exe")).name
            except (FileNotFoundError, PermissionError, OSError):
                pass
        snapshot[(int(path.name), starttime)] = (name, ticks)
    return snapshot


class ProcessImpact:
    def __init__(self, clock_ticks, window_seconds=WINDOW_SECONDS):
        self.clock_ticks = clock_ticks
        self.window_seconds = window_seconds
        self.previous = {}
        self.intervals = deque(maxlen=302)
        self.latest_activity = {}

    def ingest(self, now, snapshot):
        deltas = defaultdict(float)
        identities = []
        for identity, (name, ticks) in snapshot.items():
            previous = self.previous.get(identity)
            if previous is not None and ticks >= previous[1]:
                delta = (ticks - previous[1]) / self.clock_ticks
                if delta > 0:
                    deltas[name] += delta
                    identities.append((identity, name, delta))
        self.previous = snapshot
        self.latest_activity = dict(deltas)
        self.intervals.append((now, dict(deltas), identities))
        cutoff = now - self.window_seconds
        while self.intervals and self.intervals[0][0] < cutoff:
            self.intervals.popleft()

    def report(self, now, debug=False):
        totals = defaultdict(float)
        identity_totals = defaultdict(float)
        identity_names = {}
        identity_latest = defaultdict(float)
        for _, deltas, identities in self.intervals:
            for name, delta in deltas.items():
                totals[name] += delta
            for identity, name, delta in identities:
                identity_totals[identity] += delta
                identity_names[identity] = name
                identity_latest[identity] = delta
        total = sum(totals.values())
        processes = []
        for name, score in sorted(totals.items(), key=lambda item: (-item[1], item[0]))[:4]:
            share = score * 100.0 / total if total > 0 else 0
            level = "High" if share >= 50 else "Medium" if share >= 20 else "Low"
            processes.append({
                "name": name,
                "share": rounded(share, 1),
                "score": rounded(score, 2),
                "level": level,
                "active": self.latest_activity.get(name, 0) >= 0.5,
            })
        result = {
            "processes": processes,
            "source": "Estimated from accumulated CPU time; percentage is share of observed CPU-time impact",
        }
        if debug:
            result["debugProcesses"] = [
                {
                    "process": identity_names[identity],
                    "pid": identity[0],
                    "starttime": identity[1],
                    "cpuDeltaSeconds": rounded(identity_latest[identity], 2),
                    "accumulatedCpuSeconds": rounded(score, 2),
                    "computedScore": rounded(score, 2),
                    "gpuDelta": None,
                }
                for identity, score in sorted(identity_totals.items(), key=lambda item: -item[1])[:20]
            ]
        return result


def valid_kernel_time(seconds):
    return seconds if seconds is not None and 0 < seconds <= MAX_TIME_SECONDS else None


def gpu_sample(drm_root):
    try:
        cards = sorted(path for path in drm_root.glob("card[0-9]*") if path.is_dir())
    except (PermissionError, OSError):
        cards = []
    for card in cards:
        source = card / "device" / "gpu_busy_percent"
        busy = read_number(source)
        if busy is not None and 0 <= busy <= 100:
            return {"busyPercent": rounded(busy, 1), "source": str(source)}
    return {"busyPercent": None, "source": "Unavailable"}


def estimated_time_text(battery, kind, history, now):
    kernel_seconds = valid_kernel_time(battery["timeToFullSeconds"] if kind == "battery_charge" else battery["timeToEmptySeconds"])
    if kernel_seconds:
        return format_time(kernel_seconds, kind), "Kernel power_supply estimate"
    power_w = history.stable_power(now, kind)
    if power_w is None:
        return "Calculating…", "Waiting for at least 60 seconds of stable battery power"
    if kind == "battery_charge":
        energy = (battery["energyFullWh"] or 0) - (battery["energyNowWh"] or 0)
    else:
        energy = battery["energyNowWh"]
    if energy is None or energy <= 0:
        return "Calculating…", "Battery energy unavailable"
    seconds = energy / power_w * 3600.0
    if seconds <= 0 or seconds > MAX_TIME_SECONDS:
        return "Calculating…", "Estimated time outside the reliable range"
    return format_time(seconds, kind), "Estimated from stable battery energy rate"


def format_time(seconds, kind):
    minutes = max(1, int(round(seconds / 60.0)))
    hours, minutes = divmod(minutes, 60)
    value = (str(hours) + "h " if hours else "") + str(minutes) + "m"
    return "Full in " + value if kind == "battery_charge" else value + " remaining"


def thresholds_from_environment():
    raw = os.environ.get("RVVEBER_FHUD_POWER_THRESHOLDS_W", "10,20,30")
    try:
        values = tuple(float(part.strip()) for part in raw.split(","))
    except ValueError:
        values = ()
    return values if len(values) == 3 and 0 < values[0] < values[1] < values[2] else (10.0, 20.0, 30.0)


def anomaly(kind, power_w, thresholds, impact, gpu=None):
    if kind != "system_draw" or power_w is None:
        return {"level": "unknown", "label": "Not assessed", "detail": "System draw is only inferred while discharging"}
    low, moderate, elevated = thresholds
    if power_w < low:
        level, label = "low", "Low"
    elif power_w < moderate:
        level, label = "moderate", "Moderate"
    elif power_w < elevated:
        level, label = "elevated", "Elevated"
    else:
        level, label = "high", "Unusually high"
    detail = "Battery discharge rate · configurable UI hint"
    if level == "high" and impact["processes"] and impact["processes"][0]["share"] >= 40 and impact["processes"][0]["active"]:
        detail = "High drain · " + impact["processes"][0]["name"] + " active"
    elif level == "high" and gpu and gpu["busyPercent"] is not None and gpu["busyPercent"] >= 50:
        detail = "High drain · AMD GPU " + str(int(round(gpu["busyPercent"]))) + "% busy"
    return {"level": level, "label": label, "detail": detail}


class Monitor:
    def __init__(self, power_root=Path("/sys/class/power_supply"), proc_root=Path("/proc"), debug=False, monotonic=time.monotonic, drm_root=Path("/sys/class/drm")):
        self.power_root = power_root
        self.proc_root = proc_root
        self.debug = debug
        self.drm_root = drm_root
        self.monotonic = monotonic
        self.started = monotonic()
        self.sample_count = 0
        self.history = PowerHistory()
        self.impact = ProcessImpact(os.sysconf("SC_CLK_TCK"))
        self.thresholds = thresholds_from_environment()

    def sample(self):
        now = self.monotonic()
        supplies = discover_supplies(self.power_root)
        paths = battery_paths(supplies)
        battery = aggregate_batteries(paths)
        ac_connected, online_sources, external_sources = external_power(supplies)
        self.impact.ingest(now, proc_snapshot(self.proc_root))
        impact = self.impact.report(now, self.debug)
        gpu = gpu_sample(self.drm_root)
        self.sample_count += 1
        if battery is None:
            return {"ready": False, "sampleCount": self.sample_count, "error": "No system battery found", "impact": impact}

        status = battery["status"].lower()
        battery_supplementing_external_power = ac_connected and "discharg" in status
        if "discharg" in status or not ac_connected:
            kind = "system_draw"
            summary_label = "POWER DEFICIT · 25 MIN" if battery_supplementing_external_power else "SYSTEM DRAW · 25 MIN"
        elif "charg" in status and "not" not in status and (battery["powerW"] or 0) > 0:
            kind = "battery_charge"
            summary_label = "BATTERY CHARGE · 25 MIN"
        else:
            kind = "battery_idle"
            summary_label = "BATTERY RATE · 25 MIN"
        self.history.add(now, kind, battery["powerW"])
        summary = self.history.summary(kind)
        time_text, time_source = estimated_time_text(battery, kind, self.history, now) if kind in {"system_draw", "battery_charge"} else ("Calculating…", "Battery is not currently charging or discharging")
        history_seconds = min(WINDOW_SECONDS, max(0.0, now - self.started))
        result = {
            "ready": True,
            "timestamp": int(time.time()),
            "sampleCount": self.sample_count,
            "historySeconds": rounded(history_seconds, 1),
            "battery": battery,
            "power": {
                "acConnected": ac_connected,
                "batterySupplementingExternalPower": battery_supplementing_external_power,
                "onlineSources": online_sources,
                "detectedSources": external_sources,
            },
            "rate": {
                "watts": battery["powerW"],
                "kind": kind,
            },
            "time": {"text": time_text, "source": time_source},
            "summary": {**summary, "label": summary_label},
            "impact": impact,
            "gpu": gpu,
            "anomaly": anomaly(kind, battery["powerW"], self.thresholds, impact, gpu),
        }
        if self.debug:
            result["debug"] = {
                "enabled": True,
                "batteryPaths": [path.name for path in paths],
                "rawStatus": battery["status"],
                "capacity": battery["capacity"],
                "energyNowWh": battery["energyNowWh"],
                "energyFullWh": battery["energyFullWh"],
                "powerW": battery["powerW"],
                "currentA": battery["currentA"],
                "voltageV": battery["voltageV"],
                "acOnline": ac_connected,
                "sampleCount": self.sample_count,
                "historySeconds": rounded(history_seconds, 1),
                "gpuBusyPercent": gpu["busyPercent"],
                "gpuSource": gpu["source"],
            }
        return result


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--once", action="store_true")
    parser.add_argument("--power-root", type=Path, default=Path("/sys/class/power_supply"))
    parser.add_argument("--proc-root", type=Path, default=Path("/proc"))
    parser.add_argument("--drm-root", type=Path, default=Path("/sys/class/drm"))
    arguments = parser.parse_args()
    debug = os.environ.get("RVVEBER_FHUD_POWER_DEBUG") == "1"
    monitor = Monitor(arguments.power_root, arguments.proc_root, debug, drm_root=arguments.drm_root)
    while True:
        print(json.dumps(monitor.sample(), separators=(",", ":")), flush=True)
        if arguments.once:
            break
        time.sleep(SAMPLE_SECONDS)


if __name__ == "__main__":
    main()
