import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Alt-Tab window switcher. Hyprland binds ALT+Tab / ALT+SHIFT+Tab to
// `qs -c bar ipc call switcher next|previous`; releasing Alt picks the window.
Scope {
    id: root

    property bool open: false
    property int index: 0
    // Window addresses, most recently focused first.
    property var recent: []

    // Scratchpads live on special workspaces and have their own keys.
    readonly property var windows: {
        const all = Hyprland.toplevels.values.filter(t => t.wayland && !(t.workspace?.name ?? "").startsWith("special:"));
        const rank = t => {
            const i = recent.indexOf(t.address);
            return i < 0 ? recent.length : i;
        };
        return all.sort((a, b) => rank(a) - rank(b));
    }

    function step(delta) {
        const count = windows.length;
        if (count === 0) return;
        if (!open) {
            index = (count > 1 ? delta : 0);
            index = (index + count) % count;
            open = true;
        } else {
            index = (index + delta + count) % count;
        }
    }

    function commit() {
        if (!open) return;
        const target = windows[index];
        open = false;
        // Toplevel.activate() focuses without switching workspace; Hyprland's focus does both.
        if (target?.address)
            Hyprland.dispatch(`hl.dsp.focus({ window = "address:0x${target.address.replace(/^0x/, "")}" })`);
    }

    function remember() {
        const address = Hyprland.activeToplevel?.address;
        if (!address) return;
        recent = [address].concat(recent.filter(a => a !== address)).slice(0, 64);
    }

    Component.onCompleted: remember()

    Connections {
        target: Hyprland
        function onActiveToplevelChanged() { root.remember(); }
    }

    IpcHandler {
        target: "switcher"

        function next(): void { root.step(1); }
        function previous(): void { root.step(-1); }
        function commit(): void { root.commit(); }
        function cancel(): void { root.open = false; }
    }

    LazyLoader {
        active: root.open

        SwitcherWindow {
            switcher: root
            screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
        }
    }
}
