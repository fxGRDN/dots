import QtQuick
import QtQuick.Layouts
import Quickshell
import "Theme.js" as Theme

PanelWindow {
    id: bar

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: Theme.height
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        color: Theme.bg
        opacity: 0.88
    }

    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: 1
        color: Theme.red
        opacity: 0.7
    }

    RowLayout {
        anchors {
            left: parent.left
            verticalCenter: parent.verticalCenter
            leftMargin: 4
        }
        spacing: 0

        Notifications {}
        Clock {}
        Updates {}
        IdleToggle { window: bar }
        Tray { window: bar }
    }

    Workspaces {
        anchors.centerIn: parent
        screen: bar.screen
    }

    RowLayout {
        anchors {
            right: parent.right
            verticalCenter: parent.verticalCenter
            rightMargin: 4
        }
        spacing: 0

        SysStats {}
        BluetoothStatus {}
        Audio {}
        Network {}
        Battery {}
    }
}
