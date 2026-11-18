/*
    SPDX-FileCopyrightText: 2013 David Edmundson <davidedmundson@kde.org>
    SPDX-FileCopyrightText: 2021 Mikel Johnson <mikel5764@gmail.com>
    SPDX-FileCopyrightText: 2022 Nate Graham <nate@kde.org>
    SPDX-FileCopyrightText: 2022 ivan tkachenko <me@ratijas.tk>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import QtQuick.Dialogs

import org.kde.plasma.core as PlasmaCore
import org.kde.ksvg as KSvg
import org.kde.iconthemes as KIconThemes
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.config as KConfig
import org.kde.plasma.plasmoid

import "code/tools.js" as Tools

KCM.SimpleKCM {
    id: root

    property string cfg_menuLabel: menuLabel.text
    property string cfg_icon: Plasmoid.configuration.icon
    property alias cfg_appNameFormat: appNameFormat.currentIndex
    property bool cfg_paneSwap: Plasmoid.configuration.paneSwap
    property int cfg_menuStyle: Plasmoid.configuration.menuStyle
    property alias cfg_alphaSort: alphaSort.checked
    property var cfg_systemFavorites: String(Plasmoid.configuration.systemFavorites)
    property int cfg_primaryActions: Plasmoid.configuration.primaryActions
    property alias cfg_showActionButtonCaptions: showActionButtonCaptions.checked
    property alias cfg_compactMode: compactModeCheckbox.checked
    property alias cfg_highlightNewlyInstalledApps: highlightNewlyInstalledAppsCheckbox.checked
    property alias cfg_switchCategoryOnHover: switchCategoryOnHoverCheckbox.checked
    property alias cfg_showDescriptionsInline: showDescriptionsInlineCheckbox.checked
    property alias cfg_classicStartAllPrograms: classicStartAllProgramsCheckbox.checked
    property alias cfg_classicThemeResponsive: classicThemeResponsiveCheckbox.checked
    property alias cfg_classicSideTitlebar: classicSideTitlebarCheckbox.checked
    property alias cfg_exposedThemeResponsive: exposedThemeResponsiveCheckbox.checked
    property alias cfg_exposedSleepButton: exposedSleepButtonCheckbox.checked
    property alias cfg_arrowThemeResponsive: arrowThemeResponsiveCheckbox.checked
    property alias cfg_arrowTransparent: arrowTransparentCheckbox.checked
    property int cfg_arrowAeroColor: Plasmoid.configuration.arrowAeroColor
    property int cfg_metropolisAccent: Plasmoid.configuration.metropolisAccent
    property alias cfg_scrollWheelTabSwitching: scrollWheelTabSwitchingCheckbox.checked
    property alias cfg_groupProgramsByCategory: groupProgramsByCategory.checked
    property alias cfg_groupWine: groupWine.checked
    property alias cfg_groupDevelopment: groupDevelopment.checked
    property alias cfg_groupEducation: groupEducation.checked
    property alias cfg_groupGames: groupGames.checked
    property alias cfg_groupGraphics: groupGraphics.checked
    property alias cfg_groupInternet: groupInternet.checked
    property alias cfg_groupMultimedia: groupMultimedia.checked
    property alias cfg_groupOffice: groupOffice.checked
    property alias cfg_groupScience: groupScience.checked
    property alias cfg_showLinuxTools: showLinuxTools.checked

    Kirigami.FormLayout {
        QQC2.Button {
            id: iconButton

            Kirigami.FormData.label: i18nc("@label prefix for icon-only button", "Icon:") // qmllint disable unqualified

            implicitWidth: previewFrame.width + Kirigami.Units.smallSpacing * 2
            implicitHeight: previewFrame.height + Kirigami.Units.smallSpacing * 2
            hoverEnabled: true

            Accessible.name: i18nc("@action:button", "Change Application Launcher's icon") // qmllint disable unqualified
            Accessible.description: i18nc("@info:whatsthis", "Current icon is %1. Click to open menu to change the current icon or reset to the default icon.", root.cfg_icon) // qmllint disable unqualified
            Accessible.role: Accessible.ButtonMenu

            QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
            QQC2.ToolTip.text: i18nc("@info:tooltip", "Icon name is \"%1\"", root.cfg_icon) // qmllint disable unqualified
            QQC2.ToolTip.visible: iconButton.hovered && root.cfg_icon.length > 0

            KIconThemes.IconDialog {
                id: iconDialog
                onAccepted: {
                    root.cfg_icon = iconName || Tools.defaultIconName;
                }
            }

            FileDialog {
                id: fileDialog
                title: i18nc("@title:window", "Choose Start Menu Icon")
                nameFilters: [i18nc("@item:inlistbox", "Image files (*.png *.jpg *.jpeg *.svg *.svgz)")]
                onAccepted: {
                    root.cfg_icon = selectedFile.toString();
                }
            }

            onPressed: iconMenu.opened ? iconMenu.close() : iconMenu.open()

            KSvg.FrameSvgItem {
                id: previewFrame
                anchors.centerIn: parent
                imagePath: Plasmoid.formFactor === PlasmaCore.Types.Vertical || Plasmoid.formFactor === PlasmaCore.Types.Horizontal
                        ? "widgets/panel-background" : "widgets/background"
                width: Kirigami.Units.iconSizes.large + fixedMargins.left + fixedMargins.right
                height: Kirigami.Units.iconSizes.large + fixedMargins.top + fixedMargins.bottom

                Rectangle {
                    visible: root.cfg_menuStyle === 4
                    anchors.centerIn: parent
                    width: Kirigami.Units.iconSizes.large
                    height: width
                    color: KickoffTheme.metropolisColor(root.cfg_metropolisAccent)
                }

                CompactStartArtwork {
                    anchors.centerIn: parent
                    width: Kirigami.Units.iconSizes.large
                    height: width
                    readonly property string previewIcon: Tools.compactIcon(root.cfg_menuStyle, root.cfg_icon)
                    fileIcon: Tools.isLocalIconPath(previewIcon)
                    iconSource: fileIcon ? Qt.resolvedUrl(Tools.compactIconFileUrl(previewIcon)).toString() : previewIcon
                    coloredMark: previewIcon === Tools.stockStartIcon
                    shadowed: false
                    highlighted: false
                }
            }

            QQC2.Menu {
                id: iconMenu

                // Appear below the button
                y: parent.height

                QQC2.MenuItem {
                    text: i18nc("@item:inmenu Open icon chooser dialog", "Choose Theme Icon…")
                    icon.name: "document-open-folder"
                    Accessible.description: i18nc("@info:whatsthis", "Choose a system theme icon")
                    onClicked: iconDialog.open()
                }
                QQC2.MenuItem {
                    text: i18nc("@item:inmenu Open file chooser dialog", "Choose File…")
                    icon.name: "image-x-generic"
                    Accessible.description: i18nc("@info:whatsthis", "Choose an image file from disk")
                    onClicked: fileDialog.open()
                }
                QQC2.MenuItem {
                    text: i18nc("@item:inmenu Optional bundled start button artwork", "Clank Eye")
                    icon.source: Qt.resolvedUrl(Tools.clankEyeStartIcon)
                    onClicked: root.cfg_icon = Tools.clankEyeStartIcon
                }
                QQC2.MenuItem {
                    text: i18nc("@item:inmenu Reset icon to default", "Reset to default icon") // qmllint disable unqualified
                    icon.name: "edit-clear"
                    enabled: root.cfg_icon !== ""
                    onClicked: root.cfg_icon = ""
                }
                QQC2.MenuItem {
                    text: i18nc("@action:inmenu", "Remove icon") // qmllint disable unqualified
                    icon.name: "delete"
                    enabled: menuLabel.visible && menuLabel.enabled && root.cfg_icon !== "" && menuLabel.text !== ""
                    onClicked: root.cfg_icon = ""
                }
            }
        }

        Kirigami.ActionTextField {
            id: menuLabel
            visible: root.cfg_menuStyle !== 2 && root.cfg_menuStyle !== 4
            enabled: Plasmoid.formFactor !== PlasmaCore.Types.Vertical
            Kirigami.FormData.label: i18nc("@label:textbox", "Text label:") // qmllint disable unqualified
            text: Plasmoid.configuration.menuLabel
            placeholderText: i18nc("@info:placeholder", "Type here to add a text label") // qmllint disable unqualified
            onTextEdited: root.cfg_menuLabel = menuLabel.text
            rightActions: QQC2.Action {
                icon.name: "edit-clear"
                enabled: menuLabel.text !== ""
                text: i18nc("@action:button", "Reset menu label") // qmllint disable unqualified
                onTriggered: {
                    menuLabel.clear()
                    root.cfg_menuLabel = ""
                }
            }
        }

        QQC2.Label {
            Layout.fillWidth: true
            Layout.maximumWidth: Kirigami.Units.gridUnit * 25
            visible: menuLabel.visible && Plasmoid.formFactor === PlasmaCore.Types.Vertical
            text: i18nc("@info", "A text label cannot be set when the Panel is vertical.") // qmllint disable unqualified
            wrapMode: Text.Wrap
            font: Kirigami.Theme.smallFont
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        QQC2.ComboBox {
            id: appNameFormat

            Kirigami.FormData.label: i18nc("@label:listbox", "Show applications as:") // qmllint disable unqualified

            model: [i18nc("@item:inlistbox", "Name only"), i18nc("@item:inlistbox", "Description only"), i18nc("@item:inlistbox", "Name (Description)"), i18nc("@item:inlistbox", "Description (Name)")] // qmllint disable unqualified
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        RowLayout {
            Kirigami.FormData.label: i18nc("General options", "General:") // qmllint disable unqualified
            spacing: Kirigami.Units.smallSpacing
            QQC2.CheckBox {
                id: alphaSort
                text: i18nc("@option:check", "Sort applications alphabetically") // qmllint disable unqualified
            }

            Kirigami.ContextualHelpButton {
                toolTipText: i18nc("@info:whatsthis", "This doesn't affect how applications are sorted in either search results or the favorites page.") // qmllint disable unqualified
            }
        }

        QQC2.CheckBox {
            id: compactModeCheckbox
            text: i18nc("@option:check", "Use compact list item style") // qmllint disable unqualified
            checked: Plasmoid.configuration.compactMode
        }

        QQC2.CheckBox {
            id: highlightNewlyInstalledAppsCheckbox
            text: i18nc("@option:check", "Highlight newly-installed applications") // qmllint disable unqualified
        }

        QQC2.CheckBox {
            id: switchCategoryOnHoverCheckbox
            text: i18nc("@option:check", "Switch sidebar categories when hovering over them") // qmllint disable unqualified
        }

        QQC2.CheckBox {
            id: scrollWheelTabSwitchingCheckbox
            text: i18nc("@option:check", "Switch Applications/Places tabs with scroll wheel")
        }

        QQC2.Button {
            enabled: KConfig.KAuthorized.authorizeControlModule("kcm_plasmasearch")
            icon.name: "settings-configure"
            text: i18nc("@action:button opens plasmasearch kcm", "Configure Search Plugins…") // qmllint disable unqualified
            onClicked: KCM.KCMLauncher.openSystemSettings("kcm_plasmasearch")
        }

        QQC2.ComboBox {
            id: menuStyleCombo
            Kirigami.FormData.label: i18nc("@label:listbox", "Menu style:")
            textRole: "label"
            valueRole: "style"
            model: [
                { label: i18nc("@item:inlistbox", "Classic"), style: 0 },
                { label: i18nc("@item:inlistbox", "Exposed"), style: 1 },
                { label: i18nc("@item:inlistbox", "Arrow"), style: 2 },
                { label: i18nc("@item:inlistbox", "Metropolis"), style: 4 }
            ]
            // The hidden Affluent configuration keeps its reserved value.
            currentIndex: Math.max(0, indexOfValue(root.cfg_menuStyle))
            onActivated: root.cfg_menuStyle = currentValue
        }

        QQC2.CheckBox {
            id: showDescriptionsInlineCheckbox
            text: i18nc("@option:check", "Show application descriptions inline")
        }

        QQC2.CheckBox {
            id: classicStartAllProgramsCheckbox
            text: i18nc("@option:check", "Start in All Programs view")
            checked: Plasmoid.configuration.classicStartAllPrograms
        }

        QQC2.CheckBox {
            id: classicThemeResponsiveCheckbox
            visible: menuStyleCombo.currentIndex === 0
            text: i18nc("@option:check", "Theme responsive (system colors instead of Windows Classic)")
            checked: Plasmoid.configuration.classicThemeResponsive
        }

        QQC2.CheckBox {
            id: classicSideTitlebarCheckbox
            visible: menuStyleCombo.currentIndex === 0
            text: i18nc("@option:check", "Side titlebar (Windows 98 style)")
            checked: Plasmoid.configuration.classicSideTitlebar
        }

        QQC2.CheckBox {
            id: exposedThemeResponsiveCheckbox
            visible: menuStyleCombo.currentIndex === 1
            text: i18nc("@option:check", "Theme responsive (system colors instead of XP Luna)")
            checked: Plasmoid.configuration.exposedThemeResponsive
        }

        QQC2.CheckBox {
            id: exposedSleepButtonCheckbox
            visible: menuStyleCombo.currentIndex === 1
            text: i18nc("@option:check", "Zzz button sleeps instead of hibernating")
            checked: Plasmoid.configuration.exposedSleepButton
        }

        QQC2.CheckBox {
            id: arrowThemeResponsiveCheckbox
            visible: menuStyleCombo.currentIndex === 2
            text: i18nc("@option:check", "Theme responsive (system colors instead of Aero)")
            checked: Plasmoid.configuration.arrowThemeResponsive
        }

        QQC2.CheckBox {
            id: arrowTransparentCheckbox
            visible: menuStyleCombo.currentIndex === 2
            text: i18nc("@option:check", "Aero glass transparency (default is opaque)")
            checked: Plasmoid.configuration.arrowTransparent
        }

        QQC2.ComboBox {
            id: arrowAeroColorCombo
            visible: menuStyleCombo.currentIndex === 2
            enabled: !arrowThemeResponsiveCheckbox.checked
            Kirigami.FormData.label: i18nc("@label:listbox", "Aero color:")
            model: ["Sky", "Twilight", "Sea", "Leaf", "Lime", "Sun", "Pumpkin", "Ruby",
                    "Fuchsia", "Blush", "Violet", "Lavender", "Taupe", "Chocolate", "Slate", "Frost"]
            currentIndex: Plasmoid.configuration.arrowAeroColor
            onCurrentIndexChanged: {
                root.cfg_arrowAeroColor = currentIndex
            }
        }

        QQC2.ComboBox {
            visible: root.cfg_menuStyle === 4
            Kirigami.FormData.label: i18nc("@label:listbox", "Metropolis accent:")
            model: KickoffTheme.aeroPresets
            textRole: "name"
            currentIndex: root.cfg_metropolisAccent
            onActivated: root.cfg_metropolisAccent = currentIndex
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        QQC2.RadioButton {
            id: paneSwapOff
            Kirigami.FormData.label: i18nc("@label:group prefix for radio button group", "Sidebar position:") // qmllint disable unqualified
            text: mirrored ? i18nc("@option:radio sidebar position", "Right") : i18nc("option:radio sidebar position", "Left") // qmllint disable unqualified
            QQC2.ButtonGroup.group: paneSwapGroup
            property int index: 0
            checked: !Plasmoid.configuration.paneSwap
        }

        QQC2.RadioButton {
            id: paneSwapOn
            text: mirrored ? i18nc("@option:radio sidebar position", "Left") : i18nc("@option:radio sidebar position", "Right") // qmllint disable unqualified
            QQC2.ButtonGroup.group: paneSwapGroup
            property int index: 1
            checked: Plasmoid.configuration.paneSwap
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        QQC2.RadioButton {
            id: powerActionsButton
            Kirigami.FormData.label: i18nc("@title:group prefix for radio button group", "Show buttons for:") // qmllint disable unqualified
            text: i18nc("@option:radio Show buttons for", "Power") // qmllint disable unqualified
            QQC2.ButtonGroup.group: radioGroup
            property string actions: "suspend,hibernate,reboot,shutdown"
            property int index: 0
            checked: Plasmoid.configuration.primaryActions === index
        }

        QQC2.RadioButton {
            id: sessionActionsButton
            text: i18nc("@option:radio Show buttons for", "Session") // qmllint disable unqualified
            QQC2.ButtonGroup.group: radioGroup
            property string actions: "lock-screen,logout,save-session,switch-user"
            property int index: 1
            checked: Plasmoid.configuration.primaryActions === index
        }

        QQC2.RadioButton {
            id: allActionsButton
            text: i18nc("@option:radio Show buttons for", "Power and session") // qmllint disable unqualified
            QQC2.ButtonGroup.group: radioGroup
            property string actions: "lock-screen,logout,save-session,switch-user,suspend,hibernate,reboot,shutdown"
            property int index: 3
            checked: Plasmoid.configuration.primaryActions === index
        }

        QQC2.CheckBox {
            id: showActionButtonCaptions
            text: i18nc("@option:check", "Show action button captions") // qmllint disable unqualified
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18nc("@title:group", "All Programs folders")
        }

        QQC2.CheckBox {
            id: groupProgramsByCategory
            text: i18nc("@option:check", "Group All Programs by KDE application category")
            checked: Plasmoid.configuration.groupProgramsByCategory
        }

        QQC2.CheckBox {
            id: groupWine
            text: i18nc("@option:check", "Group Wine applications")
            checked: Plasmoid.configuration.groupWine
            enabled: groupProgramsByCategory.checked
        }

        QQC2.CheckBox {
            id: groupDevelopment
            text: i18nc("@option:check", "Group Development applications")
            checked: Plasmoid.configuration.groupDevelopment
            enabled: groupProgramsByCategory.checked
        }

        QQC2.CheckBox {
            id: groupEducation
            text: i18nc("@option:check", "Group Education applications")
            checked: Plasmoid.configuration.groupEducation
            enabled: groupProgramsByCategory.checked
        }

        QQC2.CheckBox {
            id: groupGames
            text: i18nc("@option:check", "Group Games applications")
            checked: Plasmoid.configuration.groupGames
            enabled: groupProgramsByCategory.checked
        }

        QQC2.CheckBox {
            id: groupGraphics
            text: i18nc("@option:check", "Group Graphics applications")
            checked: Plasmoid.configuration.groupGraphics
            enabled: groupProgramsByCategory.checked
        }

        QQC2.CheckBox {
            id: groupInternet
            text: i18nc("@option:check", "Group Internet applications")
            checked: Plasmoid.configuration.groupInternet
            enabled: groupProgramsByCategory.checked
        }

        QQC2.CheckBox {
            id: groupMultimedia
            text: i18nc("@option:check", "Group Multimedia applications")
            checked: Plasmoid.configuration.groupMultimedia
            enabled: groupProgramsByCategory.checked
        }

        QQC2.CheckBox {
            id: groupOffice
            text: i18nc("@option:check", "Group Office applications")
            checked: Plasmoid.configuration.groupOffice
            enabled: groupProgramsByCategory.checked
        }

        QQC2.CheckBox {
            id: groupScience
            text: i18nc("@option:check", "Group Science applications")
            checked: Plasmoid.configuration.groupScience
            enabled: groupProgramsByCategory.checked
        }

        QQC2.CheckBox {
            id: showLinuxTools
            text: i18nc("@option:check", "Show Linux Tools folder")
            checked: Plasmoid.configuration.showLinuxTools
        }
    }

    QQC2.ButtonGroup {
        id: paneSwapGroup
        onCheckedButtonChanged: {
            if (checkedButton) {
                root.cfg_paneSwap = checkedButton.index === 1
            }
        }
    }

    QQC2.ButtonGroup {
        id: radioGroup
        onCheckedButtonChanged: {
            if (checkedButton) {
                root.cfg_primaryActions = checkedButton.index
                root.cfg_systemFavorites = checkedButton.actions
            }
        }
    }
}
