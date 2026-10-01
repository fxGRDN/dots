import QtQuick
import Quickshell.Wayland
import "Theme.js" as Theme

// Keeps the screen awake while active.
BarButton {
    id: root

    property var window

    icon: inhibitor.enabled ? Theme.icons.coffee : Theme.icons.coffeeOff
    color: Theme.dim
    hoverColor: Theme.gold
    active: inhibitor.enabled

    onClicked: inhibitor.enabled = !inhibitor.enabled

    IdleInhibitor {
        id: inhibitor
        window: root.window
        enabled: false
    }
}
