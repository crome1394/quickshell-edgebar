pragma Singleton
import QtQuick
import Quickshell
import qs.theme

// Settings → Notifications → On-Screen Display: which events show the
// popup, where it sits, how it looks, its symbols, and its sound. Saved as
// one JSON field (Config.osdJson). The popup itself is OsdHost/OsdPanel.
Singleton {
    id: root

    readonly property Draft editor: Draft {
        owner: root
    }

    // The saved settings, cleaned. The popup reads this.
    readonly property var live: root.snapshot()

    readonly property var vplaces: ["top", "center", "bottom"]
    readonly property var hplaces: ["left", "center", "right"]
    readonly property var sounds: ["theme", "file", "off"]

    // Symbols in the bar's icon font (Symbols Nerd Font). Each can be
    // replaced with any short text, e.g. a different glyph or an emoji.
    readonly property var iconSlots: [
        { id: "volHigh", label: "Volume high", glyph: "" },
        { id: "volMid", label: "Volume medium", glyph: "" },
        { id: "volLow", label: "Volume low", glyph: "" },
        { id: "volMuted", label: "Volume muted", glyph: "" },
        { id: "device", label: "Output device changed", glyph: "" },
        { id: "mic", label: "Microphone", glyph: "" },
        { id: "micMuted", label: "Microphone muted", glyph: "" },
        { id: "play", label: "Playing", glyph: "" },
        { id: "pause", label: "Paused", glyph: "" },
        { id: "track", label: "New track (no cover)", glyph: "" },
        { id: "brightness", label: "Brightness", glyph: "" }
    ]


    function defaultGlyph(slot) {
        for (let i = 0; i < root.iconSlots.length; i++) {
            if (root.iconSlots[i].id === slot)
                return root.iconSlots[i].glyph
        }
        return ""
    }

    // Short text only, no control characters. "" uses the default.
    function glyphNorm(text) {
        return String(text || "").replace(/[\u0000-\u001f\u007f]/g, "").substring(0, Theme.osdGlyphMax)
    }

    function iconsNorm(src) {
        const raw = src && typeof src === "object" ? src : {}
        const out = {}
        for (let i = 0; i < root.iconSlots.length; i++) {
            const id = root.iconSlots[i].id
            out[id] = root.glyphNorm(raw[id])
        }
        return out
    }

    // "auto" or "#rrggbb".
    function colorNorm(value) {
        if (String(value) === "auto")
            return "auto"
        const c = ThemeBuilder.parse(value)
        return c ? ThemeBuilder.rgbText(c) : "auto"
    }

    // An absolute path to a sound file, or "". Never run through a shell.
    function soundFileNorm(text) {
        const path = String(text || "").trim()
        if (!path.length || path.length > 512 || path.charAt(0) !== "/" || /[\u0000-\u001f]/.test(path))
            return ""
        return path
    }

    function normalize(src) {
        const s = src && typeof src === "object" ? src : {}
        const glass = Math.round(Number(s.glass))
        return {
            volume: s.volume !== false,
            mic: s.mic !== false,
            device: s.device !== false,
            track: s.track !== false,
            playback: s.playback !== false,
            brightness: s.brightness !== false,
            vplace: root.vplaces.indexOf(s.vplace) >= 0 ? s.vplace : "bottom",
            hplace: root.hplaces.indexOf(s.hplace) >= 0 ? s.hplace : "center",
            margin: Config.stepped(s.margin, 0, 400, 4, Theme.osdMargin),
            timeout: Config.stepped(s.timeout, 500, 6000, 100, Theme.osdTimeoutMs),
            width: Config.stepped(s.width, 200, 640, 20, Theme.osdWidth),
            textSize: Config.stepped(s.textSize, 80, 160, 10, 100),
            // 0 follows menu glass (System → Transparency).
            glass: glass === 0 ? 0 : Config.stepped(glass, 40, 100, 2, 0),
            accent: root.colorNorm(s.accent === undefined ? "auto" : s.accent),
            text: root.colorNorm(s.text === undefined ? "auto" : s.text),
            border: s.border !== false,
            art: s.art !== false,
            sound: root.sounds.indexOf(s.sound) >= 0 ? s.sound : "theme",
            soundFile: root.soundFileNorm(s.soundFile),
            soundVolume: Config.stepped(s.soundVolume, 0, 100, 5, 60),
            icons: root.iconsNorm(s.icons)
        }
    }

    function snapshot() {
        const text = String(Config.osdJson || "")
        try {
            return root.normalize(text.length ? JSON.parse(text) : {})
        } catch (e) {
            return root.normalize({})
        }
    }

    function defaults() {
        return root.normalize({})
    }

    function commit(snap) {
        const clean = root.normalize(snap)
        Config.saveFields(() => {
            Config.osdJson = JSON.stringify(clean)
        })
    }

    // The symbol for a slot under a look: its own text, else the default.
    function glyph(slot, look) {
        const own = look && look.icons ? String(look.icons[slot] || "") : ""
        return own.length ? own : root.defaultGlyph(slot)
    }

    function setIcon(slot, text) {
        const icons = Object.assign({}, root.editor.value.icons)
        if (icons[slot] === undefined)
            return
        icons[slot] = root.glyphNorm(text)
        root.editor.set("icons", icons)
    }

    // argv for the volume sound, or [] for none. A file plays with pw-play
    // (part of PipeWire); the theme sound with canberra-gtk-play.
    function soundArgv(look) {
        const l = look || root.live
        const vol = Math.max(0, Math.min(100, Number(l.soundVolume))) / 100
        if (l.sound === "file") {
            const path = root.soundFileNorm(l.soundFile)
            return path.length ? ["pw-play", "--volume", vol.toFixed(2), path] : []
        }
        if (l.sound === "theme")
            return ["canberra-gtk-play", "-i", "audio-volume-change", "--volume=" + vol.toFixed(2)]
        return []
    }
}
