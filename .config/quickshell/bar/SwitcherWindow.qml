import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "Theme.js" as Theme

PanelWindow {
    id: window

    required property var switcher

    readonly property int cardWidth: 248
    readonly property int previewHeight: 150

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
    WlrLayershell.namespace: "qs-switcher"

    // Tab presses are caught by the Hyprland binds; this only sees the Alt release.
    Item {
        anchors.fill: parent
        focus: true
        Keys.onReleased: event => {
            if (event.key === Qt.Key_Alt || event.key === Qt.Key_Meta || !(event.modifiers & Qt.AltModifier))
                window.switcher.commit();
        }
        Keys.onEscapePressed: window.switcher.open = false
        Keys.onReturnPressed: window.switcher.commit()
        Keys.onLeftPressed: window.switcher.step(-1)
        Keys.onRightPressed: window.switcher.step(1)
    }

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: 0.35

        MouseArea {
            anchors.fill: parent
            onClicked: window.switcher.open = false
        }
    }

    Rectangle {
        anchors.centerIn: parent
        width: cards.width + 32
        height: cards.height + 32
        color: Theme.bg
        border.width: 1
        border.color: Theme.red

        Flow {
            id: cards
            x: 16
            y: 16
            width: Math.min(window.switcher.windows.length, Math.max(1, Math.floor((window.width - 160) / (window.cardWidth + 10)))) * (window.cardWidth + 10) - 10
            spacing: 10

            Repeater {
                model: window.switcher.windows

                Rectangle {
                    id: card
                    required property var modelData
                    required property int index
                    readonly property bool selected: index === window.switcher.index
                    readonly property string appClass: modelData.lastIpcObject?.class ?? modelData.wayland?.appId ?? ""

                    width: window.cardWidth
                    height: window.previewHeight + 44
                    color: selected ? Theme.raised : "transparent"
                    border.width: 1
                    border.color: selected ? Theme.orange : cardArea.containsMouse ? Theme.subtext : Theme.line

                    ScreencopyView {
                        id: preview
                        x: 6
                        y: 6
                        width: parent.width - 12
                        height: window.previewHeight
                        captureSource: card.modelData.wayland
                        live: false
                    }

                    Text {
                        anchors.centerIn: preview
                        visible: !preview.hasContent
                        text: "NO PREVIEW"
                        color: Theme.line
                        font.family: Theme.textFont
                        font.pixelSize: 11
                        font.letterSpacing: 2
                    }

                    IconImage {
                        id: appIcon
                        anchors {
                            left: parent.left
                            leftMargin: 8
                            bottom: parent.bottom
                            bottomMargin: 10
                        }
                        implicitSize: 18
                        source: Quickshell.iconPath(DesktopEntries.heuristicLookup(card.appClass)?.icon ?? card.appClass, "application-x-executable")
                    }

                    Text {
                        anchors {
                            left: appIcon.right
                            leftMargin: 8
                            right: workspace.left
                            rightMargin: 6
                            verticalCenter: appIcon.verticalCenter
                        }
                        text: card.modelData.title || card.appClass
                        elide: Text.ElideRight
                        color: card.selected ? Theme.orange : Theme.text
                        font.family: Theme.textFont
                        font.pixelSize: 12
                    }

                    Text {
                        id: workspace
                        anchors {
                            right: parent.right
                            rightMargin: 8
                            verticalCenter: appIcon.verticalCenter
                        }
                        text: card.modelData.workspace?.name ?? ""
                        color: Theme.dim
                        font.family: Theme.textFont
                        font.pixelSize: 11
                    }

                    MouseArea {
                        id: cardArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            window.switcher.index = card.index;
                            window.switcher.commit();
                        }
                    }
                }
            }
        }
    }
}
