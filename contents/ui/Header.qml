/*
    SPDX-FileCopyrightText: 2014 Sebastian Kügler <sebas@kde.org>
    SPDX-FileCopyrightText: 2020 Carl Schwan <carl@carlschwan.eu>
    SPDX-FileCopyrightText: 2021 Mikel Johnson <mikel5764@gmail.com>
    SPDX-FileCopyrightText: 2021 Noah Davis <noahadvs@gmail.com>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PC3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami
import org.kde.coreaddons as KCoreAddons
import org.kde.kcmutils as KCM
import org.kde.config as KConfig
import org.kde.plasma.plasmoid

PlasmaExtras.PlasmoidHeading {
    id: root

    // Arrow hides the header (avatar rides the places column). Classic shows
    // a Windows Classic titlebar up top — unless the side-titlebar setting
    // replaces it, in which case the header only appears while searching.
    visible: {
        if (KickoffTheme.hasInlineControls) {
            return false;
        }
        if (KickoffTheme.isClassic && Plasmoid.configuration.classicSideTitlebar) {
            return kickoff.exposedSearchVisible || kickoff.searchQuery.length > 0;
        }
        return true;
    }

    property alias searchText: searchField.text
    property Item configureButton: configureButton
    property Item pinButton: pinButton
    property Item avatar: avatar
    property real preferredNameAndIconWidth: 0

    contentHeight: KickoffTheme.isClassic ? exposedBanner.implicitHeight
        : (KickoffTheme.hasBanner ? exposedBanner.implicitHeight : layoutContainer.height)
            + kickoff.backgroundMetrics.topPadding
            + kickoff.backgroundMetrics.bottomPadding

    // Classic: the titlebar sits flush like a real Windows Classic caption —
    // bled up over the dialog-frame margin to 3px inside the bevel, no
    // chunky heading padding
    Binding {
        target: root
        property: "topPadding"
        value: -kickoff.backgroundMetrics.topPadding + 3
        when: KickoffTheme.isClassic
        restoreMode: Binding.RestoreBindingOrValue
    }
    Binding {
        target: root
        property: "bottomPadding"
        value: 3
        when: KickoffTheme.isClassic
        restoreMode: Binding.RestoreBindingOrValue
    }
    Binding {
        target: root
        property: "leftPadding"
        value: 0
        when: KickoffTheme.isClassic
        restoreMode: Binding.RestoreBindingOrValue
    }
    Binding {
        target: root
        property: "rightPadding"
        value: 0
        when: KickoffTheme.isClassic
        restoreMode: Binding.RestoreBindingOrValue
    }

    // Exposed (XP) mode: user banner drawn on the highlight color like Luna's
    // blue band, replacing the Plasma heading SVG. Colors from the palette.
    Binding {
        target: root.background
        property: "visible"
        value: false
        when: KickoffTheme.hasBanner
        restoreMode: Binding.RestoreBindingOrValue
    }

    Rectangle {
        parent: root
        z: -1
        // Luna's blue band is exposed-only; classic's search strip sits flat
        // on the silver chrome
        visible: KickoffTheme.isExposed
        // The header sits outside the content area that FullRepresentation
        // widens over the dialog margins, so bleed over them ourselves
        anchors.fill: parent
        anchors.topMargin: -kickoff.backgroundMetrics.topPadding
        anchors.leftMargin: -kickoff.backgroundMetrics.leftPadding
        anchors.rightMargin: -kickoff.backgroundMetrics.rightPadding
        radius: KickoffTheme.borderRadius
        gradient: Gradient {
            GradientStop { position: 0.0; color: KickoffTheme.bandTopColor }
            GradientStop { position: 0.5; color: KickoffTheme.bandMidColor }
            GradientStop { position: 1.0; color: KickoffTheme.bandBottomColor }
        }

        // square off the bottom corners; only the top follows the popup radius
        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            height: parent.radius
            color: KickoffTheme.bandBottomColor
        }

        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: 2
            color: KickoffTheme.grooveDarkColor
        }
    }

    KCoreAddons.KUser {
        id: kuser
    }

    spacing: kickoff.backgroundMetrics.spacing

    function tabSetFocus(event, invertedTarget, normalTarget) {
        // Set input focus depending on whether layout order matches focus chain order
        // normalTarget is optional
        const reason = event.key == Qt.Key_Tab ? Qt.TabFocusReason : Qt.BacktabFocusReason
        if (kickoff.paneSwap) {
            invertedTarget.forceActiveFocus(reason)
        } else if (normalTarget !== undefined) {
            normalTarget.forceActiveFocus(reason)
        } else {
            event.accepted = false
        }
    }

    contentItem: Item {
        // Exposed (XP) banner: big squaround avatar + bold name, and the
        // search bar that stays hidden until the Search places entry reveals it
        ColumnLayout {
            id: exposedBanner
            visible: KickoffTheme.hasBanner
            spacing: Kirigami.Units.smallSpacing
            anchors {
                verticalCenter: parent.verticalCenter
                left: parent.left
                // classic: bleed over the dialog-frame margins like the body
                // columns do, keeping a 3px caption inset; clear the Win98
                // side strip when it's on (search-reveal case)
                leftMargin: (KickoffTheme.isClassic
                        ? -kickoff.backgroundMetrics.leftPadding + 3
                        : kickoff.backgroundMetrics.leftPadding)
                    + (KickoffTheme.isClassic && Plasmoid.configuration.classicSideTitlebar ? KickoffTheme.sideTitleWidth : 0)
                right: parent.right
                rightMargin: KickoffTheme.isClassic
                    ? -kickoff.backgroundMetrics.rightPadding + 3
                    : kickoff.backgroundMetrics.rightPadding
            }

            // Windows Classic titlebar: slim navy bar, bold white name on the
            // left, horizontal 98-style gradient. Classic's default header.
            Rectangle {
                id: classicTitlebar
                visible: KickoffTheme.isClassic && !Plasmoid.configuration.classicSideTitlebar
                Layout.fillWidth: true
                Layout.preferredHeight: Math.round(Kirigami.Units.gridUnit * 1.4)
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: KickoffTheme.bandBottomColor }
                    GradientStop { position: 1.0; color: KickoffTheme.bandTopColor }
                }

                Text {
                    anchors {
                        left: parent.left
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                        leftMargin: Kirigami.Units.smallSpacing * 2
                        rightMargin: Kirigami.Units.smallSpacing * 2
                    }
                    // login name, not the pretty display name
                    text: kuser.loginName
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                    color: KickoffTheme.highlightedTextColor
                    font.bold: true
                    font.pixelSize: Math.round(classicTitlebar.Layout.preferredHeight * 0.55)
                }

                TapHandler {
                    onTapped: KCM.KCMLauncher.openSystemSettings("kcm_users")
                }
            }

            RowLayout {
                // avatar + name row is exposed-only; classic's header is just
                // the search strip
                visible: !KickoffTheme.isClassic
                Layout.topMargin: Kirigami.Units.smallSpacing
                Layout.bottomMargin: Kirigami.Units.smallSpacing
                spacing: Kirigami.Units.smallSpacing * 2

                Rectangle {
                    id: exposedAvatarFrame
                    Layout.preferredWidth: Kirigami.Units.iconSizes.large + Kirigami.Units.smallSpacing * 2
                    Layout.preferredHeight: Layout.preferredWidth
                    radius: Kirigami.Units.smallSpacing
                    color: KickoffTheme.bevelLightColor
                    border.width: 1
                    border.color: KickoffTheme.frameBorderColor

                    Image {
                        id: exposedFaceIcon
                        anchors.fill: parent
                        anchors.margins: Kirigami.Units.smallSpacing / 2
                        source: kuser.faceIconUrl
                        fillMode: Image.PreserveAspectCrop
                        cache: false
                        visible: status === Image.Ready
                    }
                    Kirigami.Icon {
                        anchors.fill: parent
                        anchors.margins: Kirigami.Units.smallSpacing / 2
                        source: "user-identity"
                        visible: !exposedFaceIcon.visible
                    }
                    TapHandler {
                        onTapped: KCM.KCMLauncher.openSystemSettings("kcm_users")
                    }
                }

                Text {
                    font.pixelSize: Math.round(Kirigami.Theme.defaultFont.pixelSize * 1.3)
                    font.bold: true
                    color: KickoffTheme.highlightedTextColor
                    text: kuser.fullName || kuser.loginName
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            PlasmaExtras.SearchField {
                id: exposedSearchField
                Layout.fillWidth: true
                visible: kickoff.exposedSearchVisible || text.length > 0
                placeholderText: i18nc("@info:placeholder as in Windows 7 start menu", "Search programs and files") // qmllint disable unqualified

                // Vanilla Windows search box: hardcoded white (Luna field
                // border on exposed, Classic grey sunken edge on classic)
                readonly property bool vanillaField: KickoffTheme.xpColors || KickoffTheme.classicColors
                Rectangle {
                    z: -1
                    anchors.fill: parent
                    visible: exposedSearchField.vanillaField
                    color: "#FFFFFF"
                    border.width: 1
                    border.color: KickoffTheme.classicColors ? "#808080" : "#7F9DB9"
                }
                Binding {
                    target: exposedSearchField.background
                    property: "visible"
                    value: false
                    when: exposedSearchField.vanillaField
                    restoreMode: Binding.RestoreBindingOrValue
                }
                Binding {
                    target: exposedSearchField
                    property: "color"
                    value: "#000000"
                    when: exposedSearchField.vanillaField
                    restoreMode: Binding.RestoreBindingOrValue
                }
                Binding {
                    target: exposedSearchField
                    property: "placeholderTextColor"
                    value: "#767676"
                    when: exposedSearchField.vanillaField
                    restoreMode: Binding.RestoreBindingOrValue
                }

                Binding {
                    target: kickoff
                    property: "searchField"
                    value: exposedSearchField
                    when: KickoffTheme.hasBanner
                    restoreMode: Binding.RestoreNone
                }
                Connections {
                    target: kickoff
                    function onExpandedChanged() {
                        if (!kickoff.expanded) {
                            exposedSearchField.clear()
                        }
                    }
                }
                onTextEdited: {
                    exposedSearchField.forceActiveFocus(Qt.ShortcutFocusReason)
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
                Keys.onDownPressed: event => {
                    kickoff.contentArea?.forceActiveFocus(Qt.TabFocusReason)
                }
            }
        }

        Item {
            id: layoutContainer
            visible: !KickoffTheme.hasBanner && !KickoffTheme.isMetropolis

            height: Math.max(searchField.implicitHeight, configureButton.implicitHeight)
            anchors {
                verticalCenter: parent.verticalCenter
                left: parent.left
                leftMargin: kickoff.backgroundMetrics.leftPadding
                right: parent.right
                rightMargin: kickoff.backgroundMetrics.rightPadding
            }

            Keys.forwardTo: searchField.activeFocus ? null : searchField

            RowLayout {
                id: nameAndIcon
                spacing: root.spacing
                anchors.left: parent.left
                LayoutMirroring.enabled: kickoff.sideBarOnRight
                height: parent.height
                width: root.preferredNameAndIconWidth - layoutContainer.anchors.leftMargin

                PC3.ToolButton {
                    id: avatar
                    visible: KConfig.KAuthorized.authorizeControlModule("kcm_users")

                    Layout.fillHeight: true
                    Layout.minimumWidth: height
                    Layout.maximumWidth: height

                    text: i18nc("@action:button icon-only, for tooltip/Accessible", "Open user settings") // qmllint disable unqualified
                    contentItem: Item {
                        Image {
                            id: face
                            anchors.fill: parent
                            source: kuser.faceIconUrl
                            fillMode: Image.PreserveAspectCrop
                            // The account image can change without changing its URL.
                            cache: false
                            visible: status === Image.Ready
                        }
                        Kirigami.Icon {
                            anchors.fill: parent
                            source: "user-identity"
                            visible: !face.visible
                        }
                    }

                    Keys.onTabPressed: event => {
                        root.tabSetFocus(event, kickoff.firstCentralPane);
                    }
                    Keys.onBacktabPressed: event => {
                        root.tabSetFocus(event, nextItemInFocusChain());
                    }
                    Keys.onLeftPressed: event => {
                        if (kickoff.sideBarOnRight) {
                            searchField.forceActiveFocus(Application.layoutDirection == Qt.RightToLeft ? Qt.TabFocusReason : Qt.BacktabFocusReason)
                        }
                    }
                    Keys.onRightPressed: event => {
                        if (!kickoff.sideBarOnRight) {
                            searchField.forceActiveFocus(Application.layoutDirection == Qt.RightToLeft ? Qt.BacktabFocusReason : Qt.TabFocusReason)
                        }
                    }
                    Keys.onDownPressed: event => {
                        if (kickoff.sideBar) {
                            kickoff.sideBar.forceActiveFocus(Qt.TabFocusReason)
                        } else {
                            kickoff.contentArea.forceActiveFocus(Qt.TabFocusReason)
                        }
                    }

                    onClicked: KCM.KCMLauncher.openSystemSettings("kcm_users")
                }

                MouseArea {
                    id: nameAndInfoMouseArea
                    hoverEnabled: true

                    Layout.fillHeight: true
                    Layout.fillWidth: true

                    Kirigami.Heading {
                        id: nameLabel
                        anchors.fill: parent
                        opacity: parent.containsMouse ? 0 : 1
                        color: KickoffTheme.isExposed ? KickoffTheme.highlightedTextColor : Kirigami.Theme.textColor
                        level: 4
                        text: kuser.fullName
                        textFormat: Text.PlainText
                        elide: Text.ElideRight
                        horizontalAlignment: kickoff.paneSwap ? Text.AlignRight : Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter

                        Behavior on opacity {
                            NumberAnimation {
                                duration: Kirigami.Units.longDuration
                                easing.type: Easing.InOutQuad
                            }
                        }
                    }

                    Kirigami.Heading {
                        id: infoLabel
                        anchors.fill: parent
                        level: 5
                        opacity: parent.containsMouse ? 1 : 0
                        color: KickoffTheme.isExposed ? KickoffTheme.highlightedTextColor : Kirigami.Theme.textColor
                        text: kuser.os !== "" ? `${kuser.loginName}@${kuser.host} (${kuser.os})` : `${kuser.loginName}@${kuser.host}`
                        textFormat: Text.PlainText
                        elide: Text.ElideRight
                        horizontalAlignment: kickoff.paneSwap ? Text.AlignRight : Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter

                        Behavior on opacity {
                            NumberAnimation {
                                duration: Kirigami.Units.longDuration
                                easing.type: Easing.InOutQuad
                            }
                        }
                    }

                    PC3.ToolTip.text: infoLabel.text
                    PC3.ToolTip.delay: Kirigami.Units.toolTipDelay
                    PC3.ToolTip.visible: infoLabel.truncated && containsMouse
                }
            }
            RowLayout {
                id: rowLayout
                spacing: root.spacing
                height: parent.height
                anchors {
                    left: nameAndIcon.right
                    right: parent.right
                }
                LayoutMirroring.enabled: kickoff.sideBarOnRight
                Keys.onDownPressed: event => {
                    kickoff.contentArea.forceActiveFocus(Qt.TabFocusReason);
                }

                PlasmaExtras.SearchField {
                    id: searchField
                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                    Layout.fillWidth: true
                    Layout.leftMargin: kickoff.backgroundMetrics.leftPadding
                    focus: true

                    Binding {
                        target: kickoff
                        property: "searchField"
                        value: searchField
                        // banner modes (classic, exposed) bind the banner field instead
                        when: !KickoffTheme.isWinStyle
                        // there's only one header ever, so don't waste resources
                        restoreMode: Binding.RestoreNone
                    }
                    Connections {
                        target: kickoff
                        function onExpandedChanged() {
                            if (!kickoff.expanded) {
                                searchField.clear()
                            }
                        }
                    }
                    onTextEdited: {
                        searchField.forceActiveFocus(Qt.ShortcutFocusReason)
                    }
                    Keys.priority: Keys.AfterItem
                    Keys.forwardTo: {
                        if (kickoff.contentArea === null) {
                            return []
                        }
                        if (kickoff.contentArea instanceof ListOfGridsView) {
                            // forward to grid inside of list, or down will skip the whole grid'
                            return [kickoff.contentArea.view.currentItem?.view, kickoff.contentArea.view].filter(item => item)
                        }
                        return kickoff.contentArea.view ?? []
                    }

                    Keys.onTabPressed: event => {
                        tabSetFocus(event, nextItemInFocusChain(false));
                    }
                    Keys.onBacktabPressed: event => {
                        tabSetFocus(event, nextItemInFocusChain());
                    }
                    Keys.onLeftPressed: event => {
                        if (activeFocus) {
                            (sideBarOnRight ? configureButton : avatar).forceActiveFocus(
                                Application.layoutDirection === Qt.RightToLeft ? Qt.TabFocusReason : Qt.BacktabFocusReason)
                        }
                    }
                    Keys.onRightPressed: event => {
                        if (activeFocus) {
                            (sideBarOnRight ? avatar : configureButton).forceActiveFocus(
                                Application.layoutDirection === Qt.RightToLeft ? Qt.BacktabFocusReason : Qt.TabFocusReason)
                        }
                    }
                }

                PC3.ToolButton {
                    id: configureButton
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                    visible: Plasmoid.internalAction("configure").enabled
                    icon.name: "configure"
                    text: Plasmoid.internalAction("configure").text
                    display: PC3.ToolButton.IconOnly

                    PC3.ToolTip.text: text
                    PC3.ToolTip.delay: Kirigami.Units.toolTipDelay
                    PC3.ToolTip.visible: hovered
                    Keys.onTabPressed: event => {
                        tabSetFocus(event, nextItemInFocusChain(false));
                    }
                    Keys.onBacktabPressed: event => {
                        tabSetFocus(event, nextItemInFocusChain());
                    }
                    Keys.onLeftPressed: event => {
                        (kickoff.sideBarOnRight ? pinButton : searchField).forceActiveFocus(
                            Application.layoutDirection == Qt.RightToLeft ? Qt.TabFocusReason : Qt.BacktabFocusReason)
                    }
                    Keys.onRightPressed: event => {
                        (kickoff.sideBarOnRight ? searchField : pinButton).forceActiveFocus(
                            Application.layoutDirection == Qt.RightToLeft ? Qt.BacktabFocusReason : Qt.TabFocusReason)
                    }
                    onClicked: plasmoid.internalAction("configure").trigger()
                }
                PC3.ToolButton {
                    id: pinButton
                    checkable: true
                    checked: Plasmoid.configuration.pin
                    icon.name: "window-pin"
                    text: i18nc("@action:button Pin widget open if it loses focus, icon-only button, for tooltip/Accessible", "Keep Open") // qmllint disable unqualified
                    display: PC3.ToolButton.IconOnly
                    PC3.ToolTip.text: text
                    PC3.ToolTip.delay: Kirigami.Units.toolTipDelay
                    PC3.ToolTip.visible: hovered
                    Binding {
                        target: kickoff
                        property: "hideOnWindowDeactivate"
                        value: !Plasmoid.configuration.pin
                        // there should be no other bindings, so don't waste resources
                        restoreMode: Binding.RestoreNone
                    }
                    Keys.onTabPressed: event => {
                        tabSetFocus(event, nextItemInFocusChain(false), kickoff.firstCentralPane || nextItemInFocusChain());
                    }
                    Keys.onBacktabPressed: event => {
                        tabSetFocus(event, nameAndIcon.nextItemInFocusChain(false), nextItemInFocusChain(false));
                    }
                    Keys.onLeftPressed: event => {
                        if (!kickoff.sideBarOnRight) {
                            nextItemInFocusChain(false).forceActiveFocus(Application.layoutDirection == Qt.RightToLeft ? Qt.TabFocusReason : Qt.BacktabFocusReason)
                        }
                    }
                    Keys.onRightPressed: event => {
                        if (kickoff.sideBarOnRight) {
                            nextItemInFocusChain(false).forceActiveFocus(Application.layoutDirection == Qt.RightToLeft ? Qt.BacktabFocusReason : Qt.TabFocusReason)
                        }
                    }
                    onToggled: Plasmoid.configuration.pin = checked
                }
            }
        }
    }
}
