import Quickshell

ShellRoot {
    CaptureWarmup {}
    Launcher {}
    MediaIpc {}
    Osd {}
    Clipboard {}
    Polkit {}
    Switcher {}
    NotificationService { id: notificationService }
    QuickSettings {
        id: quickSettingsPanel
        notifications: notificationService
    }

    Variants {
        model: Quickshell.screens

        Bar {
            required property var modelData
            screen: modelData
            notifications: notificationService
            quickSettings: quickSettingsPanel
        }
    }
}
