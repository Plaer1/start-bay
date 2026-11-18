/* SPDX-License-Identifier: GPL-2.0-or-later */

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Window
import org.kde.kirigami as Kirigami

MouseArea {
    id: grip

    required property bool west
    required property bool north
    readonly property int resizeEdges: (west ? Qt.LeftEdge : Qt.RightEdge)
        | (north ? Qt.TopEdge : Qt.BottomEdge)
    width: Math.max(12, Kirigami.Units.smallSpacing * 3)
    height: width
    acceptedButtons: Qt.LeftButton
    hoverEnabled: true
    cursorShape: west === north ? Qt.SizeFDiagCursor : Qt.SizeBDiagCursor
    onPressed: mouse => {
        mouse.accepted = grip.Window.window?.startSystemResize(resizeEdges) ?? false;
    }
}
