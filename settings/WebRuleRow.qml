import QtQuick
import qs.theme

// One web search shortcut on the Launcher page: the shortcuts typed
// before the search (space-separated), a name, and the address the
// search words are added to. Edits go into the page's draft.
Row {
    id: root

    required property var rule

    signal edited(string key, string value)
    signal removeClicked()

    spacing: Theme.tabGap

    TextBox {
        width: Math.round((root.width - remove.width - root.spacing * 3) * 0.18)
        text: String(root.rule.prefixes || "")
        placeholderText: "ddg"
        onTextEdited: root.edited("prefixes", text)
    }

    TextBox {
        width: Math.round((root.width - remove.width - root.spacing * 3) * 0.27)
        text: String(root.rule.name || "")
        placeholderText: "DuckDuckGo"
        onTextEdited: root.edited("name", text)
    }

    TextBox {
        width: Math.round((root.width - remove.width - root.spacing * 3) * 0.55)
        text: String(root.rule.url || "")
        placeholderText: "duckduckgo.com/?q="
        onTextEdited: root.edited("url", text)
    }

    ChipButton {
        id: remove
        label: "✕"
        tip: "Remove this shortcut"
        onClicked: root.removeClicked()
    }
}
