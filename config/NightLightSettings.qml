pragma Singleton
import QtQuick
import Quickshell
import qs.theme

// Night light: how warm (Kelvin) and an optional schedule. Settings →
// Tools → Night Light edits these through `editor`. The pill's wheel and
// its right-click menu change the temperature at once with setTempLive(),
// and the menu saves the schedule with setScheduleLive(), setStartLive(),
// and setEndLive().
Singleton {
    id: root

    readonly property Draft editor: Draft {
        owner: root
    }

    function tempNorm(value) {
        const n = Math.round(Number(value) / Theme.nightTempStep) * Theme.nightTempStep
        return n >= Theme.nightTempMin && n <= Theme.nightTempMax ? n : Theme.nightTempDefault
    }

    function timeNorm(value, fallback) {
        const m = /^(\d{1,2}):(\d{2})$/.exec(String(value || "").trim())
        if (!m || Number(m[1]) > 23 || Number(m[2]) > 59)
            return fallback
        return (m[1].length < 2 ? "0" : "") + m[1] + ":" + m[2]
    }

    function minutesOf(hhmm) {
        const parts = String(hhmm).split(":")
        return Number(parts[0]) * 60 + Number(parts[1])
    }

    // True when `date` falls between start and end (crossing midnight is fine).
    function inWindow(date, start, end) {
        const now = date.getHours() * 60 + date.getMinutes()
        const a = root.minutesOf(start)
        const b = root.minutesOf(end)
        if (a === b)
            return false
        return a < b ? now >= a && now < b : now >= a || now < b
    }

    function temp() {
        return root.tempNorm(Config.nightTemp)
    }

    function setTempLive(value) {
        const next = root.tempNorm(value)
        if (next === root.temp())
            return
        Config.saveFields(() => {
            Config.nightTemp = next
        })
    }

    // The right-click menu saves these at once. A time that is not HH:MM
    // (24-hour) is refused, and the saved value stays.
    function setScheduleLive(on) {
        const next = !!on
        if (next === Config.nightSchedule)
            return false
        Config.saveFields(() => {
            Config.nightSchedule = next
        })
        return true
    }

    function setStartLive(value) {
        return root.setTimeLive(false, value)
    }

    function setEndLive(value) {
        return root.setTimeLive(true, value)
    }

    function setTimeLive(end, value) {
        const current = end ? Config.nightEnd : Config.nightStart
        const next = root.timeNorm(value, "")
        if (next.length !== 5 || next === current)
            return false
        Config.saveFields(() => {
            if (end)
                Config.nightEnd = next
            else
                Config.nightStart = next
        })
        return true
    }

    function normalize(src) {
        const s = src || {}
        return {
            temp: root.tempNorm(s.temp),
            schedule: !!s.schedule,
            start: root.timeNorm(s.start, "20:00"),
            end: root.timeNorm(s.end, "07:00")
        }
    }

    function snapshot() {
        return root.normalize({ temp: Config.nightTemp, schedule: Config.nightSchedule, start: Config.nightStart, end: Config.nightEnd })
    }

    function defaults() {
        return root.normalize({ temp: Theme.nightTempDefault, schedule: false })
    }

    function commit(snap) {
        const clean = root.normalize(snap)
        Config.saveFields(() => {
            Config.nightTemp = clean.temp
            Config.nightSchedule = clean.schedule
            Config.nightStart = clean.start
            Config.nightEnd = clean.end
        })
    }
}
