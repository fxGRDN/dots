import QtQuick
import Quickshell
import Quickshell.Networking
import "Theme.js" as Theme

// Hover shows the network name. Click opens quick settings on the Wi-Fi tab.
BarButton {
    id: root

    required property var settings

    readonly property var device: {
        const devices = Networking.devices.values;
        return devices.find(d => d.connected && d.type === DeviceType.Wired)
            ?? devices.find(d => d.connected)
            ?? null;
    }
    readonly property bool wired: device?.type === DeviceType.Wired
    readonly property var network: device?.networks?.values.find(n => n.connected) ?? null
    readonly property real strength: network?.signalStrength ?? 0

    icon: !device ? Theme.icons.wifiOff
        : wired ? Theme.icons.ethernet
        : Theme.icons.wifi[Math.min(4, Math.floor(strength * 5))]
    color: device ? Theme.text : Theme.dim
    hoverLabel: !device ? "OFFLINE"
        : wired ? device.name
        : (network?.name ?? "") + " " + Math.round(strength * 100) + "%"

    active: settings.open && settings.tab === "wifi"

    onClicked: settings.toggle("wifi")
}
