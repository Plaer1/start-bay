/*
 * SPDX-FileCopyrightText: 2021 Noah Davis <noahadvs@gmail.com>
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtCore
import QtQuick.Templates as T
import org.kde.plasma.private.kicker as Kicker
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import org.kde.plasma.extras as PlasmaExtras
import org.kde.coreaddons as KCoreAddons
import org.kde.plasma.components as PC3

import "code/programGrouping.js" as ProgramGrouping

BasePage {
    id: root

    property real flashFavorite: 0
    readonly property var edits: kickoff.programEdits

    // Groove separator: palette bevels in classic, Luna orange in XP mode
    component ClassicGroove: Item {
        implicitHeight: 2
        // The Aero divider belongs inside the app-pane outline.
        readonly property int edgeInset: KickoffTheme.isArrow ? 1 : 0
        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                leftMargin: parent.edgeInset
                rightMargin: parent.edgeInset
            }
            height: 1
            color: KickoffTheme.grooveDarkColor
        }
        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                leftMargin: parent.edgeInset
                rightMargin: parent.edgeInset
            }
            height: 1
            color: KickoffTheme.grooveLightColor
        }
    }

    KCoreAddons.KUser {
        id: kuser
    }

    ListModel {
        id: classicPlacesModel

        function appendPlace(title, icon, url, entryKey = "", folderKey = "") {
            append({
                display: title,
                decoration: icon,
                url: String(url),
                entryKey: entryKey,
                folderKey: folderKey,
                description: "",
                favoriteId: "",
                isSearch: false,
                isSeparator: false,
                isMultilineText: false
            });
        }

        function appendApp(title, icon, desktopId) {
            const app = kickoff.catalog.entries.find(entry => entry.favoriteId === "applications:" + desktopId);
            if (app) appendPlace(title, icon, "", app.key);
        }

        function appendSeparator() {
            append({ display: "", decoration: "", url: "", entryKey: "", description: "",
                folderKey: "", favoriteId: "", isSearch: false, isSeparator: true, isMultilineText: false });
        }

        function appendSearchAction(title, icon) {
            append({ display: title, decoration: icon, url: "", entryKey: "", description: "",
                folderKey: "", favoriteId: "", isSearch: true, isSeparator: false, isMultilineText: false });
        }

        function populate() {
            clear();
            appendPlace(kuser.fullName || kuser.loginName || i18n("User"), "user-identity",
                StandardPaths.writableLocation(StandardPaths.HomeLocation));
            appendPlace(KickoffTheme.isExposed ? i18n("My Documents") : i18n("Documents"),
                "folder-documents", StandardPaths.writableLocation(StandardPaths.DocumentsLocation));
            appendPlace(KickoffTheme.isExposed ? i18n("My Pictures") : i18n("Pictures"),
                "folder-pictures", StandardPaths.writableLocation(StandardPaths.PicturesLocation));
            appendPlace(KickoffTheme.isExposed ? i18n("My Music") : i18n("Music"),
                "folder-music", StandardPaths.writableLocation(StandardPaths.MusicLocation));
            appendPlace(i18n("Videos"), "folder-videos", StandardPaths.writableLocation(StandardPaths.MoviesLocation));
            const games = root.edits.entries.find(entry => entry.isFolder && !entry.parentKey
                && ProgramGrouping.categoryForIcon(entry.categoryIcon) === "games");
            if (games) appendPlace(games.title, "folder-games", "", "", games.key);
            const linuxTools = root.edits.find("startbay:linux-tools");
            if (linuxTools && !KickoffTheme.isExposed) appendPlace(linuxTools.title, "applications-system", "", "", linuxTools.key);
            appendPlace(KickoffTheme.isExposed ? i18n("My Computer") : i18n("Computer"), "computer", "file:///");
            if (KickoffTheme.hasBanner || KickoffTheme.isMetropolis) appendSeparator();
            if (linuxTools && KickoffTheme.isExposed) appendPlace(linuxTools.title, "applications-system", "", "", linuxTools.key);
            appendApp(i18n("Control Panel"), "preferences-system", "systemsettings.desktop");
            appendApp(i18n("Help and Support"), "help-browser", "org.kde.khelpcenter.desktop");
            if (KickoffTheme.hasBanner) {
                appendSeparator();
                appendSearchAction(i18n("Search"), "system-search");
            }
            appendSearchAction(i18n("Run…"), "system-run");
        }

        function trigger(row, actionId, parameters) {
            if (row < 0 || row >= count) return false;
            const item = get(row);
            if (item.isSearch) {
                kickoff.exposedSearchVisible = true;
                kickoff.searchField?.forceActiveFocus(Qt.ShortcutFocusReason);
                return false;
            }
            if (item.folderKey) {
                root.contentAreaItem?.showProgramFolder(item.folderKey);
                return false;
            }
            if (item.entryKey) return kickoff.catalog.activate(item.entryKey, actionId, parameters);
            return item.url ? Qt.openUrlExternally(item.url) : false;
        }
    }

    ListModel {
        id: programsModel
        dynamicRoles: true

        property string folderKey: ""
        property var favoritesModel: kickoff.rootModel.favoritesModel

        function navigateToRoot() {
            navigateToFolder("");
        }

        function navigateToFolder(key) {
            folderKey = key;
            populate();
        }

        function populate() {
            if (!root.edits.isFolder(folderKey)) folderKey = "";
            const visibleEntries = root.edits.entries.filter(entry => entry.parentKey === folderKey);
            if (Plasmoid.configuration.alphaSort) {
                visibleEntries.sort((a, b) => a.title.localeCompare(b.title));
            }
            clear();
            if (folderKey) {
                append({ key: "", display: i18n("Back"), decoration: "go-previous", description: "",
                    url: "", isFolder: false, isBack: true, favoriteId: "", hasActionList: true,
                    isSeparator: false, isMultilineText: false });
            }
            for (const entry of programOrder.orderedEntries(visibleEntries)) {
                append({
                    key: entry.key,
                    display: entry.title,
                    decoration: entry.icon,
                    description: entry.description,
                    url: entry.url,
                    isFolder: entry.isFolder,
                    isBack: false,
                    favoriteId: entry.favoriteId,
                    hasActionList: true,
                    isSeparator: false,
                    isMultilineText: false
                });
            }
        }

        function trigger(row, actionId, parameters) {
            if (actionId?.startsWith("startbay:")) {
                handleMenuAction(actionId, parameters);
                return false;
            }
            if (row < 0 || row >= count) return false;
            const modelEntry = get(row);
            if (modelEntry.isBack) {
                const folder = root.edits.find(folderKey);
                folderKey = folder ? folder.parentKey : "";
                populate();
                return false;
            }
            return openEntry(modelEntry.key, actionId, parameters);
        }

        function openEntry(key, actionId, parameters) {
            const entry = root.edits.find(key);
            if (!entry) return false;
            if (entry.isFolder) {
                navigateToFolder(entry.key);
                return false;
            }
            return entry.canActivate && kickoff.catalog.activate(entry.sourceKey || entry.key, actionId, parameters);
        }

        function handleMenuAction(actionId, key) {
            switch (actionId) {
                case "startbay:open":
                    if (openEntry(key, "", null) && kickoff.hideOnWindowDeactivate) kickoff.expanded = false;
                    break;
                case "startbay:rename": {
                    const entry = root.edits.find(key);
                    if (entry) Qt.callLater(programNameDialog.ask, key, entry.title, true);
                    break;
                }
                case "startbay:cut": root.edits.cut(key); break;
                case "startbay:copy": root.edits.copy(key); break;
                case "startbay:paste": root.edits.paste(key); break;
                case "startbay:new-folder": Qt.callLater(programNameDialog.ask, key, "", false); break;
                case "startbay:remove": root.edits.remove(key); break;
                case "startbay:restore": root.edits.restoreHidden(); break;
            }
        }

        function actionsForRow(row) {
            const entry = row >= 0 && row < count ? root.edits.find(get(row).key) : null;
            const destination = entry?.isFolder ? entry.key : folderKey;
            const actions = [];
            function add(text, icon, id, key, enabled = true) {
                actions.push({ text: text, icon: icon, actionId: "startbay:" + id, actionArgument: key, enabled: enabled });
            }

            if (entry) {
                add(i18n("Open"), entry.isFolder ? "document-open-folder" : "document-open",
                    "open", entry.key, entry.isFolder || entry.canActivate);
                actions.push({ type: "separator" });
                add(i18n("Cut"), "edit-cut", "cut", entry.key);
                add(i18n("Copy"), "edit-copy", "copy", entry.key);
            }
            add(i18n("Paste"), "edit-paste", "paste", destination, root.edits.canPaste(destination));
            add(i18n("New Folder…"), "folder-new", "new-folder", destination);
            if (entry) {
                add(i18n("Rename…"), "edit-rename", "rename", entry.key);
                add(i18n("Remove from Start Bay"), "edit-delete", "remove", entry.key);
            }
            if (root.edits.hasHidden) {
                add(i18n("Restore Removed Entries"), "edit-undo", "restore", "");
            }
            if (entry?.hasActionList) {
                const nativeActions = Array.from(kickoff.catalog.actions(entry.sourceKey || entry.key));
                if (nativeActions.length) actions.push({ type: "separator" }, ...nativeActions);
            }
            return actions;
        }
    }

    QQC2.Dialog {
        id: programNameDialog
        parent: root
        anchors.centerIn: parent
        width: Math.min(root.width, Kirigami.Units.gridUnit * 18)
        modal: true
        standardButtons: QQC2.Dialog.Ok | QQC2.Dialog.Cancel
        title: renaming ? i18n("Rename Menu Entry") : i18n("New Folder")

        property string entryKey: ""
        property bool renaming: false

        function ask(key, title, rename) {
            entryKey = key;
            renaming = rename;
            programName.text = title;
            open();
        }

        onOpened: {
            programName.forceActiveFocus();
            programName.selectAll();
        }
        onAccepted: {
            if (renaming) {
                root.edits.rename(entryKey, programName.text);
            } else {
                root.edits.createFolder(entryKey, programName.text);
            }
        }
        contentItem: QQC2.TextField {
            id: programName
            placeholderText: i18n("Name")
            Accessible.name: placeholderText
            onAccepted: programNameDialog.accept()
        }
    }

    ProgramOrder {
        id: programOrder
        configuration: Plasmoid.configuration
        configKey: "programOrder"
        model: programsModel
        folderKey: programsModel.folderKey || (Plasmoid.configuration.groupProgramsByCategory ? "" : "flat")
        firstMovableIndex: programsModel.folderKey ? 1 : 0
        enabled: !Plasmoid.configuration.alphaSort
        onEnabledChanged: Qt.callLater(programsModel.populate)
    }

    Connections {
        target: root.edits
        function onEntriesChanged() {
            programsModel.populate();
            classicPlacesModel.populate();
        }
    }

    // Flash favorites when adding one.
    SequentialAnimation {
        id: flashFavoriteAnimation
        loops: 2
        alwaysRunToEnd: true

        NumberAnimation {
            target: root
            property: "flashFavorite"
            from: 0
            to: 1
            duration: Kirigami.Units.veryLongDuration
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: root
            property: "flashFavorite"
            to: 0
            duration: Kirigami.Units.veryLongDuration
            easing.type: Easing.OutCubic
        }
    }

    Connections {
        target: kickoff.rootModel.favoritesModel
        function onFavoriteAdded() : void {
            flashFavoriteAnimation.restart();
        }
    }

    sideBarComponent: KickoffListView {
        id: sideBar
        focus: true // needed for Loaders
        model: KickoffTheme.isWinStyle ? classicPlacesModel : kickoff.rootModel
        isSidebar: true
        // needed otherwise app displayed at top-level will show a first character as group.
        section.property: ""

        delegate: KickoffListDelegate {
            id: sideBarDelegate
            width: view.availableWidth
            isCategoryListItem: true
            // direct KickoffTheme text colors (navy XP, white Win7 glass…)
            sidebarColors: KickoffTheme.isWinStyle
            background: Item {
                // I have to do this for it to actually fill the item for some reason
                anchors.fill: parent
                readonly property bool highlightActive: sideBarDelegate.mouseArea.containsMouse || (flashFavoriteAnimation.running && sideBarDelegate.index === 0) || ((dropAreaLoader.item as DropArea)?.containsAcceptableDrag ?? false) || sideBarDelegate.ListView.isCurrentItem
                readonly property real highlightOpacity: flashFavoriteAnimation.running && sideBarDelegate.index === 0 ? root.flashFavorite : 1

                PlasmaExtras.Highlight {
                    anchors.fill: parent
                    active: false
                    hovered: parent.highlightActive
                    visible: !KickoffTheme.isWinStyle && !sideBarDelegate.isSeparator && parent.highlightActive
                    opacity: parent.highlightOpacity
                }
                // Win9x/XP: flat accent highlight
                Rectangle {
                    anchors.fill: parent
                    color: KickoffTheme.isMetropolis ? KickoffTheme.buttonColor : KickoffTheme.highlightColor
                    visible: KickoffTheme.isWinStyle && !KickoffTheme.isArrow && !sideBarDelegate.isSeparator && parent.highlightActive
                    opacity: parent.highlightOpacity
                }
                // Win7 sidebar hover: faint white glass pill with inner rim
                Rectangle {
                    anchors.fill: parent
                    radius: 3
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.42)
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.28) }
                        GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.16) }
                        GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.08) }
                    }
                    visible: KickoffTheme.isArrow && !sideBarDelegate.isSeparator && parent.highlightActive
                    opacity: parent.highlightOpacity

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 1
                        radius: 2
                        color: "transparent"
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.25)
                    }
                }
            }

            component FavoritesDropArea: DropArea {
                // should be  "as AbstractKickoffItemDelegate", but the type system gets confused when changing view style at runtime
                readonly property Item draggedItem: kickoff.dragSource.sourceItem
                readonly property bool acceptableDrag: draggedItem && !kickoff.rootModel.favoritesModel.isFavorite(draggedItem.model.favoriteId)
                readonly property bool containsAcceptableDrag:  acceptableDrag && containsDrag
                function evaluateEvent(event: DragEvent) : void {
                    if (acceptableDrag) {
                        event.accept(Qt.CopyAction)
                    } else {
                        event.accept(Qt.IgnoreAction)
                    }
                }
            }

            Loader {
                id: dropAreaLoader
                anchors.fill: parent
                active: sideBarDelegate.index === 0 && !!kickoff.dragSource.sourceItem
                sourceComponent: FavoritesDropArea {
                    onPositionChanged: event => evaluateEvent(event)
                    onEntered: event =>  evaluateEvent(event)
                    onDropped: event => {
                        if (acceptableDrag && !sideBarDelegate.ListView.isCurrentItem) {
                            kickoff.rootModel.favoritesModel.addFavorite(draggedItem.model.favoriteId, sideBar.model.favoritesModel.count)
                            event.accept(Qt.CopyAction)
                        } else {
                            event.accept(Qt.IgnoreAction)
                        }
                    }
                }
            }
        }
    }

    contentAreaComponent: VerticalStackView {
        id: stackView

        function showProgramFolder(key) {
            programsModel.navigateToFolder(key);
            appsModelRow = 1;
            if (currentItem?.view?.model !== programsModel) replace(preferredAllAppsViewComponent);
        }

        popEnter: Transition {
            NumberAnimation {
                property: "x"
                from: 0.5 * root.width
                to: 0
                duration: Kirigami.Units.longDuration
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                property: "opacity"
                from: 0.0
                to: 1.0
                duration: Kirigami.Units.longDuration
                easing.type: Easing.OutCubic
            }
        }

        pushEnter: Transition {
            NumberAnimation {
                property: "x"
                from: 0.5 * -root.width
                to: 0
                duration: Kirigami.Units.longDuration
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                property: "opacity"
                from: 0.0
                to: 1.0
                duration: Kirigami.Units.longDuration
                easing.type: Easing.OutCubic
            }
        }

        readonly property string preferredFavoritesViewObjectName: (KickoffTheme.isWinStyle || Plasmoid.configuration.favoritesDisplay === 1) ? "favoritesListView" : "favoritesGridView"
        readonly property Component preferredFavoritesViewComponent: (KickoffTheme.isWinStyle || Plasmoid.configuration.favoritesDisplay === 1) ? favoritesListViewComponent : favoritesGridViewComponent
        readonly property string preferredAllAppsViewObjectName: (KickoffTheme.isWinStyle || Plasmoid.configuration.applicationsDisplay === 1) ? "applicationsListView" : "listOfGridsView"
        readonly property Component preferredAllAppsViewComponent: (KickoffTheme.isWinStyle || Plasmoid.configuration.applicationsDisplay === 1) ? applicationsListViewComponent : listOfGridsViewComponent

        readonly property string preferredAppsViewObjectName: (KickoffTheme.isWinStyle || Plasmoid.configuration.applicationsDisplay === 1) ? "applicationsListView" : "applicationsGridView"
        readonly property Component preferredAppsViewComponent: (KickoffTheme.isWinStyle || Plasmoid.configuration.applicationsDisplay === 1) ? applicationsListViewComponent : applicationsGridViewComponent
        // NOTE: The 0 index modelForRow isn't supposed to be used. That's just how it works.
        // But to trigger model data update, set initial value to 0
        property int appsModelRow: 0
        readonly property var appsModel: {
            if (appsModelRow === 1 && KickoffTheme.isWinStyle) {
                return programsModel;
            }
            return kickoff.rootModel.modelForRow(appsModelRow);
        }

        Connections {
            target: kickoff.rootModel
            function onRefreshed() { // recalculate appsModel binding on rootModel refresh;
                stackView.appsModelRowChanged() // modelForRow does not create dependency
            }
        }
        focus: true
        initialItem: preferredFavoritesViewComponent

        function showSectionView(sectionName: string, parentView: KickoffListView): void {
            stackView.push(applicationsSectionViewComponent, {
                currentSection: sectionName,
                parentView,
            });
        }

        Component {
            id: favoritesListViewComponent
            Item {
                property alias view: favoritesListView.view
                property alias currentItem: favoritesListView.currentItem
                implicitWidth: favoritesListView.implicitWidth
                implicitHeight: favoritesListView.implicitHeight

                DropAreaListView {
                    id: favoritesListView
                    objectName: "favoritesListView"
                    mainContentView: true
                    focus: true
                    model: kickoff.rootModel.favoritesModel
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                        bottom: (KickoffTheme.isWinStyle && allProgramsButton.visible) ? allProgramsSeparator.top : parent.bottom
                    }
                }

                ClassicGroove {
                    id: allProgramsSeparator
                    visible: allProgramsButton.visible
                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: allProgramsButton.top
                    }
                }

                PC3.ItemDelegate {
                    id: allProgramsButton
                    visible: KickoffTheme.isWinStyle
                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                        leftMargin: Kirigami.Units.smallSpacing
                        rightMargin: Kirigami.Units.smallSpacing
                        bottomMargin: Kirigami.Units.smallSpacing
                    }
                    text: i18n("All Programs")
                    icon.name: KickoffTheme.isExposed ? "" : "go-next"
                    icon.source: KickoffTheme.isExposed ? Qt.resolvedUrl("../images/all-programs-arrow.svg") : ""
                    // XP puts the green arrow after the label
                    LayoutMirroring.enabled: KickoffTheme.isExposed
                    font.weight: Font.Bold

                    onClicked: stackView.showProgramFolder("")
                }
            }
        }

        Component {
            id: favoritesGridViewComponent
            DropAreaGridView {
                id: favoritesGridView
                objectName: "favoritesGridView"
                focus: true
                model: kickoff.rootModel.favoritesModel
            }
        }

        Component {
            id: applicationsListViewComponent
            Item {
                property alias view: applicationsListView.view
                property alias currentItem: applicationsListView.currentItem
                implicitWidth: applicationsListView.implicitWidth
                implicitHeight: applicationsListView.implicitHeight

                DropAreaListView {
                    id: applicationsListView
                    dropEnabled: model === programsModel && programOrder.enabled
                    orderController: programOrder
                    objectName: "applicationsListView"
                    mainContentView: true
                    model: stackView.appsModel
                    // we want to semantically switch between group and "", disabling grouping, workaround for QTBUG-121797
                    section.property: model && model.description === "KICKER_ALL_MODEL" ? "group" : "_unset"
                    section.criteria: ViewSection.FirstCharacter
                    hasSectionView: !KickoffTheme.isWinStyle && stackView.appsModelRow === 1

                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                        bottom: (KickoffTheme.isWinStyle && backToFavoritesButton.visible) ? backSeparator.top : parent.bottom
                    }

                    onShowSectionViewRequested: sectionName => {
                        stackView.showSectionView(sectionName, this);
                    }

                    TapHandler {
                        acceptedButtons: Qt.RightButton
                        enabled: applicationsListView.model === programsModel
                        onTapped: eventPoint => {
                            const view = applicationsListView.view;
                            const position = eventPoint.position;
                            const point = applicationsListView.mapToItem(view.contentItem, position.x, position.y);
                            if (view.indexAt(point.x, point.y) >= 0) return;
                            ActionMenu.plasmoid = kickoff;
                            ActionMenu.popup(applicationsListView, programsModel.actionsForRow(-1),
                                (id, key) => programsModel.handleMenuAction(id, key), position.x, position.y);
                        }
                    }
                }

                ClassicGroove {
                    id: backSeparator
                    visible: backToFavoritesButton.visible
                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: backToFavoritesButton.top
                    }
                }

                PC3.ItemDelegate {
                    id: backToFavoritesButton
                    visible: KickoffTheme.isWinStyle && !programsModel.folderKey
                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                        leftMargin: Kirigami.Units.smallSpacing
                        rightMargin: Kirigami.Units.smallSpacing
                        bottomMargin: Kirigami.Units.smallSpacing
                    }
                    text: i18n("Back")
                    icon.name: "go-previous"
                    font.weight: Font.Bold

                    onClicked: {
                        stackView.appsModelRow = 0;
                        stackView.replace(stackView.preferredFavoritesViewComponent);
                    }
                }
            }
        }

        Component {
            id: applicationsSectionViewComponent

            SectionView {
                id: sectionView
                model: stackView.appsModel.sections

                onHideSectionViewRequested: index => {
                    stackView.pop();
                    stackView.currentItem.view.positionViewAtIndex(index, ListView.Beginning);
                    stackView.currentItem.currentIndex = index;
                }
            }
        }

        Component {
            id: applicationsGridViewComponent
            KickoffGridView {
                id: applicationsGridView
                objectName: "applicationsGridView"
                model: stackView.appsModel
            }
        }

        Component {
            id: listOfGridsViewComponent

            ListOfGridsView {
                id: listOfGridsView
                objectName: "listOfGridsView"
                mainContentView: true
                gridModel: stackView.appsModel

                onShowSectionViewRequested: sectionName => {
                    stackView.showSectionView(sectionName, this);
                }
            }
        }

        onPreferredFavoritesViewComponentChanged: {
            if (root.sideBarItem !== null && root.sideBarItem.currentIndex === 0) {
                stackView.replace(stackView.preferredFavoritesViewComponent)
            }
        }
        onPreferredAllAppsViewComponentChanged: {
            if (root.sideBarItem !== null && root.sideBarItem.currentIndex === 1) {
                stackView.replace(stackView.preferredAllAppsViewComponent)
            }
        }
        onPreferredAppsViewComponentChanged: {
            if (root.sideBarItem !== null && root.sideBarItem.currentIndex > 1) {
                stackView.replace(stackView.preferredAppsViewComponent)
            }
        }

        Connections {
            target: root.sideBarItem
            ignoreUnknownSignals: true
            function onCurrentIndexChanged() {
                if (KickoffTheme.isWinStyle) {
                    return; // Ignore index change in classic mode!
                }
                // Only update row index if the condition is met.
                // The 0 index modelForRow isn't supposed to be used. That's just how it works.
                if (root.sideBarItem.currentIndex > 0) {
                    stackView.appsModelRow = root.sideBarItem.currentIndex
                }
                if (root.sideBarItem.currentIndex === 0
                    && stackView.currentItem.objectName !== stackView.preferredFavoritesViewObjectName) {
                    stackView.replace(stackView.preferredFavoritesViewComponent)
                } else if (root.sideBarItem.currentIndex === 1
                    && stackView.currentItem.objectName !== stackView.preferredAllAppsViewObjectName) {
                    stackView.replace(stackView.preferredAllAppsViewComponent)
                } else if (root.sideBarItem.currentIndex > 1
                    && stackView.currentItem.objectName !== stackView.preferredAppsViewObjectName) {
                    stackView.replace(stackView.preferredAppsViewComponent)
                }
            }
        }
        Connections {
            target: kickoff
            function onExpandedChanged() {
                if (!kickoff.expanded) {
                    kickoff.contentArea?.currentItem?.forceActiveFocus();
                }
                if (kickoff.expanded && KickoffTheme.isWinStyle) {
                    if (Plasmoid.configuration.classicStartAllPrograms) {
                        programsModel.navigateToRoot()
                        stackView.appsModelRow = 1
                        stackView.replace(stackView.preferredAllAppsViewComponent)
                    } else {
                        stackView.appsModelRow = 0
                        stackView.replace(stackView.preferredFavoritesViewComponent)
                    }
                }
            }
        }
    }
    // NormalPage doesn't get destroyed when deactivated, so the binding uses
    // StackView.status and visible. This way the bindings are reset when
    // NormalPage is Activated again.
    Binding {
        target: kickoff
        property: "sideBar"
        value: root.visibleSearchResults ? null : root.sideBarItem
        when: root.T.StackView.status === T.StackView.Active && root.visible
        restoreMode: Binding.RestoreBinding
    }
    Binding {
        target: kickoff
        property: "contentArea"
        value: root.visibleSearchResults || root.contentAreaItem?.currentItem || null
        when: root.T.StackView.status === T.StackView.Active && root.visible
        restoreMode: Binding.RestoreBinding
    }

    Connections {
        target: KickoffTheme
        function onMenuStyleChanged() {
            classicPlacesModel.populate();
        }
    }

    Component.onCompleted: {
        classicPlacesModel.populate();
    }
}
