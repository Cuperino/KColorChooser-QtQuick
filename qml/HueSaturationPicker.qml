/*
    SPDX-FileCopyrightText: 2026 Javier O. Cordero Pérez <javiercorderoperez@gmail.com>
    SPDX-License-Identifier: MIT
*/

import QtQuick
import org.kde.kirigami as Kirigami

Item {
    id: root

    property real hue: 0
    property real saturation: 0

    signal moved(real hue, real saturation)

    function moveTo(newHue: real, newSaturation: real): void {
        moved(Math.min(Math.max(newHue, 0), 1), Math.min(Math.max(newSaturation, 0), 1));
    }

    implicitWidth: 222
    implicitHeight: 202
    clip: true
    activeFocusOnTab: true
    Accessible.role: Accessible.Graphic

    Keys.onPressed: event => {
        const step = event.modifiers & Qt.ShiftModifier ? 0.1 : 1 / 255;
        switch (event.key) {
        case Qt.Key_Left:
            moveTo(hue + step, saturation);
            break;
        case Qt.Key_Right:
            moveTo(hue - step, saturation);
            break;
        case Qt.Key_Up:
            moveTo(hue, saturation + step);
            break;
        case Qt.Key_Down:
            moveTo(hue, saturation - step);
            break;
        default:
            return;
        }
        event.accepted = true;
    }

    // The field is drawn at a fixed value of 200.
    readonly property real fieldValue: 200 / 255
    // As QColorPicker: a pWidth × pHeight image inside a 1 px frame.
    readonly property int frameWidth: 1
    readonly property int pWidth: width - 2 * frameWidth
    readonly property int pHeight: height - 2 * frameWidth

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.width: root.frameWidth
        border.color: root.activeFocus
                      ? Kirigami.Theme.highlightColor
                      : Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.3)
    }

    Rectangle {
        x: root.frameWidth
        y: root.frameWidth
        width: root.pWidth
        height: root.pHeight
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0 / 6; color: Qt.hsva(0 / 6, 1, root.fieldValue, 1) }
            GradientStop { position: 1 / 6; color: Qt.hsva(5 / 6, 1, root.fieldValue, 1) }
            GradientStop { position: 2 / 6; color: Qt.hsva(4 / 6, 1, root.fieldValue, 1) }
            GradientStop { position: 3 / 6; color: Qt.hsva(3 / 6, 1, root.fieldValue, 1) }
            GradientStop { position: 4 / 6; color: Qt.hsva(2 / 6, 1, root.fieldValue, 1) }
            GradientStop { position: 5 / 6; color: Qt.hsva(1 / 6, 1, root.fieldValue, 1) }
            GradientStop { position: 6 / 6; color: Qt.hsva(0 / 6, 1, root.fieldValue, 1) }
        }

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.rgba(root.fieldValue, root.fieldValue, root.fieldValue, 0) }
                GradientStop { position: 1; color: Qt.rgba(root.fieldValue, root.fieldValue, root.fieldValue, 1) }
            }
        }
    }

    // Crosshair, two 20×2 black bars, placed with QColorPicker::colPt()'s
    // integer arithmetic.
    Item {
        x: root.frameWidth + Math.floor((360 - Math.round(root.hue * 360)) * (root.pWidth - 1) / 360)
        y: root.frameWidth + Math.floor((255 - Math.round(root.saturation * 255)) * (root.pHeight - 1) / 255)

        Rectangle {
            x: -9
            width: 20
            height: 2
            color: "black"
        }

        Rectangle {
            y: -9
            width: 2
            height: 20
            color: "black"
        }
    }

    MouseArea {
        anchors.fill: parent
        preventStealing: true

        function update(mouse: var): void {
            root.forceActiveFocus(Qt.MouseFocusReason);
            root.moveTo(1 - (mouse.x - root.frameWidth) / (root.pWidth - 1), 1 - (mouse.y - root.frameWidth) / (root.pHeight - 1));
        }

        onPressed: mouse => update(mouse)
        onPositionChanged: mouse => update(mouse)
    }
}
