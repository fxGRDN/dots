import QtQuick
import Quickshell
import "Theme.js" as Theme

BarButton {
    icon: Theme.icons.bell
    onClicked: Quickshell.execDetached(["swaync-client", "-t", "-sw"])
}
