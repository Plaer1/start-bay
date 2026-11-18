/*
    SPDX-License-Identifier: GPL-2.0-or-later
 */

import QtQuick
import org.kde.kirigami as Kirigami

Kirigami.Icon {
    id: root

    // Keep QIcon and QUrl values from KDE models intact. A bare absolute
    // filesystem path needs a file URL; theme names must remain strings.
    property var decoration
    property string fallbackName: "application-x-executable"

    readonly property var resolvedDecoration: {
        if (typeof decoration === "string" && decoration.startsWith("/")) {
            return Qt.resolvedUrl("file://" + decoration.split("/").map(encodeURIComponent).join("/"))
        }
        return decoration || fallbackName
    }

    source: resolvedDecoration
    fallback: fallbackName
}
