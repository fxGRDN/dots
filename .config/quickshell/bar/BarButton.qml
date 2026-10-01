import QtQuick
import "Theme.js" as Theme

// Icon + optional label; `hoverLabel` is only shown while hovered.
Item {
    id: root

    property string icon: ""
    property string label: ""
    property string hoverLabel: ""
    property color color: Theme.text
    property color hoverColor: Theme.orange
    property color labelColor: Theme.subtext
    property bool active: false
    // Reserve label width so changing text (e.g. a proportional clock) doesn't shift the bar.
    property real labelMinWidth: 0

    signal clicked(var mouse)
    signal wheel(var wheel)

    readonly property bool hovered: mouse.containsMouse

    implicitWidth: row.implicitWidth + 12
    implicitHeight: Theme.height

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 5

        Text {
            visible: root.icon !== ""
            anchors.verticalCenter: parent.verticalCenter
            text: root.icon
            color: root.hovered || root.active ? root.hoverColor : root.color
            font.family: Theme.iconFont
            font.pixelSize: Theme.iconSize
            Behavior on color { ColorAnimation { duration: 120 } }
        }

        Text {
            readonly property string shown: root.hovered && root.hoverLabel !== "" ? root.hoverLabel : root.label
            visible: shown !== ""
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(implicitWidth, root.labelMinWidth)
            horizontalAlignment: Text.AlignHCenter
            text: shown
            color: root.labelColor
            font.family: Theme.textFont
            font.pixelSize: Theme.fontSize
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: event => root.clicked(event)
        onWheel: event => root.wheel(event)
    }
}
