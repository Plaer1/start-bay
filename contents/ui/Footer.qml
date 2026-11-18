/*
 *    SPDX-FileCopyrightText: 2021 Mikel Johnson <mikel5764@gmail.com>
 *    SPDX-FileCopyrightText: 2021 Noah Davis <noahadvs@gmail.com>
 *
 *    SPDX-License-Identifier: GPL-2.0-or-later
 */

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.ksvg as KSvg
import org.kde.plasma.components as PC3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.private.kicker as Kicker
import org.kde.kirigami as Kirigami
import org.kde.kitemmodels as KItemModels
import org.kde.plasma.plasmoid

PlasmaExtras.PlasmoidHeading {
    id: root

    // Arrow (Win7) has no footer at all: search lives in the white column,
    // shutdown lives in the places column
    visible: !KickoffTheme.hasInlineControls

    readonly property alias tabBar: tabBar
    property real preferredTabBarWidth: 0
    readonly property alias leaveButtons: leaveButtons

    contentWidth: KickoffTheme.hasBanner ? exposedLeaveRow.implicitWidth : tabBar.implicitWidth + spacing
    contentHeight: KickoffTheme.hasBanner ? exposedLeaveRow.implicitHeight : leaveButtons.implicitHeight

    function systemActionRow(favoriteId: string): int {
        const favoriteIdRole = classicSystemModel.KItemModels.KRoleNames.role("favoriteId");
        for (let i = 0; i < classicSystemModel.rowCount(); i++) {
            if (classicSystemModel.data(classicSystemModel.index(i, 0), favoriteIdRole) === favoriteId) {
                return i;
            }
        }
        return -1;
    }

    function triggerSystemAction(favoriteId: string): void {
        const actionRow = systemActionRow(favoriteId);
        if (actionRow >= 0) {
            classicSystemModel.trigger(actionRow, "", null);
        }
        if (kickoff.hideOnWindowDeactivate) {
            kickoff.expanded = false;
        }
    }

    Kicker.SystemModel {
        id: classicSystemModel
        favoritesModel: kickoff.rootModel.systemFavoritesModel
    }

    // Windows-like modes replace the Plasma heading SVG: classic gets a flat
    // footer on the window color, exposed gets the Luna gradient band
    Binding {
        target: root.background
        property: "visible"
        value: false
        when: KickoffTheme.isWinStyle
        restoreMode: Binding.RestoreBindingOrValue
    }

    Rectangle {
        parent: root
        z: -1
        visible: KickoffTheme.isExposed
        anchors.fill: parent
        radius: KickoffTheme.borderRadius
        gradient: Gradient {
            GradientStop { position: 0.0; color: KickoffTheme.bandTopColor }
            GradientStop { position: 0.5; color: KickoffTheme.bandMidColor }
            GradientStop { position: 1.0; color: KickoffTheme.bandBottomColor }
        }

        // square off the top corners; only the bottom follows the popup radius
        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
            }
            height: parent.radius
            color: KickoffTheme.bandTopColor
        }
    }

    Rectangle {
        visible: KickoffTheme.isClassic
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            leftMargin: 3 - root.leftPadding
            rightMargin: 3 - root.rightPadding
            topMargin: -root.topPadding
        }
        height: 1
        color: KickoffTheme.bevelDarkColor

        Rectangle {
            anchors.top: parent.bottom
            width: parent.width
            height: 1
            color: KickoffTheme.bevelLightColor
        }
    }

    // We use an increased vertical padding to improve touch usability.
    // Classic bleeds the bottom over the dialog-frame margin so the button
    // row lines up 3px inside the bevel, mirroring the titlebar up top.
    leftPadding: kickoff.backgroundMetrics.leftPadding
    rightPadding: kickoff.backgroundMetrics.rightPadding
    topPadding: Kirigami.Units.smallSpacing * 2
    bottomPadding: KickoffTheme.isClassic
        ? -kickoff.backgroundMetrics.bottomPadding + Kirigami.Units.smallSpacing
        : Kirigami.Units.smallSpacing * 2

    topInset: 0
    leftInset: 0
    rightInset: 0
    bottomInset: 0

    spacing: kickoff.backgroundMetrics.spacing
    position: PC3.ToolBar.Footer

    PC3.TabBar {
        id: tabBar
        visible: !KickoffTheme.isWinStyle

        property real tabWidth: Math.max(applicationsTab.implicitWidth, placesTab.implicitWidth)

        focus: true

        width: KickoffTheme.isWinStyle ? 0 : (root.preferredTabBarWidth > 0 ? root.preferredTabBarWidth : undefined)
        implicitWidth: KickoffTheme.isWinStyle ? 0 : (contentWidth + leftPadding + rightPadding)
        implicitHeight: KickoffTheme.isWinStyle ? 0 : (contentHeight + topPadding + bottomPadding)

        // This is needed to keep the separators horizontally aligned
        leftPadding: mirrored ? root.spacing : 0
        rightPadding: !mirrored ? root.spacing : 0

        anchors {
            top: parent.top
            left: parent.left
            bottom: parent.bottom
        }

        position: PC3.TabBar.Footer

        contentItem: ListView {
            id: tabBarListView
            focus: true
            model: tabBar.contentModel
            currentIndex: tabBar.currentIndex

            spacing: tabBar.spacing
            orientation: ListView.Horizontal
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.AutoFlickIfNeeded
            snapMode: ListView.SnapToItem

            highlightMoveDuration: Kirigami.Units.longDuration
            highlightRangeMode: ListView.ApplyRange
            preferredHighlightBegin: tabBar.tabWidth
            preferredHighlightEnd: width - tabBar.tabWidth
            highlight: KSvg.FrameSvgItem {
                anchors.top: tabBarListView.contentItem.top
                anchors.bottom: tabBarListView.contentItem.bottom
                anchors.topMargin: -root.topPadding
                anchors.bottomMargin: -root.bottomPadding
                imagePath: "widgets/tabbar"
                prefix: tabBar.position === PC3.TabBar.Header ? "north-active-tab" : "south-active-tab"
            }
            keyNavigationEnabled: false
        }

        PC3.TabButton {
            id: applicationsTab
            focus: true
            width: tabBar.tabWidth
            anchors.top: tabBarListView.contentItem.top
            anchors.bottom: tabBarListView.contentItem.bottom
            anchors.topMargin: -root.topPadding
            anchors.bottomMargin: -root.bottomPadding
            icon.width: Kirigami.Units.iconSizes.smallMedium
            icon.height: Kirigami.Units.iconSizes.smallMedium
            icon.name: "applications-all-symbolic"
            text: i18nc("@title:tab kickoff sidebar tab", "Applications") // qmllint disable unqualified
            Keys.onBacktabPressed: event => {
                (kickoff.lastCentralPane || nextItemInFocusChain(false))
                    .forceActiveFocus(Qt.BacktabFocusReason)
            }
        }
        PC3.TabButton {
            id: placesTab
            width: tabBar.tabWidth
            anchors.top: tabBarListView.contentItem.top
            anchors.bottom: tabBarListView.contentItem.bottom
            anchors.topMargin: -root.topPadding
            anchors.bottomMargin: -root.bottomPadding
            icon.width: Kirigami.Units.iconSizes.smallMedium
            icon.height: Kirigami.Units.iconSizes.smallMedium
            icon.name: "compass"
            text: i18nc("@title:tab kickoff sidebar tab", "Places") //Explore? // qmllint disable unqualified
        }

        Connections {
            target: kickoff
            function onExpandedChanged() {
                if (!kickoff.expanded) {
                    tabBar.currentIndex = 0
                }
            }
        }

        Keys.onPressed: event => {
            const Key_Next = Application.layoutDirection === Qt.RightToLeft ? Qt.Key_Left : Qt.Key_Right
            const Key_Prev = Application.layoutDirection === Qt.RightToLeft ? Qt.Key_Right : Qt.Key_Left
            if (event.key === Key_Next) {
                if (currentIndex === count - 1) {
                    leaveButtons.nextItemInFocusChain().forceActiveFocus(Qt.TabFocusReason)
                } else {
                    incrementCurrentIndex()
                    currentItem.forceActiveFocus(Qt.TabFocusReason)
                }
                event.accepted = true
            } else if (event.key === Key_Prev && currentIndex > 0) {
                decrementCurrentIndex()
                currentItem.forceActiveFocus(Qt.BacktabFocusReason)
                event.accepted = true
            }
        }
        Keys.onUpPressed: event => {
            kickoff.firstCentralPane.forceActiveFocus(Qt.BacktabFocusReason);
        }
    }

    LeaveButtons {
        id: leaveButtons
        visible: !KickoffTheme.isWinStyle

        anchors {
            top: parent.top
            right: parent.right
            bottom: parent.bottom
        }

        // available width for leaveButtons
        maximumWidth: root.availableWidth - tabBar.width - root.spacing

        Keys.onUpPressed: event => {
            kickoff.lastCentralPane.forceActiveFocus(Qt.BacktabFocusReason);
        }
    }

    // Banner-mode footer (classic and exposed): thick Luna action bar with
    // badge icon buttons. Exposed adds the zzz button (hibernates by default;
    // a setting flips it to sleep); classic pairs Log Off with Turn Off
    // Computer like the reference menu.
    RowLayout {
        id: exposedLeaveRow
        visible: KickoffTheme.hasBanner
        anchors.fill: parent
        // classic: bleed over the dialog-frame margins so the buttons line up
        // with the body columns, 3px inside the bevel like the titlebar
        anchors.leftMargin: KickoffTheme.isClassic ? -root.leftPadding + 3 : 0
        anchors.rightMargin: KickoffTheme.isClassic ? -root.rightPadding + 3 : 0
        spacing: Kirigami.Units.largeSpacing

        Item {
            Layout.fillWidth: true
        }

        XpLeaveButton {
            readonly property bool sleeps: Plasmoid.configuration.exposedSleepButton
            icon.source: Qt.resolvedUrl(KickoffTheme.isClassic
                ? "../images/hibernate-zzz-classic.svg" : "../images/hibernate-zzz.svg")
            text: sleeps ? i18nc("@action:button", "Sleep") : i18nc("@action:button", "Hibernate") // qmllint disable unqualified
            favoriteId: sleeps ? "suspend" : "hibernate"
            display: KickoffTheme.isExposed ? PC3.AbstractButton.IconOnly : PC3.AbstractButton.TextBesideIcon
        }
        XpLeaveButton {
            icon.source: Qt.resolvedUrl(KickoffTheme.isClassic
                ? "../images/logoff-key-classic.svg" : "../images/logoff-key.svg")
            text: i18nc("@action:button", "Log Off") // qmllint disable unqualified
            favoriteId: "logout"
        }
        XpLeaveButton {
            icon.source: Qt.resolvedUrl(KickoffTheme.isClassic
                ? "../images/shutdown-power-classic.svg" : "../images/shutdown-power.svg")
            text: i18nc("@action:button", "Turn Off Computer") // qmllint disable unqualified
            favoriteId: "shutdown"
        }
    }

    component XpLeaveButton: PC3.ToolButton {
        property string favoriteId
        Kirigami.Theme.inherit: false
        Kirigami.Theme.textColor: KickoffTheme.isExposed
            ? KickoffTheme.highlightedTextColor : KickoffTheme.textColor
        Layout.fillWidth: true
        Layout.minimumWidth: icon.width + leftPadding + rightPadding
        Layout.maximumWidth: implicitWidth
        clip: true
        icon.width: Kirigami.Units.iconSizes.medium
        icon.height: Kirigami.Units.iconSizes.medium
        font.bold: true
        display: PC3.AbstractButton.TextBesideIcon
        PC3.ToolTip.text: text
        PC3.ToolTip.visible: hovered && (display === PC3.AbstractButton.IconOnly || width < implicitWidth)
        onClicked: root.triggerSystemAction(favoriteId)
        Keys.onUpPressed: event => {
            kickoff.lastCentralPane.forceActiveFocus(Qt.BacktabFocusReason);
        }
    }

    Behavior on height {
        enabled: kickoff.expanded
        NumberAnimation {
            duration: Kirigami.Units.longDuration
            easing.type: Easing.InQuad
        }
    }

    // Using item containing WheelHandler instead of MouseArea because
    // MouseArea doesn't keep track to the total amount of rotation.
    // Keeping track of the total amount of rotation makes it work
    // better for touch pads.
    Item {
        id: mouseItem
        parent: root
        anchors.left: parent.left
        height: root.height
        width: tabBar.width
        z: 1 // Has to be above contentItem to receive mouse wheel events
        WheelHandler {
            id: tabScrollHandler
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: {
                const shouldDec = rotation >= 15
                const shouldInc = rotation <= -15
                const shouldReset = (rotation > 0 && tabBar.currentIndex === 0) || (rotation < 0 && tabBar.currentIndex === tabBar.count - 1)
                if (shouldDec) {
                    tabBar.decrementCurrentIndex();
                    rotation = 0
                } else if (shouldInc) {
                    tabBar.incrementCurrentIndex();
                    rotation = 0
                } else if (shouldReset) {
                    rotation = 0
                }
            }
        }
    }

    Shortcut {
        sequences: ["Ctrl+Tab", "Ctrl+Shift+Tab", StandardKey.NextChild, StandardKey.PreviousChild]
        onActivated: {
            tabBar.currentIndex = (tabBar.currentIndex === 0) ? 1 : 0;
        }
    }
}
