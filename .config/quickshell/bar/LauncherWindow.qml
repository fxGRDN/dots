import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "Apps.js" as Apps
import "Theme.js" as Theme

PanelWindow {
    id: window

    required property var launcher

    property int sectionIndex: 0
    property int appIndex: 0
    readonly property string query: search.text.trim()
    readonly property bool searching: query !== ""

    readonly property var results: {
        if (searching) {
            return launcher.apps
                .map(entry => ({ entry: entry, score: Apps.score(query, entry, launcher.usage) }))
                .filter(r => r.score >= 0)
                .sort((a, b) => b.score - a.score)
                .map(r => r.entry);
        }
        return launcher.sections[sectionIndex]?.apps ?? [];
    }

    onResultsChanged: appIndex = 0

    function cycleSection(step) {
        search.text = "";
        const count = launcher.sections.length;
        sectionIndex = (sectionIndex + step + count) % count;
    }

    function moveSelection(step) {
        if (results.length === 0) return;
        appIndex = Math.max(0, Math.min(results.length - 1, appIndex + step));
        list.positionViewAtIndex(appIndex, ListView.Contain);
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
    WlrLayershell.namespace: "qs-launcher"

    // Dim backdrop; click outside the panel to close.
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: 0.45

        MouseArea {
            anchors.fill: parent
            onClicked: window.launcher.open = false
        }
    }

    Rectangle {
        id: panel
        width: 860
        height: 500
        anchors.centerIn: parent
        color: Theme.bg
        border.width: 1
        border.color: Theme.red

        // Swallow clicks so they don't reach the backdrop.
        MouseArea { anchors.fill: parent }

        // Search row
        Item {
            id: header
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
            height: 54

            Text {
                id: prompt
                anchors {
                    left: parent.left
                    leftMargin: 18
                    verticalCenter: parent.verticalCenter
                }
                text: ">"
                color: Theme.orange
                font.family: Theme.textFont
                font.pixelSize: 20
            }

            TextInput {
                id: search
                anchors {
                    left: prompt.right
                    leftMargin: 12
                    right: hints.left
                    rightMargin: 12
                    verticalCenter: parent.verticalCenter
                }
                focus: true
                color: Theme.text
                selectionColor: Theme.orange
                selectedTextColor: Theme.bg
                font.family: Theme.textFont
                font.pixelSize: 18
                cursorDelegate: Rectangle {
                    width: 9
                    color: Theme.orange
                    visible: search.cursorVisible
                }

                Text {
                    x: 14
                    anchors.verticalCenter: parent.verticalCenter
                    visible: search.text === ""
                    text: "SEARCH APPS"
                    color: Theme.dim
                    font: search.font
                }

                Keys.onPressed: event => {
                    const ctrl = event.modifiers & Qt.ControlModifier;
                    if (event.key === Qt.Key_Escape) {
                        if (search.text !== "") search.text = "";
                        else window.launcher.open = false;
                    } else if (event.key === Qt.Key_Down || (ctrl && event.key === Qt.Key_J)) {
                        window.moveSelection(1);
                    } else if (event.key === Qt.Key_Up || (ctrl && event.key === Qt.Key_K)) {
                        window.moveSelection(-1);
                    } else if (event.key === Qt.Key_PageDown) {
                        window.moveSelection(8);
                    } else if (event.key === Qt.Key_PageUp) {
                        window.moveSelection(-8);
                    } else if (event.key === Qt.Key_Tab) {
                        window.cycleSection(1);
                    } else if (event.key === Qt.Key_Backtab) {
                        window.cycleSection(-1);
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        const entry = window.results[window.appIndex];
                        if (entry) window.launcher.launch(entry);
                    } else {
                        return;
                    }
                    event.accepted = true;
                }
            }

            Text {
                id: hints
                anchors {
                    right: parent.right
                    rightMargin: 18
                    verticalCenter: parent.verticalCenter
                }
                text: "TAB GROUP   ENTER LAUNCH   ESC CLOSE"
                color: Theme.dim
                font.family: Theme.textFont
                font.pixelSize: 11
                font.letterSpacing: 1
            }
        }

        Rectangle {
            id: headerDivider
            anchors {
                top: header.bottom
                left: parent.left
                right: parent.right
            }
            height: 1
            color: Theme.red
            opacity: 0.6
        }

        // Sidebar
        ListView {
            id: sidebar
            anchors {
                top: headerDivider.bottom
                bottom: parent.bottom
                left: parent.left
                topMargin: 8
                bottomMargin: 8
            }
            width: 190
            clip: true
            interactive: contentHeight > height
            model: window.launcher.sections
            currentIndex: window.sectionIndex
            opacity: window.searching ? 0.45 : 1
            Behavior on opacity { NumberAnimation { duration: 120 } }

            delegate: Item {
                id: sectionRow
                required property var modelData
                required property int index
                readonly property bool selected: index === window.sectionIndex && !window.searching

                width: sidebar.width
                height: 32

                Rectangle {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    color: sectionRow.selected ? Theme.surface : "transparent"
                }

                Rectangle {
                    visible: sectionRow.selected
                    anchors {
                        left: parent.left
                        leftMargin: 8
                        top: parent.top
                        bottom: parent.bottom
                    }
                    width: 3
                    color: Theme.orange
                }

                Text {
                    anchors {
                        left: parent.left
                        leftMargin: 22
                        verticalCenter: parent.verticalCenter
                    }
                    text: sectionRow.modelData.name
                    color: sectionRow.selected ? Theme.orange : sectionHover.containsMouse ? Theme.text : Theme.subtext
                    font.family: Theme.textFont
                    font.pixelSize: 14
                    font.letterSpacing: 1
                }

                Text {
                    anchors {
                        right: parent.right
                        rightMargin: 18
                        verticalCenter: parent.verticalCenter
                    }
                    text: sectionRow.modelData.apps.length
                    color: Theme.dim
                    font.family: Theme.textFont
                    font.pixelSize: 12
                }

                MouseArea {
                    id: sectionHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        search.text = "";
                        window.sectionIndex = sectionRow.index;
                        search.forceActiveFocus();
                    }
                }
            }
        }

        Rectangle {
            id: sidebarDivider
            anchors {
                top: headerDivider.bottom
                bottom: parent.bottom
                left: sidebar.right
            }
            width: 1
            color: Theme.red
            opacity: 0.35
        }

        // App list
        Text {
            id: listTitle
            anchors {
                top: headerDivider.bottom
                left: sidebarDivider.right
                topMargin: 12
                leftMargin: 20
            }
            text: window.searching
                ? window.results.length + " RESULTS"
                : (window.launcher.sections[window.sectionIndex]?.name ?? "")
            color: Theme.purple
            font.family: Theme.textFont
            font.pixelSize: 12
            font.letterSpacing: 2
        }

        ListView {
            id: list
            anchors {
                top: listTitle.bottom
                bottom: parent.bottom
                left: sidebarDivider.right
                right: parent.right
                topMargin: 8
                bottomMargin: 8
                leftMargin: 8
                rightMargin: 8
            }
            clip: true
            model: window.results
            currentIndex: window.appIndex
            boundsBehavior: Flickable.StopAtBounds

            delegate: Item {
                id: appRow
                required property var modelData
                required property int index
                readonly property bool selected: index === window.appIndex

                width: list.width
                height: 42

                Rectangle {
                    anchors.fill: parent
                    color: appRow.selected ? Theme.surface : "transparent"
                }

                Rectangle {
                    visible: appRow.selected
                    anchors {
                        left: parent.left
                        top: parent.top
                        bottom: parent.bottom
                    }
                    width: 3
                    color: Theme.orange
                }

                IconImage {
                    id: appIcon
                    anchors {
                        left: parent.left
                        leftMargin: 16
                        verticalCenter: parent.verticalCenter
                    }
                    implicitSize: 26
                    source: Quickshell.iconPath(appRow.modelData.icon, "application-x-executable")
                }

                Text {
                    id: appName
                    anchors {
                        left: appIcon.right
                        leftMargin: 14
                        verticalCenter: parent.verticalCenter
                    }
                    text: appRow.modelData.name
                    color: appRow.selected ? Theme.orange : Theme.text
                    font.family: Theme.textFont
                    font.pixelSize: 15
                }

                Text {
                    anchors {
                        left: appName.right
                        leftMargin: 12
                        right: parent.right
                        rightMargin: 16
                        verticalCenter: parent.verticalCenter
                    }
                    text: appRow.modelData.genericName || appRow.modelData.comment || ""
                    elide: Text.ElideRight
                    color: Theme.dim
                    font.family: Theme.textFont
                    font.pixelSize: 12
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: window.appIndex = appRow.index
                    onClicked: window.launcher.launch(appRow.modelData)
                }
            }
        }

        Text {
            anchors.centerIn: list
            visible: window.results.length === 0
            text: "NOTHING FOUND"
            color: Theme.dim
            font.family: Theme.textFont
            font.pixelSize: 14
            font.letterSpacing: 2
        }
    }
}
