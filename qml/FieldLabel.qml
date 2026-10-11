/*
    SPDX-FileCopyrightText: 2026 Javier O. Cordero Pérez <javiercorderoperez@gmail.com>
    SPDX-License-Identifier: MIT
*/

import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

// A label whose "&" mnemonic moves focus to its buddy
QQC2.Label {
    id: root

    required property string label
    property Item buddy

    signal activated

    text: Kirigami.MnemonicData.richTextLabel
    Kirigami.MnemonicData.controlType: Kirigami.MnemonicData.FormLabel
    Kirigami.MnemonicData.label: label
    Accessible.name: Kirigami.MnemonicData.plainTextLabel

    onActivated: buddy?.forceActiveFocus(Qt.ShortcutFocusReason)

    Shortcut {
        sequence: root.Kirigami.MnemonicData.sequence
        onActivated: root.activated()
    }
}
