/*
    SPDX-FileCopyrightText: 2011 Martin Gräßlin <mgraesslin@kde.org>
    SPDX-FileCopyrightText: 2012 Gregor Taetzner <gregor@freenet.de>
    SPDX-FileCopyrightText: 2012 Marco Martin <mart@kde.org>
    SPDX-FileCopyrightText: 2013 David Edmundson <davidedmundson@kde.org>
    SPDX-FileCopyrightText: 2015 Eike Hein <hein@kde.org>
    SPDX-FileCopyrightText: 2021 Mikel Johnson <mikel5764@gmail.com>
    SPDX-FileCopyrightText: 2021 Noah Davis <noahadvs@gmail.com>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtCore
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.ksvg as KSvg
import org.kde.plasma.components as PC3
import org.kde.plasma.private.kicker as Kicker
import org.kde.kirigami as Kirigami

import "code/tools.js" as Tools
import "code/programGrouping.js" as ProgramGrouping

PlasmoidItem {
    id: kickoff

    width: Kirigami.Units.iconSizes.huge
    height: Kirigami.Units.iconSizes.huge

    switchWidth: fullRepresentationItem ? fullRepresentationItem.Layout.minimumWidth : Kirigami.Units.iconSizes.huge * 10
    switchHeight: fullRepresentationItem ? fullRepresentationItem.Layout.minimumHeight : Kirigami.Units.iconSizes.huge * 10

    Binding {
        target: KickoffTheme
        property: "menuStyle"
        value: Plasmoid.configuration.menuStyle
    }
    Binding {
        target: KickoffTheme
        property: "configShowDescriptionsInline"
        value: Plasmoid.configuration.showDescriptionsInline
    }
    Binding {
        target: KickoffTheme
        property: "classicResponsive"
        value: Plasmoid.configuration.classicThemeResponsive
    }
    Binding {
        target: KickoffTheme
        property: "exposedResponsive"
        value: Plasmoid.configuration.exposedThemeResponsive
    }
    Binding {
        target: KickoffTheme
        property: "arrowResponsive"
        value: Plasmoid.configuration.arrowThemeResponsive
    }
    Binding {
        target: KickoffTheme
        property: "arrowTransparent"
        value: Plasmoid.configuration.arrowTransparent
    }
    Binding {
        target: KickoffTheme
        property: "arrowAeroColor"
        value: Plasmoid.configuration.arrowAeroColor
    }
    Binding {
        target: KickoffTheme
        property: "metropolisAccent"
        value: Plasmoid.configuration.metropolisAccent
    }

    // The properties are defined here instead of the singleton because each
    // instance of Kickoff requires different instances of these properties

    readonly property bool inPanel: [
        PlasmaCore.Types.TopEdge,
        PlasmaCore.Types.RightEdge,
        PlasmaCore.Types.BottomEdge,
        PlasmaCore.Types.LeftEdge,
    ].includes(Plasmoid.location)
    readonly property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical

    // Used to prevent the width from changing frequently when the scrollbar appears or disappears
    readonly property bool mayHaveGridWithScrollBar: Plasmoid.configuration.applicationsDisplay === 0
        || (Plasmoid.configuration.favoritesDisplay === 0 && kickoff.rootModel.favoritesModel.count > minimumGridRowCount * minimumGridRowCount)

    //BEGIN Models
    readonly property Kicker.RootModel rootModel: Kicker.RootModel {
        autoPopulate: false

        // TODO: appletInterface property now can be ported to "applet" and have the real Applet* assigned directly
        appletInterface: kickoff

        appNameFormat: Plasmoid.configuration.appNameFormat
        flat: true // have categories, but no subcategories
        sorted: Plasmoid.configuration.alphaSort
        showSeparators: !sorted && Plasmoid.configuration.applicationsDisplay != 0
        showRootSeparator: true
        showTopLevelItems: true

        showAllApps: true
        showAllAppsCategorized: false
        showRecentApps: false
        showRecentDocs: false
        showPowerSession: false
        showFavoritesPlaceholder: true
        highlightNewlyInstalledApps: Plasmoid.configuration.highlightNewlyInstalledApps

        Component.onCompleted: {
            favoritesModel.initForClient("org.kde.plasma.kickoff.favorites.instance-" + Plasmoid.id)

            if (!Plasmoid.configuration.favoritesPortedToKAstats) {
                if (favoritesModel.count < 1) {
                    favoritesModel.portOldFavorites(Plasmoid.configuration.favorites);
                }
                Plasmoid.configuration.favoritesPortedToKAstats = true;
            }
        }
    }

    readonly property Kicker.RunnerModel runnerModel: Kicker.RunnerModel {
        query: kickoff.searchQuery
        onRequestUpdateQuery: query => {
            if (kickoff.searchField) {
                kickoff.searchField.text = query;
            }
        }
        // An empty runner list uses the plugins enabled in Plasma Search.
        appletInterface: kickoff
        mergeResults: true
        favoritesModel: kickoff.rootModel.favoritesModel
    }

    readonly property string searchQuery: kickoff.searchField ? kickoff.searchField.text : ""
    readonly property bool showingSearch: searchQuery.trim().length > 0
    property alias catalog: applicationCatalog
    property alias programEdits: programEdits
    property alias searchModel: searchAdapter.model

    Catalog {
        id: applicationCatalog
        rootModel: kickoff.rootModel
    }

    ProgramEdits {
        id: programEdits
        configuration: Plasmoid.configuration
        providerEntries: applicationCatalog.entries
        baseEntries: ProgramGrouping.project(applicationCatalog.entries, {
            groupProgramsByCategory: Plasmoid.configuration.groupProgramsByCategory,
            groupWine: Plasmoid.configuration.groupWine,
            groupDevelopment: Plasmoid.configuration.groupDevelopment,
            groupEducation: Plasmoid.configuration.groupEducation,
            groupGames: Plasmoid.configuration.groupGames,
            groupGraphics: Plasmoid.configuration.groupGraphics,
            groupInternet: Plasmoid.configuration.groupInternet,
            groupMultimedia: Plasmoid.configuration.groupMultimedia,
            groupOffice: Plasmoid.configuration.groupOffice,
            groupScience: Plasmoid.configuration.groupScience,
            showLinuxTools: Plasmoid.configuration.showLinuxTools
        }, i18n("Linux Tools"))
    }

    SearchModel {
        id: searchAdapter
        catalog: applicationCatalog
        entries: programEdits.entries
        runnerModel: kickoff.runnerModel
        query: kickoff.searchQuery
    }

    readonly property Kicker.ComputerModel computerModel: Kicker.ComputerModel {
        appletInterface: kickoff
        favoritesModel: kickoff.rootModel.favoritesModel
        systemApplications: Plasmoid.configuration.systemApplications
        Component.onCompleted: {
            //systemApplications = Plasmoid.configuration.systemApplications;
        }
    }

    readonly property alias recentUsageModel: recentUsageModel
    Kicker.RecentUsageModel {
        id: recentUsageModel
        favoritesModel: kickoff.rootModel.favoritesModel
    }

    readonly property alias frequentUsageModel: frequentUsageModel
    Kicker.RecentUsageModel {
        id: frequentUsageModel
        favoritesModel: kickoff.rootModel.favoritesModel
        ordering: 1 // Popular / Frequently Used
    }
    //END

    //BEGIN UI elements
    // Set in FullRepresentation.qml
    property Item header: null

    // Set in Header.qml
    // QTBUG Using PC3.TextField as type makes assignment fail
    // "Cannot assign QObject* to TextField_QMLTYPE_8*"
    property Item searchField: null

    // Set in FullRepresentation.qml, ApplicationPage.qml, PlacesPage.qml
    property Item sideBar: null // is null when searching
    property Item contentArea: null // is searchView when searching

    // Set in NormalPage.qml
    property Item footer: null
    property int pageIndex: 0

    // True when central pane (and header) LayoutMirroring diverges from global
    // LayoutMirroring, in order to achieve the desired sidebar position
    readonly property bool paneSwap: Plasmoid.configuration.paneSwap
    readonly property bool sideBarOnRight: (Application.layoutDirection == Qt.RightToLeft) != paneSwap
    // References to items according to their focus chain order
    readonly property Item firstHeaderItem: header && !KickoffTheme.isWinStyle ? (paneSwap ? header.pinButton : header.avatar) : null
    readonly property Item lastHeaderItem: header && !KickoffTheme.isWinStyle ? (paneSwap ? header.avatar : header.pinButton) : null

    // Exposed (XP) mode: search bar hidden until the Search places entry is used
    property bool exposedSearchVisible: false
    readonly property Item firstCentralPane: paneSwap ? contentArea : sideBar
    readonly property Item lastCentralPane: paneSwap ? sideBar : contentArea

    readonly property Item dragSource: Item {
        id: dragSource // BUG 449426
        property Item sourceItem
        Drag.dragType: Drag.Automatic
        Drag.supportedActions: Qt.CopyAction | Qt.LinkAction | Qt.MoveAction
    }
    //END

    //BEGIN Metrics
    readonly property KSvg.FrameSvgItem backgroundMetrics: KSvg.FrameSvgItem {
        // Inset defaults to a negative value when not set by margin hints
        readonly property real leftPadding: Math.round(margins.left - Math.max(inset.left, 0))
        readonly property real rightPadding: Math.round(margins.right - Math.max(inset.right, 0))
        readonly property real topPadding: Math.round(margins.top - Math.max(inset.top, 0))
        readonly property real bottomPadding: Math.round(margins.bottom - Math.max(inset.bottom, 0))
        readonly property real spacing: Math.round(leftPadding)
        visible: false
        imagePath: Plasmoid.formFactor === PlasmaCore.Types.Planar ? "widgets/background" : "dialogs/background"
    }

    // This is here rather than in the singleton with the other metrics items
    // because the list delegate's height depends on a configuration setting
    // and the singleton can't access those
    readonly property real listDelegateHeight: listDelegate.height
    KickoffListDelegate {
        id: listDelegate
        visible: false
        enabled: false
        model: null
        index: -1
        text: "asdf"
        url: ""
        decoration: "start-here-kde"
        description: "asdf"
        action: null
        indicator: null
    }

    // Used to show smaller Kickoff on small screens
    readonly property int minimumGridRowCount: Math.min(Screen.desktopAvailableWidth, Screen.desktopAvailableHeight) * Screen.devicePixelRatio < KickoffSingleton.gridCellSize * 4 + (fullRepresentationItem ? fullRepresentationItem.normalPage.preferredSideBarWidth : KickoffSingleton.gridCellSize * 2) ? 2 : 4
    //END

    readonly property string compactIcon: Tools.compactIcon(Plasmoid.configuration.menuStyle, Plasmoid.configuration.icon)
    Plasmoid.icon: Tools.isLocalIconPath(compactIcon)
        ? Qt.resolvedUrl(Tools.compactIconFileUrl(compactIcon)).toString()
        : compactIcon

    // Aero glass: translucent popup background + KWin blur behind the menu
    Plasmoid.backgroundHints: KickoffTheme.isArrow && KickoffTheme.arrowTransparent
        ? PlasmaCore.Types.TranslucentBackground : PlasmaCore.Types.StandardBackground

    preferredRepresentation: compactRepresentation

    fullRepresentation: FullRepresentation { focus: true }

    // Only exists because the default CompactRepresentation doesn't:
    // - open on drag
    // - allow defining a custom drop handler
    // - expose the ability to show text below or beside the icon
    // TODO remove once it gains those features
    compactRepresentation: MouseArea {
        id: compactRoot
        Layout.leftMargin: 0

        readonly property int iconSize: 40
        readonly property int panelHeight: kickoff.inPanel && parent
            ? Math.max(1, Math.round(kickoff.vertical ? parent.width : parent.height)) : iconSize
        readonly property string launcherLabel: KickoffTheme.hasInlineControls ? ""
            : (Plasmoid.configuration.menuLabel
                || (KickoffTheme.isExposed ? i18nc("@label compact Luna launcher button", "START")
                    : (KickoffTheme.isClassic ? i18nc("@label compact launcher button", "Start") : "")))
        readonly property bool shouldHaveLabel: !kickoff.vertical && launcherLabel.length > 0
        readonly property bool showingAeroOrb: kickoff.compactIcon === Tools.aeroStartIcon
        readonly property int labelStartMargin: Math.max(2, Math.round(panelHeight * 0.08))
        readonly property int labelEndMargin: Math.round(panelHeight * 0.13)
        readonly property real preferredLabelWidth: shouldHaveLabel
            ? Math.min(labelMetrics.advanceWidth, panelHeight * 6) + labelStartMargin + labelEndMargin : 0
        readonly property bool activeFace: containsMouse || compactDragArea.containsDrag

        FontLoader {
            id: lunaStartFont
            source: Qt.resolvedUrl("../fonts/ComicClankSlab-Bold.otf")
        }

        TextMetrics {
            id: labelMetrics
            font: labelTextField.font
            text: compactRoot.launcherLabel
        }

        implicitWidth: panelHeight + preferredLabelWidth
        implicitHeight: panelHeight

        Layout.preferredWidth: implicitWidth
        Layout.preferredHeight: implicitHeight
        Layout.minimumWidth: panelHeight + (shouldHaveLabel ? Math.min(preferredLabelWidth, panelHeight * 1.5) : 0)
        Layout.minimumHeight: panelHeight

        hoverEnabled: true

        property bool wasExpanded
        // Tracked manually: MouseArea.pressed can latch when the popup grabs
        // the release event, leaving the pill stuck in its depressed shade
        property bool pillHeld: false

        Accessible.name: Plasmoid.title
        Accessible.role: Accessible.Button

        onPressed: {
            wasExpanded = kickoff.expanded
            pillHeld = true
        }
        onReleased: pillHeld = false
        onCanceled: pillHeld = false
        onClicked: kickoff.expanded = !wasExpanded

        DropArea {
            id: compactDragArea
            anchors.fill: parent
            onEntered: drag => {
                if (drag.hasUrls) {
                    expandOnDragTimer.start()
                }
            }
            onExited: expandOnDragTimer.stop()
        }

        Timer {
            id: expandOnDragTimer
            // this is an interaction and not an animation, so we want it as a constant
            interval: 250
            onTriggered: kickoff.expanded = true
        }

        // Classic taskbar Start button: raised grey face that goes sunken
        // while held or while the menu is open. Vanilla mode wears the Luna
        // taskbar grey; responsive follows the scheme's button colors.
        Rectangle {
            id: classicStartFace
            visible: KickoffTheme.isClassic
            anchors.fill: parent

            readonly property bool sunken: compactRoot.pillHeld || kickoff.expanded
            readonly property color hilite: KickoffTheme.bevelLightColor
            readonly property color shadow: KickoffTheme.bevelDarkColor

            color: {
                // Windows Classic silver, matching the menu chrome
                const base = KickoffTheme.buttonColor;
                return sunken ? Qt.darker(base, 1.06) : base;
            }

            Rectangle {
                anchors { left: parent.left; right: parent.right; top: parent.top }
                height: 1
                color: classicStartFace.sunken ? classicStartFace.shadow : classicStartFace.hilite
            }
            Rectangle {
                anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                width: 1
                color: classicStartFace.sunken ? classicStartFace.shadow : classicStartFace.hilite
            }
            Rectangle {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: 1
                color: classicStartFace.sunken ? classicStartFace.hilite : classicStartFace.shadow
            }
            Rectangle {
                anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
                width: 1
                color: classicStartFace.sunken ? classicStartFace.hilite : classicStartFace.shadow
            }
        }

        // XP Luna start pill: green gradient, square left edge, blunt rounded
        // right cap. k darkens while the button is actually held, lightens on
        // hover; never latches while the menu is open.
        Rectangle {
            id: xpPill
            visible: KickoffTheme.isExposed
            anchors.fill: parent
            radius: height * 0.45
            antialiasing: true
            // depressed while held AND for as long as the menu stays open, like XP
            readonly property real k: (compactRoot.pillHeld || kickoff.expanded) ? 1.3 : (compactRoot.containsMouse ? 0.9 : 1.0)
            // Vanilla Luna greens; theme-responsive derives the pill from the
            // scheme's positive-text color instead
            readonly property color pos: Kirigami.Theme.positiveTextColor
            readonly property color c0: KickoffTheme.xpColors ? "#9FE07C" : Qt.lighter(pos, 1.55)
            readonly property color c1: KickoffTheme.xpColors ? "#57C63A" : Qt.lighter(pos, 1.15)
            readonly property color c2: KickoffTheme.xpColors ? "#3BAB24" : pos
            readonly property color c3: KickoffTheme.xpColors ? "#257C13" : Qt.darker(pos, 1.4)
            gradient: faceGradient
            readonly property Gradient faceGradient: Gradient {
                GradientStop { position: 0.0; color: Qt.darker(xpPill.c0, xpPill.k) }
                GradientStop { position: 0.18; color: Qt.darker(Qt.lighter(xpPill.c1, 1.12), xpPill.k) }
                GradientStop { position: 0.38; color: Qt.darker(xpPill.c1, xpPill.k) }
                GradientStop { position: 0.6; color: Qt.darker(xpPill.c2, xpPill.k) }
                GradientStop { position: 1.0; color: Qt.darker(xpPill.c3, xpPill.k) }
            }

            Rectangle {
                anchors {
                    left: parent.left
                    top: parent.top
                    bottom: parent.bottom
                }
                width: xpPill.radius
                gradient: xpPill.faceGradient
            }
        }

        Rectangle {
            id: aeroStartFace
            visible: KickoffTheme.isArrow && !compactRoot.showingAeroOrb
            anchors.fill: parent
            anchors.margins: 1
            radius: height / 2
            antialiasing: true

            readonly property bool sunken: compactRoot.pillHeld || kickoff.expanded
            readonly property color glass: KickoffTheme.w7Colors
                ? Qt.darker(KickoffTheme.aeroBaseColor, 2.8)
                : Qt.darker(KickoffTheme.buttonColor, 1.9)
            readonly property real sheen: sunken ? 1.05 : (compactRoot.activeFace ? 1.6 : 1.35)

            border.width: 1
            border.color: Qt.lighter(glass, compactRoot.activeFace ? 2 : 1.55)
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.lighter(aeroStartFace.glass, aeroStartFace.sheen) }
                GradientStop { position: 0.5; color: aeroStartFace.glass }
                GradientStop { position: 0.51; color: Qt.darker(aeroStartFace.glass, 1.28) }
                GradientStop { position: 1; color: Qt.lighter(aeroStartFace.glass, 1.15) }
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: 2
                radius: height / 2
                color: "transparent"
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.16)
                antialiasing: true
            }
        }

        Rectangle {
            visible: KickoffTheme.isMetropolis
            anchors.fill: parent
            anchors.margins: 1
            color: compactRoot.pillHeld || kickoff.expanded
                ? Qt.darker(KickoffTheme.alternateViewColor, 1.2)
                : (compactRoot.activeFace ? KickoffTheme.buttonColor : KickoffTheme.alternateViewColor)
            border.width: 1
            border.color: Qt.lighter(KickoffTheme.alternateViewColor, 1.3)
        }

        RowLayout {
            anchors.fill: parent
            spacing: 0

            CompactStartArtwork {
                Layout.fillWidth: kickoff.vertical
                Layout.fillHeight: true
                Layout.preferredWidth: compactRoot.panelHeight
                Layout.minimumWidth: kickoff.vertical ? 0 : compactRoot.panelHeight
                iconSource: Plasmoid.icon
                fileIcon: Tools.isLocalIconPath(kickoff.compactIcon)
                coloredMark: kickoff.compactIcon === Tools.stockStartIcon
                shadowed: KickoffTheme.isClassic || KickoffTheme.isExposed
                highlighted: compactRoot.activeFace
            }

            PC3.Label {
                id: labelTextField

                visible: compactRoot.shouldHaveLabel
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.leftMargin: compactRoot.labelStartMargin
                Layout.rightMargin: compactRoot.labelEndMargin

                text: compactRoot.launcherLabel
                textFormat: Text.StyledText
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.NoWrap
                elide: Text.ElideRight
                readonly property bool useLunaFont: KickoffTheme.isExposed && lunaStartFont.status === FontLoader.Ready
                font.family: useLunaFont ? lunaStartFont.font.family
                    : (KickoffTheme.isClassic || KickoffTheme.isExposed) ? "monospace" : Kirigami.Theme.defaultFont.family
                font.weight: useLunaFont ? lunaStartFont.font.weight : (KickoffTheme.isClassic ? Font.Bold : Font.Normal)
                font.pixelSize: Math.max(1, Math.round(compactRoot.panelHeight * 0.55))
                color: KickoffTheme.isExposed ? "#FFFFFF"
                    : KickoffTheme.isClassic ? KickoffTheme.buttonTextColor : Kirigami.Theme.textColor
                style: KickoffTheme.isExposed ? Text.Raised : Text.Normal
                styleColor: Qt.rgba(0, 0, 0, 0.52)
            }
        }
    }

    Kicker.ProcessRunner {
        id: processRunner
    }

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18nc("@action:inmenu launches kmenuedit", "Edit Applications…") // qmllint disable unqualified
            icon.name: "kmenuedit"
            visible: Plasmoid.immutability !== PlasmaCore.Types.SystemImmutable
                && String(StandardPaths.findExecutable("kmenuedit")) !== ""
            onTriggered: processRunner.runMenuEditor()
        }
    ]

    Component.onCompleted: Plasmoid.activationTogglesExpanded = true

    onExpandedChanged: {
        if (!kickoff.expanded) {
            exposedSearchVisible = false;
        }
    }
} // root
