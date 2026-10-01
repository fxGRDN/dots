import QtQuick
import Quickshell

// Windowed preview of the lockscreen: qs -p ~/.config/quickshell/lock/preview.qml
// Does not lock the session.
ShellRoot {
    LockContext {
        id: lockContext
        onUnlocked: Qt.quit()
    }

    FloatingWindow {
        implicitWidth: 1920
        implicitHeight: 1080
        color: "#0c0808"

        LockSurface {
            anchors.fill: parent
            context: lockContext
        }
    }
}
