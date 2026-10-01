import QtQuick
import "Theme.js" as Theme

// Click to toggle between time and date.
BarButton {
    id: root

    property var now: new Date()
    property bool showDate: false

    label: showDate ? Qt.formatDate(now, "ddd dd MMM yyyy").toUpperCase() : Qt.formatTime(now, "hh:mm:ss AP")
    labelColor: hovered ? Theme.orange : Theme.text
    labelMinWidth: showDate ? 0 : widestTime

    // Pixelon is proportional, so size for the widest digit in every position.
    readonly property real widestTime: {
        let digit = 0;
        for (let d = 0; d <= 9; d++) digit = Math.max(digit, metrics.advanceWidth(String(d)));
        const suffix = Math.max(metrics.advanceWidth(" AM"), metrics.advanceWidth(" PM"));
        return Math.ceil(6 * digit + metrics.advanceWidth("::") + suffix) + 1;
    }

    onClicked: showDate = !showDate

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
}
