import QtQuick
import Quickshell
import Quickshell.Bluetooth
import "Theme.js" as Theme

// Left click: blueman-manager. Right click: toggle the adapter.
BarButton {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter ?? (Bluetooth.adapters.values.length > 0 ? Bluetooth.adapters.values[0] : null)
    readonly property bool enabled: adapter?.enabled ?? false
    readonly property var connected: adapter ? adapter.devices.values.filter(d => d.connected) : []
    readonly property var withBattery: connected.find(d => d.batteryAvailable)

    icon: !enabled ? Theme.icons.bluetoothOff
        : connected.length > 0 ? Theme.icons.bluetoothConnected
        : Theme.icons.bluetooth
    color: enabled ? Theme.text : Theme.dim
    label: withBattery ? Math.round(withBattery.battery * 100) + "%" : ""
    hoverLabel: connected.length > 0 ? connected.map(d => d.name).join(", ") : ""

    onClicked: event => {
        if (event.button === Qt.RightButton) {
            if (adapter) adapter.enabled = !adapter.enabled;
        } else {
            Quickshell.execDetached(["blueman-manager"]);
        }
    }
}
