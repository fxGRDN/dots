import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import "Theme.js" as Theme

Row {
    id: root

    property var window

    leftPadding: 6
    rightPadding: 6
    spacing: 10

    Repeater {
        model: SystemTray.items

        Item {
            id: trayItem
            required property SystemTrayItem modelData

            implicitWidth: 16
            implicitHeight: Theme.height

            IconImage {
                anchors.centerIn: parent
                implicitSize: 15
                source: trayItem.modelData.icon
                opacity: mouse.containsMouse ? 1 : 0.85
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                cursorShape: Qt.PointingHandCursor
                onClicked: event => {
                    const item = trayItem.modelData;
                    if (event.button === Qt.RightButton || (event.button === Qt.LeftButton && item.onlyMenu)) {
                        if (item.hasMenu) {
                            const pos = trayItem.mapToItem(null, 0, trayItem.height);
                            item.display(root.window, pos.x, pos.y);
                        }
                    } else if (event.button === Qt.MiddleButton) {
                        item.secondaryActivate();
                    } else {
                        item.activate();
                    }
                }
                onWheel: event => trayItem.modelData.scroll(event.angleDelta.y, false)
            }
        }
    }
}
