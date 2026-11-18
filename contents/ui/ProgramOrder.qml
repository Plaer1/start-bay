/*
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

import QtQuick

// Orders catalog entries by their stable keys within one folder. The owner
// supplies the applet configuration object and the name of its string entry.
QtObject {
    id: root
    required property var configuration
    required property string configKey
    required property var model
    property string folderKey: ""
    property int firstMovableIndex: 0
    property bool enabled: true

    function storedOrders() {
        try {
            const parsed = JSON.parse(configuration[configKey] || "{}")
            return parsed && typeof parsed === "object" && !Array.isArray(parsed) ? parsed : {}
        } catch (error) {
            return {}
        }
    }

    // Called when populating a folder. Entries absent from the saved order
    // remain reachable, following the ordered entries in catalog order.
    function orderedEntries(entries) {
        if (!enabled) return entries.slice()
        const saved = storedOrders()[folderKey]
        if (!Array.isArray(saved)) return entries.slice()
        const positions = new Map()
        for (let i = 0; i < saved.length; ++i) {
            if (!positions.has(saved[i])) positions.set(saved[i], i)
        }
        return entries.map((entry, index) => ({entry, index})).sort((a, b) => {
            const ai = positions.has(a.entry.key) ? positions.get(a.entry.key) : saved.length + a.index
            const bi = positions.has(b.entry.key) ? positions.get(b.entry.key) : saved.length + b.index
            return ai - bi
        }).map(item => item.entry)
    }

    function canMoveRow(from, to) {
        return enabled && from >= firstMovableIndex && to >= firstMovableIndex
            && from < model.count && to < model.count
            && !!model.get(from).key && !!model.get(to).key
    }

    function moveRow(from, to) {
        if (!canMoveRow(from, to) || from === to) return false
        model.move(from, to, 1)
        const keys = []
        for (let i = firstMovableIndex; i < model.count; ++i) {
            const key = model.get(i).key
            if (key) keys.push(key)
        }
        const orders = storedOrders()
        orders[folderKey] = keys
        configuration[configKey] = JSON.stringify(orders)
        return true
    }
}
