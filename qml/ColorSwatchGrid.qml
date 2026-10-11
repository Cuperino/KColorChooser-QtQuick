/*
    SPDX-FileCopyrightText: 2026 Javier O. Cordero Pérez <javiercorderoperez@gmail.com>
    SPDX-License-Identifier: MIT
*/

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Templates as T
import org.kde.kirigami as Kirigami

// Colors fill the grid column by column
Grid {
    id: root

    property var colors: []
    property int currentIndex: -1

    signal activated(int index, color swatchColor)

    function focusSwatch(index: int): void {
        swatchRepeater.itemAt(Math.max(index, 0))?.forceActiveFocus(Qt.ShortcutFocusReason);
    }

    flow: Grid.TopToBottom

    Repeater {
        id: swatchRepeater

        model: root.colors

        T.AbstractButton {
            id: swatch

            required property int index
            required property color modelData

            implicitWidth: 28
            implicitHeight: 24
            activeFocusOnTab: true
            checked: swatch.index === root.currentIndex
            Accessible.name: swatch.modelData.toString()
            Accessible.role: Accessible.Button
            onClicked: root.activated(swatch.index, swatch.modelData)

            background: Item {
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 3
                    color: swatch.modelData
                }

                Rectangle {
                    x: 0
                    y: parent.height - 2
                    width: parent.width - 1
                    height: 1
                    color: Kirigami.Theme.highlightColor
                    visible: swatch.checked || swatch.visualFocus
                }
            }
        }
    }
}
