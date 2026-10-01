import QtQuick
import Quickshell
import Quickshell.Io
import "Theme.js" as Theme

// Pending pacman updates; hidden when there are none. Click to run yay -Syu.
BarButton {
    id: root

    property int count: 0

    visible: count > 0
    icon: Theme.icons.updates
    label: count.toString()
    color: Theme.gold

    onClicked: upgrade.running = true

    // checkupdates exits 0 with updates, 2 with none, and 1 on failure
    // (e.g. a concurrent run holding its temp db); keep the old count and retry on failure.
    Process {
        id: check
        command: ["sh", "-c", "out=$(checkupdates 2>/dev/null); code=$?; printf '%s\\n' \"$out\" | grep -c . ; echo \"$code\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const [lines, code] = text.trim().split("\n").map(Number);
                if (code === 0) root.count = lines;
                else if (code === 2) root.count = 0;
                else retry.start();
            }
        }
    }

    Timer {
        id: retry
        interval: 30 * 1000
        onTriggered: check.running = true
    }

    Process {
        id: upgrade
        command: ["kitty", "sh", "-c", "yay -Syu; echo Done - Press enter to exit; read"]
        onExited: check.running = true
    }

    Timer {
        running: true
        repeat: true
        triggeredOnStart: true
        interval: 5 * 60 * 1000
        onTriggered: check.running = true
    }
}
