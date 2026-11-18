/*
    SPDX-License-Identifier: GPL-2.0-or-later

    Classic mode (menuStyle 0): Windows Classic — Win9x/2000 silver chrome,
    navy selection, hard 1px bevels, dead-square corners. The banner band
    roles carry the Windows Classic active-titlebar navy gradient.
*/

import QtQuick

KickoffThemeBase {
    windowColor: vanilla ? "#C0C0C0" : sysPalette.window
    textColor: vanilla ? "#000000" : sysPalette.windowText
    highlightColor: vanilla ? "#000080" : sysPalette.highlight
    highlightedTextColor: vanilla ? "#FFFFFF" : sysPalette.highlightedText
    buttonColor: vanilla ? "#C0C0C0" : sysPalette.button
    buttonTextColor: vanilla ? "#000000" : sysPalette.buttonText

    // white app column / silver places column
    viewColor: vanilla ? "#FFFFFF" : sysPalette.base
    alternateViewColor: vanilla ? "#C0C0C0" : sysPalette.alternateBase
    sidebarTextColor: vanilla ? "#000000" : sysPalette.windowText

    // Windows Classic active-titlebar gradient (horizontal in Header)
    bandTopColor: vanilla ? "#1084D0" : Qt.lighter(sysPalette.highlight, 1.3)
    bandMidColor: vanilla ? "#0855A8" : sysPalette.highlight
    bandBottomColor: vanilla ? "#000080" : Qt.darker(sysPalette.highlight, 1.25)

    // hard Win Classic 3D chrome
    bevelLightColor: vanilla ? "#FFFFFF" : sysPalette.light
    bevelDarkColor: vanilla ? "#808080" : sysPalette.dark

    borderRadius: 0
}
