import QtQuick
import "Theme.js" as Theme

// Left click: notification centre. Right click: do not disturb.
BarButton {
    id: root

    required property var service

    icon: service.dnd ? Theme.icons.bellSleep
        : service.unread > 0 ? Theme.icons.bellRing
        : Theme.icons.bell
    color: service.dnd ? Theme.dim : service.unread > 0 ? Theme.orange : Theme.text
    label: service.unread > 0 ? String(service.unread) : ""
    labelColor: Theme.orange
    active: service.centerOpen

    onClicked: mouse => {
        if (mouse.button === Qt.RightButton) service.dnd = !service.dnd;
        else service.toggleCenter();
    }
}
