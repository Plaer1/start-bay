/* SPDX-License-Identifier: GPL-2.0-or-later */

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

QQC2.Menu {
    id: root

    required property var actionModel
    required property bool populate
    required property real roomAbove
    signal actionChosen(string favoriteId)

    y: -height - Kirigami.Units.smallSpacing
    width: Math.max(parent?.width ?? 0, Kirigami.Units.gridUnit * 10)
    height: Math.min(implicitHeight, Math.max(0, roomAbove - Kirigami.Units.smallSpacing))
    padding: Kirigami.Units.smallSpacing
    focus: true

    Component.onCompleted: {
        if (typeof popupType !== "undefined") {
            popupType = QQC2.Popup.Item;
        }
    }

    background: Rectangle {
        color: KickoffTheme.alternateViewColor
        border.width: 1
        border.color: Qt.lighter(KickoffTheme.alternateViewColor, 1.3)
        radius: KickoffTheme.borderRadius
    }

    Instantiator {
        model: root.actionModel
        active: root.populate
        delegate: QQC2.MenuItem {
            id: row
            required property var model

            text: model.display
            implicitHeight: Kirigami.Units.gridUnit * 2
            leftPadding: Kirigami.Units.smallSpacing * 2
            rightPadding: leftPadding
            onTriggered: root.actionChosen(model.favoriteId)

            background: Rectangle {
                color: row.highlighted ? KickoffTheme.buttonColor : "transparent"
                radius: KickoffTheme.borderRadius
            }

            contentItem: RowLayout {
                spacing: Kirigami.Units.smallSpacing * 2

                Kirigami.Icon {
                    Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                    Layout.preferredHeight: Layout.preferredWidth
                    source: row.model.decoration
                }

                QQC2.Label {
                    Layout.fillWidth: true
                    text: row.text
                    color: KickoffTheme.sidebarTextColor
                    elide: Text.ElideRight
                }
            }
        }

        onObjectAdded: (index, object) => root.insertItem(index, object)
        onObjectRemoved: (index, object) => root.removeItem(object)
    }
}
