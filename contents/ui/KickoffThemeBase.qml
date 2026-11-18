/*
    SPDX-License-Identifier: GPL-2.0-or-later

    Base color-role contract every Start Bay theme module fills in.
    Defaults are the theme-responsive baseline: everything derives from the
    system palette (the application color scheme), nothing hardcoded.
    Vanilla "true to Windows" themes override roles when `vanilla` is set.
*/

import QtQuick
import org.kde.kirigami as Kirigami

QtObject {
    // Shared inputs, wired up by the KickoffTheme dispatcher
    required property SystemPalette sysPalette
    // false = "Theme responsive" setting active: stick to the scheme colors
    property bool vanilla: true

    // Core window roles
    property color windowColor: sysPalette.window
    property color textColor: sysPalette.windowText
    property color highlightColor: sysPalette.highlight
    property color highlightedTextColor: sysPalette.highlightedText
    property color buttonColor: sysPalette.button
    property color buttonTextColor: sysPalette.buttonText

    // Two-tone columns: app list / places pane
    property color viewColor: sysPalette.base
    property color alternateViewColor: sysPalette.alternateBase
    property color sidebarTextColor: sysPalette.windowText
    property color sidebarHighlightedTextColor: highlightedTextColor

    // Header/footer band gradient
    property color bandTopColor: Qt.lighter(highlightColor, 1.3)
    property color bandMidColor: highlightColor
    property color bandBottomColor: Qt.darker(highlightColor, 1.25)
    property color frameBorderColor: Qt.darker(highlightColor, 1.4)

    // 3D chrome
    property color bevelLightColor: sysPalette.light
    property color bevelDarkColor: sysPalette.dark
    property color grooveDarkColor: bevelDarkColor
    property color grooveLightColor: bevelLightColor
    property color columnSeparatorDarkColor: bevelDarkColor
    property color columnSeparatorLightColor: bevelLightColor

    // Selection pill accents (only Aero draws these, but the roles derive
    // sanely from the palette everywhere)
    property color aeroSelTopColor: Qt.lighter(sysPalette.highlight, 1.6)
    property color aeroSelBottomColor: Qt.lighter(sysPalette.highlight, 1.15)
    property color aeroSelBorderColor: sysPalette.highlight

    property real borderRadius: Kirigami.Units.cornerRadius
}
