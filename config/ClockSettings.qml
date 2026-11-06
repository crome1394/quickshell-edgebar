pragma Singleton
import QtQuick
import Quickshell
import qs.theme

// Region & Clock → Clock: the clock face, the week start, and which click
// opens the calendar.
Singleton {
    id: root

    readonly property string defaultFormat: "dddd, MM·dd·yyyy | HH:mm:ss"

    readonly property Draft editor: Draft {
        owner: root
    }

    readonly property var presets: [
        { label: "Full", format: "dddd, MM·dd·yyyy | HH:mm:ss", tip: "Weekday, date, and 24-hour time with seconds" },
        { label: "Date", format: "ddd MM·dd·yyyy  HH:mm", tip: "Short weekday, date, and time" },
        { label: "Time", format: "HH:mm:ss", tip: "24-hour time with seconds" },
        { label: "Short", format: "HH:mm", tip: "24-hour time" },
        { label: "12h", format: "h:mm AP", tip: "12-hour time with AM or PM" },
        { label: "US", format: "ddd M/d/yyyy  h:mm AP", tip: "US date and 12-hour time" },
        { label: "ISO", format: "yyyy-MM-dd HH:mm", tip: "ISO date and 24-hour time" },
        { label: "ISO seconds", format: "yyyy-MM-dd HH:mm:ss", tip: "ISO date and 24-hour time with seconds" },
        { label: "Weekday", format: "dddd HH:mm", tip: "Weekday and 24-hour time" }
    ]

    // True when a Qt date format shows seconds. Quoted text is literal.
    function hasSeconds(format) {
        return /s/.test(String(format || "").replace(/'[^']*'/g, ""))
    }

    function formatNorm(fmt) {
        let text = String(fmt || "").replace(/[\r\n]/g, " ").trim()
        if (text.length > Theme.clockFormatMax)
            text = text.substring(0, Theme.clockFormatMax).trim()
        return text.length ? text : root.defaultFormat
    }

    function percentNorm(pct) {
        return Config.fontPercentNorm(pct)
    }

    function weekNorm(value) {
        const n = Math.round(Number(value))
        return n >= 0 && n <= 6 ? n : 0
    }

    function clickNorm(value) {
        return String(value || "") === "left" ? "left" : "right"
    }

    // Saved values, for the pill.
    function formatText() {
        return root.formatNorm(Config.clockFormat)
    }

    function percentValue() {
        const n = Math.round(Number(Config.clockFontPercent))
        if (n >= Theme.clockFontMin && n <= Theme.clockFontMax)
            return n
        return Theme.clockFontDefault
    }

    function fontFamily(fallback) {
        const name = Config.fontClamp(Config.clockFont)
        return name.length ? name : String(fallback || "")
    }

    function colorValue() {
        return Config.colorNorm(Config.clockColor)
    }

    function weekStartValue() {
        return root.weekNorm(Config.clockWeekStart)
    }

    function clickValue() {
        return root.clickNorm(Config.clockClick)
    }

    // The format field keeps what was typed; signature() compares what would save.
    function normalize(src) {
        let format = String(src.format || "").replace(/[\r\n]/g, " ")
        if (format.length > Theme.clockFormatMax)
            format = format.substring(0, Theme.clockFormatMax)
        return {
            format: format,
            font: Config.fontClamp(src.font),
            percent: root.percentNorm(src.percent),
            bold: !!src.bold,
            italic: !!src.italic,
            color: Config.colorNorm(src.color),
            weekStart: root.weekNorm(src.weekStart),
            click: root.clickNorm(src.click)
        }
    }

    function signature(src) {
        const v = root.normalize(src)
        v.format = root.formatNorm(v.format)
        return JSON.stringify(v)
    }

    function snapshot() {
        return root.normalize({
            format: root.formatText(),
            font: Config.clockFont,
            percent: root.percentValue(),
            bold: Config.clockBold,
            italic: Config.clockItalic,
            color: Config.clockColor,
            weekStart: Config.clockWeekStart,
            click: Config.clockClick
        })
    }

    function defaults() {
        return {
            format: root.defaultFormat,
            font: "",
            percent: Theme.clockFontDefault,
            bold: true,
            italic: false,
            color: "",
            weekStart: 0,
            click: "right"
        }
    }

    function commit(snap) {
        const clean = root.normalize(snap)
        Config.saveFields(() => {
            Config.clockFormat = root.formatNorm(clean.format)
            Config.clockFont = clean.font
            Config.clockFontPercent = clean.percent
            Config.clockBold = clean.bold
            Config.clockItalic = clean.italic
            Config.clockColor = clean.color
            Config.clockWeekStart = clean.weekStart
            Config.clockClick = clean.click
        })
    }
}
