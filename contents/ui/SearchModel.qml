/* SPDX-License-Identifier: GPL-2.0-or-later */

import QtQuick

// Materialize Kicker's child rows with their native QML roles. Each result's
// source and row travel together, so activation never searches by display text.
Item {
    id: root
    visible: false
    property var catalog
    property var entries: []
    property var runnerModel
    property string query: ""
    property alias model: results
    property var sources: []
    property string completedQuery: ""

    function desktopId(value) {
        let id = String(value || "").split("?")[0].split("#")[0];
        if (id.startsWith("applications:")) id = id.substring("applications:".length);
        if (id.includes("/")) id = id.substring(id.lastIndexOf("/") + 1);
        return id.endsWith(".desktop") ? id : "";
    }
    function schedule() { Qt.callLater(rebuild); }
    function rebuild() {
        const needle = query.trim().toLowerCase();
        results.clear();
        sources = [];
        if (!needle) return;
        const seen = {};
        for (const entry of entries) {
            if (entry.isFolder || !entry.canActivate ||
                !(String(entry.title).toLowerCase().includes(needle) ||
                  String(entry.description || "").toLowerCase().includes(needle))) continue;
            const id = desktopId(entry.favoriteId) || desktopId(entry.url);
            const key = id || entry.key;
            if (seen[key]) continue;
            seen[key] = true;
            sources.push({ local: true, key: entry.sourceKey || entry.key, query: query });
            results.append({ display: entry.title, description: entry.description || "",
                decoration: entry.icon || "", url: entry.url || "", group: i18n("Applications"),
                favoriteId: entry.favoriteId || "", hasActionList: !!entry.hasActionList,
                isMultilineText: false });
        }
        // Do not retain runner rows from an earlier query while the runner is
        // still resolving the current one.
        if (completedQuery !== query || !runnerModel || runnerModel.querying) return;
        for (let i = 0; i < groups.count; ++i) {
            const group = groups.objectAt(i);
            if (!group) continue;
            for (let j = 0; j < group.rows.count; ++j) {
                const row = group.rows.objectAt(j);
                if (!row || !row.data) continue;
                const data = row.data;
                const id = desktopId(data.favoriteId) || desktopId(data.url);
                if (id && seen[id]) continue;
                if (id) seen[id] = true;
                sources.push({ local: false, model: group.childModel, rowObject: row, query: query });
                results.append({ display: String(data.display || ""),
                    description: String(data.description || ""),
                    decoration: data.decoration || "", url: data.url || "",
                    group: String(data.group || ""), favoriteId: data.favoriteId || "",
                    hasActionList: !!data.hasActionList,
                    isMultilineText: !!data.isMultilineText });
            }
        }
    }
    onQueryChanged: { completedQuery = ""; schedule(); }
    onEntriesChanged: schedule()
    onRunnerModelChanged: schedule()
    Connections {
        target: root.runnerModel
        ignoreUnknownSignals: true
        function onQueryFinished() { root.completedQuery = root.query; root.schedule(); }
        function onModelReset() { root.schedule(); }
        function onRowsInserted() { root.schedule(); }
        function onRowsRemoved() { root.schedule(); }
        function onDataChanged() { root.schedule(); }
    }
    Instantiator {
        id: groups
        model: root.runnerModel
        delegate: QtObject {
            id: group
            required property int index
            readonly property var childModel: root.runnerModel ? root.runnerModel.modelForRow(index) : null
            property alias rows: children
            property Instantiator childRows: Instantiator {
                id: children
                model: group.childModel
                delegate: QtObject {
                    required property int index
                    required property var model
                    readonly property int rowIndex: index
                    readonly property var data: model
                }
                onObjectAdded: root.schedule()
                onObjectRemoved: root.schedule()
            }
            property Connections childChanges: Connections {
                target: group.childModel
                ignoreUnknownSignals: true
                function onDataChanged() { root.schedule(); }
                function onModelReset() { root.schedule(); }
                function onRowsInserted() { root.schedule(); }
                function onRowsRemoved() { root.schedule(); }
            }
        }
        onObjectAdded: root.schedule()
        onObjectRemoved: root.schedule()
    }
    ListModel {
        id: results
        dynamicRoles: true
        property var favoritesModel: root.runnerModel ? root.runnerModel.favoritesModel : null
        function actionsForRow(row) {
            const source = root.sources[row];
            if (!source || source.query !== root.query) return [];
            return source.local ? root.catalog.actions(source.key) : source.rowObject?.data?.actionList || [];
        }
        function trigger(row, actionId, argument) {
            const source = root.sources[row];
            if (!source || source.query !== root.query) return false;
            if (source.local) return root.catalog && root.catalog.activate(source.key, actionId, argument);
            return source.model && source.rowObject && source.model.trigger(source.rowObject.rowIndex, actionId, argument);
        }
    }
}
