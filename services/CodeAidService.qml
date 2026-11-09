pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import qs.codeaid
import qs.config
import qs.theme

// Code Aid: copy a code snippet. Whether the picker is open, the snippet
// folder (read only while it is needed), copying, and saving or deleting
// snippet files. shell.qml creates CodeAidPanel only while open. With
// the built-in one off (Settings → Tools → Code Aid), toggling runs your
// command instead (such as rofi-code-aid).
Singleton {
    id: root

    property bool open: false
    // A copy by name waiting for the folder to be read (IPC copy).
    property string pendingLabel: ""
    property string error: ""
    // What was last copied, read fresh with wl-paste: the bar only hears
    // about clipboard changes while it has focus, so its own copy can be old.
    property string clipboard: ""

    readonly property string dir: CodeAidSettings.dirValue()
    readonly property bool storeWanted: root.open || root.pendingLabel.length > 0
    readonly property var store: storeLoader.item

    function toggle() {
        if (root.open)
            root.hide()
        else
            root.show()
    }

    function show() {
        if (!CodeAidSettings.builtIn()) {
            const argv = CodeAidSettings.commandArgv()
            if (argv.length)
                Quickshell.execDetached(argv)
            return
        }
        SearchService.hide()
        LibraryService.hide()
        root.error = ""
        root.readClipboard()
        root.open = true
    }

    function hide() {
        root.open = false
    }

    // Copy finished code, and remember the snippet for the Recent group.
    function copy(text, label) {
        SearchService.copyText(String(text || ""))
        SearchService.record("snip:" + String(label || ""))
    }

    function lastUsed(label) {
        const r = SearchService.history["snip:" + String(label || "")]
        return r ? Number(r.t || 0) : 0
    }

    function findByLabel(label) {
        const list = root.store ? root.store.snippets : []
        const want = String(label || "").toLowerCase()
        for (let i = 0; i < list.length; i++) {
            if (list[i].label.toLowerCase() === want)
                return list[i]
        }
        return null
    }

    function readClipboard() {
        if (paste.running)
            return
        root.clipboard = String(Quickshell.clipboardText || "")
        paste.running = true
    }

    // Blanks get their defaults when copying by name. Waits for both the
    // folder and a fresh clipboard reading.
    function copyPending() {
        if (paste.running || !root.store || !root.store.ready)
            return
        const s = root.findByLabel(root.pendingLabel)
        if (s)
            root.copy(CodeAidLogic.fill(s.body, {}, root.clipboard), s.label)
        root.pendingLabel = ""
    }

    // Save a snippet: old is the snippet being edited, or null for a new
    // one. Returns "" when saving started, or why it cannot.
    function save(old, language, name, body) {
        const label = CodeAidLogic.makeLabel(language, name)
        const parts = CodeAidLogic.splitLabel(label)
        if (!parts.name.length)
            return "Give the snippet a name."
        if (String(body || "").length > CodeAidLogic.bodyMax)
            return "That snippet is too long."
        const other = root.findByLabel(label)
        if (other && (!old || other.path !== old.path))
            return "There is already a snippet called " + label + "."
        if (!root.store || !root.dir.length)
            return "The snippet folder is not ready yet."
        // Keep an edited snippet's file unless its label changed.
        let file = old ? old.file : ""
        if (!old || CodeAidLogic.fileName(label) !== CodeAidLogic.fileName(old.label)) {
            const base = CodeAidLogic.fileName(label)
            file = base
            for (let n = 2; root.store.fileNames.indexOf(file) >= 0; n++)
                file = base + "-" + n
        }
        if (!CodeAidLogic.fileNameOk(file))
            return "That name cannot be used for a file."
        writer.pendingText = CodeAidLogic.serialize(label, body)
        writer.pendingPath = root.dir + "/" + file
        writer.removeAfter = old && old.file !== file ? old.path : ""
        mkdir.command = ["mkdir", "-p", "--", root.dir]
        mkdir.running = true
        return ""
    }

    // Delete a snippet's file. Only files this tool would write, in the
    // snippet folder.
    function remove(snip) {
        if (!snip || !root.safePath(snip.path))
            return false
        rm.command = ["rm", "--", snip.path]
        rm.running = true
        return true
    }

    function safePath(path) {
        const p = String(path || "")
        const cut = p.lastIndexOf("/")
        return cut > 0 && p.substring(0, cut) === root.dir && CodeAidLogic.fileNameOk(p.substring(cut + 1))
    }

    LazyLoader {
        id: storeLoader
        active: root.storeWanted && root.dir.length > 0
        CodeAidStore {
            id: loadedStore
            dir: root.dir
            onReadyChanged: {
                if (loadedStore.ready && root.pendingLabel.length)
                    root.copyPending()
            }
        }
    }

    Process {
        id: paste
        command: ["wl-paste", "-n"]
        stdout: StdioCollector {
            id: pasteOut
            waitForEnd: true
        }
        onExited: (code) => {
            // No wl-paste, or an empty or non-text clipboard: keep what the bar knows.
            if (code === 0)
                root.clipboard = pasteOut.text
            if (root.pendingLabel.length)
                root.copyPending()
        }
    }

    Process {
        id: mkdir
        onExited: (code) => {
            if (code !== 0) {
                root.error = "Could not make the snippet folder."
                return
            }
            writer.path = writer.pendingPath
            writer.setText(writer.pendingText)
        }
    }

    FileView {
        id: writer
        property string pendingText: ""
        property string pendingPath: ""
        property string removeAfter: ""
        atomicWrites: true
        printErrors: false
        blockLoading: false
        onSaved: {
            root.error = ""
            if (writer.removeAfter.length && root.safePath(writer.removeAfter)) {
                rm.command = ["rm", "--", writer.removeAfter]
                rm.running = true
            }
            writer.removeAfter = ""
        }
        onSaveFailed: root.error = "Could not save the snippet."
    }

    Process {
        id: rm
        onExited: (code) => {
            if (code !== 0)
                root.error = "Could not delete the snippet."
        }
    }

    // qs ipc call codeAid toggle | open | close   (same as the keybind)
    // qs ipc call codeAid copy "<language · name>" copy a snippet, blanks at their defaults
    IpcHandler {
        target: "codeAid"
        function toggle(): void { root.toggle() }
        function open(): void { root.show() }
        function close(): void { root.hide() }
        function copy(label: string): string {
            const l = String(label || "").trim()
            if (!l.length || l.length > 200 || /[\r\n\0]/.test(l))
                return "give a label, like: bash · for loop"
            root.pendingLabel = l
            root.readClipboard()
            return "copying " + l
        }
    }
}
