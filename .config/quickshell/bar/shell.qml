import Quickshell

ShellRoot {
    Launcher {}

    Variants {
        model: Quickshell.screens

        Bar {
            required property var modelData
            screen: modelData
        }
    }
}
