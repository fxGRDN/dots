import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Polkit

// Polkit agent: the "authentication required" prompt apps like pkexec or GParted show.
Scope {
    id: root

    PolkitAgent {
        id: agent
    }

    LazyLoader {
        active: agent.isActive && agent.flow !== null

        PolkitWindow {
            flow: agent.flow
            screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
        }
    }
}
