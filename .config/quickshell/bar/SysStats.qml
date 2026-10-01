import QtQuick
import Quickshell
import Quickshell.Io
import "Theme.js" as Theme

// Click the chevron to reveal CPU / memory / temperature and the colour picker.
Row {
    id: root

    property bool expanded: false
    property int cpu: 0
    property int memory: 0
    property int temperature: 0

    BarButton {
        icon: root.expanded ? Theme.icons.chevronRight : Theme.icons.chevronLeft
        color: Theme.dim
        onClicked: root.expanded = !root.expanded
    }

    Row {
        id: drawer
        clip: true
        width: root.expanded ? implicitWidth : 0
        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

        BarButton {
            icon: Theme.icons.eyedropper
            onClicked: Quickshell.execDetached(["hyprpicker", "-a"])
        }
        BarButton {
            icon: Theme.icons.cpu
            label: root.cpu + "%"
        }
        BarButton {
            icon: Theme.icons.memory
            label: root.memory + "%"
        }
        BarButton {
            icon: Theme.icons.thermometer
            label: root.temperature + "°"
            color: root.temperature >= 80 ? Theme.brightRed : Theme.text
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "|"
            color: Theme.dim
            font.family: Theme.textFont
            font.pixelSize: Theme.fontSize
            rightPadding: 4
        }
    }

    Process {
        id: stats
        command: [Quickshell.shellDir + "/stats.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(/\s+/).map(Number);
                if (parts.length === 3) {
                    root.cpu = parts[0];
                    root.memory = parts[1];
                    root.temperature = parts[2];
                }
            }
        }
    }

    Timer {
        running: root.expanded
        repeat: true
        triggeredOnStart: true
        interval: 2000
        onTriggered: stats.running = true
    }
}
