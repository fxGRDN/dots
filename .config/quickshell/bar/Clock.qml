import QtQuick
import Quickshell
import Quickshell.Hyprland
import "Theme.js" as Theme

// Left click: calendar. Right click: toggle between time and date.
BarButton {
    id: root

    property var now: new Date()
    property bool showDate: false

    label: showDate ? Qt.formatDate(now, "ddd dd MMM yyyy").toUpperCase() : Qt.formatTime(now, "hh:mm:ss AP")
    labelColor: hovered || active ? Theme.orange : Theme.text
    labelMinWidth: showDate ? 0 : widestTime
    active: calendar.visible

    // Pixelon is proportional, so size for the widest digit in every position.
    readonly property real widestTime: {
        let digit = 0;
        for (let d = 0; d <= 9; d++) digit = Math.max(digit, metrics.advanceWidth(String(d)));
        const suffix = Math.max(metrics.advanceWidth(" AM"), metrics.advanceWidth(" PM"));
        return Math.ceil(6 * digit + metrics.advanceWidth("::") + suffix) + 1;
    }

    // See QuickSettings: a click that just closed the popup via the focus grab shouldn't reopen it.
    property real closedAt: 0

    onClicked: event => {
        if (event.button === Qt.RightButton) {
            showDate = !showDate;
        } else if (calendar.visible) {
            calendar.visible = false;
        } else if (Date.now() - closedAt > 250) {
            calendar.month = new Date(now.getFullYear(), now.getMonth(), 1);
            calendar.visible = true;
        }
    }

    FontMetrics {
        id: metrics
        font.family: Theme.textFont
        font.pixelSize: Theme.fontSize
    }

    Timer {
        running: true
        repeat: true
        interval: 1000
        onTriggered: root.now = new Date()
    }

    HyprlandFocusGrab {
        active: calendar.visible
        windows: [calendar]
        onCleared: {
            calendar.visible = false;
            root.closedAt = Date.now();
        }
    }

    Calendar {
        id: calendar
        anchor.item: root
        anchor.edges: Edges.Bottom | Edges.Left
        anchor.gravity: Edges.Bottom | Edges.Right
        anchor.margins.top: 6
        now: root.now
    }
}
