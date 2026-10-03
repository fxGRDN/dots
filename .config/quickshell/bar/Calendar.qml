import QtQuick
import Quickshell
import "Theme.js" as Theme

// Month view, Monday first, with ISO week numbers. Scroll or arrows change month.
PopupWindow {
    id: popup

    required property var now
    property var month: new Date()

    readonly property var weekdays: ["MO", "TU", "WE", "TH", "FR", "SA", "SU"]

    // 6 rows x 7 days, starting on the Monday on or before the 1st.
    readonly property var days: {
        const first = new Date(month.getFullYear(), month.getMonth(), 1);
        const offset = (first.getDay() + 6) % 7;
        const result = [];
        for (let i = 0; i < 42; i++)
            result.push(new Date(first.getFullYear(), first.getMonth(), 1 - offset + i));
        return result;
    }

    function isoWeek(date) {
        const d = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
        d.setUTCDate(d.getUTCDate() + 4 - (d.getUTCDay() || 7));
        const yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
        return Math.ceil(((d - yearStart) / 86400000 + 1) / 7);
    }

    function sameDay(a, b) {
        return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
    }

    function shift(months) {
        month = new Date(month.getFullYear(), month.getMonth() + months, 1);
    }

    implicitWidth: panel.implicitWidth
    implicitHeight: panel.implicitHeight
    color: "transparent"

    Rectangle {
        id: panel
        implicitWidth: body.implicitWidth + 36
        implicitHeight: body.implicitHeight + 32
        color: Qt.rgba(0.047, 0.031, 0.031, 0.94)
        border.width: 1
        border.color: Theme.red

        focus: true
        Keys.onLeftPressed: popup.shift(-1)
        Keys.onRightPressed: popup.shift(1)
        Keys.onEscapePressed: popup.visible = false

        WheelHandler {
            onWheel: event => popup.shift(event.angleDelta.y > 0 ? -1 : 1)
        }

        Column {
            id: body
            x: 18
            y: 16
            spacing: 14

            Column {
                spacing: 4

                Text {
                    text: Qt.formatTime(popup.now, "hh:mm AP")
                    color: Theme.orange
                    font.family: Theme.textFont
                    font.pixelSize: 34
                }

                Text {
                    text: Qt.formatDate(popup.now, "dddd, d MMMM yyyy").toUpperCase()
                    color: Theme.subtext
                    font.family: Theme.textFont
                    font.pixelSize: 11
                    font.letterSpacing: 1.5
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.red
                opacity: 0.5
            }

            Item {
                width: grid.width
                height: 18

                NavButton {
                    anchors.left: parent.left
                    text: "<"
                    onClicked: popup.shift(-1)
                }

                Text {
                    anchors.centerIn: parent
                    text: Qt.formatDate(popup.month, "MMMM yyyy").toUpperCase()
                    color: monthArea.containsMouse ? Theme.orange : Theme.purple
                    font.family: Theme.textFont
                    font.pixelSize: 12
                    font.letterSpacing: 2

                    MouseArea {
                        id: monthArea
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: popup.month = new Date(popup.now.getFullYear(), popup.now.getMonth(), 1)
                    }
                }

                NavButton {
                    anchors.right: parent.right
                    text: ">"
                    onClicked: popup.shift(1)
                }
            }

            Grid {
                id: grid
                columns: 8
                columnSpacing: 2
                rowSpacing: 2

                Cell { text: "" }

                Repeater {
                    model: popup.weekdays

                    Cell {
                        required property string modelData
                        required property int index
                        text: modelData
                        color: index >= 5 ? Theme.subtext : Theme.dim
                        font.pixelSize: 10
                    }
                }

                // 6 rows of [week number, 7 days].
                Repeater {
                    model: 48

                    Item {
                        id: slot
                        required property int index
                        readonly property bool isWeek: index % 8 === 0
                        readonly property var day: popup.days[Math.floor(index / 8) * 7 + Math.max(0, index % 8 - 1)]

                        width: 32
                        height: 26

                        Cell {
                            visible: slot.isWeek
                            text: popup.isoWeek(slot.day)
                            color: Theme.dim
                            font.pixelSize: 10
                        }

                        DayCell {
                            visible: !slot.isWeek
                            date: slot.day
                        }
                    }
                }
            }
        }
    }

    component Cell: Text {
        width: 32
        height: 26
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        color: Theme.text
        font.family: Theme.textFont
        font.pixelSize: 13
    }

    component DayCell: Rectangle {
        id: cell
        required property var date
        readonly property bool today: popup.sameDay(date, popup.now)
        readonly property bool inMonth: date.getMonth() === popup.month.getMonth()
        readonly property bool weekend: date.getDay() === 0 || date.getDay() === 6

        width: 32
        height: 26
        color: today ? Theme.orange : "transparent"
        border.width: today ? 0 : 1
        border.color: cellHover.hovered && inMonth ? Theme.line : "transparent"

        HoverHandler { id: cellHover }

        Text {
            anchors.centerIn: parent
            text: cell.date.getDate()
            color: cell.today ? Theme.bg : !cell.inMonth ? Theme.line : cell.weekend ? Theme.subtext : Theme.text
            font.family: Theme.textFont
            font.pixelSize: 13
        }
    }

    component NavButton: Text {
        id: nav
        signal clicked()

        color: navArea.containsMouse ? Theme.orange : Theme.dim
        font.family: Theme.textFont
        font.pixelSize: 14

        MouseArea {
            id: navArea
            anchors.fill: parent
            anchors.margins: -6
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: nav.clicked()
        }
    }
}
