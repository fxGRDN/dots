import QtQuick
import Quickshell.Services.UPower
import "Theme.js" as Theme

// Click to toggle between percentage and time remaining.
BarButton {
    id: root

    readonly property var device: UPower.displayDevice
    readonly property int percent: Math.round((device?.percentage ?? 0) * 100)
    readonly property bool charging: device?.state === UPowerDeviceState.Charging
        || device?.state === UPowerDeviceState.FullyCharged
        || device?.state === UPowerDeviceState.PendingCharge
    property bool showTime: false

    function formatSeconds(seconds) {
        if (!seconds || seconds <= 0) return "--:--";
        const h = Math.floor(seconds / 3600);
        const m = Math.floor((seconds % 3600) / 60);
        return h + "h" + String(m).padStart(2, "0");
    }

    visible: device?.isLaptopBattery ?? false
    icon: charging ? Theme.icons.batteryCharging : Theme.icons.battery[Math.max(0, Math.min(9, Math.ceil(percent / 10) - 1))]
    color: charging ? Theme.gold
        : percent <= 20 ? Theme.brightRed
        : percent <= 30 ? Theme.orange
        : Theme.text
    labelColor: percent <= 20 && !charging ? Theme.brightRed : Theme.subtext
    label: showTime ? formatSeconds(charging ? device.timeToFull : device.timeToEmpty) : percent + "%"

    onClicked: showTime = !showTime

    SequentialAnimation on opacity {
        running: root.percent <= 20 && !root.charging
        loops: Animation.Infinite
        NumberAnimation { to: 0.35; duration: 500 }
        NumberAnimation { to: 1; duration: 500 }
        onRunningChanged: if (!running) root.opacity = 1
    }
}
