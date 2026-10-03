import Quickshell

ShellRoot {
    Launcher {}
    MediaIpc {}
    Osd {}
    Clipboard {}
    Polkit {}
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
