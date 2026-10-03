import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import "Theme.js" as Theme

// Volume/brightness pop-up near the bottom of the focused screen.
// Volume is watched through PipeWire, so any change (keys, bar scroll, pwvucontrol) shows it.
// Brightness has no change events in sysfs, so the brightness keys call
// `qs -c bar ipc call osd brightness` after changing it.
Scope {
    id: root

    property string kind: "volume"
    property bool shown: false
    // PipeWire reports initial values right after startup; don't flash the OSD for those.
    property bool ready: false

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    property real brightness: 0

    readonly property real value: kind === "volume" ? volume : brightness
    readonly property bool off: kind === "volume" && muted

    function show(which) {
        if (!ready) return;
        kind = which;
        shown = true;
        hideTimer.restart();
    }

    PwObjectTracker {
        objects: [root.sink]
    }

    Connections {
        target: root.sink?.audio ?? null
        function onVolumeChanged() { root.show("volume"); }
        function onMutedChanged() { root.show("volume"); }
    }

    Timer {
        running: true
        interval: 1500
        onTriggered: root.ready = true
    }

    Timer {
        id: hideTimer
        interval: 1400
        onTriggered: root.shown = false
    }

    FileView {
        id: current
        path: "/sys/class/backlight/intel_backlight/brightness"
    }

    FileView {
        id: max
        path: "/sys/class/backlight/intel_backlight/max_brightness"
    }

    IpcHandler {
        target: "osd"

        function brightness(): void {
            current.reload();
            current.waitForJob();
            root.brightness = parseInt(current.text()) / Math.max(1, parseInt(max.text()));
            root.show("brightness");
        }
    }

    LazyLoader {
        active: root.shown

        PanelWindow {
            screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
            anchors.bottom: true
            margins.bottom: 90
            implicitWidth: 300
            implicitHeight: 46
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "qs-osd"
            mask: Region {}

            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0.047, 0.031, 0.031, 0.92)
                border.width: 1
                border.color: root.off ? Theme.line : Theme.red

                Row {
                    anchors.centerIn: parent
                    spacing: 12

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 18
                        text: root.kind === "brightness" ? Theme.icons.brightness
                            : root.muted ? Theme.icons.volumeMuted
                            : root.volume >= 0.66 ? Theme.icons.volumeHigh
                            : root.volume >= 0.33 ? Theme.icons.volumeMedium
                            : Theme.icons.volumeLow
                        color: root.off ? Theme.dim : Theme.orange
                        font.family: Theme.iconFont
                        font.pixelSize: 17
                    }

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Repeater {
                            model: 20

                            Rectangle {
                                required property int index
                                readonly property bool lit: index < Math.round(root.value * 20)
                                width: 8
                                height: 12
                                color: !lit ? Theme.line : root.off ? Theme.dim
                                    : index >= 16 ? Theme.gold : Theme.orange
                            }
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 44
                        horizontalAlignment: Text.AlignRight
                        text: root.off ? "MUTE" : Math.round(root.value * 100) + "%"
                        color: root.off ? Theme.dim : Theme.text
                        font.family: Theme.textFont
                        font.pixelSize: 13
                    }
                }
            }
        }
    }
}
