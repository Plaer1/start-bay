/*
    SPDX-FileCopyrightText: 2011 Martin Gräßlin <mgraesslin@kde.org>
    SPDX-FileCopyrightText: 2012 Marco Martin <mart@kde.org>
    SPDX-FileCopyrightText: 2015-2018 Eike Hein <hein@kde.org>
    SPDX-FileCopyrightText: 2021 Mikel Johnson <mikel5764@gmail.com>
    SPDX-FileCopyrightText: 2021 Noah Davis <noahadvs@gmail.com>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import org.kde.ksvg as KSvg
import org.kde.kirigami as Kirigami
import org.kde.coreaddons as KCoreAddons
import org.kde.kcmutils as KCM
import org.kde.kitemmodels as KItemModels
import org.kde.plasma.components as PC3
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.private.kicker as Kicker
import org.kde.plasma.plasmoid
import org.kde.plasma.workspace.trianglemousefilter

FocusScope {
    id: root

    // Arrow (Win7) sidebar shutdown split button, sharing the classic
    // button's config-backed action history
    readonly property string sideShutdownFavoriteId: Plasmoid.configuration.classicShutdownAction
    property string sideShutdownText: ""

    function sideActionRow(favoriteId: string): int {
        const favoriteIdRole = sideSystemModel.KItemModels.KRoleNames.role("favoriteId");
        for (let i = 0; i < sideSystemModel.rowCount(); i++) {
            if (sideSystemModel.data(sideSystemModel.index(i, 0), favoriteIdRole) === favoriteId) {
                return i;
            }
        }
        return -1;
    }

    function triggerSideAction(favoriteId: string): void {
        const actionRow = sideActionRow(favoriteId);
        if (actionRow >= 0) {
            sideSystemModel.trigger(actionRow, "", null);
        }
        if (kickoff.hideOnWindowDeactivate) {
            kickoff.expanded = false;
        }
    }

    function chooseSideAction(favoriteId: string): void {
        Plasmoid.configuration.classicShutdownAction = favoriteId;
        triggerSideAction(favoriteId);
    }

    function updateSideShutdownText(): void {
        const actionRow = sideActionRow(sideShutdownFavoriteId);
        sideShutdownText = actionRow >= 0
            ? String(sideSystemModel.data(sideSystemModel.index(actionRow, 0), Qt.DisplayRole))
            : i18nc("@action:button", "Shut down") // qmllint disable unqualified
    }

    onSideShutdownFavoriteIdChanged: updateSideShutdownText()
    Component.onCompleted: updateSideShutdownText()

    Kicker.SystemModel {
        id: sideSystemModel
        favoritesModel: kickoff.rootModel.systemFavoritesModel
        onModelReset: root.updateSideShutdownText()
        onRowsInserted: root.updateSideShutdownText()
    }

    PlasmaExtras.Menu {
        id: sideShutdownMenu
        placement: {
            switch (Plasmoid.location) {
            case PlasmaCore.Types.LeftEdge:
            case PlasmaCore.Types.RightEdge:
            case PlasmaCore.Types.TopEdge:
                return PlasmaExtras.Menu.BottomPosedRightAlignedPopup;
            case PlasmaCore.Types.BottomEdge:
            default:
                return PlasmaExtras.Menu.TopPosedRightAlignedPopup;
            }
        }
    }

    Instantiator {
        model: sideSystemModel
        active: KickoffTheme.isArrow
        delegate: PlasmaExtras.MenuItem {
            required property var model

            text: model.display
            icon: model.decoration
            onClicked: {
                root.chooseSideAction(model.favoriteId);
            }
        }
        onObjectAdded: (index, object) => sideShutdownMenu.addMenuItem(object)
        onObjectRemoved: (index, object) => sideShutdownMenu.removeMenuItem(object)
    }

    property real preferredSideBarWidth: implicitSideBarWidth
    property real preferredSideBarHeight: implicitSideBarHeight

    property alias sideBarComponent: sideBarLoader.sourceComponent
    property alias sideBarItem: sideBarLoader.item
    property alias contentAreaComponent: contentAreaLoader.sourceComponent
    property alias contentAreaItem: contentAreaLoader.item
    readonly property Item visibleSearchResults: searchResults.visible ? searchResults : null

    property alias implicitSideBarWidth: sideBarLoader.implicitWidth
    property alias implicitSideBarHeight: sideBarLoader.implicitHeight

    readonly property real preferredProgramsWidth: KickoffTheme.isWinStyle
        ? Math.round(contentAreaLoader.implicitWidth * 4 / 7) : contentAreaLoader.implicitWidth
    implicitWidth: preferredSideBarWidth + separator.implicitWidth + preferredProgramsWidth
    implicitHeight: Math.max(preferredSideBarHeight, contentAreaLoader.implicitHeight)

    readonly property int metropolisFrameInset: KickoffTheme.isMetropolis ? 1 : 0
    readonly property int arrowPaneInset: Math.round(Kirigami.Units.smallSpacing * 1.5)
    readonly property int programsPaneInset: KickoffTheme.isArrow ? arrowPaneInset : metropolisFrameInset

    // Luna/Win7 two-tone columns: tinted places pane for the banner modes,
    // white app pane for all three (arrow leaves the sidebar on its chrome)
    Rectangle {
        anchors.fill: sideBarFilter
        visible: KickoffTheme.hasBanner || KickoffTheme.isMetropolis
        color: KickoffTheme.alternateViewColor
        gradient: KickoffTheme.isExposed ? lunaShade : null

        readonly property Gradient lunaShade: Gradient {
            GradientStop { position: 0; color: Qt.lighter(KickoffTheme.alternateViewColor, 1.05) }
            GradientStop { position: 1; color: KickoffTheme.alternateViewColor }
        }
    }
    // Win7's white app list floats inside the glass pill with a chrome
    // margin on every side, never touching the popup edge
    Rectangle {
        anchors {
            top: contentAreaLoader.top
            left: contentAreaLoader.left
            right: contentAreaLoader.right
            bottom: arrowSearchBox.visible ? arrowSearchBox.bottom : contentAreaLoader.bottom
        }
        visible: KickoffTheme.isWinStyle
        color: KickoffTheme.viewColor
        radius: KickoffTheme.isArrow ? 2 : 0
        border.width: KickoffTheme.isArrow ? 1 : 0
        border.color: Qt.rgba(0, 0, 0, 0.18)

        // Win7 search strip: child of the pane so it always sits exactly
        // inside the pane's border, corner to corner, no seams
        Rectangle {
            visible: KickoffTheme.w7Colors
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                margins: 1
            }
            height: arrowSearchBox.height - 2
            radius: 1
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#FAFCFE" }
                GradientStop { position: 1.0; color: "#EDF1F7" }
            }

            Rectangle {
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                }
                height: 1
                color: "#DDE3EA"
            }
        }
    }

    KCoreAddons.KUser {
        id: basePageUser
    }

    TriangleMouseFilter {
        id: sideBarFilter
        active: Plasmoid.configuration.switchCategoryOnHover
        anchors {
            top: parent.top
            left: parent.left
            bottom: parent.bottom
            topMargin: root.metropolisFrameInset
            leftMargin: root.metropolisFrameInset
            bottomMargin: root.metropolisFrameInset
        }
        LayoutMirroring.enabled: kickoff.sideBarOnRight
        implicitWidth: root.preferredSideBarWidth
        implicitHeight: root.preferredSideBarHeight
        edge: kickoff.sideBarOnRight ? Qt.LeftEdge : Qt.RightEdge
        blockFirstEnter: true

        // Win7 (arrow): framed user picture floating on top of the places column
        Item {
            id: arrowAvatarBox
            visible: KickoffTheme.isArrow
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
            height: visible ? Kirigami.Units.iconSizes.huge + Kirigami.Units.largeSpacing * 2 : 0

            Item {
                id: arrowAvatarFrame
                anchors.centerIn: parent
                width: Kirigami.Units.iconSizes.huge + 16
                height: width

                // soft drop shadow under the frame
                Rectangle {
                    anchors.fill: parent
                    anchors.topMargin: 3
                    anchors.leftMargin: 1
                    anchors.rightMargin: -2
                    anchors.bottomMargin: -4
                    radius: 6
                    color: Qt.rgba(0, 0, 0, 0.35)
                }

                // outer glow rim around the glass
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -1
                    radius: 6
                    color: "transparent"
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.45)
                }

                // chunky Win7 glass frame: sky-tinted, lit from above
                Rectangle {
                    anchors.fill: parent
                    radius: 5
                    border.width: 1
                    border.color: Qt.rgba(0, 0, 0, 0.50)
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#FFFFFF" }
                        GradientStop { position: 0.45; color: "#DCE6F2" }
                        GradientStop { position: 1.0; color: "#A9BED6" }
                    }

                    // bowed sheen: elliptical highlight whose curved bottom
                    // edge crosses the band — the glass pillows, not flat
                    Item {
                        anchors.fill: parent
                        anchors.margins: 1
                        clip: true

                        Rectangle {
                            x: -parent.width * 0.25
                            y: -parent.height * 0.75
                            width: parent.width * 1.5
                            height: parent.height * 1.2
                            radius: width / 2
                            gradient: Gradient {
                                GradientStop { position: 0.45; color: Qt.rgba(1, 1, 1, 0.08) }
                                GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.55) }
                            }
                        }
                    }

                    // dark seam between frame and picture
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 5
                        color: "#FFFFFF"
                        border.width: 1
                        border.color: Qt.rgba(0, 0, 0, 0.40)

                        Image {
                            id: arrowFaceIcon
                            anchors.fill: parent
                            anchors.margins: 1
                            source: basePageUser.faceIconUrl
                            fillMode: Image.PreserveAspectCrop
                            cache: false
                            visible: status === Image.Ready
                        }
                        Kirigami.Icon {
                            anchors.fill: parent
                            anchors.margins: 1
                            source: "user-identity"
                            visible: !arrowFaceIcon.visible
                        }

                        // bowed gloss over the picture, same convex curve
                        Item {
                            anchors.fill: parent
                            anchors.margins: 1
                            clip: true

                            Rectangle {
                                x: -parent.width * 0.25
                                y: -parent.height * 0.9
                                width: parent.width * 1.5
                                height: parent.height * 1.3
                                radius: width / 2
                                gradient: Gradient {
                                    GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.04) }
                                    GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.30) }
                                }
                            }
                        }
                    }

                    TapHandler {
                        onTapped: KCM.KCMLauncher.openSystemSettings("kcm_users")
                    }
                }
            }
        }

        Item {
            id: metropolisAccountBox
            visible: KickoffTheme.isMetropolis
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: visible ? Kirigami.Units.iconSizes.huge + Kirigami.Units.largeSpacing * 2 : 0

            Rectangle {
                anchors.centerIn: parent
                width: Kirigami.Units.iconSizes.huge
                height: width
                color: KickoffTheme.buttonColor

                Image {
                    id: metropolisFace
                    anchors.fill: parent
                    anchors.margins: 2
                    source: basePageUser.faceIconUrl
                    fillMode: Image.PreserveAspectCrop
                    visible: status === Image.Ready
                }

                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: Kirigami.Units.iconSizes.medium
                    height: width
                    source: "user-identity"
                    color: KickoffTheme.sidebarTextColor
                    visible: !metropolisFace.visible
                }

                TapHandler {
                    onTapped: KCM.KCMLauncher.openSystemSettings("kcm_users")
                }
            }
        }

        // Shared power control at the bottom of the places column.
        Item {
            id: sidePowerBox
            visible: KickoffTheme.hasInlineControls
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                // match the white pane's bottom inset so the shutdown button
                // shares the search row's centerline
                bottomMargin: root.arrowPaneInset
            }
            // same height as the search row so the two share a centerline
            height: visible ? arrowSearchBox.height : 0

            Rectangle {
                id: shutdownGroup
                anchors {
                    left: parent.left
                    leftMargin: Kirigami.Units.largeSpacing
                    verticalCenter: parent.verticalCenter
                }
                width: Math.max(0, Math.min(shutdownRow.implicitWidth, parent.width - 2 * Kirigami.Units.largeSpacing))
                height: shutdownRow.implicitHeight
                radius: KickoffTheme.isMetropolis ? KickoffTheme.borderRadius : 3
                color: KickoffTheme.buttonColor
                border.width: 1
                border.color: KickoffTheme.isMetropolis ? Qt.lighter(KickoffTheme.alternateViewColor, 1.3)
                    : (KickoffTheme.w7Colors ? "#16232F" : Qt.darker(KickoffTheme.buttonColor, 2.0))
                gradient: KickoffTheme.isArrow ? aeroPowerGradient : null

                readonly property Gradient aeroPowerGradient: Gradient {
                    GradientStop { position: 0.0; color: KickoffTheme.w7Colors ? "#7D92A8" : Qt.lighter(KickoffTheme.buttonColor, 1.25) }
                    GradientStop { position: 0.5; color: KickoffTheme.w7Colors ? "#54687F" : KickoffTheme.buttonColor }
                    GradientStop { position: 1.0; color: KickoffTheme.w7Colors ? "#33465C" : Qt.darker(KickoffTheme.buttonColor, 1.35) }
                }

                // inner light rim
                Rectangle {
                    visible: KickoffTheme.isArrow
                    anchors.fill: parent
                    anchors.margins: 1
                    radius: 2
                    color: "transparent"
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.30)
                }

                // bowed sheen, same convex glass as the avatar frame
                Item {
                    visible: KickoffTheme.isArrow
                    anchors.fill: parent
                    anchors.margins: 1
                    clip: true

                    Rectangle {
                        x: -parent.width * 0.15
                        y: -parent.height * 0.9
                        width: parent.width * 1.3
                        height: parent.height * 1.35
                        radius: width / 2
                        gradient: Gradient {
                            GradientStop { position: 0.55; color: Qt.rgba(1, 1, 1, 0.06) }
                            GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.34) }
                        }
                    }
                }

                MetropolisPowerMenu {
                    id: metropolisPowerMenu
                    parent: shutdownGroup
                    actionModel: sideSystemModel
                    populate: KickoffTheme.isMetropolis
                    roomAbove: root.height - sidePowerBox.height
                    onActionChosen: favoriteId => root.chooseSideAction(favoriteId)
                }

                RowLayout {
                    id: shutdownRow
                    anchors.fill: parent
                    spacing: 0

                    T.AbstractButton {
                        id: shutdownMainArea
                        hoverEnabled: true
                        activeFocusOnTab: true
                        text: root.sideShutdownText
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        Layout.preferredWidth: shutdownLabel.implicitWidth + Kirigami.Units.largeSpacing * 2
                        Layout.preferredHeight: shutdownLabel.implicitHeight + Kirigami.Units.smallSpacing * 3
                        onClicked: root.triggerSideAction(root.sideShutdownFavoriteId)

                        Rectangle {
                            anchors.fill: parent
                            radius: 3
                            color: KickoffTheme.isMetropolis ? KickoffTheme.highlightColor : "#FFFFFF"
                            opacity: shutdownMainArea.hovered || shutdownMainArea.visualFocus
                                ? (shutdownMainArea.pressed ? 0.10 : 0.20) : 0
                        }
                        PC3.Label {
                            id: shutdownLabel
                            anchors.centerIn: parent
                            width: Math.max(0, parent.width - Kirigami.Units.smallSpacing * 2)
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            text: shutdownMainArea.text
                            color: KickoffTheme.w7Colors ? "#FFFFFF" : KickoffTheme.buttonTextColor
                        }
                    }

                    Rectangle {
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1
                        color: KickoffTheme.isMetropolis ? Qt.lighter(KickoffTheme.alternateViewColor, 1.3) : Qt.rgba(0, 0, 0, 0.45)
                    }

                    T.AbstractButton {
                        id: shutdownArrowArea
                        hoverEnabled: true
                        activeFocusOnTab: true
                        Accessible.name: i18nc("@action:button", "Power and session options")
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 1.4
                        Layout.fillHeight: true
                        onClicked: {
                            if (KickoffTheme.isMetropolis) {
                                metropolisPowerMenu.open();
                            } else {
                                sideShutdownMenu.visualParent = shutdownGroup;
                                sideShutdownMenu.openRelative();
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: 3
                            color: KickoffTheme.isMetropolis ? KickoffTheme.highlightColor : "#FFFFFF"
                            opacity: shutdownArrowArea.hovered || shutdownArrowArea.visualFocus
                                ? (shutdownArrowArea.pressed ? 0.10 : 0.20) : 0
                        }
                        Kirigami.Icon {
                            anchors.centerIn: parent
                            width: Kirigami.Units.iconSizes.small
                            height: width
                            source: KickoffTheme.isMetropolis ? "arrow-up" : "arrow-right"
                            color: KickoffTheme.w7Colors ? "#FFFFFF" : KickoffTheme.buttonTextColor
                        }
                    }
                }
            }
        }

        Loader {
            id: sideBarLoader
            anchors {
                left: parent.left
                right: parent.right
                bottom: sidePowerBox.visible ? sidePowerBox.top : parent.bottom
                top: metropolisAccountBox.visible ? metropolisAccountBox.bottom
                    : (arrowAvatarBox.visible ? arrowAvatarBox.bottom : parent.top)
            }
            // When positioned after the content area, Tab should go to the start of the footer focus chain
            Keys.onTabPressed: event => {
                (kickoff.paneSwap ? kickoff.footer.nextItemInFocusChain() : contentAreaLoader)
                    .forceActiveFocus(Qt.TabFocusReason);
            }
            Keys.onBacktabPressed: event => {
                (kickoff.paneSwap ? contentAreaLoader : kickoff.header.pinButton)
                    .forceActiveFocus(Qt.BacktabFocusReason);
            }
            Keys.onLeftPressed: event => {
                if (kickoff.sideBarOnRight) {
                    contentAreaLoader.forceActiveFocus();
                }
            }
            Keys.onRightPressed: event => {
                if (!kickoff.sideBarOnRight) {
                    contentAreaLoader.forceActiveFocus();
                }
            }
            Keys.onUpPressed: event => {
                kickoff.header.nextItemInFocusChain()
                    .forceActiveFocus(Qt.BacktabFocusReason);
            }
            Keys.onDownPressed: event => {
                (kickoff.paneSwap ? kickoff.footer.leaveButtons.nextItemInFocusChain() : kickoff.footer.tabBar)
                    .forceActiveFocus(Qt.TabFocusReason);
            }
        }
    }
    Item {
        id: separator
        anchors {
            top: parent.top
            left: sideBarFilter.right
            bottom: parent.bottom
            topMargin: root.metropolisFrameInset
            bottomMargin: root.metropolisFrameInset
        }
        LayoutMirroring.enabled: kickoff.sideBarOnRight
        implicitWidth: KickoffTheme.isWinStyle ? 2 : separatorSvg.naturalSize.width
        implicitHeight: implicitWidth

        KSvg.SvgItem {
            id: separatorSvg
            visible: !KickoffTheme.isWinStyle
            anchors.fill: parent
            elementId: "vertical-line"
            svg: KickoffSingleton.lineSvg
        }

        // Column divider groove (palette bevels in classic, Luna blue in XP)
        Rectangle {
            visible: KickoffTheme.isWinStyle
            anchors {
                top: parent.top
                bottom: parent.bottom
                left: parent.left
            }
            width: 1
            color: KickoffTheme.columnSeparatorDarkColor
        }
        Rectangle {
            visible: KickoffTheme.isWinStyle
            anchors {
                top: parent.top
                bottom: parent.bottom
                right: parent.right
            }
            width: 1
            color: KickoffTheme.columnSeparatorLightColor
        }
    }
    // Win7: the search box sits INSIDE the white app column, at its bottom
    Item {
        id: arrowSearchBox
        visible: KickoffTheme.hasInlineControls
        anchors {
            left: contentAreaLoader.left
            right: contentAreaLoader.right
            bottom: parent.bottom
            // keep the glass margin under the white pane too
            bottomMargin: root.arrowPaneInset
        }
        height: visible ? arrowSearchField.height + Kirigami.Units.largeSpacing * 2 : 0

        PC3.TextField {
            id: arrowSearchField
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
                leftMargin: KickoffTheme.isArrow ? Kirigami.Units.smallSpacing * 2 : Kirigami.Units.gridUnit
                rightMargin: arrowSearchField.anchors.leftMargin
            }
            height: Math.round(Kirigami.Units.gridUnit * 1.5)
            leftPadding: Kirigami.Units.smallSpacing * 2
            rightPadding: Kirigami.Units.iconSizes.small + Kirigami.Units.smallSpacing * 3
            verticalAlignment: TextInput.AlignVCenter
            placeholderText: i18nc("@info:placeholder as in Windows 7 start menu", "Search programs and files") // qmllint disable unqualified
            // Win7's placeholder is italic; typed text is not
            font.italic: KickoffTheme.isArrow && text.length === 0

            // Vanilla Win7 search box: compact, white, sunken
            Rectangle {
                z: -1
                anchors.fill: parent
                visible: KickoffTheme.w7Colors || KickoffTheme.isMetropolis
                color: KickoffTheme.isMetropolis ? KickoffTheme.viewColor : "#FFFFFF"
                border.width: 1
                border.color: KickoffTheme.isMetropolis
                    ? (arrowSearchField.activeFocus ? KickoffTheme.highlightColor : KickoffTheme.frameBorderColor)
                    : "#98A8B8"

                // inner top shadow lines give the etched/sunken depth
                Rectangle {
                    visible: KickoffTheme.w7Colors
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                        margins: 1
                    }
                    height: 1
                    color: Qt.rgba(0, 0, 0, 0.10)
                }
                Rectangle {
                    visible: KickoffTheme.w7Colors
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                        topMargin: 2
                        leftMargin: 1
                        rightMargin: 1
                    }
                    height: 1
                    color: Qt.rgba(0, 0, 0, 0.04)
                }
            }

            // magnifier on the right, Win7 style
            Text {
                anchors {
                    right: parent.right
                    rightMargin: Kirigami.Units.smallSpacing * 2
                    verticalCenter: parent.verticalCenter
                }
                visible: KickoffTheme.isArrow
                text: "🔍"
                font.pixelSize: Math.round(arrowSearchField.height * 0.5)
            }
            Kirigami.Icon {
                anchors { right: parent.right; rightMargin: Kirigami.Units.smallSpacing * 2; verticalCenter: parent.verticalCenter }
                visible: KickoffTheme.isMetropolis
                width: Kirigami.Units.iconSizes.small
                height: width
                source: "system-search"
                color: KickoffTheme.textColor
            }

            Binding {
                target: arrowSearchField.background
                property: "visible"
                value: false
                when: KickoffTheme.w7Colors || KickoffTheme.isMetropolis
                restoreMode: Binding.RestoreBindingOrValue
            }
            Binding {
                target: arrowSearchField
                property: "color"
                value: KickoffTheme.textColor
                when: KickoffTheme.w7Colors || KickoffTheme.isMetropolis
                restoreMode: Binding.RestoreBindingOrValue
            }
            Binding {
                target: arrowSearchField
                property: "placeholderTextColor"
                value: KickoffTheme.isMetropolis ? Qt.alpha(KickoffTheme.textColor, 0.64) : "#767676"
                when: KickoffTheme.w7Colors || KickoffTheme.isMetropolis
                restoreMode: Binding.RestoreBindingOrValue
            }

            Binding {
                target: kickoff
                property: "searchField"
                value: arrowSearchField
                when: KickoffTheme.hasInlineControls
                restoreMode: Binding.RestoreNone
            }
            Connections {
                target: kickoff
                function onExpandedChanged() {
                    if (!kickoff.expanded) {
                        arrowSearchField.clear()
                    }
                }
            }
            onTextEdited: {
                arrowSearchField.forceActiveFocus(Qt.ShortcutFocusReason)
            }
            Keys.priority: Keys.AfterItem
            Keys.forwardTo: {
                if (kickoff.contentArea === null) {
                    return []
                }
                if (kickoff.contentArea instanceof ListOfGridsView) {
                    return [kickoff.contentArea.view.currentItem?.view, kickoff.contentArea.view].filter(item => item)
                }
                return kickoff.contentArea.view ?? []
            }
            Keys.onUpPressed: event => {
                kickoff.contentArea?.forceActiveFocus(Qt.BacktabFocusReason)
            }
        }
    }

    Loader {
        id: contentAreaLoader
        focus: true
        clip: KickoffTheme.isWinStyle
        enabled: !kickoff.showingSearch
        visible: !kickoff.showingSearch
        anchors {
            top: parent.top
            left: separator.right
            right: parent.right
            bottom: arrowSearchBox.visible ? arrowSearchBox.top : parent.bottom
            topMargin: root.programsPaneInset
            leftMargin: KickoffTheme.isArrow ? root.arrowPaneInset : 0
            rightMargin: root.programsPaneInset
        }
        LayoutMirroring.enabled: kickoff.sideBarOnRight
        // When positioned after the sidebar, Tab should go to the start of the footer focus chain
        Keys.onTabPressed: event => {
            (kickoff.paneSwap ? sideBarLoader : kickoff.footer.nextItemInFocusChain())
                .forceActiveFocus(Qt.TabFocusReason)
        }
        Keys.onBacktabPressed: event => {
            (kickoff.paneSwap ? kickoff.header.avatar : sideBarLoader)
                .forceActiveFocus(Qt.BacktabFocusReason)
        }
        Keys.onLeftPressed: event => {
            if (!kickoff.sideBarOnRight) {
                sideBarLoader.forceActiveFocus();
            }
        }
        Keys.onRightPressed: event => {
            if (kickoff.sideBarOnRight) {
                sideBarLoader.forceActiveFocus();
            }
        }
        Keys.onUpPressed: event => {
            kickoff.searchField.forceActiveFocus(Qt.BacktabFocusReason);
        }
        Keys.onDownPressed: event => {
            (kickoff.paneSwap ? kickoff.footer.tabBar : kickoff.footer.leaveButtons.nextItemInFocusChain())
                .forceActiveFocus(Qt.TabFocusReason)
        }
    }

    SearchResults {
        id: searchResults
        anchors.fill: contentAreaLoader
        visible: kickoff.showingSearch
        model: kickoff.searchModel
        Keys.onEscapePressed: {
            kickoff.searchField?.clear();
            kickoff.searchField?.forceActiveFocus(Qt.ShortcutFocusReason);
        }
    }
}
