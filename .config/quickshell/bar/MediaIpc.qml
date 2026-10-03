import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import "Players.js" as Players

// Media keys: qs -c bar ipc call media <toggle|next|previous>
Scope {
    id: root

    readonly property var player: Players.pick(Mpris.players.values)

    IpcHandler {
        target: "media"

        function toggle(): void { root.player?.togglePlaying(); }
        function next(): void { root.player?.next(); }
        function previous(): void { root.player?.previous(); }
    }
}
