/* SPDX-License-Identifier: GPL-2.0-or-later */
import QtQuick
import org.kde.kitemmodels as KItemModels

// A snapshot of the KDE application menu. QModelIndex and row numbers are kept
// only until the next rebuild; callers persist keys, never model handles.
Item {
    id: catalog
    visible: false

    required property var rootModel
    property var entries: []
    property var handles: ({})
    signal changed()

    function role(model, row, name) {
        const roleId = model.KItemModels.KRoleNames.role(name);
        return roleId < 0 ? undefined : model.data(model.index(row, 0), roleId);
    }

    function collect(model, parentKey, result, nextHandles) {
        if (!model) return;
        for (let row = 0; row < model.count; ++row) {
            if (role(model, row, "isSeparator")) continue;
            const child = model.modelForRow(row);
            // These are alternate/special views, not application categories.
            if (child && (child.description === "KICKER_ALL_MODEL"
                          || child.description === "KICKER_ALL_APPS"
                          || child.description === "KICKER_FAVORITES_MODEL")) continue;
            const title = String(role(model, row, "display") || "");
            const favoriteId = String(role(model, row, "favoriteId") || "");
            const url = String(role(model, row, "url") || "");
            const isFolder = !!child;
            const icon = role(model, row, "decoration") || "";
            if (!title || (!isFolder && !favoriteId && !url)) continue;
            const identity = isFolder ? title : (favoriteId || url);
            const key = parentKey + "/" + (isFolder ? "folder:" : "app:") + encodeURIComponent(identity);
            if (nextHandles[key]) continue;
            result.push({
                key: key,
                parentKey: parentKey,
                title: title,
                description: String(role(model, row, "description") || ""),
                icon: icon,
                // Kicker exposes no directory ID; KDE directory icon names are
                // nonlocalized category metadata, unlike the displayed title.
                categoryIcon: isFolder ? String(role(model, row, "iconName") || icon.name || icon) : "",
                isFolder: isFolder,
                url: url,
                favoriteId: favoriteId,
                hasActionList: !!role(model, row, "hasActionList"),
                canActivate: !isFolder
            });
            nextHandles[key] = { model: model, row: row };
            if (child) collect(child, key, result, nextHandles);
        }
    }

    function rebuild() {
        const result = [];
        const nextHandles = {};
        collect(rootModel, "", result, nextHandles);
        handles = nextHandles;
        entries = result;
        changed();
    }

    // Returns Kicker's close-request result, not asynchronous launch success.
    function activate(key, actionId, argument) {
        const handle = handles[key];
        if (!handle || !handle.model) return false;
        return handle.model.trigger(handle.row, actionId || "", argument === undefined ? null : argument);
    }

    function actions(key) {
        const handle = handles[key];
        return handle?.model ? role(handle.model, handle.row, "actionList") || [] : [];
    }

    Connections {
        target: catalog.rootModel
        function onModelAboutToBeReset() { catalog.handles = ({}); }
        function onRefreshed() { catalog.rebuild(); }
    }
    Component.onCompleted: rebuild()
}
