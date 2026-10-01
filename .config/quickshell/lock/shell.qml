import Quickshell
import Quickshell.Wayland

ShellRoot {
    LockContext {
        id: lockContext

        onUnlocked: {
            // Unlock before exiting, or the compositor keeps a fallback lock up.
            lock.locked = false;
            Qt.quit();
        }
    }

    WlSessionLock {
        id: lock
        locked: true

        WlSessionLockSurface {
            color: "#0c0808"

            LockSurface {
                anchors.fill: parent
                context: lockContext
            }
        }
    }
}
