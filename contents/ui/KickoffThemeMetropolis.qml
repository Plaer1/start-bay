/* SPDX-License-Identifier: GPL-2.0-or-later */

import QtQuick

KickoffThemeBase {
    required property color sideColor

    vanilla: false

    windowColor: sysPalette.window
    viewColor: sysPalette.window
    alternateViewColor: sideColor
    highlightColor: sideColor
    highlightedTextColor: "#FFFFFF"
    sidebarTextColor: "#FFFFFF"
    sidebarHighlightedTextColor: "#FFFFFF"
    buttonColor: Qt.lighter(sideColor, 1.17)
    buttonTextColor: "#FFFFFF"
    frameBorderColor: Qt.tint(sysPalette.window, Qt.alpha(sysPalette.windowText, 0.23))
    grooveDarkColor: frameBorderColor
    grooveLightColor: "transparent"
    columnSeparatorDarkColor: frameBorderColor
    columnSeparatorLightColor: "transparent"
    borderRadius: 0
}
