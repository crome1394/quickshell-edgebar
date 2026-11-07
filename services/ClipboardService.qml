pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.theme

// Clipboard history through cliphist. While history is on (Settings →
// Tools → Clipboard) and cliphist is installed, one `wl-paste --watch`
// stores each copy; nothing else runs until the viewer opens. The viewer
// (ClipboardPanel) exists only while open: qs ipc call clipboard toggle.
//
// cliphist skips copies a password manager marks as sensitive.
// Commands are fixed argv; entry ids are checked to be numbers first.
Singleton {
    id: root

    property bool open: false
    property bool checked: false
    property bool available: false
    readonly property bool recording: ClipboardSettings.enabled() && root.available

    // Newest first: { id, preview, kind, detail, color }.
    property var entries: []
    property bool loading: false
    property string error: ""

    // Private per-user folder for decoded preview images; none without
    // XDG_RUNTIME_DIR (never a shared /tmp), so images just don't preview.
    readonly property string runtimeDir: String(Quickshell.env("XDG_RUNTIME_DIR") || "")
    readonly property string imageDir: root.runtimeDir.length ? root.runtimeDir + "/quickshell-clipboard" : ""

    function toggle() {
        if (root.open)
            root.hide()
        else
            root.show()
    }

    // Opening checks again for cliphist when it was missing, so installing
    // it needs no restart.
    function show() {
        root.open = true
        if (!root.available)
            probe.running = true
        root.refresh()
    }

    function hide() {
        root.open = false
        if (root.imageDir.length)
            cleanImages.running = true
    }

    function idOk(id) {
        return /^\d{1,12}$/.test(String(id || ""))
    }

    // What kind of entry a cliphist preview line is, for the tag and the
    // preview pane. Images come as "[[ binary data 33 KiB png 800x600 ]]".
    function classify(preview) {
        const p = String(preview || "").trim()
        const bin = p.match(/^\[\[ binary data (.+?) \]\]$/)
        if (bin) {
            const dims = bin[1].match(/(\d+x\d+)/)
            const size = bin[1].match(/^(\d+(?:\.\d+)? \w+)/)
            return { kind: "image", detail: [size ? size[1] : "", dims ? dims[1] : ""].filter((x) => x.length).join(" · ") }
        }
        if (/^https?:\/\/\S+$/i.test(p))
            return { kind: "link", detail: "" }
        if (/^#(?:[0-9a-f]{3}|[0-9a-f]{4}|[0-9a-f]{6}|[0-9a-f]{8})$/i.test(p) || /^rgba?\(\s*\d{1,3}\s*,\s*\d{1,3}\s*,\s*\d{1,3}\s*(,\s*[\d.]+\s*)?\)$/i.test(p))
            return { kind: "color", detail: "" }
        if (/^(?:~|\.{0,2}\/|file:\/\/)[^\s]*$/.test(p) && p.length > 1)
            return { kind: "path", detail: "" }
        if (/[{};]\s|=>|::|\b(?:function|def|const|let|import|return|class|fn|pub|var)\b|^\s*[$#] |\|\s*\w+|&&/.test(p))
            return { kind: "code", detail: "" }
        return { kind: "text", detail: "" }
    }

    // `cliphist list` output: "<id>\t<preview>" per line, newest first.
    function parse(text) {
        const out = []
        const lines = String(text || "").split("\n")
        for (let i = 0; i < lines.length; i++) {
            const tab = lines[i].indexOf("\t")
            if (tab < 1)
                continue
            const id = lines[i].substring(0, tab)
            if (!root.idOk(id))
                continue
            const preview = lines[i].substring(tab + 1)
            const kind = root.classify(preview)
            out.push({ id: id, preview: preview, kind: kind.kind, detail: kind.detail })
        }
        return out
    }

    function refresh() {
        if (!root.available) {
            root.entries = []
            return
        }
        root.loading = true
        listProc.running = true
    }

    // Copy an entry back to the clipboard (it moves to the top of the history).
    function copy(entry) {
        if (!entry || !root.idOk(entry.id))
            return false
        Quickshell.execDetached(["sh", "-c", "cliphist decode \"$1\" | wl-copy", "sh", entry.id])
        return true
    }

    function remove(entry) {
        if (!entry || !root.idOk(entry.id))
            return
        root.entries = root.entries.filter((e) => e.id !== entry.id)
        Quickshell.execDetached(["sh", "-c", "printf '%s\\t\\n' \"$1\" | cliphist delete", "sh", entry.id])
    }

    function wipe() {
        root.entries = []
        if (root.available)
            Quickshell.execDetached(["cliphist", "wipe"])
    }

    // Full text of an entry for the preview pane. done(text). One at a
    // time: a newer request replaces an older one.
    property var textDone: null
    function previewText(entry, done) {
        if (!entry || !root.idOk(entry.id))
            return
        root.textDone = done
        textProc.running = false
        textProc.command = ["cliphist", "decode", entry.id]
        textProc.running = true
    }

    // An image entry written to a private runtime folder for the preview
    // pane. done(fileUrl), "" on failure. Written to a temp name, then moved.
    property var imageDone: null
    function previewImage(entry, done) {
        if (!entry || !root.idOk(entry.id) || !root.imageDir.length) {
            done("")
            return
        }
        root.imageDone = done
        imageProc.running = false
        imageProc.target = root.imageDir + "/" + entry.id + ".img"
        imageProc.command = ["sh", "-c",
            "umask 077 && mkdir -p -- \"$2\" && cliphist decode \"$1\" > \"$2/.$1.tmp\" && mv -f -- \"$2/.$1.tmp\" \"$2/$1.img\"",
            "sh", entry.id, root.imageDir]
        imageProc.running = true
    }

    // Is cliphist installed? Fixed script, no input.
    Process {
        id: probe
        running: true
        command: ["sh", "-c", "command -v cliphist"]
        onExited: (code) => {
            root.available = code === 0
            root.checked = true
            if (root.available && root.open)
                root.refresh()
        }
    }

    function recheck() {
        probe.running = true
    }

    // The history keeper: wl-paste runs cliphist store on every copy.
    // setpriv makes the kernel stop it when the bar exits, even on a crash
    // or kill, so restarts never leave extra watchers behind.
    Process {
        id: watcher
        running: root.recording
        command: ["setpriv", "--pdeathsig", "TERM", "--", "wl-paste"].concat(ClipboardSettings.images() ? [] : ["--type", "text"])
            .concat(["--watch", "cliphist", "-max-items", String(ClipboardSettings.maxItems()), "store"])
        onExited: {
            if (root.recording)
                watcherRestart.restart()
        }
    }

    Timer {
        id: watcherRestart
        interval: Theme.clipboardRestartMs
        onTriggered: {
            if (root.recording && !watcher.running)
                watcher.running = Qt.binding(() => root.recording)
        }
    }

    Process {
        id: listProc
        command: ["cliphist", "-preview-width", String(Theme.clipboardPreviewWidth), "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.entries = root.parse(text)
                root.loading = false
            }
        }
        onExited: (code) => {
            root.loading = false
            root.error = code === 0 ? "" : "cliphist could not read the history."
        }
    }

    Process {
        id: textProc
        stdout: StdioCollector {
            onStreamFinished: {
                if (root.textDone)
                    root.textDone(text.length > Theme.clipboardPreviewMax ? text.substring(0, Theme.clipboardPreviewMax) + "\n…" : text)
            }
        }
    }

    Process {
        id: imageProc
        property string target: ""
        onExited: (code) => {
            if (root.imageDone)
                root.imageDone(code === 0 ? "file://" + imageProc.target : "")
        }
    }

    // Decoded preview images are dropped when the viewer closes.
    Process {
        id: cleanImages
        command: ["rm", "-rf", "--", root.imageDir]
    }

    // qs ipc call clipboard toggle | open | close
    IpcHandler {
        target: "clipboard"
        function toggle(): void { root.toggle() }
        function open(): void { root.show() }
        function close(): void { root.hide() }
    }
}
