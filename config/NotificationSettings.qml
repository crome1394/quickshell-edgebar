pragma Singleton
import QtQuick
import Quickshell
import qs.theme

// Notifications page: toast corner and timeout, and history options.
// applySerial counts saves, so NotificationService can push the corner
// and timeout into the SwayNC config.
Singleton {
    id: root

    property int applySerial: 0

    readonly property Draft editor: Draft {
        owner: root
    }

    function cornerNorm(value) {
        const corner = String(value || "")
        if (corner === "topLeft" || corner === "topRight" || corner === "bottomLeft" || corner === "bottomRight")
            return corner
        return "bottomRight"
    }

    function timeoutNorm(value) {
        let n = Math.round(Number(value))
        if (!(n >= 0))
            n = Theme.notificationTimeoutDefault
        if (n > Theme.notificationTimeoutMax)
            n = Theme.notificationTimeoutMax
        return n
    }

    function cornerValue() {
        return root.cornerNorm(Config.notificationCorner)
    }

    function timeoutValue() {
        return root.timeoutNorm(Config.notificationTimeout)
    }

    function normalize(src) {
        return {
            expand: !!src.expand,
            stagger: src.stagger !== false,
            clearBoot: !!src.clearBoot,
            showCount: src.showCount !== false,
            corner: root.cornerNorm(src.corner),
            timeout: root.timeoutNorm(src.timeout === undefined ? Theme.notificationTimeoutDefault : src.timeout)
        }
    }

    function snapshot() {
        return root.normalize({
            expand: Config.notificationAutoExpand,
            stagger: Config.notificationStaggerRows,
            clearBoot: Config.notificationClearOnBoot,
            showCount: Config.notificationShowCount,
            corner: Config.notificationCorner,
            timeout: Config.notificationTimeout
        })
    }

    function defaults() {
        return {
            expand: false,
            stagger: true,
            clearBoot: false,
            showCount: true,
            corner: "bottomRight",
            timeout: Theme.notificationTimeoutDefault
        }
    }

    function commit(snap) {
        const clean = root.normalize(snap)
        Config.saveFields(() => {
            Config.notificationAutoExpand = clean.expand
            Config.notificationStaggerRows = clean.stagger
            Config.notificationClearOnBoot = clean.clearBoot
            Config.notificationShowCount = clean.showCount
            Config.notificationCorner = clean.corner
            Config.notificationTimeout = clean.timeout
        })
        root.applySerial++
    }
}
