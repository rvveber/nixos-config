import Quickshell
import Quickshell.Io

Scope {
    id: root

    property bool hudVisible: false
    property string hudMode: "apps"
    property string returnTarget: ""

    function toggleHud(mode: string): void {
        if (root.hudVisible && root.hudMode === mode) {
            root.hudVisible = false;
            return;
        }
        root.hudMode = mode;
        root.captureTarget();
        root.hudVisible = true;
    }

    function captureTarget(): void {
        if (!activeWindow.running)
            activeWindow.running = true;
    }

    function openDemo(): void {
        root.toggleHud("demo");
    }

    function lockAndSuspend(): void {
        Quickshell.execDetached(["uwsm", "app", "--", "rvveber-fhud-lock-and-suspend"]);
    }

    function suspend(): void {
        Quickshell.execDetached(["systemctl", "suspend"]);
    }

    function hibernate(): void {
        Quickshell.execDetached(["systemctl", "hibernate"]);
    }

    function reboot(): void {
        Quickshell.execDetached(["systemctl", "reboot"]);
    }

    function powerOff(): void {
        Quickshell.execDetached(["systemctl", "poweroff"]);
    }

    IpcHandler {
        target: "hud"

        function toggle(mode: string): void {
            root.toggleHud(mode);
        }
        function open(mode: string): void {
            root.hudMode = mode;
            root.captureTarget();
            root.hudVisible = true;
        }
        function close(): void {
            root.hudVisible = false;
        }
    }

    Process {
        id: activeWindow
        command: ["hyprctl", "activewindow", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.returnTarget = JSON.parse(text).address || "";
                } catch (error) {
                    root.returnTarget = "";
                }
            }
        }
    }
}
