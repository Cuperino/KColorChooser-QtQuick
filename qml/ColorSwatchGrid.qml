/*
    SPDX-FileCopyrightText: 2026 Javier O. Cordero Pérez <javiercorderoperez@gmail.com>
    SPDX-License-Identifier: MIT
*/

pragma ComponentBehavior: Bound

import QtQuick
import org.kde.kirigami as Kirigami

// QWellArray: one focus stop whose current cell moves with the arrow keys and
// is chosen with Space or a click. Colors fill the grid column by column.
Item {
    id: root

    property var colors: []
    property int rows: 1
    // The cell marked while the grid has focus.
    property int currentIndex: 0

    readonly property int columnCount: Math.ceil(colors.length / rows)
    readonly property int cellWidth: 28
    readonly property int cellHeight: 24

    signal activated(int index, color swatchColor)

    function activate(index: int): void {
        activated(index, colors[index]);
    }

    function indexAt(x: real, y: real): int {
        const row = Math.floor(y / cellHeight);
        const column = Math.floor(x / cellWidth);
        if (row < 0 || column < 0 || row >= rows || column >= columnCount) {
            return -1;
        }
        return row + column * rows;
    }

    implicitWidth: grid.implicitWidth
    implicitHeight: grid.implicitHeight
    activeFocusOnTab: true
    Accessible.role: Accessible.Table

    Keys.onPressed: event => {
        const row = currentIndex % rows;
        const column = Math.floor(currentIndex / rows);
        switch (event.key) {
        case Qt.Key_Left:
            if (column > 0) {
                currentIndex -= rows;
            }
            break;
        case Qt.Key_Right:
            if (column < columnCount - 1) {
                currentIndex += rows;
            }
            break;
        case Qt.Key_Up:
            if (row > 0) {
                --currentIndex;
            }
            break;
        case Qt.Key_Down:
            if (row < rows - 1) {
                ++currentIndex;
            }
            break;
        case Qt.Key_Space:
            activate(currentIndex);
            break;
        default:
            return;
        }
        event.accepted = true;
    }

    Grid {
        id: grid

        rows: root.rows
        flow: Grid.TopToBottom

        Repeater {
            model: root.colors

            Item {
                id: swatch

                required property int index
                required property color modelData

                readonly property bool current: index === root.currentIndex

                implicitWidth: root.cellWidth
                implicitHeight: root.cellHeight
                Accessible.name: swatch.modelData.toString()
                Accessible.role: Accessible.Cell
                Accessible.focusable: true
                Accessible.focused: swatch.current && root.activeFocus

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 3
                    color: swatch.modelData
                }

                // Breeze's focus frame, which QWellArray draws on its current cell.
                Rectangle {
                    y: parent.height - 1
                    width: parent.width
                    height: 1
                    color: Kirigami.Theme.highlightColor
                    visible: swatch.current && root.activeFocus
                }
            }
        }
    }

    // The press moves the current cell, the release chooses it.
    MouseArea {
        anchors.fill: parent
        onPressed: mouse => {
            root.currentIndex = root.indexAt(mouse.x, mouse.y);
            root.forceActiveFocus(Qt.MouseFocusReason);
        }
        onReleased: root.activate(root.currentIndex)
    }
}
