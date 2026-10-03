import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import "Theme.js" as Theme

// Newest-first popups under the bar, top right. They leave the screen after their
// timeout (hover pauses it) but stay in the notification centre until dismissed.
PanelWindow {
    id: window

    required property var service

    visible: service.popups.length > 0
    anchors {
        top: true
        right: true
    }
    margins {
        top: 8
        right: 8
    }
    implicitWidth: 380
    implicitHeight: Math.max(1, column.implicitHeight)
    color: "transparent"
    exclusionMode: ExclusionMode.Normal
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-notifications"

    Column {
        id: column
        width: parent.width
        spacing: 8

        Repeater {
            model: window.service.popups

            NotificationCard {
                id: popup
                required property var modelData

                width: column.width
                notification: modelData
                service: window.service
                bodyLines: 4
                onActivated: window.service.removePopup(modelData)

                readonly property int timeout: {
                    if (critical) return 0;
                    const seconds = modelData.expireTimeout;
                    return seconds > 0 ? Math.min(seconds * 1000, 15000) : 6000;
                }

                Timer {
                    running: popup.timeout > 0 && !popupHover.hovered
                    interval: popup.timeout
                    onTriggered: {
                        if (popup.modelData.transient) popup.modelData.expire();
                        window.service.removePopup(popup.modelData);
                    }
                }

                HoverHandler { id: popupHover }

                Connections {
                    target: popup.modelData
                    function onClosed() { window.service.removePopup(popup.modelData); }
                }
            }
        }
    }
}
