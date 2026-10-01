import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "Apps.js" as Apps
import "Groups.js" as Groups

// Toggle with: qs -c bar ipc call launcher toggle
Scope {
    id: root

    property bool open: false
    property var usage: ({})

    readonly property var apps: DesktopEntries.applications.values
        .filter(entry => !entry.noDisplay)
        .sort(Apps.byUsageThenName(root.usage))

    // Sidebar sections: frequent, custom groups, then every standard category with apps.
    readonly property var sections: {
        const result = [];
        const frequent = apps.filter(entry => (usage[entry.id] || 0) > 0).slice(0, 10);
        if (frequent.length > 0) result.push({ name: "FREQUENT", apps: frequent });

        for (const group of Groups.groups) {
            const members = group.apps
                .map(id => apps.find(entry => entry.id === id))
                .filter(Boolean);
            if (members.length > 0) result.push({ name: group.name, apps: members });
        }

        const names = Apps.categories.map(c => c.name).concat([Apps.otherCategory]);
        for (const name of names) {
            const members = apps.filter(entry => Apps.categoryOf(entry) === name);
            if (members.length > 0) result.push({ name: name, apps: members });
        }

        result.push({ name: "ALL", apps: apps });
        return result;
    }

    function launch(entry) {
        usage[entry.id] = (usage[entry.id] || 0) + 1;
        usage = Object.assign({}, usage);
        usageFile.setText(JSON.stringify(usage));

        if (entry.runInTerminal) {
            Quickshell.execDetached(["uwsm", "app", "--", "kitty", "-e"].concat(Array.from(entry.command)));
        } else {
            Quickshell.execDetached(["uwsm", "app", "--", entry.id + ".desktop"]);
        }
        open = false;
    }

    FileView {
        id: usageFile
        path: Quickshell.statePath("launcher-usage.json")
        atomicWrites: true
        printErrors: false
        onLoaded: {
            try {
                root.usage = JSON.parse(text()) || {};
            } catch (e) {
                root.usage = {};
            }
        }
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void { root.open = !root.open; }
        function show(): void { root.open = true; }
        function hide(): void { root.open = false; }
    }

    LazyLoader {
        active: root.open

        LauncherWindow {
            launcher: root
            screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
        }
    }
}
