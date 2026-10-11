/*
    SPDX-FileCopyrightText: 2026 Javier O. Cordero Pérez <javiercorderoperez@gmail.com>
    SPDX-License-Identifier: MIT
*/

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

RowLayout {
    id: root

    property real hue: 0
    property real saturation: 0
    property real value: 0
    property real alpha: 1
    property color color

    readonly property string valueLabelText: valLabel.Kirigami.MnemonicData.plainTextLabel

    readonly property int red: Math.round(color.r * 255)
    readonly property int green: Math.round(color.g * 255)
    readonly property int blue: Math.round(color.b * 255)

    signal hsvaEdited(real hue, real saturation, real value, real alpha)
    signal colorEdited(color editedColor)

    spacing: Kirigami.Units.largeSpacing

    Rectangle {
        Layout.fillHeight: true
        Layout.preferredWidth: 60
        border.color: Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.3)
        color: Qt.rgba(root.color.r, root.color.g, root.color.b, 1)
        Accessible.ignored: true
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 4
        columnSpacing: 6
        rowSpacing: 6

        FieldLabel {
            id: hueLabel

            Layout.alignment: Qt.AlignRight
            label: i18n("Hu&e:")
            buddy: hueField
        }
        QQC2.SpinBox {
            id: hueField

            Layout.preferredWidth: 60
            from: 0
            to: 359
            editable: true
            value: Math.round(root.hue * 360) % 360
            onValueModified: root.hsvaEdited(value / 360, root.saturation, root.value, root.alpha)
            Accessible.name: hueLabel.Kirigami.MnemonicData.plainTextLabel
        }

        FieldLabel {
            id: redLabel

            Layout.alignment: Qt.AlignRight
            label: i18n("&Red:")
            buddy: redField
        }
        QQC2.SpinBox {
            id: redField

            Layout.preferredWidth: 60
            from: 0
            to: 255
            editable: true
            value: root.red
            onValueModified: root.colorEdited(Qt.rgba(value / 255, root.green / 255, root.blue / 255, root.alpha))
            Accessible.name: redLabel.Kirigami.MnemonicData.plainTextLabel
        }

        FieldLabel {
            id: satLabel

            Layout.alignment: Qt.AlignRight
            label: i18n("&Sat:")
            buddy: satField
        }
        QQC2.SpinBox {
            id: satField

            Layout.preferredWidth: 60
            from: 0
            to: 255
            editable: true
            value: Math.round(root.saturation * 255)
            onValueModified: root.hsvaEdited(root.hue, value / 255, root.value, root.alpha)
            Accessible.name: satLabel.Kirigami.MnemonicData.plainTextLabel
        }

        FieldLabel {
            id: greenLabel

            Layout.alignment: Qt.AlignRight
            label: i18n("&Green:")
            buddy: greenField
        }
        QQC2.SpinBox {
            id: greenField

            Layout.preferredWidth: 60
            from: 0
            to: 255
            editable: true
            value: root.green
            onValueModified: root.colorEdited(Qt.rgba(root.red / 255, value / 255, root.blue / 255, root.alpha))
            Accessible.name: greenLabel.Kirigami.MnemonicData.plainTextLabel
        }

        FieldLabel {
            id: valLabel

            Layout.alignment: Qt.AlignRight
            label: i18n("&Val:")
            buddy: valField
        }
        QQC2.SpinBox {
            id: valField

            Layout.preferredWidth: 60
            from: 0
            to: 255
            editable: true
            value: Math.round(root.value * 255)
            onValueModified: root.hsvaEdited(root.hue, root.saturation, value / 255, root.alpha)
            Accessible.name: valLabel.Kirigami.MnemonicData.plainTextLabel
        }

        FieldLabel {
            id: blueLabel

            Layout.alignment: Qt.AlignRight
            label: i18n("Bl&ue:")
            buddy: blueField
        }
        QQC2.SpinBox {
            id: blueField

            Layout.preferredWidth: 60
            from: 0
            to: 255
            editable: true
            value: root.blue
            onValueModified: root.colorEdited(Qt.rgba(root.red / 255, root.green / 255, value / 255, root.alpha))
            Accessible.name: blueLabel.Kirigami.MnemonicData.plainTextLabel
        }

        FieldLabel {
            id: alphaLabel

            Layout.alignment: Qt.AlignRight
            Layout.columnSpan: 3
            label: i18n("A&lpha channel:")
            buddy: alphaField
        }
        QQC2.SpinBox {
            id: alphaField

            Layout.preferredWidth: 60
            from: 0
            to: 255
            editable: true
            value: Math.round(root.alpha * 255)
            onValueModified: root.hsvaEdited(root.hue, root.saturation, root.value, value / 255)
            Accessible.name: alphaLabel.Kirigami.MnemonicData.plainTextLabel
        }

        FieldLabel {
            id: htmlLabel

            Layout.topMargin: Kirigami.Units.smallSpacing
            Layout.alignment: Qt.AlignRight
            label: i18n("&HTML:")
            buddy: htmlField
        }
        QQC2.TextField {
            id: htmlField

            Layout.topMargin: Kirigami.Units.smallSpacing
            Layout.columnSpan: 3
            Layout.preferredWidth: Kirigami.Units.gridUnit * 7.5
            text: "#" + [root.red, root.green, root.blue].map(component => component.toString(16).padStart(2, "0")).join("")
            validator: RegularExpressionValidator {
                regularExpression: /#?([0-9a-fA-F]{6}|[0-9a-fA-F]{8})/
            }
            onEditingFinished: {
                if (!acceptableInput) {
                    return;
                }
                const hex = text.startsWith("#") ? text : "#" + text;
                const parsed = Qt.color(hex);
                root.colorEdited(hex.length === 7 ? Qt.rgba(parsed.r, parsed.g, parsed.b, root.alpha) : parsed);
            }
            Accessible.name: htmlLabel.Kirigami.MnemonicData.plainTextLabel
        }
    }
}
