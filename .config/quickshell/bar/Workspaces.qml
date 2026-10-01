import QtQuick
import Quickshell
import Quickshell.Hyprland
import "Theme.js" as Theme

// Workspaces 1-5 are always shown; higher ones appear while they exist.
Row {
    id: root

    property var screen
    readonly property int persistent: 5

    spacing: 6

    readonly property var ids: {
        const result = [];
        for (let i = 1; i <= persistent; i++) result.push(i);
        for (const ws of Hyprland.workspaces.values) {
            if (ws.id > persistent && !result.includes(ws.id)) result.push(ws.id);
        }
        return result.sort((a, b) => a - b);
    }

    Repeater {
        model: root.ids

        Item {
            id: cell
            required property int modelData

            readonly property bool focused: Hyprland.focusedWorkspace?.id === modelData
            readonly property bool occupied: Hyprland.workspaces.values.some(ws => ws.id === modelData && ws.toplevels.values.length > 0)

            implicitWidth: pip.width
            implicitHeight: Theme.height

            Rectangle {
                id: pip
                anchors.verticalCenter: parent.verticalCenter
                width: cell.focused ? 24 : 10
                height: 10
                color: cell.focused ? Theme.orange
                    : cell.occupied ? Theme.subtext
                    : "transparent"
                border.width: cell.focused || cell.occupied ? 0 : 1
                border.color: hover.containsMouse ? Theme.orange : Theme.dim

                Behavior on width { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 140 } }
            }

            MouseArea {
                id: hover
                anchors.fill: parent
                anchors.margins: -3
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Hyprland.dispatch(`hl.dsp.focus({ workspace = ${cell.modelData} })`)
            }
        }
    }

    // Touchpads send many small deltas; switch once per full wheel notch (120).
    property real scrollAccumulator: 0

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            root.scrollAccumulator += event.angleDelta.y;
            if (Math.abs(root.scrollAccumulator) < 120) return;
            const direction = root.scrollAccumulator > 0 ? "r-1" : "r+1";
            root.scrollAccumulator = 0;
            Hyprland.dispatch(`hl.dsp.focus({ workspace = "${direction}" })`);
        }
    }
}
