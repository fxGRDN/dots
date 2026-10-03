import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "Theme.js" as Theme

// Drops down from the bell. Click outside or press Esc to close.
PanelWindow {
    id: window

    required property var service

    anchors {
        top: true
        left: true
    }
    margins {
        top: 6
        left: 6
    }
    implicitWidth: 420
    implicitHeight: Math.min(panel.implicitHeight, 680)
    color: "transparent"
    exclusionMode: ExclusionMode.Normal
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: "qs-notification-center"

    HyprlandFocusGrab {
        active: true
        windows: [window]
        onCleared: window.service.closeCenter()
    }

    Rectangle {
        id: panel
        anchors.fill: parent
        implicitHeight: header.height + 1 + Math.max(list.contentHeight, empty.implicitHeight + 40) + 16
        color: Qt.rgba(0.047, 0.031, 0.031, 0.94)
        border.width: 1
        border.color: Theme.red

        focus: true
        Keys.onEscapePressed: window.service.closeCenter()

        Item {
            id: header
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
            height: 44

            Text {
                anchors {
                    left: parent.left
                    leftMargin: 16
                    verticalCenter: parent.verticalCenter
                }
                text: "NOTIFICATIONS" + (window.service.notifications.length > 0 ? "  " + window.service.notifications.length : "")
                color: Theme.purple
                font.family: Theme.textFont
                font.pixelSize: 12
                font.letterSpacing: 2
            }

            Row {
                anchors {
                    right: parent.right
                    rightMargin: 12
                    verticalCenter: parent.verticalCenter
                }
                spacing: 14

                HeaderButton {
                    text: window.service.dnd ? "DND ON" : "DND OFF"
                    active: window.service.dnd
                    onClicked: window.service.dnd = !window.service.dnd
                }

                HeaderButton {
                    visible: window.service.notifications.length > 0
                    text: "CLEAR ALL"
                    onClicked: window.service.clearAll()
                }
            }
        }

        Rectangle {
            id: divider
            anchors {
                top: header.bottom
                left: parent.left
                right: parent.right
            }
            height: 1
            color: Theme.red
            opacity: 0.6
        }

        ListView {
            id: list
            anchors {
                top: divider.bottom
                bottom: parent.bottom
                left: parent.left
                right: parent.right
                margins: 8
            }
            clip: true
            spacing: 8
            boundsBehavior: Flickable.StopAtBounds
            model: window.service.notifications

            delegate: NotificationCard {
                required property var modelData

                width: list.width
                notification: modelData
                service: window.service
                bodyLines: 12
            }
        }

        Text {
            id: empty
            anchors.centerIn: list
            visible: window.service.notifications.length === 0
            text: window.service.dnd ? "DO NOT DISTURB" : "ALL QUIET"
            color: Theme.dim
            font.family: Theme.textFont
            font.pixelSize: 13
            font.letterSpacing: 3
        }
    }

    component HeaderButton: Text {
        id: button
        property bool active: false
        signal clicked()

        color: area.containsMouse ? Theme.orange : active ? Theme.gold : Theme.subtext
        font.family: Theme.textFont
        font.pixelSize: 11
        font.letterSpacing: 1.5

        MouseArea {
            id: area
            anchors.fill: parent
            anchors.margins: -6
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.clicked()
        }
    }
}
