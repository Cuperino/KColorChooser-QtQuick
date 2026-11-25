/*
    SPDX-FileCopyrightText: 2026 Javier O. Cordero Pérez <javiercorderoperez@gmail.com>
    SPDX-License-Identifier: MIT
*/

pragma ComponentBehavior: Bound

import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.kcolorchooser

// QColorWell: one focus stop whose current cell moves with the arrow keys and
// is chosen with Space or a click. Colors fill the grid column by column, and
// each can be dragged out as application/x-color.
Item {
    id: root

    property var colors: []
    property int rows: 1
    // The cell marked while the grid has focus, or -1 for none.
    property int currentIndex: 0
    // The cell last chosen, or -1 for none.
    property int selectedIndex: -1

    readonly property int columnCount: Math.ceil(colors.length / rows)
    readonly property int cellWidth: 28
    readonly property int cellHeight: 24

    signal activated(int index, color swatchColor)

    // As QWellArray::setSelected(): choosing no cell only clears the selection.
    function select(index: int): void {
        selectedIndex = index;
        if (index >= 0) {
            activated(index, colors[index]);
        }
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
        // With no current cell, QWellArray's arrows find no cell to move to.
        const row = currentIndex >= 0 ? currentIndex % rows : -1;
        const column = currentIndex >= 0 ? Math.floor(currentIndex / rows) : -1;
        switch (event.key) {
        case Qt.Key_Left:
            if (column > 0) {
                currentIndex -= rows;
            }
            break;
        case Qt.Key_Right:
            if (row >= 0 && column < columnCount - 1) {
                currentIndex += rows;
            }
            break;
        case Qt.Key_Up:
            if (row > 0) {
                --currentIndex;
            }
            break;
        case Qt.Key_Down:
            if (row >= 0 && row < rows - 1) {
                ++currentIndex;
            }
            break;
        case Qt.Key_Space:
            select(currentIndex);
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

    // The press moves the current cell, the release chooses it, and moving
    // past the drag distance first drags the pressed cell's color instead.
    MouseArea {
        id: mouseArea

        // Whether the press can still end in a click or start a drag.
        property bool pressPending: false
        property point pressPosition
        // QColorWell restores the selected cell, not the current one, on a drag.
        property int indexBeforePress: -1

        anchors.fill: parent

        onPressed: mouse => {
            indexBeforePress = root.selectedIndex;
            root.forceActiveFocus(Qt.MouseFocusReason);
            root.currentIndex = root.indexAt(mouse.x, mouse.y);
            pressPending = true;
            pressPosition = Qt.point(mouse.x, mouse.y);
        }
        onPositionChanged: mouse => {
            if (!pressPending) {
                return;
            }
            if (Math.abs(mouse.x - pressPosition.x) + Math.abs(mouse.y - pressPosition.y) <= Qt.styleHints.startDragDistance) {
                return;
            }
            pressPending = false;
            root.currentIndex = indexBeforePress;
            const index = root.indexAt(pressPosition.x, pressPosition.y);
            if (index >= 0) {
                ColorChooserHelper.dragColor(mouseArea, root.colors[index], root.cellWidth, root.cellHeight);
            }
        }
        onReleased: {
            if (!pressPending) {
                return;
            }
            pressPending = false;
            root.select(root.currentIndex);
        }
        onCanceled: pressPending = false
    }
}
