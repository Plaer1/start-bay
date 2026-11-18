/*
    SPDX-License-Identifier: GPL-2.0-or-later

    Arrow mode (menuStyle 2): Windows 7 Aero — colorized smoky glass chrome,
    white content pane, pale glass selection pills, white sidebar text.
*/

import QtQuick
import org.kde.kirigami as Kirigami

KickoffThemeBase {
    // Extra inputs specific to Aero
    property bool transparent: false
    property int presetIndex: 0

    // Win7 "Window Color" presets. Sky's ColorizationColor 0x6B74B8FC is the
    // documented default; the rest approximate the picker swatches (exact
    // registry ARGBs live in DWMBlurGlass discussion #309's attachment).
    readonly property var aeroPresets: [
        { name: "Sky",       color: "#74B8FC" },
        { name: "Twilight",  color: "#0A2AA5" },
        { name: "Sea",       color: "#16A091" },
        { name: "Leaf",      color: "#23A21D" },
        { name: "Lime",      color: "#A3C500" },
        { name: "Sun",       color: "#FFB901" },
        { name: "Pumpkin",   color: "#F16A0F" },
        { name: "Ruby",      color: "#CE0A0F" },
        { name: "Fuchsia",   color: "#FF0F9E" },
        { name: "Blush",     color: "#F489B4" },
        { name: "Violet",    color: "#8023B8" },
        { name: "Lavender",  color: "#8E8CD8" },
        { name: "Taupe",     color: "#AB9782" },
        { name: "Chocolate", color: "#6E3B14" },
        { name: "Slate",     color: "#6D7A85" },
        { name: "Frost",     color: "#B5C6D8" }
    ]
    readonly property color aeroBaseColor: aeroPresets[Math.max(0, Math.min(presetIndex, aeroPresets.length - 1))].color

    // Win7 chrome: the smoky colorized glass of the right column/footer/frame.
    // Transparent mode keeps a low alpha so the blurred backdrop shows through.
    readonly property color chromeColor: {
        const base = vanilla ? Qt.darker(aeroBaseColor, 2.4) : sysPalette.window;
        return transparent ? Qt.rgba(base.r, base.g, base.b, 0.58) : base;
    }

    windowColor: chromeColor
    textColor: vanilla ? "#000000" : sysPalette.windowText
    highlightColor: vanilla ? Qt.rgba(aeroBaseColor.r, aeroBaseColor.g, aeroBaseColor.b, 0.4) : sysPalette.highlight
    highlightedTextColor: vanilla ? "#000000" : sysPalette.highlightedText

    viewColor: vanilla ? "#FFFFFF" : sysPalette.base
    // white text on the colorized glass
    sidebarTextColor: vanilla ? "#FFFFFF" : sysPalette.windowText
    sidebarHighlightedTextColor: vanilla ? "#FFFFFF" : sysPalette.highlightedText

    frameBorderColor: vanilla ? Qt.darker(aeroBaseColor, 3.2) : Qt.darker(sysPalette.highlight, 1.4)

    // single grey hairline above Back — no light half, it glares on white
    grooveDarkColor: vanilla ? "#D9DEE4" : sysPalette.dark
    grooveLightColor: vanilla ? "transparent" : sysPalette.light
    // Win7 columns contrast on their own; no groove between them
    columnSeparatorDarkColor: "transparent"
    columnSeparatorLightColor: "transparent"

    // pale glass selection pill: gradient fill, accent border, inner rim
    aeroSelTopColor: vanilla ? "#EAF4FC" : Qt.lighter(sysPalette.highlight, 1.6)
    aeroSelBottomColor: vanilla ? "#C7E1F8" : Qt.lighter(sysPalette.highlight, 1.15)
    aeroSelBorderColor: vanilla ? "#7DA2CE" : sysPalette.highlight

    borderRadius: Kirigami.Units.smallSpacing
}
