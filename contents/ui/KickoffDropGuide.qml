/* SPDX-License-Identifier: GPL-2.0-or-later */

pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: root

    required property bool vertical
    required property bool active
    readonly property int thickness: KickoffTheme.isArrow ? 8 : (KickoffTheme.isExposed ? 4 : 3)
    readonly property color lineColor: KickoffTheme.isClassic ? KickoffTheme.textColor
        : (KickoffTheme.isArrow ? KickoffTheme.aeroSelBorderColor : KickoffTheme.highlightColor)
    readonly property int capLength: KickoffTheme.isClassic ? 5 : 7

    opacity: active ? 1 : 0
    visible: active && opacity > 0
    Accessible.ignored: true

    Behavior on opacity {
        enabled: !KickoffTheme.isClassic
        NumberAnimation {
            duration: KickoffTheme.dropMotionDuration
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        anchors.fill: parent
        visible: KickoffTheme.isArrow
        radius: Math.min(width, height) / 2
        color: Qt.alpha(root.lineColor, 0.3)
    }

    Rectangle {
        anchors.centerIn: parent
        width: root.vertical ? 2 : parent.width
        height: root.vertical ? parent.height : 2
        radius: KickoffTheme.isClassic ? 0 : 1
        color: root.lineColor

        Rectangle {
            x: root.vertical ? (KickoffTheme.isClassic ? parent.width - width : (parent.width - width) / 2) : 0
            y: root.vertical ? 0 : (KickoffTheme.isClassic ? parent.height - height : (parent.height - height) / 2)
            width: root.vertical ? 1 : parent.width
            height: root.vertical ? parent.height : 1
            color: KickoffTheme.isArrow ? KickoffTheme.aeroSelTopColor : KickoffTheme.bevelLightColor
            visible: KickoffTheme.isArrow || KickoffTheme.isClassic
        }
    }

    Repeater {
        model: KickoffTheme.isArrow ? 0 : 2

        Rectangle {
            required property int index

            width: root.vertical ? root.thickness : root.capLength
            height: root.vertical ? root.capLength : root.thickness
            x: root.vertical || index === 0 ? 0 : root.width - width
            y: !root.vertical || index === 0 ? 0 : root.height - height
            radius: KickoffTheme.isClassic ? 0 : 1
            color: KickoffTheme.xpColors ? KickoffTheme.grooveDarkColor : root.lineColor
        }
    }
}
