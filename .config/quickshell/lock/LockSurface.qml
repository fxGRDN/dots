import QtQuick
import QtMultimedia
import Quickshell

Item {
    id: root
    required property LockContext context

    readonly property string background: Quickshell.env("LOCK_BG")
        || "/home/felix/.local/share/wallpapers/pixelhole.gif"
    readonly property bool backgroundIsGif: background.toLowerCase().endsWith(".gif")

    // Colours taken from the pixelhole wallpaper (see hypr/scheme/current.lua).
    QtObject {
        id: pal
        readonly property color voidBlack: "#0c0808"
        readonly property color text: "#ffe8c4"
        readonly property color subtext: "#c45a38"
        readonly property color orange: "#ff6a10"
        readonly property color red: "#b00800"
        readonly property color gold: "#ffcc44"
        readonly property color magenta: "#c44dff"
        readonly property color purple: "#a040c0"
        readonly property string font: "Pixelon"
    }

    Rectangle {
        anchors.fill: parent
        color: pal.voidBlack
    }

    Loader {
        anchors.fill: parent
        sourceComponent: root.backgroundIsGif ? gifBackground : videoBackground
    }

    Component {
        id: gifBackground
        AnimatedImage {
            source: "file://" + root.background
            fillMode: Image.PreserveAspectCrop
            smooth: false
            playing: true
        }
    }

    Component {
        id: videoBackground
        Video {
            source: "file://" + root.background
            fillMode: VideoOutput.PreserveAspectCrop
            loops: MediaPlayer.Infinite
            muted: true
            autoPlay: true
        }
    }

    // Clock and date sit above the accretion disk.
    Column {
        anchors {
            top: parent.top
            topMargin: 48
            horizontalCenter: parent.horizontalCenter
        }
        spacing: 6

        Text {
            id: clock
            property var now: new Date()
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatTime(now, "HH:mm")
            color: pal.text
            font.family: pal.font
            font.pixelSize: 84
            renderType: Text.NativeRendering

            Timer {
                running: true
                repeat: true
                interval: 1000
                onTriggered: clock.now = new Date()
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDate(clock.now, "ddd  //  dd MMM yyyy").toUpperCase()
            color: pal.subtext
            font.family: pal.font
            font.pixelSize: 18
            font.letterSpacing: 2
        }
    }

    // Password field at the bottom of the screen.
    Column {
        anchors {
            bottom: parent.bottom
            bottomMargin: 64
            horizontalCenter: parent.horizontalCenter
        }
        spacing: 12

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "✦  EVENT HORIZON  /  SESSION LOCKED  ✦"
            color: pal.orange
            opacity: 0.85
            font.family: pal.font
            font.pixelSize: 13
            font.letterSpacing: 2
        }

        Rectangle {
            id: field
            width: 440
            height: 54
            anchors.horizontalCenter: parent.horizontalCenter
            color: Qt.rgba(0.047, 0.031, 0.031, 0.72)
            border.width: 2
            border.color: root.context.unlockInProgress ? pal.gold
                : root.context.showFailure ? pal.magenta
                : input.activeFocus && root.context.currentText.length > 0 ? pal.orange
                : pal.red

            Behavior on border.color { ColorAnimation { duration: 150 } }

            transform: Translate { id: shake }

            SequentialAnimation {
                id: shakeAnimation
                loops: 2
                NumberAnimation { target: shake; property: "x"; to: -10; duration: 40 }
                NumberAnimation { target: shake; property: "x"; to: 10; duration: 80 }
                NumberAnimation { target: shake; property: "x"; to: 0; duration: 40 }
            }

            Connections {
                target: root.context
                function onFailed() { shakeAnimation.restart() }
            }

            Text {
                anchors.centerIn: parent
                visible: root.context.currentText.length === 0
                text: root.context.unlockInProgress ? "VERIFYING..."
                    : root.context.showFailure ? "WRONG PASSCODE"
                    : "ENTER PASSCODE"
                color: root.context.showFailure ? pal.magenta : pal.subtext
                font.family: pal.font
                font.pixelSize: 16
                font.letterSpacing: 3
            }

            // Square pixel "dots", one per typed character.
            Row {
                anchors.centerIn: parent
                spacing: 6
                Repeater {
                    model: Math.min(root.context.currentText.length, 28)
                    Rectangle {
                        required property int index
                        width: 10
                        height: 10
                        color: index === root.context.currentText.length - 1 ? pal.gold : pal.orange
                    }
                }
            }

            TextInput {
                id: input
                anchors.fill: parent
                opacity: 0
                focus: true
                enabled: !root.context.unlockInProgress
                echoMode: TextInput.Password
                inputMethodHints: Qt.ImhSensitiveData
                cursorVisible: false

                onTextChanged: root.context.currentText = text
                onAccepted: root.context.tryUnlock()
                Keys.onEscapePressed: text = ""

                Connections {
                    target: root.context
                    function onCurrentTextChanged() {
                        if (input.text !== root.context.currentText) input.text = root.context.currentText;
                    }
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.context.failedAttempts > 0
            text: root.context.failedAttempts + (root.context.failedAttempts === 1 ? " FAILED ATTEMPT" : " FAILED ATTEMPTS")
            color: pal.purple
            font.family: pal.font
            font.pixelSize: 12
            font.letterSpacing: 2
        }
    }
}
