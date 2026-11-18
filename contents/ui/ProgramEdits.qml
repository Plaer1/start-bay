/* SPDX-License-Identifier: GPL-2.0-or-later */
import QtQuick

// Per-applet presentation edits. Provider entries and desktop files are never
// modified; sourceKey identifies the catalog entry behind an app shortcut.
QtObject {
    id: root
    required property var configuration
    property var baseEntries: []
    property var providerEntries: baseEntries
    property string clipboardKey: ""
    property string clipboardMode: ""
    readonly property string serialized: configuration.programEdits || ""
    readonly property var entries: project(baseEntries)
    readonly property bool hasHidden: readState().hidden.length > 0
    signal changed()

    function readState() {
        let value
        try { value = JSON.parse(serialized || "{}") } catch (error) { value = {} }
        if (!value || typeof value !== "object" || Array.isArray(value)) value = {}
        if (!value.overrides || typeof value.overrides !== "object" || Array.isArray(value.overrides)) value.overrides = {}
        if (!Array.isArray(value.added)) value.added = []
        if (!Array.isArray(value.hidden)) value.hidden = []
        return value
    }

    function save(state) {
        configuration.programEdits = JSON.stringify(state)
        changed()
    }

    function project(input) {
        const state = readState()
        const base = Array.isArray(input) ? input : []
        const providers = new Map()
        for (const entry of providerEntries) providers.set(entry.key, entry)
        const all = []
        for (const entry of base.concat(state.added)) {
            if (!entry || !entry.key) continue
            const provider = entry.sourceKey ? providers.get(entry.sourceKey) : null
            // A copy keeps its own identity and placement, but follows current
            // provider metadata when the source is still installed.
            const item = Object.assign({}, entry)
            if (provider && !item.isFolder) {
                item.description = provider.description
                item.icon = provider.icon
                item.url = provider.url
                item.favoriteId = provider.favoriteId
                item.hasActionList = provider.hasActionList
                item.canActivate = provider.canActivate
            } else if (item.sourceKey && !item.isFolder) {
                item.canActivate = false
                item.hasActionList = false
            }
            const override = state.overrides[item.key]
            if (override && typeof override === "object") {
                if (typeof override.title === "string") item.title = override.title
                if (typeof override.parentKey === "string") item.parentKey = override.parentKey
            }
            all.push(item)
        }
        const byKey = new Map(all.map(entry => [entry.key, entry]))
        // Keep edited shortcuts reachable if their old provider folder vanishes.
        for (const entry of all) {
            if (entry.parentKey && !byKey.has(entry.parentKey)) entry.parentKey = ""
        }
        const hidden = new Set(state.hidden)
        // A hidden folder hides its descendants without destroying their edits.
        return all.filter(entry => {
            let current = entry
            const visited = new Set()
            while (current) {
                if (hidden.has(current.key) || visited.has(current.key)) return false
                visited.add(current.key)
                current = current.parentKey ? byKey.get(current.parentKey) : null
            }
            return true
        })
    }

    function find(key) { return entries.find(entry => entry.key === key) }
    function isFolder(key) { return key === "" || !!find(key)?.isFolder }
    function cleanTitle(title) { return String(title || "").trim() }
    function update(key, field, value) {
        const state = readState()
        const override = state.overrides[key] || {}
        override[field] = value
        state.overrides[key] = override
        save(state)
    }
    function rename(key, title) {
        const value = cleanTitle(title)
        if (!find(key) || !value) return false
        update(key, "title", value)
        return true
    }
    function cut(key) {
        if (!find(key)) return false
        clipboardKey = key
        clipboardMode = "cut"
        return true
    }
    function copy(key) {
        if (!find(key)) return false
        clipboardKey = key
        clipboardMode = "copy"
        return true
    }
    function canPaste(folderKey) {
        const source = find(clipboardKey)
        if (!source || !isFolder(folderKey) || (clipboardMode !== "cut" && clipboardMode !== "copy")) return false
        // A folder cannot be pasted into itself or any descendant.
        let current = folderKey
        const visited = new Set()
        while (current) {
            if (current === source.key || visited.has(current)) return false
            visited.add(current)
            const parent = find(current)
            if (!parent) return false
            current = parent.parentKey
        }
        return true
    }
    function newKey() {
        return "user:" + Date.now().toString(36) + ":" + Math.random().toString(36).slice(2)
    }
    function paste(folderKey) {
        if (!canPaste(folderKey)) return false
        const source = find(clipboardKey)
        if (clipboardMode === "cut") {
            update(source.key, "parentKey", folderKey)
            clipboardKey = ""
            clipboardMode = ""
            return true
        }
        const state = readState()
        const visible = entries
        function cloneBranch(item, parentKey) {
            const clone = {
                key: newKey(), parentKey: parentKey, title: item.title, isFolder: item.isFolder,
                description: "", icon: item.isFolder ? "folder" : "application-x-executable",
                url: "", favoriteId: "", hasActionList: false, canActivate: false
            }
            if (!clone.isFolder) clone.sourceKey = item.sourceKey || item.key
            state.added.push(clone)
            if (item.isFolder) {
                for (const child of visible.filter(candidate => candidate.parentKey === item.key)) {
                    cloneBranch(child, clone.key)
                }
            }
        }
        cloneBranch(source, folderKey)
        save(state)
        return true
    }
    function createFolder(folderKey, title) {
        const value = cleanTitle(title)
        if (!isFolder(folderKey) || !value) return false
        const state = readState()
        state.added.push({key: newKey(), parentKey: folderKey, title: value,
                          description: "", icon: "folder", isFolder: true, url: "",
                          favoriteId: "", hasActionList: false, canActivate: false})
        save(state)
        return true
    }
    function remove(key) {
        if (!find(key)) return false
        const state = readState()
        if (!state.hidden.includes(key)) state.hidden.push(key)
        save(state)
        if (clipboardKey === key) { clipboardKey = ""; clipboardMode = "" }
        return true
    }
    function restoreHidden() {
        const state = readState()
        if (!state.hidden.length) return false
        state.hidden = []
        save(state)
        return true
    }
}
