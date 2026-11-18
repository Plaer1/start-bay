/*
    SPDX-FileCopyrightText: 2011 Martin Gräßlin <mgraesslin@kde.org>
    SPDX-FileCopyrightText: 2012 Gregor Taetzner <gregor@freenet.de>
    SPDX-FileCopyrightText: 2012 Marco Martin <mart@kde.org>
    SPDX-FileCopyrightText: 2013 2014 David Edmundson <davidedmundson@kde.org>
    SPDX-FileCopyrightText: 2014 Sebastian Kügler <sebas@kde.org>
    SPDX-FileCopyrightText: 2021 Mikel Johnson <mikel5764@gmail.com>
    SPDX-FileCopyrightText: 2021 Noah Davis <noahadvs@gmail.com>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Templates as T
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.private.kicker as Kicker
import org.kde.kirigami as Kirigami
import org.kde.plasma.extras as PlasmaExtras
import org.kde.coreaddons as KCoreAddons

EmptyPage {
    id: root

    Kirigami.Theme.colorSet: KickoffTheme.isWinStyle ? Kirigami.Theme.Window : Kirigami.Theme.Complementary
    Kirigami.Theme.inherit: !KickoffTheme.isWinStyle

    // In Windows-like modes push the system palette (application color scheme)
    // into the Kirigami theme so every child label/control inherits it instead
    // of the Plasma SVG theme colors. Nothing hardcoded; all from the palette.
    readonly property QtObject kirigamiTheme: Kirigami.Theme
    Binding {
        target: root.kirigamiTheme
        property: "backgroundColor"
        value: KickoffTheme.windowColor
        when: KickoffTheme.isWinStyle
        restoreMode: Binding.RestoreBindingOrValue
    }
    Binding {
        target: root.kirigamiTheme
        property: "textColor"
        value: KickoffTheme.textColor
        when: KickoffTheme.isWinStyle
        restoreMode: Binding.RestoreBindingOrValue
    }
    Binding {
        target: root.kirigamiTheme
        property: "highlightColor"
        value: KickoffTheme.highlightColor
        when: KickoffTheme.isWinStyle
        restoreMode: Binding.RestoreBindingOrValue
    }
    Binding {
        target: root.kirigamiTheme
        property: "highlightedTextColor"
        value: KickoffTheme.highlightedTextColor
        when: KickoffTheme.isWinStyle
        restoreMode: Binding.RestoreBindingOrValue
    }

    // Optional Windows 98 style vertical side titlebar (classic setting,
    // default off): navy strip down the left edge, content shifts right
    readonly property bool classicSideTitle: KickoffTheme.isClassic && Plasmoid.configuration.classicSideTitlebar
    readonly property real sideTitleWidth: KickoffTheme.sideTitleWidth

    // kickoff is Kickoff.qml
    leftPadding: -kickoff.backgroundMetrics.leftPadding + (classicSideTitle ? sideTitleWidth : 0)
    rightPadding: -kickoff.backgroundMetrics.rightPadding
    topPadding: 0
    bottomPadding: -kickoff.backgroundMetrics.bottomPadding

    // Use the same outer frame footprint for all Start Bay styles.
    readonly property bool coversDialogFrame: KickoffTheme.isWinStyle
    leftInset: coversDialogFrame ? -kickoff.backgroundMetrics.leftPadding : 0
    rightInset: coversDialogFrame ? -kickoff.backgroundMetrics.rightPadding : 0
    topInset: coversDialogFrame ? -kickoff.backgroundMetrics.topPadding : 0
    bottomInset: coversDialogFrame ? -kickoff.backgroundMetrics.bottomPadding : 0
    readonly property var appletInterface: kickoff

    // Plasma can persist a temporary minimum width after a theme change.
    // Keep both width hints independent of style and content initialization.
    readonly property int defaultPopupWidth: 438
    implicitWidth: defaultPopupWidth
    Layout.preferredWidth: defaultPopupWidth
    Layout.minimumWidth: Math.min(defaultPopupWidth, Kirigami.Units.gridUnit * 17)
    Layout.minimumHeight: KickoffTheme.isWinStyle ? Math.min(implicitHeight,
        implicitHeaderHeight2 + implicitFooterHeight2 + Kirigami.Units.gridUnit * 8)
        : implicitHeight

    background: Rectangle {
        color: KickoffTheme.windowColor
        radius: KickoffTheme.borderRadius
        border.width: (KickoffTheme.isArrow || KickoffTheme.isExposed || KickoffTheme.isMetropolis) ? 1 : 0
        border.color: KickoffTheme.frameBorderColor

        // Aero soul: diagonal reflection streaks across the glass
        Item {
            visible: KickoffTheme.isArrow
            anchors.fill: parent
            anchors.margins: 1
            clip: true

            Rectangle {
                x: -parent.width * 0.1
                y: -parent.height * 0.5
                width: parent.width * 0.55
                height: parent.height * 2
                rotation: 24
                color: Qt.rgba(1, 1, 1, 0.03)
            }
            Rectangle {
                x: parent.width * 0.58
                y: -parent.height * 0.5
                width: parent.width * 0.18
                height: parent.height * 2
                rotation: 24
                color: Qt.rgba(1, 1, 1, 0.02)
            }
        }

        // Aero glow cap: fixed-height bright zone ending in the waterline cut,
        // not a smooth full-height ramp
        Rectangle {
            visible: KickoffTheme.isArrow
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 1
            }
            height: Kirigami.Units.gridUnit * 4
            radius: Math.max(0, parent.radius - 1)
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.14) }
                GradientStop { position: 0.55; color: Qt.rgba(1, 1, 1, 0.05) }
                GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
            }
        }

        // Bottom vignette: glass weight pooling toward the footer
        Rectangle {
            visible: KickoffTheme.isArrow
            anchors.fill: parent
            anchors.margins: 1
            radius: Math.max(0, parent.radius - 1)
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.7; color: Qt.rgba(0, 0, 0, 0.03) }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.14) }
            }
        }

        // Aero soul: inner light border, the classic double-edge glass frame
        Rectangle {
            visible: KickoffTheme.isArrow
            anchors.fill: parent
            anchors.margins: 1
            radius: Math.max(0, parent.radius - 1)
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.18)
        }

        // Windows 98 side titlebar: navy strip, bold white text reading
        // bottom-to-top, "Distro. user@host" like the old "Windows98" brand
        Rectangle {
            visible: root.classicSideTitle
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
                margins: 3 // stay inside the ClassicBorder bevel
            }
            width: root.sideTitleWidth
            color: KickoffTheme.classicColors ? "#000080" : KickoffTheme.highlightColor

            KCoreAddons.KUser {
                id: sideTitleUser
            }

            Text {
                anchors.centerIn: parent
                rotation: -90
                width: parent.height - Kirigami.Units.smallSpacing * 4
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                text: `${sideTitleUser.os || "Linux"}. ${sideTitleUser.loginName}@${sideTitleUser.host}`
                textFormat: Text.PlainText
                color: KickoffTheme.classicColors ? "#FFFFFF" : KickoffTheme.highlightedTextColor
                font.bold: true
                font.pixelSize: Math.round(root.sideTitleWidth * 0.6)
            }
        }

        ClassicBorder {
            // Windows Classic raised 3D frame around the whole menu
            visible: KickoffTheme.isClassic
            sunken: false
        }
    }

    Item {
        parent: root
        x: root.background.x
        y: root.background.y
        width: root.background.width
        height: root.background.height
        z: 10
        visible: KickoffTheme.isWinStyle && kickoff.inPanel

        Repeater {
            model: [
                { west: true, north: true }, { west: false, north: true },
                { west: true, north: false }, { west: false, north: false }
            ]

            PopupCornerGrip {
                required property var modelData

                west: modelData.west
                north: modelData.north
                x: west ? 0 : parent.width - width
                y: north ? 0 : parent.height - height
                visible: (west ? Plasmoid.location !== PlasmaCore.Types.LeftEdge : Plasmoid.location !== PlasmaCore.Types.RightEdge)
                    && (north ? Plasmoid.location !== PlasmaCore.Types.TopEdge : Plasmoid.location !== PlasmaCore.Types.BottomEdge)
            }
        }
    }

    property alias normalPage: normalPage
    property bool blockingHoverFocus: true
    property var interceptedPosition: null

    /* NOTE: Important things to know about keyboard input handling:
     *
     * - Key events are passed up to parent items until the end is reached.
     * Be mindful of this when using `Keys.forwardTo`.
     *
     * - Keys defaults to BeforeItem while KeyNavigation defaults to AfterItem.
     *
     * - When Keys and KeyNavigation are using the same priority, it seems like
     * the one declared first in the QML file gets priority over the other.
     *
     * - Except for Keys.onPressed, all Keys.on*Pressed signals automatically
     * set `event.accepted = true`.
     *
     * - If you do `item.forceActiveFocus()` and `item` is a focus scope, the
     * children of `item` won't necessarily get focus. It seems like
     * `forceActiveFocus()` is better for forcing a specific thing to be focused
     * while KeyNavigation is better at passing focus down to children of the
     * thing you want to focus when dealing with focus scopes.
     *
     * - KeyNavigation uses BacktabFocusReason (TabFocusReason if mirrored) for left,
     * TabFocusReason (BacktabFocusReason if mirrored) for right,
     * BacktabFocusReason for up and TabFocusReason for down.
     *
     * - KeyNavigation does not seem to respect dynamic changes to focus chain
     * rules in the reverse direction, which can lead to confusing results.
     * It is therefore safer to use Keys for items whose position in the Tab
     * order must be changed on demand. (Tested with Qt 5.15.8 on X11.)
     */

    header: Header {
        id: header
        preferredNameAndIconWidth: normalPage.preferredSideBarWidth
        Binding {
            target: kickoff
            property: "header"
            value: header
            restoreMode: Binding.RestoreBinding
        }
    }

    contentItem: VerticalStackView {
        id: contentItemStackView
        focus: true
        movementTransitionsEnabled: true
        implicitHeight: normalPage.implicitHeight + topPadding + bottomPadding
        implicitWidth: normalPage.implicitWidth + leftPadding + rightPadding
        // Not using a component to prevent it from being destroyed
        initialItem: NormalPage {
            id: normalPage
            objectName: "normalPage"
        }

        Connections {
            target: kickoff
            function onExpandedChanged() {
                if (!kickoff.expanded) {
                    root.blockingHoverFocus = true
                    root.interceptedPosition = null
                }
            }
        }

        Connections {
            target: blockHoverFocusHandler
            enabled: blockHoverFocusHandler.enabled && !root.interceptedPosition
            function onPointChanged() {
                root.interceptedPosition = blockHoverFocusHandler.point.position
            }
        }

        Connections {
            target: blockHoverFocusHandler
            enabled: blockHoverFocusHandler.enabled && root.interceptedPosition && root.blockingHoverFocus
            function onPointChanged() {
                if (blockHoverFocusHandler.point.position === root.interceptedPosition) {
                    return;
                }
                root.blockingHoverFocus = false
            }
        }

        HoverHandler {
            id: blockHoverFocusHandler
            enabled: !contentItemStackView.busy && (!root.interceptedPosition || root.blockingHoverFocus)
        }

        Keys.priority: Keys.AfterItem
        // This is here rather than root because events are implicitly forwarded
        // to parent items. Don't want to send multiple events to searchField.
        Keys.forwardTo: kickoff.searchField


    }

    Loader {
        active: !!kickoff.dragSource.sourceItem
        anchors.fill: parent
        sourceComponent: DropArea {
            id: favoriteRemoveDropArea

            // should be  "as AbstractKickoffItemDelegate", but the type system gets confused when changing view style at runtime
            readonly property Item draggedItem: kickoff.dragSource.sourceItem

            onEntered: event => {
                if (draggedItem?.view.model instanceof Kicker.KAStatsFavoritesModel) {
                    event.accept (Qt.MoveAction)
                    draggedItem.removalPlaceholderActive = true
                } else {
                    event.accepted = false
                }
            }

            onDropped: event => {
                if (draggedItem && kickoff.rootModel.favoritesModel.isFavorite(draggedItem.model.favoriteId) && draggedItem.view.model instanceof Kicker.KAStatsFavoritesModel) {
                    kickoff.rootModel.favoritesModel.removeFavorite(draggedItem.model.favoriteId);
                    event.accept(Qt.MoveAction)
                } else {
                    draggedItem.removalPlaceholderActive = false
                    event.accepted = false
                }
            }

            onExited: {
                if (draggedItem) {
                    draggedItem.removalPlaceholderActive = false
                }
            }
        }
    }

    Component.onCompleted: {
        rootModel.refresh();
    }
}
