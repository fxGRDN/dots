import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "Theme.js" as Theme
import "Keybinds.js" as Keybinds

// Keybind cheatsheet. Hover to peek, click to pin (click elsewhere to close).
// Reads bind descriptions from Hyprland each time it opens, so it never goes stale.
BarButton {
    id: root

    property var window
    property bool pinned: false
    // After closing by click, ignore hover until the pointer leaves the button.
    property bool suppressHover: false
    property var columns: []

    readonly property bool wanted: pinned || (hovered && !suppressHover) || panelHover.hovered

    icon: Theme.icons.keyboard
    color: Theme.dim
    hoverColor: Theme.gold
    active: popup.visible

    onHoveredChanged: if (!hovered) suppressHover = false
    onWantedChanged: {
        if (wanted) {
            closeTimer.stop();
            if (!popup.visible) openTimer.restart();
        } else {
            openTimer.stop();
            closeTimer.restart();
        }
    }

    onClicked: {
        if (pinned) {
            close();
        } else {
            pinned = true;
            show();
        }
    }

    function show() {
        openTimer.stop();
        binds.running = true;
        popup.visible = true;
    }

    function close() {
        pinned = false;
        suppressHover = true;
        popup.visible = false;
    }

    Timer {
        id: openTimer
        interval: 250
        onTriggered: root.show()
    }

    Timer {
        id: closeTimer
        interval: 300
        onTriggered: popup.visible = false
    }

    Process {
        id: binds
        command: ["hyprctl", "binds", "-j"]
        stdout: StdioCollector {
            onStreamFinished: root.columns = Keybinds.columns(Keybinds.parse(text), 3)
        }
    }

    HyprlandFocusGrab {
        active: root.pinned && popup.visible
        windows: [popup, root.window]
        onCleared: root.close()
    }

    PopupWindow {
        id: popup

        anchor.item: root
        anchor.edges: Edges.Bottom | Edges.Right
        anchor.gravity: Edges.Bottom | Edges.Left
        anchor.margins.top: 6
        implicitWidth: panel.implicitWidth
        implicitHeight: panel.implicitHeight
        color: "transparent"

        Rectangle {
            id: panel

            implicitWidth: body.implicitWidth + 32
            implicitHeight: body.implicitHeight + 28
            color: Qt.rgba(0.047, 0.031, 0.031, 0.94)
            border.width: 1
            border.color: Theme.red

            HoverHandler { id: panelHover }

            Column {
                id: body
                x: 16
                y: 14
                spacing: 14

                Item {
                    width: parent.width
                    height: title.implicitHeight

                    Text {
                        id: title
                        text: "KEYBINDS"
                        color: Theme.purple
                        font.family: Theme.textFont
                        font.pixelSize: 12
                        font.letterSpacing: 2
                    }

                    Text {
                        anchors.right: parent.right
                        text: root.pinned ? "PINNED" : "CLICK TO PIN"
                        color: root.pinned ? Theme.gold : Theme.dim
                        font.family: Theme.textFont
                        font.pixelSize: 10
                        font.letterSpacing: 1.5
                    }
                }

                Row {
                    spacing: 28

                    Repeater {
                        model: root.columns

                        Column {
                            required property var modelData
                            width: 290
                            spacing: 14

                            Repeater {
                                model: modelData

                                Group {}
                            }
                        }
                    }
                }
            }
        }
    }

    component Group: Column {
        required property var modelData
        width: parent.width
        spacing: 5

        Text {
            text: modelData.name.toUpperCase()
            color: Theme.orange
            font.family: Theme.textFont
            font.pixelSize: 11
            font.letterSpacing: 2
            bottomPadding: 2
        }

        Repeater {
            model: modelData.rows

            Item {
                required property var modelData
                width: parent.width
                height: 20

                Text {
                    anchors {
                        left: parent.left
                        right: keys.left
                        rightMargin: 10
                        verticalCenter: parent.verticalCenter
                    }
                    text: modelData.action
                    elide: Text.ElideRight
                    color: Theme.text
                    font.family: Theme.textFont
                    font.pixelSize: 12
                }

                Row {
                    id: keys
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    Repeater {
                        model: modelData.combos

                        Row {
                            required property var modelData
                            required property int index
                            spacing: 3

                            Text {
                                visible: index > 0
                                anchors.verticalCenter: parent.verticalCenter
                                text: "/"
                                color: Theme.dim
                                font.family: Theme.textFont
                                font.pixelSize: 11
                                rightPadding: 3
                            }

                            Repeater {
                                model: modelData

                                Rectangle {
                                    required property string modelData
                                    implicitWidth: cap.implicitWidth + 10
                                    implicitHeight: 17
                                    color: Theme.raised
                                    border.width: 1
                                    border.color: Theme.line

                                    Text {
                                        id: cap
                                        anchors.centerIn: parent
                                        text: modelData
                                        color: Theme.gold
                                        font.family: Theme.textFont
                                        font.pixelSize: 10
                                        font.letterSpacing: 1
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
