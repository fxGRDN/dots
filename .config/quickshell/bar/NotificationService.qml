import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Notifications

// Notification daemon (replaces swaync): popups, notification centre, do-not-disturb.
// IPC: qs -c bar ipc call notifications <toggle|clear|toggleDnd>
Scope {
    id: root

    property bool centerOpen: false
    property bool dnd: false
    property var popups: []
    // Arrival times by notification id; the server doesn't record them.
    property var arrived: ({})
    property int unread: 0

    readonly property var notifications: server.trackedNotifications.values.slice().reverse()
    readonly property var focusedScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]

    property real closedAt: 0
    // Ticks so relative times ("5M") stay current.
    property real now: Date.now()

    Timer {
        running: root.notifications.length > 0
        repeat: true
        interval: 30000
        onTriggered: root.now = Date.now()
    }

    function toggleCenter() {
        // A click on the bell also clears the centre's focus grab; don't reopen right away.
        if (!centerOpen && Date.now() - closedAt < 250) return;
        centerOpen = !centerOpen;
    }

    function closeCenter() {
        if (!centerOpen) return;
        centerOpen = false;
        closedAt = Date.now();
    }

    function removePopup(notification) {
        popups = popups.filter(n => n !== notification);
    }

    function clearAll() {
        for (const n of notifications) n.dismiss();
        popups = [];
    }

    function timeOf(notification) {
        const at = arrived[notification.id];
        if (!at) return "";
        const minutes = Math.floor((Math.max(now, at) - at) / 60000);
        if (minutes < 1) return "NOW";
        if (minutes < 60) return minutes + "M";
        return Qt.formatTime(new Date(at), "HH:mm");
    }

    onCenterOpenChanged: if (centerOpen) { unread = 0; popups = []; }

    NotificationServer {
        id: server

        keepOnReload: true
        bodySupported: true
        bodyMarkupSupported: true
        actionsSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: notification => {
            notification.tracked = true;
            root.arrived[notification.id] = Date.now();

            const critical = notification.urgency === NotificationUrgency.Critical;
            if (!root.centerOpen) root.unread += 1;
            if (root.centerOpen || (root.dnd && !critical)) return;

            root.popups = [notification].concat(root.popups.filter(n => n.id !== notification.id)).slice(0, 4);
        }
    }

    IpcHandler {
        target: "notifications"

        function toggle(): void { root.toggleCenter(); }
        function clear(): void { root.clearAll(); }
        function toggleDnd(): void { root.dnd = !root.dnd; }
    }

    NotificationPopups {
        service: root
        screen: root.focusedScreen
    }

    LazyLoader {
        active: root.centerOpen

        NotificationCenter {
            service: root
            screen: root.focusedScreen
        }
    }
}
