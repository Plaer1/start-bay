/* SPDX-License-Identifier: GPL-2.0-or-later */
.pragma library

// The KDE menu does not expose the .directory ID to QML. These are icon names
// from KDE's standard desktop-directory files, not translated category labels.
function categoryForIcon(icon) {
    const name = String(icon || "").replace(/-symbolic$/, "");
    const categories = {
        "wine": "wine",
        "applications-development": "development",
        "applications-education": "education",
        "applications-games": "games",
        "applications-graphics": "graphics",
        "applications-internet": "internet",
        "applications-network": "internet",
        "applications-multimedia": "multimedia",
        "applications-office": "office",
        "applications-science": "science",
        "applications-system": "system",
        "preferences-system": "settings"
    };
    return categories[name] || "";
}

function project(entries, configuration, linuxToolsTitle) {
    const config = configuration || {};
    const children = {};
    const result = [];
    const seen = {};
    const linuxKey = "startbay:linux-tools";
    const flags = {
        wine: "groupWine", development: "groupDevelopment",
        education: "groupEducation", games: "groupGames",
        graphics: "groupGraphics", internet: "groupInternet",
        multimedia: "groupMultimedia", office: "groupOffice",
        science: "groupScience"
    };
    let linuxAdded = false;

    for (const entry of entries || []) {
        const parent = entry.parentKey || "";
        if (!children[parent]) children[parent] = [];
        children[parent].push(entry);
    }

    function copy(entry, parent) {
        const out = {};
        for (const key in entry) out[key] = entry[key];
        out.parentKey = parent;
        return out;
    }

    function ensureLinux() {
        if (linuxAdded) return;
        linuxAdded = true;
        result.push({key: linuxKey, parentKey: "", title: linuxToolsTitle,
                     description: "", icon: "applications-system", categoryIcon: "",
                     isFolder: true, isVirtual: true, canActivate: false,
                     favoriteId: "", url: "", hasActionList: false});
    }

    function addApp(entry, parent) {
        const id = String(entry.favoriteId || entry.url || entry.key);
        if (!seen[parent]) seen[parent] = {};
        if (seen[parent][id]) return;
        seen[parent][id] = true;
        result.push(copy(entry, parent));
    }

    function walk(sourceParent, destination, flatten, inLinux) {
        const rows = children[sourceParent] || [];
        for (const entry of rows) {
            if (!entry.isFolder) {
                if (inLinux) ensureLinux();
                addApp(entry, destination);
                continue;
            }
            const category = categoryForIcon(entry.categoryIcon || entry.icon);
            const linux = inLinux || (config.showLinuxTools !== false
                                      && (category === "system" || category === "settings"));
            if (linux) {
                walk(entry.key, linuxKey, true, true);
                continue;
            }
            const flag = flags[category];
            const collapse = flatten || config.groupProgramsByCategory === false
                             || (flag && config[flag] === false);
            if (collapse) {
                walk(entry.key, destination, true, false);
            } else {
                result.push(copy(entry, destination));
                walk(entry.key, entry.key, false, false);
            }
        }
    }

    walk("", "", false, false);
    if (config.showLinuxTools !== false) ensureLinux();
    return result;
}
