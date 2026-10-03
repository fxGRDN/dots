import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import "Theme.js" as Theme

PanelWindow {
    id: window

    required property var settings

    readonly property var notifications: settings.notifications

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio)

    readonly property var wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var networks: (wifi?.networks?.values ?? [])
        .filter(n => n.name !== "")
        .sort((a, b) => (b.connected - a.connected) || (b.known - a.known) || (b.signalStrength - a.signalStrength))

    readonly property var adapter: Bluetooth.defaultAdapter ?? Bluetooth.adapters.values[0] ?? null
    readonly property var devices: (adapter?.devices?.values ?? [])
        .filter(d => d.paired || d.name !== d.address)
        .sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || a.name.localeCompare(b.name))

    property real brightness: 0
    // Network waiting for a password after connect() reported missing secrets.
    property var pskFor: null

    function setBrightness(value) {
        brightness = Math.max(0.01, Math.min(1, value));
        Quickshell.execDetached(["brightnessctl", "-q", "set", Math.round(brightness * 100) + "%"]);
    }

    anchors {
        top: true
        right: true
    }
    margins {
        top: 6
        right: 6
    }
    implicitWidth: 400
    implicitHeight: panel.implicitHeight
    color: "transparent"
    exclusionMode: ExclusionMode.Normal
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: "qs-quicksettings"

    HyprlandFocusGrab {
        active: true
        windows: [window]
        onCleared: window.settings.close()
    }

    PwObjectTracker {
        objects: [window.sink, window.source].concat(window.sinks)
    }

    // Scan only while the list is visible; scanning costs power.
    Binding {
        when: window.wifi !== null
        target: window.wifi
        property: "scannerEnabled"
        value: window.settings.tab === "wifi"
    }

    Binding {
        when: window.adapter !== null
        target: window.adapter
        property: "discovering"
        value: window.settings.tab === "bluetooth" && (window.adapter?.enabled ?? false)
    }

    FileView {
        id: brightnessFile
        path: "/sys/class/backlight/intel_backlight/brightness"
        onLoaded: window.brightness = parseInt(text()) / Math.max(1, parseInt(maxBrightnessFile.text()))
    }

    FileView {
        id: maxBrightnessFile
        path: "/sys/class/backlight/intel_backlight/max_brightness"
        blockLoading: true
    }

    Rectangle {
        id: panel
        anchors.fill: parent
        implicitHeight: content.implicitHeight + 28
        color: Qt.rgba(0.047, 0.031, 0.031, 0.94)
        border.width: 1
        border.color: Theme.red

        focus: true
        Keys.onEscapePressed: window.settings.close()

        Column {
            id: content
            x: 16
            y: 14
            width: parent.width - 32
            spacing: 14

            Text {
                text: "QUICK SETTINGS"
                color: Theme.purple
                font.family: Theme.textFont
                font.pixelSize: 12
                font.letterSpacing: 2
            }

            Row {
                spacing: 8

                Tile {
                    icon: window.wifi && Networking.wifiEnabled ? Theme.icons.wifi[4] : Theme.icons.wifiOff
                    label: "WI-FI"
                    on: Networking.wifiEnabled
                    onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
                }

                Tile {
                    icon: window.adapter?.enabled ? Theme.icons.bluetooth : Theme.icons.bluetoothOff
                    label: "BLUETOOTH"
                    on: window.adapter?.enabled ?? false
                    onClicked: if (window.adapter) window.adapter.enabled = !window.adapter.enabled
                }

                Tile {
                    icon: window.notifications.dnd ? Theme.icons.bellSleep : Theme.icons.bell
                    label: "SILENT"
                    on: window.notifications.dnd
                    onClicked: window.notifications.dnd = !window.notifications.dnd
                }

                Tile {
                    icon: window.source?.audio?.muted ? Theme.icons.micOff : Theme.icons.mic
                    label: "MIC"
                    on: !(window.source?.audio?.muted ?? true)
                    onClicked: if (window.source?.audio) window.source.audio.muted = !window.source.audio.muted
                }
            }

            Column {
                width: parent.width
                spacing: 10

                PixelSlider {
                    icon: window.sink?.audio?.muted ? Theme.icons.volumeMuted : Theme.icons.volumeHigh
                    value: window.sink?.audio?.volume ?? 0
                    off: window.sink?.audio?.muted ?? false
                    onMoved: v => { if (window.sink?.audio) window.sink.audio.volume = v; }
                    onIconClicked: if (window.sink?.audio) window.sink.audio.muted = !window.sink.audio.muted
                }

                PixelSlider {
                    icon: window.source?.audio?.muted ? Theme.icons.micOff : Theme.icons.mic
                    value: window.source?.audio?.volume ?? 0
                    off: window.source?.audio?.muted ?? false
                    onMoved: v => { if (window.source?.audio) window.source.audio.volume = v; }
                    onIconClicked: if (window.source?.audio) window.source.audio.muted = !window.source.audio.muted
                }

                PixelSlider {
                    icon: Theme.icons.brightness
                    value: window.brightness
                    onMoved: v => window.setBrightness(v)
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.red
                opacity: 0.5
            }

            Row {
                spacing: 20

                TabButton { tab: "output"; text: "OUTPUT" }
                TabButton { tab: "wifi"; text: "WI-FI" }
                TabButton { tab: "bluetooth"; text: "BLUETOOTH" }
            }

            Flickable {
                width: parent.width
                height: Math.min(contentHeight, 250)
                contentHeight: lists.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: lists
                    width: parent.width
                    spacing: 2

                    Repeater {
                        model: window.settings.tab === "output" ? window.sinks : []

                        ListRow {
                            required property var modelData
                            icon: /head|bluez/i.test(modelData.name + modelData.description) ? Theme.icons.headphones : Theme.icons.speaker
                            name: modelData.description || modelData.nickname || modelData.name
                            selected: modelData === window.sink
                            status: selected ? Theme.icons.check : ""
                            onClicked: Pipewire.preferredDefaultAudioSink = modelData
                        }
                    }

                    Repeater {
                        model: window.settings.tab === "wifi" && Networking.wifiEnabled ? window.networks : []

                        ListRow {
                            id: networkRow
                            required property var modelData
                            icon: Theme.icons.wifi[Math.min(4, Math.floor(modelData.signalStrength * 5))]
                            name: modelData.name
                            detail: modelData.stateChanging ? "CONNECTING" : modelData.connected ? "CONNECTED" : modelData.known ? "SAVED" : ""
                            selected: modelData.connected
                            status: modelData.connected ? Theme.icons.check : modelData.security !== WifiSecurityType.Open ? Theme.icons.lock : ""
                            onClicked: {
                                if (modelData.connected) {
                                    modelData.disconnect();
                                } else {
                                    window.pskFor = null;
                                    modelData.connect();
                                }
                            }

                            Connections {
                                target: networkRow.modelData
                                function onConnectionFailed(reason) {
                                    if (reason === ConnectionFailReason.NoSecrets) window.pskFor = networkRow.modelData;
                                }
                            }
                        }
                    }

                    Repeater {
                        model: window.settings.tab === "bluetooth" && (window.adapter?.enabled ?? false) ? window.devices : []

                        ListRow {
                            required property var modelData
                            iconSource: Quickshell.iconPath(modelData.icon, "bluetooth")
                            name: modelData.name
                            detail: modelData.pairing ? "PAIRING"
                                : modelData.state === BluetoothDeviceState.Connecting ? "CONNECTING"
                                : modelData.connected ? (modelData.batteryAvailable ? Math.round(modelData.battery * 100) + "%" : "CONNECTED")
                                : modelData.paired ? "PAIRED" : "NEW"
                            selected: modelData.connected
                            status: modelData.connected ? Theme.icons.check : ""
                            onClicked: {
                                if (!modelData.paired) {
                                    modelData.trusted = true;
                                    modelData.pair();
                                } else {
                                    modelData.connected = !modelData.connected;
                                }
                            }
                        }
                    }
                }
            }

            Text {
                visible: text !== ""
                text: window.settings.tab === "wifi" && !Networking.wifiEnabled ? "WI-FI IS OFF"
                    : window.settings.tab === "wifi" && window.networks.length === 0 ? "SCANNING..."
                    : window.settings.tab === "bluetooth" && !(window.adapter?.enabled ?? false) ? "BLUETOOTH IS OFF"
                    : window.settings.tab === "bluetooth" && window.devices.length === 0 ? "SCANNING..."
                    : ""
                color: Theme.dim
                font.family: Theme.textFont
                font.pixelSize: 12
                font.letterSpacing: 2
            }

            // Password prompt for a network that needs one.
            Rectangle {
                visible: window.pskFor !== null && window.settings.tab === "wifi"
                width: parent.width
                height: 34
                color: Theme.surface
                border.width: 1
                border.color: Theme.orange

                onVisibleChanged: if (visible) psk.forceActiveFocus()

                TextInput {
                    id: psk
                    anchors {
                        fill: parent
                        leftMargin: 12
                        rightMargin: 12
                    }
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: TextInput.Password
                    passwordCharacter: "■"
                    color: Theme.text
                    font.family: Theme.textFont
                    font.pixelSize: 14
                    cursorDelegate: Rectangle {
                        width: 7
                        color: Theme.orange
                        visible: psk.cursorVisible
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: psk.text === ""
                        text: "PASSWORD FOR " + (window.pskFor?.name ?? "").toUpperCase()
                        color: Theme.dim
                        font.family: Theme.textFont
                        font.pixelSize: 12
                        font.letterSpacing: 1
                    }

                    Keys.onReturnPressed: {
                        window.pskFor.connectWithPsk(text);
                        text = "";
                        window.pskFor = null;
                    }
                    Keys.onEscapePressed: {
                        text = "";
                        window.pskFor = null;
                        panel.forceActiveFocus();
                    }
                }
            }

            Row {
                spacing: 18

                LinkButton {
                    text: "MIXER"
                    onClicked: { Quickshell.execDetached(["uwsm", "app", "--", "pwvucontrol"]); window.settings.close(); }
                }
                LinkButton {
                    text: "NETWORK"
                    onClicked: { Quickshell.execDetached(["uwsm", "app", "--", "foot", "nmtui"]); window.settings.close(); }
                }
                LinkButton {
                    text: "BLUETOOTH"
                    onClicked: { Quickshell.execDetached(["uwsm", "app", "--", "foot", "bluetoothctl"]); window.settings.close(); }
                }
            }
        }
    }

    component Tile: Rectangle {
        id: tile
        property string icon
        property string label
        property bool on
        signal clicked()

        width: 86
        height: 58
        color: on ? Theme.raised : "transparent"
        border.width: 1
        border.color: on ? Theme.orange : tileArea.containsMouse ? Theme.subtext : Theme.line

        Column {
            anchors.centerIn: parent
            spacing: 5

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: tile.icon
                color: tile.on ? Theme.orange : Theme.dim
                font.family: Theme.iconFont
                font.pixelSize: 18
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: tile.label
                color: tile.on ? Theme.text : Theme.dim
                font.family: Theme.textFont
                font.pixelSize: 10
                font.letterSpacing: 1
            }
        }

        MouseArea {
            id: tileArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: tile.clicked()
        }
    }

    component PixelSlider: Item {
        id: slider
        property string icon
        property real value
        property bool off: false
        signal moved(real value)
        signal iconClicked()

        width: parent.width
        height: 20

        Text {
            id: sliderIcon
            anchors.verticalCenter: parent.verticalCenter
            width: 22
            text: slider.icon
            color: slider.off ? Theme.dim : iconArea.containsMouse ? Theme.gold : Theme.orange
            font.family: Theme.iconFont
            font.pixelSize: 16

            MouseArea {
                id: iconArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: slider.iconClicked()
            }
        }

        Item {
            id: track
            anchors {
                left: sliderIcon.right
                leftMargin: 8
                right: percent.left
                rightMargin: 10
                verticalCenter: parent.verticalCenter
            }
            height: 12

            Row {
                spacing: 2

                Repeater {
                    model: 25

                    Rectangle {
                        required property int index
                        readonly property bool lit: index < Math.round(slider.value * 25)
                        width: (track.width - 2 * 24) / 25
                        height: 12
                        color: !lit ? Theme.line : slider.off ? Theme.dim : index >= 20 ? Theme.gold : Theme.orange
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                cursorShape: Qt.PointingHandCursor
                function set(x) { slider.moved(Math.max(0, Math.min(1, x / track.width))); }
                onPressed: mouse => set(mouse.x - 4)
                onPositionChanged: mouse => { if (pressed) set(mouse.x - 4); }
                onWheel: wheel => slider.moved(Math.max(0, Math.min(1, slider.value + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))))
            }
        }

        Text {
            id: percent
            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
            }
            width: 40
            horizontalAlignment: Text.AlignRight
            text: slider.off ? "OFF" : Math.round(slider.value * 100) + "%"
            color: slider.off ? Theme.dim : Theme.text
            font.family: Theme.textFont
            font.pixelSize: 12
        }
    }

    component TabButton: Text {
        id: tabButton
        property string tab
        readonly property bool current: window.settings.tab === tab

        color: current ? Theme.orange : tabArea.containsMouse ? Theme.text : Theme.subtext
        font.family: Theme.textFont
        font.pixelSize: 12
        font.letterSpacing: 1.5
        bottomPadding: 5

        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 2
            color: Theme.orange
            visible: tabButton.current
        }

        MouseArea {
            id: tabArea
            anchors.fill: parent
            anchors.margins: -4
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: window.settings.tab = tabButton.tab
        }
    }

    component ListRow: Item {
        id: row
        property string icon: ""
        property string iconSource: ""
        property string name
        property string detail: ""
        property string status: ""
        property bool selected: false
        signal clicked()

        width: parent.width
        height: 32

        Rectangle {
            anchors.fill: parent
            color: row.selected || rowArea.containsMouse ? Theme.surface : "transparent"
        }

        Rectangle {
            visible: row.selected
            width: 3
            height: parent.height
            color: Theme.orange
        }

        Text {
            id: rowIcon
            visible: row.iconSource === ""
            anchors {
                left: parent.left
                leftMargin: 12
                verticalCenter: parent.verticalCenter
            }
            width: 18
            text: row.icon
            color: row.selected ? Theme.orange : Theme.subtext
            font.family: Theme.iconFont
            font.pixelSize: 15
        }

        Image {
            visible: row.iconSource !== ""
            anchors.centerIn: rowIcon
            width: 16
            height: 16
            source: row.iconSource
            sourceSize: Qt.size(16, 16)
        }

        Text {
            anchors {
                left: rowIcon.right
                leftMargin: 10
                right: rowDetail.left
                rightMargin: 8
                verticalCenter: parent.verticalCenter
            }
            text: row.name
            elide: Text.ElideRight
            color: row.selected ? Theme.orange : Theme.text
            font.family: Theme.textFont
            font.pixelSize: 13
        }

        Text {
            id: rowDetail
            anchors {
                right: rowStatus.left
                rightMargin: 8
                verticalCenter: parent.verticalCenter
            }
            text: row.detail
            color: Theme.dim
            font.family: Theme.textFont
            font.pixelSize: 10
            font.letterSpacing: 1
        }

        Text {
            id: rowStatus
            anchors {
                right: parent.right
                rightMargin: 10
                verticalCenter: parent.verticalCenter
            }
            width: 16
            horizontalAlignment: Text.AlignRight
            text: row.status
            color: row.selected ? Theme.orange : Theme.dim
            font.family: Theme.iconFont
            font.pixelSize: 13
        }

        MouseArea {
            id: rowArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: row.clicked()
        }
    }

    component LinkButton: Text {
        id: link
        signal clicked()

        color: linkArea.containsMouse ? Theme.orange : Theme.dim
        font.family: Theme.textFont
        font.pixelSize: 11
        font.letterSpacing: 1.5

        MouseArea {
            id: linkArea
            anchors.fill: parent
            anchors.margins: -4
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: link.clicked()
        }
    }
}
