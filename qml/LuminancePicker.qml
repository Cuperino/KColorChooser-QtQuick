/*
    SPDX-FileCopyrightText: 2026 Javier O. Cordero Pérez <javiercorderoperez@gmail.com>
    SPDX-License-Identifier: MIT
*/

import QtQuick
import QtQuick.Shapes
import org.kde.kirigami as Kirigami

// QColorLuminancePicker: a value strip with an arrow on its right, brightest at the top.
Item {
    id: root

    property real hue: 0
    property real saturation: 0
    property real value: 0

    // QColorLuminancePicker's foff and coff: the frame is inset foff from the
    // top and bottom, and values map onto the height less coff on each side.
    readonly property int frameOffset: 3
    readonly property int contentsOffset: 4
    // Integer arithmetic, as QColorLuminancePicker::val2y().
    readonly property int valueY: contentsOffset + Math.floor((255 - Math.round(value * 255)) * (height - 2 * contentsOffset - 1) / 255)

    signal moved(real value)

    function moveTo(newValue: real): void {
        moved(Math.min(Math.max(newValue, 0), 1));
    }

    implicitWidth: 20
    implicitHeight: Kirigami.Units.gridUnit * 10
    activeFocusOnTab: true
    Accessible.role: Accessible.Slider
    Accessible.description: Math.round(value * 255).toString()

    Keys.onPressed: event => {
        const step = event.key === Qt.Key_PageUp || event.key === Qt.Key_PageDown ? 0.1 : 1 / 255;
        switch (event.key) {
        case Qt.Key_Up:
        case Qt.Key_PageUp:
            moveTo(value + step);
            break;
        case Qt.Key_Down:
        case Qt.Key_PageDown:
            moveTo(value - step);
            break;
        case Qt.Key_Home:
            moveTo(1);
            break;
        case Qt.Key_End:
            moveTo(0);
            break;
        default:
            return;
        }
        event.accepted = true;
    }

    Rectangle {
        y: root.frameOffset
        width: root.width - 5
        height: root.height - 2 * root.frameOffset
        color: "transparent"
        border.width: 1
        border.color: root.activeFocus
                      ? Kirigami.Theme.highlightColor
                      : Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.3)

        Rectangle {
            anchors.fill: parent
            anchors.margins: parent.border.width
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.hsva(root.hue, root.saturation, 1, 1) }
                GradientStop { position: 1; color: "black" }
            }
        }
    }

    Shape {
        x: root.width - 5
        y: root.valueY - 5
        width: 5
        height: 11

        // Centered on the pixel row, to cover the same pixels as QPainter's
        // aliased polygon.
        ShapePath {
            strokeWidth: -1
            fillColor: Kirigami.Theme.textColor
            startX: 0
            startY: 5.5
            PathLine { x: 5; y: 10.5 }
            PathLine { x: 5; y: 0.5 }
            PathLine { x: 0; y: 5.5 }
        }
    }

    MouseArea {
        anchors.fill: parent
        preventStealing: true

        function update(mouse: var): void {
            root.forceActiveFocus(Qt.MouseFocusReason);
            root.moveTo(1 - (mouse.y - root.contentsOffset) / (height - 2 * root.contentsOffset - 1));
        }

        onPressed: mouse => update(mouse)
        onPositionChanged: mouse => update(mouse)
    }
}
