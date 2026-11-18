/* SPDX-License-Identifier: GPL-2.0-or-later */

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import org.kde.kirigami as Kirigami
import "code/tools.js" as Tools

Item {
    id: root

    required property string iconSource
    required property bool fileIcon
    required property bool coloredMark
    required property bool shadowed
    required property bool highlighted
    readonly property real availableExtent: Math.min(width, height)
    readonly property real artworkInset: shadowed ? Math.max(2, Math.round(availableExtent * 0.08)) : 1

    Accessible.ignored: true

    Item {
        anchors.centerIn: parent
        width: Math.max(0, root.availableExtent - 2 * root.artworkInset)
        height: width

        layer.enabled: root.shadowed
        layer.effect: MultiEffect {
            blurMax: 6
            shadowEnabled: root.shadowed
            shadowBlur: 0.4
            shadowColor: "#bb000000"
            shadowHorizontalOffset: 1
            shadowVerticalOffset: Math.max(1, Math.round(root.availableExtent * 0.045))
        }

        Image {
            id: imageArt
            anchors.fill: parent
            source: root.fileIcon ? root.iconSource : ""
            // The bundled 256px PNG has transparent padding outside this area.
            sourceClipRect: root.coloredMark ? Qt.rect(40, 40, 176, 176) : Qt.rect(0, 0, 0, 0)
            visible: status === Image.Ready
            fillMode: Image.PreserveAspectFit
            mipmap: true
            smooth: true
        }

        Kirigami.Icon {
            anchors.fill: parent
            visible: !imageArt.visible
            source: root.fileIcon ? Tools.defaultIconName : root.iconSource
            fallback: Tools.defaultIconName
            active: root.highlighted
            roundToIconSize: false
        }
    }
}
