/*
    SPDX-License-Identifier: GPL-2.0-or-later

    Exposed mode (menuStyle 1): Windows XP Luna — blue banner bands, white
    app column, pale-blue places column, cartoony rounding, orange groove.
*/

import QtQuick
import org.kde.kirigami as Kirigami

KickoffThemeBase {
    windowColor: vanilla ? "#FFFFFF" : sysPalette.window
    textColor: vanilla ? "#000000" : sysPalette.windowText
    highlightColor: vanilla ? "#316AC5" : sysPalette.highlight
    highlightedTextColor: vanilla ? "#FFFFFF" : sysPalette.highlightedText

    // white app column / pale-blue places column, navy sidebar text
    viewColor: vanilla ? "#FFFFFF" : sysPalette.base
    alternateViewColor: vanilla ? "#D5E4FA" : sysPalette.alternateBase
    sidebarTextColor: vanilla ? "#0A246A" : sysPalette.windowText

    // Luna banner blues
    bandTopColor: vanilla ? "#397FDB" : Qt.lighter(sysPalette.highlight, 1.3)
    bandMidColor: vanilla ? "#2869C6" : sysPalette.highlight
    bandBottomColor: vanilla ? "#1B50A9" : Qt.darker(sysPalette.highlight, 1.25)
    frameBorderColor: vanilla ? "#1E48A8" : Qt.darker(sysPalette.highlight, 1.4)
    bevelLightColor: vanilla ? "#F7ECCB" : sysPalette.light

    // Luna's orange divider groove above All Programs
    grooveDarkColor: vanilla ? "#E68B2C" : sysPalette.dark
    grooveLightColor: vanilla ? "#F7B978" : sysPalette.light
    columnSeparatorDarkColor: vanilla ? "#96AFE0" : sysPalette.dark
    columnSeparatorLightColor: vanilla ? "#FFFFFF" : sysPalette.light

    borderRadius: Kirigami.Units.gridUnit * 0.6
}
