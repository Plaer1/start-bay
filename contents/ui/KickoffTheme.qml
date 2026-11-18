/*
    SPDX-FileCopyrightText: 2021 Mikel Johnson <mikel5764@gmail.com>
    SPDX-FileCopyrightText: 2021 Noah Davis <noahadvs@gmail.com>

    SPDX-License-Identifier: GPL-2.0-or-later

    Theme dispatcher. Each menu style owns its colors in its own module:
      KickoffThemeClassic — Windows Classic (Win9x/2000 grey)
      KickoffThemeLuna    — Windows XP Luna (exposed)
      KickoffThemeAero    — Windows 7 Aero (arrow)
      KickoffThemeMetropolis — flat, palette-responsive two-column style
      KickoffThemeBase    — responsive/palette baseline + plasma fallback
    This singleton only picks the active module and forwards its roles, so
    consumers keep using KickoffTheme.* and never touch per-theme logic.
*/

pragma Singleton

import QtQuick
import org.kde.kirigami as Kirigami

QtObject {
    id: root

    property int menuStyle: 0
    property bool configShowDescriptionsInline: false
    property bool classicResponsive: false
    property bool exposedResponsive: false
    property bool arrowResponsive: false
    property bool arrowTransparent: false
    property int arrowAeroColor: 0
    property int metropolisAccent: 0

    readonly property bool isClassic: menuStyle === 0
    readonly property bool isExposed: menuStyle === 1
    readonly property bool isArrow: menuStyle === 2
    readonly property bool isMetropolis: menuStyle === 4
    readonly property bool isWinStyle: isClassic || isExposed || isArrow || isMetropolis
    readonly property bool hasInlineControls: isArrow || isMetropolis
    // Fixed "true to Windows" palettes active (vs "Theme responsive")
    readonly property bool classicColors: isClassic && !classicResponsive
    readonly property bool xpColors: isExposed && !exposedResponsive
    readonly property bool w7Colors: isArrow && !arrowResponsive
    // Modes with a banner/titlebar header up top
    readonly property bool hasBanner: isClassic || isExposed
    readonly property int dropMotionDuration: Math.round(Kirigami.Units.shortDuration
        * (isClassic ? 0.6 : (isArrow ? 1.35 : 1.0)))
    readonly property int dropMotionEasing: isClassic ? Easing.OutQuad
        : (isArrow ? Easing.OutQuint : Easing.OutCubic)

    // Width of the Windows 98 style vertical side titlebar (classic setting)
    readonly property real sideTitleWidth: Math.round(Kirigami.Units.gridUnit * 1.25)

    // Windows-like modes pull their responsive colors from the system palette
    // (the application color scheme — same source regular Qt apps use), not
    // the Plasma SVG theme, so the menu matches application windows.
    readonly property SystemPalette systemPalette: SystemPalette {
        colorGroup: SystemPalette.Active
    }

    // One module per menu style
    readonly property KickoffThemeBase classicTheme: KickoffThemeClassic {
        sysPalette: root.systemPalette
        vanilla: !root.classicResponsive
    }
    readonly property KickoffThemeBase lunaTheme: KickoffThemeLuna {
        sysPalette: root.systemPalette
        vanilla: !root.exposedResponsive
    }
    readonly property KickoffThemeAero aeroTheme: KickoffThemeAero {
        sysPalette: root.systemPalette
        vanilla: !root.arrowResponsive
        transparent: root.arrowTransparent
        presetIndex: root.arrowAeroColor
    }
    readonly property KickoffThemeBase metropolisTheme: KickoffThemeMetropolis {
        sysPalette: root.systemPalette
        sideColor: root.metropolisColor(root.metropolisAccent)
    }
    // Non-Windows fallback: vanilla Kickoff look from the Plasma theme
    readonly property KickoffThemeBase plasmaTheme: KickoffThemeBase {
        sysPalette: root.systemPalette
        windowColor: Kirigami.Theme.backgroundColor
        textColor: Kirigami.Theme.textColor
        highlightColor: Kirigami.Theme.highlightColor
        highlightedTextColor: Kirigami.Theme.highlightedTextColor
    }

    readonly property KickoffThemeBase active: isClassic ? classicTheme
        : isExposed ? lunaTheme
        : isArrow ? aeroTheme : isMetropolis ? metropolisTheme : plasmaTheme

    // Forwarded color roles — the public API every view reads
    readonly property color windowColor: active.windowColor
    readonly property color textColor: active.textColor
    readonly property color highlightColor: active.highlightColor
    readonly property color highlightedTextColor: active.highlightedTextColor
    readonly property color buttonColor: active.buttonColor
    readonly property color buttonTextColor: active.buttonTextColor
    readonly property color viewColor: active.viewColor
    readonly property color alternateViewColor: active.alternateViewColor
    readonly property color sidebarTextColor: active.sidebarTextColor
    readonly property color sidebarHighlightedTextColor: active.sidebarHighlightedTextColor
    readonly property color bandTopColor: active.bandTopColor
    readonly property color bandMidColor: active.bandMidColor
    readonly property color bandBottomColor: active.bandBottomColor
    readonly property color frameBorderColor: active.frameBorderColor
    readonly property color bevelLightColor: active.bevelLightColor
    readonly property color bevelDarkColor: active.bevelDarkColor
    readonly property color grooveDarkColor: active.grooveDarkColor
    readonly property color grooveLightColor: active.grooveLightColor
    readonly property color columnSeparatorDarkColor: active.columnSeparatorDarkColor
    readonly property color columnSeparatorLightColor: active.columnSeparatorLightColor
    readonly property color aeroSelTopColor: active.aeroSelTopColor
    readonly property color aeroSelBottomColor: active.aeroSelBottomColor
    readonly property color aeroSelBorderColor: active.aeroSelBorderColor
    readonly property real borderRadius: active.borderRadius

    // Aero extras consumed by ConfigGeneral's preset dropdown and main.qml
    readonly property var aeroPresets: aeroTheme.aeroPresets
    readonly property color aeroBaseColor: aeroTheme.aeroBaseColor
    readonly property color arrowChromeColor: aeroTheme.chromeColor

    function metropolisColor(index: int): color {
        if (index < 1 || index >= aeroPresets.length) return "#075EA8";
        return Qt.darker(aeroPresets[index].color, 1.85);
    }
}
