import QtQuick

Rectangle {
    id: root

    width: Screen.width
    height: Screen.height
    color: pal.voidBlack

    property int userIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
    property int sessionIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
    readonly property string userName: users.currentItem ? users.currentItem.userName : userModel.lastUser
    readonly property string userLabel: users.currentItem ? (users.currentItem.realName || users.currentItem.userName) : userModel.lastUser
    readonly property string sessionName: sessions.currentItem ? sessions.currentItem.sessionName : ""

    property bool loginInProgress: false
    property bool showFailure: false
    property int failedAttempts: 0

    // Colours taken from the pixelhole wallpaper, same as the Quickshell lockscreen.
    QtObject {
        id: pal
        readonly property color voidBlack: "#0c0808"
        readonly property color text: "#ffe8c4"
        readonly property color subtext: "#c45a38"
        readonly property color dim: "#6a4040"
        readonly property color orange: "#ff6a10"
        readonly property color red: "#b00800"
        readonly property color gold: "#ffcc44"
        readonly property color magenta: "#c44dff"
        readonly property color purple: "#a040c0"
        readonly property string font: config.font || "Pixelon"
        readonly property string iconFont: config.iconFont || "FiraCode Nerd Font Propo"
    }

    function cycle(step, index, count) {
        return count > 0 ? (index + step + count) % count : 0;
    }

    // Fade to the void colour first and only then log in: SDDM tears the greeter
    // down as soon as authentication succeeds, and Hyprland starts on the same colour.
    function login() {
        if (loginInProgress) return;
        loginInProgress = true;
        showFailure = false;
        fadeOut.restart();
    }

    SequentialAnimation {
        id: fadeOut
        NumberAnimation { target: curtain; property: "opacity"; to: 1; duration: 450; easing.type: Easing.InQuad }
        ScriptAction { script: sddm.login(root.userName, input.text, root.sessionIndex) }
    }

    NumberAnimation {
        id: fadeIn
        target: curtain
        property: "opacity"
        to: 0
        duration: 250
        easing.type: Easing.OutQuad
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            fadeIn.restart();
            root.loginInProgress = false;
            root.showFailure = true;
            root.failedAttempts += 1;
            input.text = "";
            shakeAnimation.restart();
            input.forceActiveFocus();
        }
        function onLoginSucceeded() {
            root.loginInProgress = false;
        }
    }

    // Transparent views that expose the selected user and session roles
    // (an invisible ListView never instantiates its delegates).
    ListView {
        id: users
        width: 1
        height: 1
        opacity: 0
        interactive: false
        model: userModel
        currentIndex: root.userIndex
        delegate: Item {
            readonly property string userName: model.name
            readonly property string realName: model.realName
        }
    }

    ListView {
        id: sessions
        width: 1
        height: 1
        opacity: 0
        interactive: false
        model: sessionModel
        currentIndex: root.sessionIndex
        delegate: Item {
            readonly property string sessionName: model.name
        }
    }

    AnimatedImage {
        anchors.fill: parent
        source: config.background || "background.gif"
        fillMode: Image.PreserveAspectCrop
        smooth: false
        playing: true
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

    // User, password field and status at the bottom of the screen.
    Column {
        anchors {
            bottom: parent.bottom
            bottomMargin: 64
            horizontalCenter: parent.horizontalCenter
        }
        spacing: 12

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 14

            Selector {
                text: "<"
                visible: userModel.count > 1
                onActivated: root.userIndex = root.cycle(-1, root.userIndex, userModel.count)
            }

            Text {
                text: "\u2726  " + root.userLabel.toUpperCase() + "  /  EVENT HORIZON  \u2726"
                color: pal.orange
                opacity: 0.85
                font.family: pal.font
                font.pixelSize: 13
                font.letterSpacing: 2
            }

            Selector {
                text: ">"
                visible: userModel.count > 1
                onActivated: root.userIndex = root.cycle(1, root.userIndex, userModel.count)
            }
        }

        Rectangle {
            id: field
            width: 440
            height: 54
            anchors.horizontalCenter: parent.horizontalCenter
            color: Qt.rgba(0.047, 0.031, 0.031, 0.72)
            border.width: 2
            border.color: root.loginInProgress ? pal.gold
                : root.showFailure ? pal.magenta
                : input.activeFocus && input.text.length > 0 ? pal.orange
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

            Text {
                anchors.centerIn: parent
                visible: input.text.length === 0
                text: root.loginInProgress ? "VERIFYING..."
                    : root.showFailure ? "WRONG PASSCODE"
                    : "ENTER PASSCODE"
                color: root.showFailure ? pal.magenta : pal.subtext
                font.family: pal.font
                font.pixelSize: 16
                font.letterSpacing: 3
            }

            // Square pixel "dots", one per typed character.
            Row {
                anchors.centerIn: parent
                spacing: 6
                Repeater {
                    model: Math.min(input.text.length, 28)
                    Rectangle {
                        required property int index
                        width: 10
                        height: 10
                        color: index === input.text.length - 1 ? pal.gold : pal.orange
                    }
                }
            }

            TextInput {
                id: input
                anchors.fill: parent
                opacity: 0
                focus: true
                enabled: !root.loginInProgress
                echoMode: TextInput.Password
                inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
                cursorVisible: false

                onTextChanged: if (text.length > 0) root.showFailure = false
                onAccepted: root.login()

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        text = "";
                    } else if (event.key === Qt.Key_F1) {
                        root.userIndex = root.cycle(1, root.userIndex, userModel.count);
                    } else if (event.key === Qt.Key_F2) {
                        root.sessionIndex = root.cycle(1, root.sessionIndex, sessionModel.count);
                    } else {
                        return;
                    }
                    event.accepted = true;
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.failedAttempts > 0
                ? root.failedAttempts + (root.failedAttempts === 1 ? " FAILED ATTEMPT" : " FAILED ATTEMPTS")
                : keyboard.capsLock ? "CAPS LOCK IS ON" : " "
            color: keyboard.capsLock && root.failedAttempts === 0 ? pal.gold : pal.purple
            font.family: pal.font
            font.pixelSize: 12
            font.letterSpacing: 2
        }
    }

    // Session picker, bottom left.
    Row {
        anchors {
            left: parent.left
            bottom: parent.bottom
            leftMargin: 28
            bottomMargin: 24
        }
        spacing: 10

        Selector {
            text: "<"
            onActivated: root.sessionIndex = root.cycle(-1, root.sessionIndex, sessionModel.count)
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "SESSION  " + root.sessionName.toUpperCase()
            color: pal.subtext
            font.family: pal.font
            font.pixelSize: 13
            font.letterSpacing: 2
        }

        Selector {
            text: ">"
            onActivated: root.sessionIndex = root.cycle(1, root.sessionIndex, sessionModel.count)
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            leftPadding: 14
            text: userModel.count > 1 ? "F1 USER   F2 SESSION" : "F2 SESSION"
            color: pal.dim
            font.family: pal.font
            font.pixelSize: 11
            font.letterSpacing: 1
        }
    }

    // Power controls, bottom right.
    Row {
        anchors {
            right: parent.right
            bottom: parent.bottom
            rightMargin: 28
            bottomMargin: 20
        }
        spacing: 22

        Selector {
            icon: true
            visible: sddm.canSuspend
            text: String.fromCodePoint(0xF04B2)
            onActivated: sddm.suspend()
        }

        Selector {
            icon: true
            visible: sddm.canReboot
            text: String.fromCodePoint(0xF0709)
            onActivated: sddm.reboot()
        }

        Selector {
            icon: true
            visible: sddm.canPowerOff
            text: String.fromCodePoint(0xF0425)
            hoverColor: pal.magenta
            onActivated: sddm.powerOff()
        }
    }

    Rectangle {
        id: curtain
        anchors.fill: parent
        z: 100
        color: pal.voidBlack
        opacity: 0
    }

    component Selector: Text {
        id: selector
        property bool icon: false
        property color hoverColor: pal.orange
        signal activated()

        color: area.containsMouse ? hoverColor : icon ? pal.subtext : pal.dim
        font.family: icon ? pal.iconFont : pal.font
        font.pixelSize: icon ? 22 : 18

        MouseArea {
            id: area
            anchors.fill: parent
            anchors.margins: -6
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                selector.activated();
                input.forceActiveFocus();
            }
        }
    }
}
