import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import "Theme.js" as Theme
import "Players.js" as Players

// Click: play/pause. Right click: show/hide the music scratchpad. Scroll: next/previous.
RowLayout {
    id: root

    readonly property var player: Players.pick(Mpris.players.values)
    readonly property bool playing: player?.isPlaying ?? false

    visible: player !== null
    spacing: 0

    BarButton {
        visible: root.player?.canGoPrevious ?? false
        icon: Theme.icons.skipPrevious
        color: Theme.dim
        onClicked: root.player.previous()
    }

    BarButton {
        icon: root.playing ? Theme.icons.pause : Theme.icons.play
        color: root.playing ? Theme.orange : Theme.subtext
        label: Players.describe(root.player)
        labelColor: root.playing ? Theme.text : Theme.dim
        labelMaxWidth: 280

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/scratchpad.sh", "music"]);
            else
                root.player.togglePlaying();
        }
        onWheel: wheel => {
            if (wheel.angleDelta.y > 0 && root.player.canGoPrevious) root.player.previous();
            else if (wheel.angleDelta.y < 0 && root.player.canGoNext) root.player.next();
        }
    }

    BarButton {
        visible: root.player?.canGoNext ?? false
        icon: Theme.icons.skipNext
        color: Theme.dim
        onClicked: root.player.next()
    }
}
