import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Clipboard history picker on top of cliphist (fed by `wl-paste --watch cliphist store`).
// Toggle with: qs -c bar ipc call clipboard toggle
Scope {
    id: root

    property bool open: false
    // [{ id, line, preview, image }] newest first, as cliphist lists them.
    property var entries: []
    readonly property string imageDir: Quickshell.env("XDG_RUNTIME_DIR") + "/qs-clipboard"

    onOpenChanged: {
        if (open) {
            list.running = true;
        } else {
            Quickshell.execDetached(["rm", "-rf", imageDir]);
        }
    }

    function parse(text) {
        return text.split("\n").filter(line => line !== "").map(line => {
            const tab = line.indexOf("\t");
            const preview = line.slice(tab + 1);
            const image = preview.match(/^\[\[ binary data (.+) (png|jpe?g|webp|gif|bmp) (\d+x\d+) \]\]$/);
            return {
                id: line.slice(0, tab),
                line: line,
                preview: image ? "IMAGE  " + image[2].toUpperCase() + "  " + image[3] + "  " + image[1] : preview,
                image: image !== null
            };
        });
    }

    function copy(entry) {
        Quickshell.execDetached(["sh", "-c", 'cliphist decode "$1" | wl-copy', "_", entry.line]);
        open = false;
    }

    function remove(entry) {
        entries = entries.filter(e => e.id !== entry.id);
        Quickshell.execDetached(["sh", "-c", 'printf "%s\\n" "$1" | cliphist delete', "_", entry.line]);
    }

    function wipe() {
        entries = [];
        Quickshell.execDetached(["cliphist", "wipe"]);
    }

    Process {
        id: list
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: root.entries = root.parse(text)
        }
    }

    IpcHandler {
        target: "clipboard"

        function toggle(): void { root.open = !root.open; }
    }

    LazyLoader {
        active: root.open

        ClipboardWindow {
            clipboard: root
            screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
        }
    }
}
