import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import "Theme.js" as Theme

// One notification: urgency stripe, icon/image, app + time, summary, body, actions.
Rectangle {
    id: card

    required property var notification
    required property var service
    // Popups clamp the body; the centre shows it in full.
    property int bodyLines: 4

    signal activated()

    readonly property bool critical: notification.urgency === NotificationUrgency.Critical
    readonly property color accent: critical ? Theme.magenta
        : notification.urgency === NotificationUrgency.Low ? Theme.dim
        : Theme.orange
    // Images and icons can be file paths, raw image data, or theme icon names that may
    // not exist; try each candidate and hide the icon rather than show a broken one.
    readonly property string iconSource: {
        const names = [];
        for (const source of [notification.image || "", notification.appIcon || ""]) {
            if (source === "") continue;
            if (source.startsWith("/")) return "file://" + source;
            if (source.startsWith("file://")) return source;
            if (source.startsWith("image://icon/")) names.push(source.slice("image://icon/".length));
            else if (source.startsWith("image://")) return source;
            else names.push(source);
        }
        const app = (notification.appName || "").toLowerCase();
        names.push(notification.desktopEntry || "", app, app.replace(/\s+/g, "-"), app.split(/\s+/)[0]);
        for (const name of names) {
            const path = name !== "" ? Quickshell.iconPath(name, true) : "";
            if (path !== "") return path;
        }
        return "";
    }
    readonly property var visibleActions: Array.from(notification.actions ?? [])
        .filter(a => a.identifier !== "default" && a.text !== "")

    implicitHeight: content.implicitHeight + 24
    color: hover.hovered ? Theme.surface : Qt.rgba(0.047, 0.031, 0.031, 0.94)
    border.width: 1
    border.color: card.critical ? Theme.magenta : Theme.red

    HoverHandler { id: hover }

    TapHandler {
        onTapped: {
            const fallback = Array.from(card.notification.actions ?? []).find(a => a.identifier === "default");
            if (fallback) fallback.invoke();
            card.activated();
            card.notification.dismiss();
        }
    }

    Rectangle {
        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
        }
        width: 3
        color: card.accent
    }

    Column {
        id: content
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            leftMargin: 16
            rightMargin: 12
            topMargin: 12
        }
        spacing: 6

        Item {
            width: parent.width
            height: 16

            Text {
                anchors {
                    left: parent.left
                    right: meta.left
                    rightMargin: 8
                    verticalCenter: parent.verticalCenter
                }
                text: (card.notification.appName || "NOTIFICATION").toUpperCase()
                elide: Text.ElideRight
                color: card.accent
                font.family: Theme.textFont
                font.pixelSize: 11
                font.letterSpacing: 1.5
            }

            Row {
                id: meta
                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                spacing: 10

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: card.service.timeOf(card.notification)
                    color: Theme.dim
                    font.family: Theme.textFont
                    font.pixelSize: 11
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Theme.icons.close
                    color: closeArea.containsMouse ? Theme.orange : Theme.dim
                    font.family: Theme.iconFont
                    font.pixelSize: 14

                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        anchors.margins: -6
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: card.notification.dismiss()
                    }
                }
            }
        }

        Row {
            width: parent.width
            spacing: 12

            IconImage {
                id: icon
                visible: card.iconSource !== ""
                implicitSize: 36
                source: card.iconSource
            }

            Column {
                width: parent.width - (icon.visible ? icon.width + parent.spacing : 0)
                spacing: 3

                Text {
                    width: parent.width
                    text: card.notification.summary
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    color: Theme.text
                    font.family: Theme.textFont
                    font.pixelSize: 14
                }

                Text {
                    width: parent.width
                    visible: text !== ""
                    text: card.notification.body
                    textFormat: Text.StyledText
                    wrapMode: Text.Wrap
                    maximumLineCount: card.bodyLines
                    elide: Text.ElideRight
                    color: Theme.subtext
                    linkColor: Theme.orange
                    font.family: Theme.textFont
                    font.pixelSize: 12
                    onLinkActivated: link => Qt.openUrlExternally(link)
                }
            }
        }

        Flow {
            width: parent.width
            visible: card.visibleActions.length > 0
            spacing: 6

            Repeater {
                model: card.visibleActions

                Rectangle {
                    id: actionButton
                    required property var modelData

                    width: actionLabel.implicitWidth + 20
                    height: 24
                    color: actionArea.containsMouse ? Theme.orange : "transparent"
                    border.width: 1
                    border.color: Theme.orange

                    Text {
                        id: actionLabel
                        anchors.centerIn: parent
                        text: actionButton.modelData.text.toUpperCase()
                        color: actionArea.containsMouse ? Theme.bg : Theme.orange
                        font.family: Theme.textFont
                        font.pixelSize: 11
                        font.letterSpacing: 1
                    }

                    MouseArea {
                        id: actionArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            actionButton.modelData.invoke();
                            card.activated();
                        }
                    }
                }
            }
        }
    }
}
