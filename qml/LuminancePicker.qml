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

    readonly property int contentsOffset: 1
    readonly property real valueY: contentsOffset + (1 - value) * (height - 2 * contentsOffset)

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
        width: root.width - 5
        height: root.height
        border.width: 1
        border.color: root.activeFocus
                      ? Kirigami.Theme.highlightColor
                      : Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.3)
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.hsva(root.hue, root.saturation, 1, 1) }
            GradientStop { position: 1; color: "black" }
        }
    }

    Shape {
        x: root.width - 5
        y: root.valueY - 5
        width: 5
        height: 10
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: -1
            fillColor: Kirigami.Theme.textColor
            startX: 0
            startY: 5
            PathLine { x: 5; y: 10 }
            PathLine { x: 5; y: 0 }
            PathLine { x: 0; y: 5 }
        }
    }

    MouseArea {
        anchors.fill: parent
        preventStealing: true

        function update(mouse: var): void {
            root.forceActiveFocus(Qt.MouseFocusReason);
            root.moveTo(1 - (mouse.y - root.contentsOffset) / (height - 2 * root.contentsOffset));
        }

        onPressed: mouse => update(mouse)
        onPositionChanged: mouse => update(mouse)
    }
}
