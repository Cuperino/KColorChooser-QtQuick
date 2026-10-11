/*
    SPDX-FileCopyrightText: 2026 Javier O. Cordero Pérez <javiercorderoperez@gmail.com>
    SPDX-License-Identifier: MIT
*/

import QtCore
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcolorchooser

Kirigami.Page {
    id: root

    required property color initialColor

    // HSV components are the source of truth so that hue and saturation
    // survive passing through achromatic colors.
    property real hue: 0
    property real saturation: 0
    property real value: 1
    property real alpha: 1
    readonly property color color: Qt.hsva(hue, saturation, value, alpha)

    // Same palette as QColorDialog, listed column by column.
    readonly property list<color> basicColors: {
        const result = [];
        for (let g = 0; g < 4; ++g) {
            for (let r = 0; r < 4; ++r) {
                for (let b = 0; b < 3; ++b) {
                    // Integer division, as Qt's qRgb(r * 255 / 3, g * 255 / 3, b * 255 / 2).
                    result.push(Qt.rgba(Math.floor(r * 255 / 3) / 255, Math.floor(g * 255 / 3) / 255, Math.floor(b * 255 / 2) / 255, 1));
                }
            }
        }
        return result;
    }
    property int basicColorIndex: -1

    readonly property int customColorCount: 16
    readonly property list<string> customColors: {
        const colors = Array.from(customColorSettings.colors).slice(0, customColorCount);
        while (colors.length < customColorCount) {
            colors.push("#ffffff");
        }
        return colors;
    }
    // The underlined custom cell, and the slot "Add to Custom Colors" writes to next.
    property int selectedCustomColorIndex: -1
    property int customColorIndex: 0

    signal aboutRequested
    signal aboutKDERequested
    signal finished

    function setColor(newColor: color): void {
        if (!newColor.valid) {
            return;
        }
        if (newColor.hsvValue > 0 && newColor.hsvSaturation > 0) {
            hue = Math.max(newColor.hsvHue, 0);
        }
        if (newColor.hsvValue > 0) {
            saturation = newColor.hsvSaturation;
        }
        value = newColor.hsvValue;
        alpha = newColor.a;
    }

    // Underline the cell showing this color, if any.
    function selectColor(selectedColor: color): void {
        const basicIndex = basicColors.findIndex(basicColor => Qt.colorEqual(basicColor, selectedColor));
        if (basicIndex >= 0) {
            basicColorIndex = basicIndex;
            selectedCustomColorIndex = -1;
            return;
        }
        const customIndex = customColors.findIndex(customColor => Qt.colorEqual(customColor, selectedColor));
        if (customIndex >= 0) {
            selectedCustomColorIndex = customIndex;
            customColorIndex = customIndex;
            basicColorIndex = -1;
        }
    }

    function addCustomColor(): void {
        const colors = Array.from(customColors);
        colors[customColorIndex] = color.toString();
        customColorSettings.colors = colors;
        customColorIndex = (customColorIndex + 1) % customColorCount;
    }

    title: i18n("Select Color")
    globalToolBarStyle: Kirigami.ApplicationHeaderStyle.None
    padding: 10

    Component.onCompleted: {
        // QColorDialog starts out white before the initial color is applied.
        selectColor("white");
        setColor(initialColor);
        selectColor(initialColor);
    }

    Settings {
        id: customColorSettings

        property list<string> colors

        category: "CustomColors"
    }

    Connections {
        target: ColorChooserHelper

        function onScreenColorPicked(pickedColor: color): void {
            root.setColor(Qt.rgba(pickedColor.r, pickedColor.g, pickedColor.b, root.alpha));
        }
    }

    Shortcut {
        sequences: [StandardKey.Copy]
        enabled: root.visible
        onActivated: ColorChooserHelper.copyToClipboard(root.color)
    }

    Shortcut {
        sequences: [StandardKey.Paste]
        enabled: root.visible
        onActivated: root.setColor(ColorChooserHelper.colorFromClipboard())
    }

    Shortcut {
        sequences: [StandardKey.Cancel]
        enabled: root.visible
        onActivated: root.finished()
    }

    RowLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.largeSpacing + Kirigami.Units.smallSpacing

        ColumnLayout {
            Layout.fillHeight: true
            spacing: 6

            FieldLabel {
                label: i18n("&Basic colors")
                onActivated: basicColorsGrid.focusSwatch(0)
            }

            ColorSwatchGrid {
                id: basicColorsGrid

                colors: root.basicColors
                rows: 6
                currentIndex: root.basicColorIndex
                onActivated: (index, swatchColor) => {
                    root.basicColorIndex = index;
                    root.selectedCustomColorIndex = -1;
                    root.setColor(swatchColor);
                }
            }

            QQC2.Button {
                Layout.fillWidth: true
                text: i18n("&Pick Screen Color")
                visible: ColorChooserHelper.canPickScreenColor
                onClicked: ColorChooserHelper.pickScreenColor()
            }

            Item {
                Layout.fillHeight: true
            }

            FieldLabel {
                label: i18n("&Custom colors")
                onActivated: customColorsGrid.focusSwatch(root.selectedCustomColorIndex)
            }

            ColorSwatchGrid {
                id: customColorsGrid

                colors: root.customColors
                rows: 2
                currentIndex: root.selectedCustomColorIndex
                onActivated: (index, swatchColor) => {
                    root.selectedCustomColorIndex = index;
                    root.customColorIndex = index;
                    root.basicColorIndex = -1;
                    root.setColor(swatchColor);
                }
            }

            QQC2.Button {
                Layout.fillWidth: true
                text: i18n("&Add to Custom Colors")
                onClicked: root.addCustomColor()
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            RowLayout {
                // QColorDialog's pickLay: the luminance picker extends lumSpace
                // above and below the color picker, 10 px past the layout spacing.
                readonly property int lumSpace: 3

                Layout.topMargin: 8 - lumSpace
                spacing: 6 + 10

                HueSaturationPicker {
                    Layout.topMargin: parent.lumSpace
                    Layout.bottomMargin: parent.lumSpace
                    hue: root.hue
                    saturation: root.saturation
                    onMoved: (newHue, newSaturation) => {
                        root.hue = newHue;
                        root.saturation = newSaturation;
                    }
                }

                LuminancePicker {
                    Layout.fillHeight: true
                    Accessible.name: colorFields.valueLabelText
                    hue: root.hue
                    saturation: root.saturation
                    value: root.value
                    onMoved: newValue => root.value = newValue
                }
            }

            Item {
                Layout.fillHeight: true
                Layout.minimumHeight: 22
            }

            ColorFields {
                id: colorFields

                Layout.fillWidth: true
                Layout.rightMargin: 4
                hue: root.hue
                saturation: root.saturation
                value: root.value
                alpha: root.alpha
                color: root.color
                onHsvaEdited: (newHue, newSaturation, newValue, newAlpha) => {
                    root.hue = newHue;
                    root.saturation = newSaturation;
                    root.value = newValue;
                    root.alpha = newAlpha;
                }
                onColorEdited: editedColor => root.setColor(editedColor)
            }
        }
    }

    footer: QQC2.Control {
        padding: 10

        contentItem: RowLayout {
            spacing: Kirigami.Units.largeSpacing

            QQC2.DialogButtonBox {
                padding: 0
                standardButtons: QQC2.DialogButtonBox.Help
                onHelpRequested: {
                    const helpButton = standardButton(QQC2.DialogButtonBox.Help);
                    helpMenu.popup(helpButton, 0, -helpMenu.implicitHeight);
                }
            }

            Item {
                Layout.fillWidth: true
            }

            QQC2.DialogButtonBox {
                padding: 0
                standardButtons: QQC2.DialogButtonBox.Ok | QQC2.DialogButtonBox.Cancel
                Component.onCompleted: standardButton(QQC2.DialogButtonBox.Ok).Accessible.defaultButton = true
                onAccepted: root.finished()
                onRejected: root.finished()
            }
        }

        QQC2.Menu {
            id: helpMenu

            // KHelpMenu's entries, minus What's This? and Configure Language…, which
            // depend on Qt Widgets.
            QQC2.MenuItem {
                text: i18n("&Report Bug…")
                icon.name: "tools-report-bug"
                onTriggered: Qt.openUrlExternally(ColorChooserHelper.bugReportUrl)
            }

            QQC2.MenuSeparator {}

            QQC2.MenuItem {
                text: i18n("&Donate")
                icon.name: "help-donate-usd"
                onTriggered: Qt.openUrlExternally(ColorChooserHelper.donateUrl)
            }

            QQC2.MenuSeparator {}

            QQC2.MenuItem {
                text: i18n("&About %1", i18n("KColorChooser"))
                onTriggered: root.aboutRequested()
            }

            QQC2.MenuItem {
                text: i18n("About &KDE")
                icon.name: "kde"
                onTriggered: root.aboutKDERequested()
            }
        }
    }
}
