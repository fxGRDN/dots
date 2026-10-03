import QtQuick
import Quickshell
import Quickshell.Wayland

// Quickshell (0.3.1) bug workaround: with QT_QUICK_BACKEND=software, screen capture only
// falls back to SHM buffers if the first capture happens before any other window maps.
// Otherwise every ScreencopyView (the Alt-Tab previews) stays empty. Capture one frame from
// a 1px window at startup, then hide it. Must be the first item in shell.qml, and must not
// be lazy-loaded (that maps it after the bar).
PanelWindow {
    id: window

    anchors.top: true
    implicitWidth: 1
    implicitHeight: 1
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    mask: Region {}

    ScreencopyView {
        anchors.fill: parent
        captureSource: window.screen
        live: false
        onHasContentChanged: if (hasContent) window.visible = false
    }
}
