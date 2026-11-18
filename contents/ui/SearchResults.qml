/* SPDX-License-Identifier: GPL-2.0-or-later */

import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.extras as PlasmaExtras

KickoffListView {
    id: root
    objectName: "searchView"
    mainContentView: true
    activeFocusOnTab: true
    delegate: KickoffListDelegate {
        width: view.availableWidth
        isSearchResult: true
    }
    Keys.onUpPressed: event => kickoff.searchField?.forceActiveFocus(Qt.BacktabFocusReason)
    Keys.onTabPressed: event => kickoff.firstHeaderItem?.forceActiveFocus(Qt.TabFocusReason)
    Keys.onBacktabPressed: event => kickoff.lastHeaderItem?.forceActiveFocus(Qt.BacktabFocusReason)
    Loader {
        anchors.centerIn: root.view
        width: root.view.width - Kirigami.Units.gridUnit * 4
        active: kickoff.searchQuery.trim().length > 0 && !kickoff.runnerModel.querying && root.count === 0
        visible: active
        sourceComponent: PlasmaExtras.PlaceholderMessage {
            iconName: "edit-none"
            text: i18nc("@info:status", "No matches")
        }
    }
}
