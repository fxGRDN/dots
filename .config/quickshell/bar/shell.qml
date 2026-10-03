import Quickshell

ShellRoot {
    Launcher {}
    MediaIpc {}
    Osd {}
    NotificationService { id: notificationService }

    Variants {
        model: Quickshell.screens

        Bar {
            required property var modelData
            screen: modelData
            notifications: notificationService
        }
    }
}
