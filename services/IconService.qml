pragma Singleton
import QtQuick
import Quickshell
import qs.config

// Turns an icon theme name or an absolute path into an Image source.
// Returns "" when there is nothing safe to show, so callers can draw
// their own fallback.
Singleton {
    id: root

    // Encode each path segment so "#", "%", "?" and spaces stay part of
    // the file name instead of being read as URL syntax.
    function fileUrl(path) {
        return "file://" + String(path).split("/").map(encodeURIComponent).join("/")
    }

    function url(iconName) {
        const text = String(iconName || "")
        if (!text.length || !Config.iconOk(text) || text.indexOf("..") >= 0)
            return ""
        if (text.charAt(0) === "/")
            return root.fileUrl(text)
        const found = String(Quickshell.iconPath(text, true) || "")
        if (!found.length)
            return ""
        if (found.indexOf("://") >= 0)
            return found
        if (found.charAt(0) === "/")
            return root.fileUrl(found)
        return found
    }
}
