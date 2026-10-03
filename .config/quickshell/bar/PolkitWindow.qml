import QtQuick
import Quickshell
import Quickshell.Wayland
import "Theme.js" as Theme

PanelWindow {
    id: window

    required property var flow

    property bool busy: false

    function submit() {
        if (!flow.isResponseRequired || busy) return;
        busy = true;
        flow.submit(password.text);
        password.text = "";
    }

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "qs-polkit"

    Connections {
        target: window.flow
        function onAuthenticationFailed() {
            window.busy = false;
            shake.restart();
        }
        function onIsResponseRequiredChanged() {
            if (window.flow.isResponseRequired) {
                window.busy = false;
                password.forceActiveFocus();
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: 0.55
    }

    Rectangle {
        id: panel
        width: 480
        height: content.implicitHeight + 48
        anchors.centerIn: parent
        color: Theme.bg
        border.width: 1
        border.color: window.flow.failed ? Theme.magenta : Theme.red

        SequentialAnimation {
            id: shake
            loops: 2
            NumberAnimation { target: panel; property: "anchors.horizontalCenterOffset"; to: -10; duration: 40 }
            NumberAnimation { target: panel; property: "anchors.horizontalCenterOffset"; to: 10; duration: 80 }
            NumberAnimation { target: panel; property: "anchors.horizontalCenterOffset"; to: 0; duration: 40 }
        }

        Column {
            id: content
            x: 24
            y: 24
            width: parent.width - 48
            spacing: 16

            Text {
                text: "AUTHENTICATION REQUIRED"
                color: Theme.purple
                font.family: Theme.textFont
                font.pixelSize: 12
                font.letterSpacing: 2
            }

            Text {
                width: parent.width
                text: window.flow.message
                wrapMode: Text.Wrap
                color: Theme.text
                font.family: Theme.textFont
                font.pixelSize: 15
                lineHeight: 1.15
            }

            Text {
                width: parent.width
                text: window.flow.actionId
                elide: Text.ElideMiddle
                color: Theme.dim
                font.family: Theme.textFont
                font.pixelSize: 10
                font.letterSpacing: 1
            }

            Rectangle {
                width: parent.width
                height: 40
                color: Theme.surface
                border.width: 1
                border.color: password.activeFocus ? Theme.orange : Theme.line

                TextInput {
                    id: password
                    anchors {
                        fill: parent
                        leftMargin: 14
                        rightMargin: 14
                    }
                    focus: true
                    enabled: !window.busy
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: window.flow.responseVisible ? TextInput.Normal : TextInput.Password
                    passwordCharacter: "■"
                    color: Theme.text
                    font.family: Theme.textFont
                    font.pixelSize: 16
                    font.letterSpacing: 2
                    cursorDelegate: Rectangle {
                        width: 8
                        color: Theme.orange
                        visible: password.cursorVisible
                    }

                    Text {
                        x: 14
                        anchors.verticalCenter: parent.verticalCenter
                        visible: password.text === ""
                        text: window.busy ? "CHECKING..." : (window.flow.inputPrompt || "Password").replace(/:\s*$/, "").toUpperCase()
                        color: Theme.dim
                        font.family: Theme.textFont
                        font.pixelSize: 13
                        font.letterSpacing: 1.5
                    }

                    Keys.onReturnPressed: window.submit()
                    Keys.onEnterPressed: window.submit()
                    Keys.onEscapePressed: window.flow.cancelAuthenticationRequest()
                }
            }

            Text {
                visible: text !== ""
                width: parent.width
                text: window.flow.supplementaryMessage !== "" ? window.flow.supplementaryMessage
                    : window.flow.failed ? "Wrong password, try again." : ""
                wrapMode: Text.Wrap
                color: window.flow.supplementaryIsError || window.flow.failed ? Theme.magenta : Theme.subtext
                font.family: Theme.textFont
                font.pixelSize: 12
            }

            Row {
                anchors.right: parent.right
                spacing: 22

                ActionButton {
                    text: "CANCEL"
                    onClicked: window.flow.cancelAuthenticationRequest()
                }

                ActionButton {
                    text: "AUTHENTICATE"
                    primary: true
                    onClicked: window.submit()
                }
            }
        }
    }

    component ActionButton: Text {
        id: button
        property bool primary: false
        signal clicked()

        color: area.containsMouse ? Theme.gold : primary ? Theme.orange : Theme.subtext
        font.family: Theme.textFont
        font.pixelSize: 12
        font.letterSpacing: 1.5

        MouseArea {
            id: area
            anchors.fill: parent
            anchors.margins: -6
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.clicked()
        }
    }
}
