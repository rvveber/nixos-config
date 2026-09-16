import importlib.util
import tempfile
import unittest
from pathlib import Path


MODULE_PATH = Path(__file__).parents[1] / "scripts" / "power_monitor.py"
SPEC = importlib.util.spec_from_file_location("power_monitor", MODULE_PATH)
power_monitor = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(power_monitor)


def write_supply(root, name, values):
    path = root / name
    path.mkdir()
    for key, value in values.items():
        (path / key).write_text(str(value))
    return path


class BatteryDataTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)

    def tearDown(self):
        self.temporary.cleanup()

    def test_reads_energy_and_power_fields(self):
        battery = write_supply(self.root, "BAT0", {
            "type": "Battery",
            "status": "Discharging",
            "capacity": 50,
            "energy_now": 28_200_000,
            "energy_full": 56_400_000,
            "energy_full_design": 61_000_000,
            "power_now": 9_200_000,
        })
        values = power_monitor.aggregate_batteries([battery])
        self.assertEqual(values["energyNowWh"], 28.2)
        self.assertEqual(values["energyFullWh"], 56.4)
        self.assertEqual(values["powerW"], 9.2)
        self.assertFalse(values["energyEstimated"])
        self.assertEqual(values["powerSource"], "BAT0/power_now")

    def test_calculates_power_and_energy_from_charge_and_voltage(self):
        battery = write_supply(self.root, "BAT0", {
            "type": "Battery",
            "status": "Charging",
            "charge_now": 1_000_000,
            "charge_full": 4_000_000,
            "charge_full_design": 5_000_000,
            "current_now": 2_000_000,
            "voltage_now": 12_000_000,
            "voltage_min_design": 11_000_000,
        })
        values = power_monitor.aggregate_batteries([battery])
        self.assertEqual(values["energyNowWh"], 12.0)
        self.assertEqual(values["energyFullWh"], 44.0)
        self.assertEqual(values["energyFullDesignWh"], 55.0)
        self.assertEqual(values["powerW"], 24.0)
        self.assertTrue(values["energyEstimated"])
        self.assertIn("current_now × BAT0/voltage_now", values["powerSource"])

    def test_missing_unknown_and_zero_values_remain_finite(self):
        battery = write_supply(self.root, "BAT0", {
            "type": "Battery",
            "status": "Unknown",
            "capacity": "Unknown",
            "current_now": 0,
            "voltage_now": 11_000_000,
        })
        values = power_monitor.aggregate_batteries([battery])
        self.assertIsNone(values["energyNowWh"])
        self.assertEqual(values["powerW"], 0.0)
        self.assertTrue(all(value is None or not isinstance(value, float) or value == value for value in values.values()))

    def test_aggregates_system_batteries_and_excludes_mouse(self):
        first = write_supply(self.root, "BAT0", {
            "type": "Battery", "status": "Discharging", "energy_now": 10_000_000,
            "energy_full": 20_000_000, "power_now": 4_000_000,
        })
        second = write_supply(self.root, "BAT1", {
            "type": "Battery", "status": "Discharging", "energy_now": 15_000_000,
            "energy_full": 30_000_000, "power_now": 5_000_000,
        })
        write_supply(self.root, "hidpp_battery_0", {"type": "Battery", "capacity": 38})
        supplies = power_monitor.discover_supplies(self.root)
        paths = power_monitor.battery_paths(supplies)
        self.assertEqual(paths, [first, second])
        values = power_monitor.aggregate_batteries(paths)
        self.assertEqual(values["energyNowWh"], 25.0)
        self.assertEqual(values["energyFullWh"], 50.0)
        self.assertEqual(values["powerW"], 9.0)

    def test_detects_mains_and_usb_power(self):
        write_supply(self.root, "ADP1", {"type": "Mains", "online": 0})
        write_supply(self.root, "USB0", {"type": "USB_PD", "online": 1})
        online, names, detected = power_monitor.external_power(power_monitor.discover_supplies(self.root))
        self.assertTrue(online)
        self.assertEqual(names, ["USB0"])
        self.assertEqual(detected, ["ADP1", "USB0"])


class HistoryTests(unittest.TestCase):
    def test_integrates_battery_power_and_bounds_history(self):
        history = power_monitor.PowerHistory(window_seconds=15)
        for stamp, watts in [(0, 10), (5, 20), (10, 10), (20, 30)]:
            history.add(stamp, "system_draw", watts)
        summary = history.summary("system_draw")
        self.assertEqual(summary["sampleCount"], 3)
        self.assertEqual(summary["peakW"], 30)
        self.assertAlmostEqual(summary["energyWh"], 0.08, places=2)

    def test_estimates_time_only_after_stable_period(self):
        history = power_monitor.PowerHistory()
        battery = {
            "timeToEmptySeconds": None,
            "timeToFullSeconds": None,
            "energyNowWh": 20,
            "energyFullWh": 50,
        }
        for stamp in range(0, 66, 5):
            history.add(stamp, "system_draw", 10)
        text, source = power_monitor.estimated_time_text(battery, "system_draw", history, 65)
        self.assertEqual(text, "2h 0m remaining")
        self.assertIn("stable", source)

    def test_rejects_absurd_kernel_and_unstable_estimates(self):
        history = power_monitor.PowerHistory()
        battery = {
            "timeToEmptySeconds": 999_999,
            "timeToFullSeconds": None,
            "energyNowWh": 20,
            "energyFullWh": 50,
        }
        for index, stamp in enumerate(range(0, 66, 5)):
            history.add(stamp, "system_draw", 2 if index % 2 else 40)
        text, _ = power_monitor.estimated_time_text(battery, "system_draw", history, 65)
        self.assertEqual(text, "Calculating…")


class ProcessImpactTests(unittest.TestCase):
    def test_tracks_identity_lifecycle_pid_reuse_and_name_aggregation(self):
        impact = power_monitor.ProcessImpact(clock_ticks=100)
        impact.ingest(0, {(10, 1000): ("steamwebhelper", 100), (11, 1001): ("steamwebhelper", 200)})
        impact.ingest(5, {(10, 1000): ("steamwebhelper", 200), (11, 1001): ("steamwebhelper", 300), (20, 2000): ("quickshell", 50)})
        impact.ingest(10, {(10, 3000): ("other", 900), (20, 2000): ("quickshell", 150)})
        report = impact.report(10, debug=True)
        self.assertEqual(report["processes"][0]["name"], "steamwebhelper")
        self.assertEqual(report["processes"][0]["score"], 2.0)
        self.assertEqual(report["processes"][1]["name"], "quickshell")
        self.assertFalse(any(item["process"] == "other" for item in report["debugProcesses"]))

    def test_prunes_intervals_after_25_minutes(self):
        impact = power_monitor.ProcessImpact(clock_ticks=100, window_seconds=10)
        impact.ingest(0, {(1, 1): ("old", 0)})
        impact.ingest(5, {(1, 1): ("old", 100)})
        impact.ingest(20, {(2, 2): ("new", 0)})
        report = impact.report(20)
        self.assertEqual(report["processes"], [])

    def test_reads_bounded_system_gpu_busy_percentage(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            card = root / "card1" / "device"
            card.mkdir(parents=True)
            (card / "gpu_busy_percent").write_text("70")
            self.assertEqual(power_monitor.gpu_sample(root)["busyPercent"], 70)
            (card / "gpu_busy_percent").write_text("Unknown")
            self.assertIsNone(power_monitor.gpu_sample(root)["busyPercent"])


class StateTests(unittest.TestCase):
    def setUp(self):
        self.temporary_directories = []

    def tearDown(self):
        for temporary in self.temporary_directories:
            temporary.cleanup()

    def monitor_for(self, battery_values, ac_online):
        temporary = tempfile.TemporaryDirectory()
        self.temporary_directories.append(temporary)
        root = Path(temporary.name)
        write_supply(root, "BAT0", {"type": "Battery", **battery_values})
        if ac_online is not None:
            write_supply(root, "ADP1", {"type": "Mains", "online": int(ac_online)})
        monitor = power_monitor.Monitor(root, root)
        return monitor

    def test_unplugged_battery_is_system_draw(self):
        monitor = self.monitor_for({
            "status": "Discharging", "energy_now": 20_000_000,
            "energy_full": 50_000_000, "power_now": 8_000_000,
        }, False)
        sample = monitor.sample()
        self.assertEqual(sample["rate"]["kind"], "system_draw")
        self.assertEqual(sample["summary"]["label"], "SYSTEM DRAW · 25 MIN")
        self.assertEqual(sample["anomaly"]["label"], "Low")

    def test_plugged_charging_battery_is_battery_charge_rate(self):
        monitor = self.monitor_for({
            "status": "Charging", "energy_now": 49_500_000,
            "energy_full": 50_000_000, "power_now": 5_000_000,
        }, True)
        sample = monitor.sample()
        self.assertEqual(sample["rate"]["kind"], "battery_charge")
        self.assertEqual(sample["summary"]["label"], "BATTERY CHARGE · 25 MIN")
        self.assertEqual(sample["anomaly"]["label"], "Not assessed")

    def test_plugged_discharging_battery_is_external_power_deficit(self):
        monitor = self.monitor_for({
            "status": "Discharging", "energy_now": 20_000_000,
            "energy_full": 50_000_000, "power_now": 18_000_000,
        }, True)
        sample = monitor.sample()
        self.assertTrue(sample["power"]["acConnected"])
        self.assertTrue(sample["power"]["batterySupplementingExternalPower"])
        self.assertEqual(sample["rate"]["kind"], "system_draw")
        self.assertEqual(sample["summary"]["label"], "POWER DEFICIT · 25 MIN")

    def test_unplugged_discharge_is_not_external_power_deficit(self):
        monitor = self.monitor_for({
            "status": "Discharging", "energy_now": 20_000_000,
            "energy_full": 50_000_000, "power_now": 18_000_000,
        }, False)
        sample = monitor.sample()
        self.assertFalse(sample["power"]["batterySupplementingExternalPower"])
        self.assertEqual(sample["summary"]["label"], "SYSTEM DRAW · 25 MIN")

    def test_missing_power_stays_unavailable(self):
        monitor = self.monitor_for({
            "status": "Discharging", "energy_now": 1_000_000,
            "energy_full": 50_000_000,
        }, False)
        sample = monitor.sample()
        self.assertIsNone(sample["rate"]["watts"])
        self.assertEqual(sample["time"]["text"], "Calculating…")

    def test_pending_charge_keeps_real_state_and_ac_context(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            write_supply(root, "BAT0", {
                "type": "Battery", "status": "Not charging", "capacity": 2,
                "charge_now": 112_000, "charge_full": 4_526_000,
                "charge_full_design": 5_200_000, "current_now": 0,
                "voltage_now": 11_014_000, "voltage_min_design": 11_800_000,
            })
            write_supply(root, "ADP1", {"type": "Mains", "online": 1})
            monitor = power_monitor.Monitor(root, root)
            sample = monitor.sample()
            self.assertTrue(sample["power"]["acConnected"])
            self.assertEqual(sample["battery"]["status"], "Not charging")
            self.assertEqual(sample["rate"]["watts"], 0.0)
            self.assertEqual(sample["rate"]["kind"], "battery_idle")
            self.assertEqual(sample["time"]["text"], "Calculating…")

    def test_anomaly_names_dominant_process_only_while_active(self):
        impact = {"processes": [{"name": "steamwebhelper", "share": 70, "active": True}]}
        result = power_monitor.anomaly("system_draw", 43.7, (10, 20, 30), impact)
        self.assertEqual(result["label"], "Unusually high")
        self.assertEqual(result["detail"], "High drain · steamwebhelper active")
        self.assertEqual(power_monitor.anomaly("battery_charge", 43.7, (10, 20, 30), impact)["label"], "Not assessed")

    def test_monitor_restart_starts_a_fresh_bounded_history(self):
        clock_value = [0]
        clock = lambda: clock_value[0]
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            write_supply(root, "BAT0", {
                "type": "Battery", "status": "Discharging",
                "energy_now": 20_000_000, "energy_full": 50_000_000,
                "power_now": 10_000_000,
            })
            first = power_monitor.Monitor(root, root, monotonic=clock)
            for index in range(305):
                clock_value[0] = index * 5
                first.sample()
            self.assertLessEqual(first.sample()["summary"]["sampleCount"], 302)
            restarted = power_monitor.Monitor(root, root, monotonic=clock)
            self.assertEqual(restarted.sample()["sampleCount"], 1)
            self.assertEqual(restarted.sample()["historySeconds"], 0)


if __name__ == "__main__":
    unittest.main()
