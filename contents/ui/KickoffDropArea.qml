/*
 * SPDX-FileCopyrightText: 2021 Noah Davis <noahadvs@gmail.com>
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

pragma ComponentBehavior: Bound

import QtQuick
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

DropArea {
    id: root
    required property Flickable targetView
    readonly property bool enableAutoScroll: targetView.height < targetView.contentHeight
    property real scrollUpMargin: 0
    property real scrollDownMargin: 0
    property bool dropEnabled: true
    enabled: dropEnabled && Plasmoid.immutability !== PlasmaCore.Types.SystemImmutable

    // A controller handles All Programs. Favorites uses the native model.
    property var orderController: null
    property bool receivingUrls: false
    readonly property bool grid: targetView instanceof GridView
    readonly property bool rightToLeft: grid && targetView.effectiveLayoutDirection === Qt.RightToLeft
    readonly property Item sourceItem: containsDrag && drag.source === kickoff.dragSource
        ? kickoff.dragSource.sourceItem : null
    readonly property int hoveredRow: containsDrag ? rowAt(drag.x, drag.y) : -1
    readonly property int indicatedRow: {
        if (sourceItem?.view === targetView && canMove(sourceItem.index, hoveredRow)) return hoveredRow;
        if (containsDrag && receivingUrls) return hoveredRow >= 0 ? hoveredRow : targetView.count - 1;
        return -1;
    }
    readonly property Item indicatedItem: indicatedRow >= 0 ? targetView.itemAtIndex(indicatedRow) : null
    readonly property bool trailing: sourceItem ? indicatedRow > sourceItem.index : hoveredRow < 0

    function rowAt(x, y) {
        const point = mapToItem(targetView, x, y);
        return targetView.indexAt(point.x + targetView.contentX, point.y + targetView.contentY);
    }

    function canMove(from, to) {
        return from >= 0 && from < targetView.count && to >= 0 && to < targetView.count && from !== to
            && (orderController ? orderController.canMoveRow(from, to) : typeof targetView.model?.moveRow === "function");
    }

    function acceptDrag(event) {
        const source = event.source === kickoff.dragSource ? kickoff.dragSource.sourceItem : null;
        receivingUrls = !orderController && !source && event.hasUrls
            && typeof targetView.model?.addFavoriteTo === "function";
        if (source?.view === targetView) {
            event.accept(Qt.MoveAction);
        } else if (receivingUrls) {
            event.acceptProposedAction();
        } else {
            event.accepted = false;
        }
    }

    onEntered: event => acceptDrag(event)
    onPositionChanged: event => acceptDrag(event)
    onExited: receivingUrls = false

    onDropped: event => {
        const source = event.source === kickoff.dragSource ? kickoff.dragSource.sourceItem : null;
        const destination = rowAt(event.x, event.y);
        event.accepted = false;
        if (source?.view === targetView && canMove(source.index, destination)) {
            const from = source.index;
            if (orderController) {
                if (!orderController.moveRow(from, destination)) return;
            } else {
                targetView.model.moveRow(from, destination);
            }
            targetView.currentIndex = destination;
            event.accept(Qt.MoveAction);
        } else if (receivingUrls && event.hasUrls) {
            let row = destination;
            for (const url of event.urls) {
                if (row >= 0) {
                    targetView.model.addFavoriteTo(url, ":current", row++);
                } else {
                    targetView.model.addFavoriteTo(url, ":current");
                }
            }
            event.acceptProposedAction();
        }
        receivingUrls = false;
    }

    Item {
        parent: root.targetView
        anchors.fill: parent
        clip: true
        z: 8

        KickoffDropGuide {
            id: guide
            vertical: root.grid
            active: root.containsDrag && (!!root.indicatedItem || (root.receivingUrls && root.targetView.count === 0))
            readonly property real cellX: root.indicatedItem ? root.indicatedItem.x - root.targetView.contentX : 0
            readonly property real cellY: root.indicatedItem ? root.indicatedItem.y - root.targetView.contentY : 0
            readonly property real cellWidth: root.indicatedItem?.width ?? root.targetView.width
            readonly property real cellHeight: root.indicatedItem?.height ?? root.targetView.height
            readonly property bool rightEdge: root.trailing !== root.rightToLeft

            x: vertical ? Math.max(0, Math.min(parent.width - width,
                Math.round(cellX + (rightEdge ? cellWidth : 0) - width / 2))) : Math.round(cellX + 4)
            y: vertical ? Math.round(cellY + 4) : Math.max(0, Math.min(parent.height - height,
                Math.round(cellY + (root.trailing && root.indicatedItem ? cellHeight : 0) - height / 2)))
            width: vertical ? thickness : Math.max(0, cellWidth - 8)
            height: vertical ? Math.max(0, cellHeight - 8) : thickness
        }
    }

    function moveRow(targetIndex) {
        if (targetIndex < 0 || targetIndex >= targetView.count) {
            return;
        }

        if (root.orderController) {
            if (!root.orderController.moveRow(targetView.currentIndex, targetIndex)) return;
        } else {
            targetView.model.moveRow(targetView.currentIndex, targetIndex);
        }
        targetView.currentIndex = targetIndex;
    }

    Shortcut {
        enabled: root.enabled && ((root.targetView instanceof GridView && root.targetView.currentIndex >= root.targetView.columns)
              || (root.targetView instanceof ListView && root.targetView.currentIndex > 0))
        sequence: "Ctrl+Shift+Up"
        onActivated: root.moveRow(root.targetView.currentIndex - (root.targetView instanceof GridView ? root.targetView.columns : 1))
    }

    Shortcut {
        enabled: root.enabled && ((root.targetView instanceof GridView && root.targetView.currentIndex < root.targetView.count - root.targetView.columns)
              || (root.targetView instanceof ListView && root.targetView.currentIndex + 1 < root.targetView.count))
        sequence: "Ctrl+Shift+Down"
        onActivated: root.moveRow(root.targetView.currentIndex + (root.targetView instanceof GridView ? root.targetView.columns : 1))
    }

    Shortcut {
        enabled: root.enabled && root.targetView instanceof GridView && root.targetView.currentIndex % root.targetView.columns > 0
        sequence: "Ctrl+Shift+Left"
        onActivated: root.moveRow(root.targetView.currentIndex - 1)
    }

    Shortcut {
        enabled: root.enabled && root.targetView instanceof GridView && root.targetView.currentIndex % root.targetView.columns !== root.targetView.columns - 1
        sequence: "Ctrl+Shift+Right"
        onActivated: root.moveRow(root.targetView.currentIndex + 1)
    }

    SmoothedAnimation {
        target: root.targetView
        property: "contentY"
        to: 0
        velocity: 200
        running: root.enableAutoScroll && root.containsDrag && root.drag.y <= root.scrollUpMargin
    }
    SmoothedAnimation {
        target: root.targetView
        property: "contentY"
        to: root.targetView.contentHeight - root.targetView.height
        velocity: 200
        running: root.enableAutoScroll && root.containsDrag && root.drag.y >= root.height - root.scrollDownMargin
    }
}
