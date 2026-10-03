import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "Theme.js" as Theme

PanelWindow {
    id: window

    required property var clipboard

    property int index: 0
    readonly property string query: search.text.trim().toLowerCase()
    readonly property var results: query === ""
        ? clipboard.entries
        : clipboard.entries.filter(e => e.preview.toLowerCase().includes(query))
    readonly property var selected: results[index] ?? null

    property string previewText: ""
    property string previewImage: ""

    onResultsChanged: index = Math.min(index, Math.max(0, results.length - 1))
    onSelectedChanged: {
        previewText = "";
        previewImage = "";
        previewDelay.restart();
    }

    function move(step) {
        if (results.length === 0) return;
        index = Math.max(0, Math.min(results.length - 1, index + step));
        list.positionViewAtIndex(index, ListView.Contain);
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
    WlrLayershell.namespace: "qs-clipboard"

    // Decoding is a process per entry, so wait until the selection settles.
    Timer {
        id: previewDelay
        interval: 60
        onTriggered: {
            const entry = window.selected;
            if (!entry) return;
            if (entry.image) {
                const path = window.clipboard.imageDir + "/" + entry.id + ".img";
                imageDecoder.path = path;
                imageDecoder.command = ["sh", "-c", 'mkdir -p "$(dirname "$2")" && [ -s "$2" ] || cliphist decode "$1" > "$2"', "_", entry.line, path];
                imageDecoder.running = true;
            } else {
                textDecoder.command = ["cliphist", "decode", entry.line];
                textDecoder.running = true;
            }
        }
    }

    Process {
        id: textDecoder
        stdout: StdioCollector {
            onStreamFinished: window.previewText = text.length > 6000 ? text.slice(0, 6000) + "\n…" : text
        }
    }

    Process {
        id: imageDecoder
        property string path: ""
        onExited: window.previewImage = "file://" + path
    }

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: 0.45

        MouseArea {
            anchors.fill: parent
            onClicked: window.clipboard.open = false
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

        MouseArea { anchors.fill: parent }

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
                    text: "SEARCH CLIPBOARD"
                    color: Theme.dim
                    font: search.font
                }

                Keys.onPressed: event => {
                    const ctrl = event.modifiers & Qt.ControlModifier;
                    const shift = event.modifiers & Qt.ShiftModifier;
                    if (event.key === Qt.Key_Escape) {
                        if (search.text !== "") search.text = "";
                        else window.clipboard.open = false;
                    } else if (event.key === Qt.Key_Down || (ctrl && event.key === Qt.Key_J)) {
                        window.move(1);
                    } else if (event.key === Qt.Key_Up || (ctrl && event.key === Qt.Key_K)) {
                        window.move(-1);
                    } else if (event.key === Qt.Key_PageDown) {
                        window.move(8);
                    } else if (event.key === Qt.Key_PageUp) {
                        window.move(-8);
                    } else if (event.key === Qt.Key_Delete && ctrl && shift) {
                        window.clipboard.wipe();
                    } else if (event.key === Qt.Key_Delete && shift) {
                        if (window.selected) window.clipboard.remove(window.selected);
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        if (window.selected) window.clipboard.copy(window.selected);
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
                text: "ENTER COPY   SHIFT+DEL REMOVE   ESC CLOSE"
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

        Text {
            id: listTitle
            anchors {
                top: headerDivider.bottom
                left: parent.left
                topMargin: 12
                leftMargin: 20
            }
            text: window.results.length + (window.query === "" ? " ENTRIES" : " RESULTS")
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
                left: parent.left
                topMargin: 8
                bottomMargin: 8
                leftMargin: 8
            }
            width: 420
            clip: true
            model: window.results
            currentIndex: window.index
            boundsBehavior: Flickable.StopAtBounds

            delegate: Item {
                id: row
                required property var modelData
                required property int index
                readonly property bool selected: index === window.index

                width: list.width
                height: 34

                Rectangle {
                    anchors.fill: parent
                    color: row.selected ? Theme.surface : "transparent"
                }

                Rectangle {
                    visible: row.selected
                    anchors {
                        left: parent.left
                        top: parent.top
                        bottom: parent.bottom
                    }
                    width: 3
                    color: Theme.orange
                }

                Text {
                    anchors {
                        left: parent.left
                        leftMargin: 16
                        right: parent.right
                        rightMargin: 12
                        verticalCenter: parent.verticalCenter
                    }
                    text: row.modelData.preview.replace(/\s+/g, " ")
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                    color: row.modelData.image ? Theme.magenta : row.selected ? Theme.orange : Theme.text
                    font.family: Theme.textFont
                    font.pixelSize: 13
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: window.index = row.index
                    onClicked: window.clipboard.copy(row.modelData)
                }
            }
        }

        Rectangle {
            id: previewDivider
            anchors {
                top: headerDivider.bottom
                bottom: parent.bottom
                left: list.right
                leftMargin: 8
            }
            width: 1
            color: Theme.red
            opacity: 0.35
        }

        Item {
            id: preview
            anchors {
                top: headerDivider.bottom
                bottom: parent.bottom
                left: previewDivider.right
                right: parent.right
                margins: 16
            }
            clip: true

            Image {
                anchors.fill: parent
                visible: window.selected?.image ?? false
                source: window.previewImage
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                smooth: false
            }

            Text {
                anchors.fill: parent
                visible: !(window.selected?.image ?? true)
                text: window.previewText
                textFormat: Text.PlainText
                wrapMode: Text.WrapAnywhere
                elide: Text.ElideRight
                color: Theme.subtext
                font.family: Theme.iconFont
                font.pixelSize: 12
            }
        }

        Text {
            anchors.centerIn: list
            visible: window.results.length === 0
            text: window.clipboard.entries.length === 0 ? "CLIPBOARD EMPTY" : "NOTHING FOUND"
            color: Theme.dim
            font.family: Theme.textFont
            font.pixelSize: 14
            font.letterSpacing: 2
        }
    }
}
