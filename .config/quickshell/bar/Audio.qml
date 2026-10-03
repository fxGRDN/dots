import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "Theme.js" as Theme

// Scroll: volume ±5%. Left click: quick settings on the output tab. Right click: mute.
BarButton {
    id: root

    required property var settings

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false

    icon: muted ? Theme.icons.volumeMuted
        : volume >= 0.66 ? Theme.icons.volumeHigh
        : volume >= 0.33 ? Theme.icons.volumeMedium
        : Theme.icons.volumeLow
    color: muted ? Theme.dim : Theme.text
    label: muted ? "MUTED" : Math.round(volume * 100) + "%"

    active: settings.open && settings.tab === "output"

    onClicked: event => {
        if (event.button === Qt.RightButton) {
            if (sink?.audio) sink.audio.muted = !sink.audio.muted;
        } else {
            settings.toggle("output");
        }
    }

    onWheel: event => {
        if (!sink?.audio) return;
        const step = event.angleDelta.y > 0 ? 0.05 : -0.05;
        sink.audio.volume = Math.max(0, Math.min(1, sink.audio.volume + step));
    }

    PwObjectTracker {
        objects: [root.sink]
    }
}
