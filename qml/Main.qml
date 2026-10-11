/*
    SPDX-FileCopyrightText: 2026 Javier O. Cordero Pérez <javiercorderoperez@gmail.com>
    SPDX-License-Identifier: MIT
*/

import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard

Kirigami.ApplicationWindow {
    id: root

    required property color initialColor
    readonly property color selectedColor: chooserPage.color

    title: i18n("Select Color — KColorChooser")
    width: minimumWidth
    height: minimumHeight
    minimumWidth: chooserPage.implicitWidth
    maximumWidth: chooserPage.implicitWidth
    minimumHeight: chooserPage.implicitHeight
    maximumHeight: chooserPage.implicitHeight

    pageStack.initialPage: ColorChooserPage {
        id: chooserPage

        initialColor: root.initialColor
        onAboutRequested: root.pageStack.layers.push(aboutPage)
        onAboutKDERequested: root.pageStack.layers.push(aboutKDEPage)
        onFinished: root.close()
    }

    Component {
        id: aboutPage

        FormCard.AboutPage {}
    }

    Component {
        id: aboutKDEPage

        FormCard.AboutKDEPage {}
    }
}
