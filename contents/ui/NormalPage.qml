/*
 * SPDX-FileCopyrightText: 2021 Noah Davis <noahadvs@gmail.com>
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Templates as T
import org.kde.kirigami as Kirigami

EmptyPage {
    id: root
    // In classic mode the tab bar is collapsed and the places list sizes to its
    // view (circular), so seed the sidebar with an explicit width like Win7's
    // right column. Otherwise it collapses to 0.
    property real preferredSideBarWidth: KickoffTheme.isMetropolis ? Kirigami.Units.gridUnit * 9
        : KickoffTheme.isWinStyle ? Math.max(Kirigami.Units.gridUnit * 11, applicationsPage.implicitSideBarWidth)
        : Math.max(footer.tabBar.implicitWidth, applicationsPage.implicitSideBarWidth)
    contentItem: HorizontalStackView {
        id: stackView
        focus: true
        reverseTransitions: footer.tabBar.currentIndex === 1
        initialItem: ApplicationsPage {
            id: applicationsPage
            preferredSideBarWidth: root.preferredSideBarWidth + kickoff.backgroundMetrics.leftPadding
        }
        Component {
            id: placesPage
            PlacesPage {
                preferredSideBarWidth: root.preferredSideBarWidth + kickoff.backgroundMetrics.leftPadding
                preferredSideBarHeight: applicationsPage.implicitSideBarHeight
            }
        }
        Connections {
            target: footer.tabBar
            function onCurrentIndexChanged() {
                if (footer.tabBar.currentIndex === 0) {
                    stackView.replace(applicationsPage)
                } else if (footer.tabBar.currentIndex === 1) {
                    stackView.replace(placesPage)
                }
            }
        }
    }

    footer: Footer {
        id: footer
        preferredTabBarWidth: root.preferredSideBarWidth
        Binding {
            target: kickoff
            property: "footer"
            value: footer
            restoreMode: Binding.RestoreBinding
        }
        // Eat down events to prevent them from reaching the contentArea or searchField
        Keys.onDownPressed: event => {}
    }
}
