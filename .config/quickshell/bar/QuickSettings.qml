import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Quick settings panel, opened from the network/bluetooth/volume icons.
// Toggle with: qs -c bar ipc call quicksettings toggle (or `open wifi`)
Scope {
    id: root

    required property var notifications

    property bool open: false
    property string tab: "output"
    // Clicking a bar icon while open first clears the focus grab (closing the panel),
    // then delivers the click; ignore that click so it doesn't reopen immediately.
    property real closedAt: 0

    function toggle(which) {
        if (!open && Date.now() - closedAt < 250) return;
        if (which) tab = which;
        open = !open;
    }

    function close() {
        open = false;
        closedAt = Date.now();
    }

    IpcHandler {
        target: "quicksettings"

        function toggle(): void { root.toggle(""); }
        // tab: output | wifi | bluetooth
        function open(tab: string): void {
            root.tab = tab;
            root.open = true;
        }
    }

    LazyLoader {
        active: root.open

        QuickSettingsWindow {
            settings: root
            screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
        }
    }
}
