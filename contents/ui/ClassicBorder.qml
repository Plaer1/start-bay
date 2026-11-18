/*
    SPDX-FileCopyrightText: 2021 Mikel Johnson <mikel5764@gmail.com>
    SPDX-FileCopyrightText: 2021 Noah Davis <noahadvs@gmail.com>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick

Rectangle {
    id: root

    property bool sunken: true

    anchors.fill: parent
    color: "transparent"
    border {
        width: 2
        color: root.sunken ? KickoffTheme.bevelDarkColor : KickoffTheme.bevelLightColor
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        color: "transparent"
        border {
            width: 1
            color: root.sunken ? KickoffTheme.bevelLightColor : KickoffTheme.bevelDarkColor
        }
    }
}
