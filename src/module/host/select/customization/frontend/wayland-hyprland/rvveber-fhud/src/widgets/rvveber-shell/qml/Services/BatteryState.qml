import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import QtQuick

Scope {
    id: root

    property var device: UPower.displayDevice
    property var profiles: PowerProfiles
    property var telemetry: ({})
    property string telemetryError: "Waiting for power monitor"
    property bool monitorRunning: false
    readonly property bool upowerAvailable: device.ready && device.isLaptopBattery
    readonly property bool telemetryAvailable: telemetry.ready === true
    readonly property bool available: upowerAvailable || telemetryAvailable
    readonly property var rawBattery: telemetryAvailable ? telemetry.battery : ({})
    readonly property var power: telemetryAvailable ? telemetry.power : ({})
    readonly property var rate: telemetryAvailable ? telemetry.rate : ({})
    readonly property var time: telemetryAvailable ? telemetry.time : ({})
    readonly property var summary: telemetryAvailable ? telemetry.summary : ({})
    readonly property var impact: telemetryAvailable ? telemetry.impact : ({
            "processes": []
        })
    readonly property var gpu: telemetryAvailable ? telemetry.gpu : ({})
    readonly property var anomaly: telemetryAvailable ? telemetry.anomaly : ({})
    readonly property bool debugEnabled: telemetry.debug !== undefined && telemetry.debug.enabled === true
    readonly property int percentage: {
        if (upowerAvailable)
            return Math.round(device.percentage * 100);
        return root.finite(rawBattery.capacity) ? Math.round(rawBattery.capacity) : 0;
    }
    readonly property string iconName: upowerAvailable ? device.iconName : ""
    readonly property real energy: root.finite(rawBattery.energyNowWh) ? rawBattery.energyNowWh : upowerAvailable ? device.energy : 0
    readonly property real energyCapacity: root.finite(rawBattery.energyFullWh) ? rawBattery.energyFullWh : upowerAvailable ? device.energyCapacity : 0
    readonly property real energyDesignCapacity: root.finite(rawBattery.energyFullDesignWh) ? rawBattery.energyFullDesignWh : 0
    readonly property bool energyEstimated: telemetryAvailable && rawBattery.energyEstimated === true
    readonly property real changeRate: root.finite(rawBattery.powerW) ? rawBattery.powerW : upowerAvailable ? Math.abs(device.changeRate) : 0
    readonly property bool calculatedHealthAvailable: energyCapacity > 0 && energyDesignCapacity > 0
    readonly property bool healthAvailable: calculatedHealthAvailable || (upowerAvailable && device.healthSupported)
    readonly property int healthPercentage: {
        if (calculatedHealthAvailable)
            return Math.round(Math.max(0, Math.min(100, 100 * energyCapacity / energyDesignCapacity)));
        return upowerAvailable && device.healthSupported ? Math.round(device.healthPercentage) : 0;
    }
    readonly property string storedEnergyText: (energyEstimated ? "≈ " : "") + energy.toFixed(1) + " Wh"
    readonly property string batteryHealthText: {
        if (calculatedHealthAvailable)
            return energyCapacity.toFixed(1) + " / " + energyDesignCapacity.toFixed(1) + " Wh · " + healthPercentage + "%";
        return healthAvailable ? healthPercentage + "%" : "Unavailable";
    }
    readonly property bool acConnected: telemetryAvailable ? power.acConnected === true : !UPower.onBattery
    readonly property bool batterySupplementingExternalPower: telemetryAvailable && power.batterySupplementingExternalPower === true
    readonly property string powerText: acConnected ? "External power connected" : "Battery"
    readonly property string profileName: profiles ? PowerProfile.toString(profiles.profile) : "Unknown"
    readonly property string profileDetail: {
        if (!profiles)
            return "Power profile unavailable";
        if (profiles.degradationReason !== PerformanceDegradationReason.None)
            return profileName + " · " + PerformanceDegradationReason.toString(profiles.degradationReason);
        return profileName;
    }
    readonly property string state: {
        if (upowerAvailable) {
            if (device.state === UPowerDeviceState.Charging)
                return "Charging";
            if (device.state === UPowerDeviceState.FullyCharged)
                return "Full";
            if (device.state === UPowerDeviceState.Discharging)
                return "Discharging";
            if (device.state === UPowerDeviceState.PendingCharge)
                return "Pending";
            if (device.state === UPowerDeviceState.PendingDischarge)
                return "Pending discharge";
        }
        if (telemetryAvailable)
            return rawBattery.status || "Unknown";
        return available ? "Unknown" : "Unavailable";
    }
    readonly property string stateDetail: {
        if (state === "Pending" && acConnected)
            return "External power connected · waiting to charge";
        if (state === "Not charging" && acConnected)
            return "External power connected · battery not charging";
        return powerText;
    }
    readonly property string rateText: {
        if (!root.finite(changeRate))
            return "Unavailable";
        if (changeRate < 0.05)
            return "0.0 W · " + powerText;
        if (state === "Charging")
            return "+" + changeRate.toFixed(1) + " W into battery";
        if (state === "Discharging")
            return "−" + changeRate.toFixed(1) + " W from battery";
        return changeRate.toFixed(1) + " W · battery flow";
    }
    readonly property string remaining: {
        if (telemetryAvailable && time.text)
            return time.text;
        if (!upowerAvailable)
            return "Calculating…";
        if (root.validDuration(device.timeToFull))
            return "Full in " + root.formatDuration(device.timeToFull);
        if (root.validDuration(device.timeToEmpty))
            return root.formatDuration(device.timeToEmpty) + " remaining";
        return "Calculating…";
    }
    readonly property string summaryText: {
        if (!telemetryAvailable || !summary || !root.finite(summary.averageW))
            return "Collecting samples…";
        return "Avg " + summary.averageW.toFixed(1) + " W   Peak " + summary.peakW.toFixed(1) + " W   " + summary.energyWh.toFixed(2) + " Wh";
    }
    readonly property string summaryLabel: telemetryAvailable && summary.label ? summary.label : "25 MIN"
    readonly property string impactLabel: {
        const minutes = telemetryAvailable ? Math.min(25, Math.floor((telemetry.historySeconds || 0) / 60)) : 0;
        return "TOP IMPACT · " + minutes + " / 25 MIN";
    }
    readonly property var impactProcesses: impact.processes || []
    readonly property string impactSource: impact.source || "Estimated from accumulated CPU time"
    readonly property string powerSource: rawBattery.powerSource || "UPower display device"
    readonly property string timeSource: time.source || "UPower display device"
    readonly property string anomalyLabel: anomaly.label || "Not assessed"
    readonly property string anomalyDetail: anomaly.detail || "Waiting for battery telemetry"
    readonly property string drawDetail: batterySupplementingExternalPower ? "External power connected · battery is supplying the shortfall" : anomalyDetail
    readonly property string anomalyLevel: anomaly.level || "unknown"
    readonly property string debugText: {
        if (!debugEnabled)
            return "";
        const debug = telemetry.debug;
        return ["Battery path  " + debug.batteryPaths.join(", "), "Status        " + debug.rawStatus, "Capacity      " + root.debugValue(debug.capacity, "%"), "Energy now    " + root.debugValue(debug.energyNowWh, " Wh"), "Energy full   " + root.debugValue(debug.energyFullWh, " Wh"), "Power now     " + root.debugValue(debug.powerW, " W"), "Current now   " + root.debugValue(debug.currentA, " A"), "Voltage now   " + root.debugValue(debug.voltageV, " V"), "AC online     " + debug.acOnline, "GPU busy      " + root.debugValue(debug.gpuBusyPercent, "%"), "Profile       " + profileName, "Samples       " + debug.sampleCount, "History       " + Math.round(debug.historySeconds) + " s"].join("\n");
    }
    readonly property string debugProcessText: {
        if (!debugEnabled || !impact.debugProcesses)
            return "";
        return impact.debugProcesses.map(process => process.process + " pid=" + process.pid + " start=" + process.starttime + " cpuΔ=" + process.cpuDeltaSeconds + "s" + " cpuΣ=" + process.accumulatedCpuSeconds + "s" + " gpuΔ=" + (process.gpuDelta === null ? "unavailable" : process.gpuDelta) + " score=" + process.computedScore).join("\n");
    }
    readonly property string health: {
        if (!available)
            return "unknown";
        if (state === "Discharging" && percentage <= 5)
            return "critical";
        if (state === "Discharging" && percentage <= 15)
            return "caution";
        if ((state === "Pending" || state === "Not charging") && percentage <= 5)
            return "caution";
        if (anomalyLevel === "high" || anomalyLevel === "elevated")
            return "caution";
        return "normal";
    }

    function finite(value): bool {
        return typeof value === "number" && Number.isFinite(value);
    }

    function validDuration(seconds: real): bool {
        return root.finite(seconds) && seconds > 0 && seconds <= 86400;
    }

    function formatDuration(seconds: real): string {
        const totalMinutes = Math.max(1, Math.round(seconds / 60));
        const hours = Math.floor(totalMinutes / 60);
        const minutes = totalMinutes % 60;
        return hours > 0 ? hours + "h " + minutes + "m" : minutes + "m";
    }

    function debugValue(value, unit): string {
        return root.finite(value) ? value + unit : "unavailable";
    }

    function parseTelemetry(line: string): void {
        if (!line || line.trim().length === 0)
            return;
        try {
            const parsed = JSON.parse(line);
            if (parsed.ready === false) {
                root.telemetryError = parsed.error || "Power monitor unavailable";
                return;
            }
            root.telemetry = parsed;
            root.telemetryError = "";
        } catch (error) {
            root.telemetryError = "Invalid power monitor sample";
        }
    }

    function setProfile(profile: string): void {
        if (!profiles)
            return;
        if (profile === "power-saver")
            profiles.profile = PowerProfile.PowerSaver;
        else if (profile === "performance")
            profiles.profile = PowerProfile.Performance;
        else
            profiles.profile = PowerProfile.Balanced;
    }

    Process {
        id: monitor
        command: ["rvveber-fhud-power-monitor"]
        running: true
        onRunningChanged: {
            root.monitorRunning = running;
            if (!running)
                restartMonitor.restart();
        }
        stdout: SplitParser {
            onRead: data => root.parseTelemetry(data)
        }
    }

    Timer {
        id: restartMonitor
        interval: 5000
        onTriggered: {
            if (!monitor.running)
                monitor.running = true;
        }
    }
}
