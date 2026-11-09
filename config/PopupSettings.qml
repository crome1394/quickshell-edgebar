pragma Singleton
import QtQuick
import Quickshell
import qs.theme

// How the built-in notification popups look: style, size, glass, motion,
// the progress bar, grouping, big image previews, and per-app colors.
// Saved as one JSON field (Config.notificationPopupJson) and edited as the
// `popup` part of NotificationSettings' draft, so the Notifications page
// keeps one Apply/Undo/Reset.
Singleton {
    id: root

    readonly property var styles: ["compact", "standard", "large"]
    readonly property var motions: ["none", "slide", "fade"]

    // The saved look, cleaned. Popups read this.
    readonly property var live: root.saved()


    function appName(text) {
        return String(text || "").replace(/[\u0000-\u001f]/g, "").trim().substring(0, 60)
    }

    function colorsNorm(list) {
        const out = []
        const seen = {}
        const src = Array.isArray(list) ? list : []
        for (let i = 0; i < src.length && out.length < Theme.popupAppColorsMax; i++) {
            const app = root.appName(src[i] && src[i].app)
            const c = ThemeBuilder.parse(src[i] && src[i].color)
            const key = app.toLowerCase()
            if (!app.length || !c || seen[key])
                continue
            seen[key] = true
            out.push({ app: app, color: ThemeBuilder.rgbText(c) })
        }
        return out
    }

    function normalize(src) {
        const s = src && typeof src === "object" ? src : {}
        const glass = Math.round(Number(s.glass))
        return {
            style: root.styles.indexOf(s.style) >= 0 ? s.style : "standard",
            motion: root.motions.indexOf(s.motion) >= 0 ? s.motion : "slide",
            width: Config.stepped(s.width, 280, 560, 20, Theme.notificationToastWidth),
            max: Config.stepped(s.max, 1, 8, 1, Theme.notificationToastMax),
            image: Config.stepped(s.image, 32, 128, 8, Theme.notificationToastImage),
            lines: Config.stepped(s.lines, 0, 10, 1, Theme.notificationToastBodyLines),
            margin: Config.stepped(s.margin, 0, 64, 4, Theme.notificationToastMargin),
            // 0 follows menu glass (System → Transparency).
            glass: glass === 0 ? 0 : Config.stepped(glass, 40, 100, 2, 0),
            stripe: s.stripe !== false,
            group: s.group !== false,
            progress: s.progress !== false,
            bigImages: s.bigImages !== false,
            appColors: root.colorsNorm(s.appColors)
        }
    }

    function saved() {
        const text = String(Config.notificationPopupJson || "")
        try {
            return root.normalize(text.length ? JSON.parse(text) : {})
        } catch (e) {
            return root.normalize({})
        }
    }

    function defaults() {
        return root.normalize({})
    }

    // Called inside Config.saveFields() by NotificationSettings.commit().
    function write(popup) {
        Config.notificationPopupJson = JSON.stringify(root.normalize(popup))
    }

    // The stripe color for an app: your own color, else a steady hue from
    // its name, or "" with the stripe off and no color of its own.
    function appColor(app, look) {
        const p = look || root.live
        const key = root.appName(app).toLowerCase()
        for (let i = 0; i < p.appColors.length; i++) {
            if (p.appColors[i].app.toLowerCase() === key)
                return p.appColors[i].color
        }
        if (!p.stripe || !key.length)
            return ""
        let hash = 0
        for (let k = 0; k < key.length; k++)
            hash = (hash * 31 + key.charCodeAt(k)) % 360
        return Qt.hsla(hash / 360, 0.62, 0.62, 1)
    }
}
