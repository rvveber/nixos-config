import Quickshell
import Quickshell.Io
import QtQuick

Scope {
    id: root

    property real brightness: 0
    property bool brightnessAvailable: false
    property bool brightnessChanging: false
    property string networkName: "Offline"
    property string networkState: "Disconnected"
    property string bluetoothState: "Off"
    property bool wifiEnabled: false
    property var wifiNetworks: []
    property string wiredName: "Disconnected"
    property string vpnName: "Disconnected"
    property bool bluetoothPowered: false
    property bool bluetoothDiscovering: false
    property var bluetoothDevices: []
    property bool networkReady: false
    property bool wifiScanning: false
    property bool wifiChanging: false
    property bool bluetoothReady: false
    property bool bluetoothChanging: false
    property double now: Date.now()
    property double brightnessUpdatedAt: 0
    property double networkUpdatedAt: 0
    property double bluetoothUpdatedAt: 0
    readonly property bool wifiWorking: !networkReady || wifiScanning || wifiChanging
    readonly property bool bluetoothWorking: !bluetoothReady || bluetoothChanging || bluetoothDiscovering
    readonly property string brightnessHealth: !brightnessAvailable ? "unknown" : now - brightnessUpdatedAt > 3500 ? "stale" : "normal"
    readonly property string networkHealth: !networkReady ? "unknown" : now - networkUpdatedAt > 12000 ? "stale" : networkState === "Disconnected" ? "caution" : "normal"
    readonly property string bluetoothHealth: !bluetoothReady ? "unknown" : now - bluetoothUpdatedAt > 35000 ? "stale" : "normal"
    readonly property string brightnessFreshness: freshness(brightnessUpdatedAt)
    readonly property string networkFreshness: freshness(networkUpdatedAt)
    readonly property string bluetoothFreshness: freshness(bluetoothUpdatedAt)

    function run(process: Process): void {
        if (!process.running)
            process.running = true;
    }

    function freshness(updatedAt: real): string {
        if (updatedAt <= 0)
            return "WAITING FOR SOURCE";
        const age = Math.max(0, Math.floor((root.now - updatedAt) / 1000));
        if (age < 2)
            return "LIVE";
        if (age < 60)
            return "UPDATED " + age + "S AGO";
        return "UPDATED " + Math.floor(age / 60) + "M AGO";
    }

    function setBrightness(value: real): void {
        const clamped = Math.max(0.01, Math.min(1, value));
        root.brightnessChanging = true;
        root.brightness = clamped;
        Quickshell.execDetached(["brightnessctl", "set", Math.round(clamped * 100) + "%"]);
    }

    function splitNmcli(line: string): var {
        const fields = [];
        let field = "";
        let escaped = false;
        for (const character of line) {
            if (escaped) {
                field += character;
                escaped = false;
            } else if (character === "\\") {
                escaped = true;
            } else if (character === ":") {
                fields.push(field);
                field = "";
            } else {
                field += character;
            }
        }
        fields.push(field);
        return fields;
    }

    function parseBrightness(text: string): void {
        const fields = text.trim().split(",");
        if (fields.length < 4)
            return;
        root.brightnessAvailable = true;
        root.brightnessChanging = false;
        root.brightness = Number(fields[3].replace("%", "")) / 100;
        root.brightnessUpdatedAt = Date.now();
    }

    function parseNetwork(text: string): void {
        const rows = text.trim().split("\n").map(root.splitNmcli);
        const wifi = rows.find(fields => fields[0] === "wifi" && fields[1] === "connected");
        const wired = rows.find(fields => fields[0] === "ethernet" && fields[1] === "connected");
        root.networkReady = true;
        root.networkUpdatedAt = Date.now();
        if (!wifi && !wired) {
            root.networkName = "Offline";
            root.networkState = "Disconnected";
            root.wiredName = "Disconnected";
            return;
        }
        const primary = wifi || wired;
        root.networkName = primary[2] || primary[3] || primary[0];
        root.networkState = wifi ? "Wi-Fi" : "Ethernet";
        root.wiredName = wired ? (wired[2] || wired[3]) : "Disconnected";
    }

    function parseBluetooth(text: string): void {
        const sections = text.split("--DEVICES--");
        root.bluetoothPowered = /Powered:\s+yes/.test(sections[0] || "");
        root.bluetoothDiscovering = /Discovering:\s+yes/.test(sections[0] || "");
        root.bluetoothDevices = (sections[1] || "").trim().split("\n").map(line => {
            const fields = line.split("\t");
            return {
                address: fields[0] || "",
                connected: fields[1] === "yes",
                paired: fields[2] === "yes",
                trusted: fields[3] === "yes",
                name: fields.slice(4).join("\t") || fields[0]
            };
        }).filter(device => /^[0-9A-F]{2}(?::[0-9A-F]{2}){5}$/i.test(device.address));
        const connected = root.bluetoothDevices.find(device => device.connected);
        root.bluetoothState = connected ? connected.name : root.bluetoothPowered ? "Ready" : "Off";
        root.bluetoothReady = true;
        root.bluetoothChanging = false;
        root.bluetoothUpdatedAt = Date.now();
    }

    function parseWifiState(text: string): void {
        root.wifiEnabled = text.trim() === "enabled";
        root.wifiChanging = false;
    }

    function parseWifiNetworks(text: string): void {
        if (text.trim().length === 0) {
            root.wifiNetworks = [];
            root.wifiScanning = false;
            return;
        }

        const seen = new Set();
        root.wifiNetworks = text.trim().split("\n").map(line => {
            const fields = root.splitNmcli(line);
            return {
                active: fields[0] === "*",
                ssid: fields[1] || "Hidden network",
                strength: Number(fields[2]) || 0,
                frequency: fields[3] || "--",
                security: fields[4] || "Open"
            };
        }).filter(network => {
            if (!network.ssid || seen.has(network.ssid))
                return false;
            seen.add(network.ssid);
            return true;
        }).slice(0, 8);
        root.wifiScanning = false;
    }

    function parseConnections(text: string): void {
        const rows = text.trim().split("\n").map(root.splitNmcli);
        const vpn = rows.find(fields => fields[0] === "vpn" || fields[0] === "wireguard");
        root.vpnName = vpn ? (vpn[1] || vpn[2] || "Connected") : "Disconnected";
    }

    function rescanWifi(): void {
        root.wifiScanning = true;
        Quickshell.execDetached(["nmcli", "device", "wifi", "rescan"]);
        wifiRefresh.restart();
    }

    function setWifiEnabled(enabled: bool): void {
        root.wifiChanging = true;
        root.wifiEnabled = enabled;
        Quickshell.execDetached(["nmcli", "radio", "wifi", enabled ? "on" : "off"]);
        wifiRefresh.restart();
    }

    function setBluetoothPowered(powered: bool): void {
        root.bluetoothChanging = true;
        root.bluetoothPowered = powered;
        Quickshell.execDetached(["bluetoothctl", "power", powered ? "on" : "off"]);
        bluetoothRefresh.restart();
    }

    function scanBluetooth(): void {
        root.bluetoothChanging = true;
        Quickshell.execDetached(["bluetoothctl", "scan", root.bluetoothDiscovering ? "off" : "on"]);
        bluetoothRefresh.restart();
    }

    function toggleBluetoothDevice(device): void {
        if (!device)
            return;
        if (device.connected) {
            Quickshell.execDetached(["bluetoothctl", "disconnect", device.address]);
        } else {
            Quickshell.execDetached(["bash", "-lc", "bluetoothctl trust \"$1\"; bluetoothctl pair \"$1\"; bluetoothctl connect \"$1\"", "fhud-bluetooth", device.address]);
        }
        root.bluetoothChanging = true;
        bluetoothRefresh.restart();
    }

    function forgetBluetoothDevice(device): void {
        if (device) {
            root.bluetoothChanging = true;
            Quickshell.execDetached(["bluetoothctl", "remove", device.address]);
            bluetoothRefresh.restart();
        }
    }

    Process {
        id: brightness
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: root.parseBrightness(text)
        }
    }

    Process {
        id: network
        command: ["nmcli", "-t", "--escape", "yes", "-f", "TYPE,STATE,CONNECTION,DEVICE", "device"]
        stdout: StdioCollector {
            onStreamFinished: root.parseNetwork(text)
        }
    }

    Process {
        id: bluetooth
        command: ["bash", "-lc", "bluetoothctl show; printf '%s\\n' --DEVICES--; bluetoothctl devices | while read -r _ address name; do info=$(bluetoothctl info \"$address\" 2>/dev/null); connected=$(printf '%s\\n' \"$info\" | sed -n 's/^\\s*Connected: //p'); paired=$(printf '%s\\n' \"$info\" | sed -n 's/^\\s*Paired: //p'); trusted=$(printf '%s\\n' \"$info\" | sed -n 's/^\\s*Trusted: //p'); printf '%s\\t%s\\t%s\\t%s\\t%s\\n' \"$address\" \"$connected\" \"$paired\" \"$trusted\" \"$name\"; done"]
        stdout: StdioCollector {
            onStreamFinished: root.parseBluetooth(text)
        }
    }

    Process {
        id: wifiState
        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: root.parseWifiState(text)
        }
    }

    Process {
        id: wifiList
        command: ["nmcli", "-t", "--escape", "yes", "-f", "IN-USE,SSID,SIGNAL,FREQ,SECURITY", "device", "wifi", "list", "--rescan", "no"]
        stdout: StdioCollector {
            onStreamFinished: root.parseWifiNetworks(text)
        }
    }

    Process {
        id: connections
        command: ["nmcli", "-t", "--escape", "yes", "-f", "TYPE,NAME,DEVICE", "connection", "show", "--active"]
        stdout: StdioCollector {
            onStreamFinished: root.parseConnections(text)
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.now = Date.now();
            root.run(brightness);
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.run(network);
            root.run(wifiState);
            root.run(wifiList);
            root.run(connections);
        }
    }

    Timer {
        interval: 15000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.run(bluetooth)
    }

    Timer {
        id: wifiRefresh
        interval: 1500
        onTriggered: {
            root.run(network);
            root.run(wifiState);
            root.run(wifiList);
        }
    }

    Timer {
        id: bluetoothRefresh
        interval: 1200
        onTriggered: root.run(bluetooth)
    }
}
