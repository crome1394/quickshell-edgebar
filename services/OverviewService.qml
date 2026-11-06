pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.config
import qs.theme

// Workspace overview. IPC target "overview":
// toggle, open, close, desktop, all, next, prev.
// The heavy layer loads only while this is open. Nothing is captured while it is closed.
Singleton {
    id: root

    property bool open: false
    property real reveal: 0
    property string viewMode: "workspace"
    property int switchDir: 1
    property bool skipCommit: false
    property double lastToggleMs: 0
    property double suppressUntil: 0
    property int openSerial: 0
    property int refreshSerial: 0
    property int commitSerial: 0
    property int stepSerial: 0
    property int stepDir: 1

    readonly property bool surfaceLive: root.open || root.reveal > 0.02

    Behavior on reveal {
        NumberAnimation {
            duration: Math.max(0, OverviewSettings.live.ovDuration)
            easing.type: Easing.OutCubic
        }
    }

    function nowMs() {
        return Date.now()
    }

    function quote(text) {
        return "'" + String(text || "").replace(/\\/g, "\\\\").replace(/'/g, "\\'") + "'"
    }

    // Quickshell addresses omit the 0x prefix Hyprland's address: selector requires.
    function addressOf(addr) {
        let raw = String(addr || "")
        if (raw.indexOf("address:") === 0)
            raw = raw.slice("address:".length)
        if (raw.indexOf("0x") !== 0 && raw.indexOf("0X") !== 0)
            raw = "0x" + raw
        return "address:" + raw
    }

    function dispatch(expr) {
        root.suppressUntil = root.nowMs() + Theme.overviewSuppressMs
        try {
            Hyprland.dispatch(expr)
        } catch (e) {
        }
    }

    function refreshHypr() {
        try {
            Hyprland.refreshMonitors()
        } catch (e) {
        }
        try {
            Hyprland.refreshWorkspaces()
        } catch (e) {
        }
        try {
            Hyprland.refreshToplevels()
        } catch (e) {
        }
    }

    function syncBlur() {
        const on = !!OverviewSettings.live.ovBackdropBlur
        try {
            Hyprland.dispatch("function() hl.layer_rule({ name = \"quickshell-overview-blur\", match = { namespace = \"^quickshell-overview$\" }, blur = "
                + (on ? "true" : "false") + ", ignore_alpha = 0.05 }) end")
        } catch (e) {
        }
    }

    function toggle() {
        const now = root.nowMs()
        if (now - root.lastToggleMs < Theme.overviewDebounceMs)
            return
        root.lastToggleMs = now
        if (root.open)
            root.closeOverview()
        else
            root.openOverview(OverviewSettings.live.ovShowAll ? "all" : "workspace")
    }

    function openMode(mode) {
        const now = root.nowMs()
        if (now - root.lastToggleMs < Theme.overviewDebounceMs)
            return
        root.lastToggleMs = now
        const next = mode === "desktop" || mode === "all" ? mode : "workspace"
        if (root.open && root.viewMode === next) {
            root.closeOverview()
            return
        }
        root.openOverview(next)
    }

    function openOverview(mode) {
        root.refreshHypr()
        root.viewMode = mode === "desktop" || mode === "all" ? mode : "workspace"
        root.open = true
        root.reveal = 1
        root.openSerial++
        root.syncBlur()
    }

    function closeOverview() {
        if (!root.open && root.reveal <= 0)
            return
        if (!root.skipCommit)
            root.commitSerial++
        root.skipCommit = false
        root.open = false
        root.reveal = 0
    }

    function step(dir) {
        root.stepDir = dir >= 0 ? 1 : -1
        if (root.open) {
            root.stepSerial++
            return
        }
        const mon = Hyprland.focusedMonitor
        if (!mon)
            return
        const cards = root.cardsFor(mon.name).filter(function (card) { return !card.all })
        if (!cards.length)
            return
        const key = root.activeKey(mon.name)
        let idx = 0
        for (let i = 0; i < cards.length; i++) {
            if (cards[i].key === key)
                idx = i
        }
        let next = idx + root.stepDir
        if (next < 0)
            next = cards.length - 1
        if (next >= cards.length)
            next = 0
        root.followCard(cards[next], mon.name, true)
    }

    function monitorByName(name) {
        const model = Hyprland.monitors
        const vals = model && model.values ? model.values : []
        for (let i = 0; i < vals.length; i++) {
            if (vals[i].name === name)
                return vals[i]
        }
        return null
    }

    function activeKey(monName) {
        const mon = root.monitorByName(monName)
        const ws = mon ? mon.activeWorkspace : null
        if (!ws)
            return ""
        const name = String(ws.name || "")
        if (name.indexOf("special:") === 0)
            return "s:" + name
        const id = Number(ws.id) || 0
        if (id > 0)
            return "w:" + id
        return ""
    }

    function listOf(model) {
        return model && model.values ? model.values : []
    }

    function windowRecord(tl, monName) {
        if (!tl)
            return null
        const ipc = tl.lastIpcObject || {}
        const mon = tl.monitor
        let owner = mon && mon.name ? String(mon.name) : ""
        if (!owner && tl.workspace && tl.workspace.monitor && tl.workspace.monitor.name)
            owner = String(tl.workspace.monitor.name)
        if (owner !== monName)
            return null
        if (ipc.mapped === false || ipc.hidden)
            return null
        const at = ipc.at || [0, 0]
        const size = ipc.size || [0, 0]
        const w = Number(size[0]) || 0
        const h = Number(size[1]) || 0
        if (w < 2 || h < 2)
            return null
        const ws = tl.workspace
        const wsIpc = ipc.workspace || {}
        const wsName = String((ws && ws.name) || wsIpc.name || "")
        const wsId = (ws && Number(ws.id) > 0) ? Number(ws.id) : (Number(wsIpc.id) || 0)
        const app = (tl.wayland && tl.wayland.appId) ? String(tl.wayland.appId) : String(ipc["class"] || "")
        return {
            addr: String(tl.address || ""),
            title: String(tl.title || ipc.title || app || "Window"),
            appId: app,
            x: Number(at[0]) || 0,
            y: Number(at[1]) || 0,
            w: w,
            h: h,
            wsId: wsId,
            wsName: wsName,
            special: wsName.indexOf("special:") === 0,
            pinned: !!ipc.pinned
        }
    }

    function windowsOn(monName) {
        const vals = root.listOf(Hyprland.toplevels)
        const out = []
        for (let i = 0; i < vals.length; i++) {
            const rec = root.windowRecord(vals[i], monName)
            if (rec && rec.addr)
                out.push(rec)
        }
        out.sort(function (a, b) {
            if (a.y !== b.y)
                return a.y - b.y
            return a.x - b.x
        })
        return out
    }

    function countOn(monName, key) {
        const wins = root.windowsOn(monName)
        let n = 0
        for (let i = 0; i < wins.length; i++) {
            if (root.windowMatches(wins[i], key))
                n++
        }
        return n
    }

    function windowMatches(win, key) {
        if (!key)
            return false
        if (win.pinned)
            return true
        if (key.indexOf("s:") === 0)
            return win.wsName === key.slice(2)
        if (key.indexOf("w:") === 0)
            return win.wsId === Number(key.slice(2))
        return false
    }

    function phantomCard(id) {
        return {
            key: "w:" + id,
            id: id,
            wsId: id,
            name: String(id),
            symbol: "",
            word: "",
            font: "",
            bold: true,
            italic: false,
            color: "",
            special: "",
            phantom: true,
            all: false,
            count: 0
        }
    }

    function decorateCard(card) {
        if (!card)
            return card
        if (card.all) {
            card.symbol = ""
            card.word = "All"
            card.font = ""
            card.bold = true
            card.italic = false
            card.color = ""
            return card
        }
        if (card.special) {
            const face = WorkspaceSettings.specialFace()
            card.symbol = String(face.label || "")
            card.word = String(face.text || card.name || "")
            card.font = String(face.font || "")
            card.bold = face.bold !== false
            card.italic = !!face.italic
            card.color = String(face.color || "")
            return card
        }
        const id = Number(card.wsId || card.id) || 0
        card.wsId = id
        const face = WorkspaceSettings.faceForId(id)
        card.symbol = String(face.label || "")
        card.word = String(face.text || "")
        card.font = String(face.font || "")
        card.bold = face.bold !== false
        card.italic = !!face.italic
        card.color = String(face.color || "")
        return card
    }

    function cardCaption(card) {
        if (!card)
            return ""
        const opts = OverviewSettings.live
        if (card.all)
            return "All"
        if (opts.ovNumberLabels && !card.special) {
            if (card.phantom && !opts.ovDynamic)
                return "+"
            const key = String(card.key || "")
            if (key.indexOf("w:") === 0)
                return key.slice(2)
            if (card.wsId)
                return String(card.wsId)
            return String(card.name || "")
        }
        if (card.phantom && !opts.ovDynamic)
            return "+"
        const sym = String(card.symbol || "")
        const word = String(card.word || "")
        if (sym && word)
            return sym + "  " + word
        if (word)
            return word
        if (sym)
            return sym
        return String(card.name || card.wsId || "")
    }

    function workspaceTarget(card) {
        if (!card || card.all)
            return null
        const key = String(card.key || "")
        if (key.indexOf("s:") === 0)
            return key.slice(2)
        if (card.special)
            return String(card.special)
        if (key.indexOf("w:") === 0) {
            const n = Number(key.slice(2))
            if (n > 0)
                return n
        }
        const n = Number(card.wsId)
        if (n > 0)
            return n
        return null
    }

    function nextWorkspaceId() {
        const vals = root.listOf(Hyprland.workspaces)
        let maxId = 1
        for (let i = 0; i < vals.length; i++) {
            const id = Number(vals[i].id) || 0
            if (id > maxId)
                maxId = id
        }
        return maxId + 1
    }

    function cardsFor(monName) {
        const opts = OverviewSettings.live
        const vals = root.listOf(Hyprland.workspaces)
        const byId = {}
        const specials = []
        for (let i = 0; i < vals.length; i++) {
            const ws = vals[i]
            if (!ws.monitor || ws.monitor.name !== monName)
                continue
            const name = String(ws.name || "")
            const id = Number(ws.id) || 0
            if (name.indexOf("special:") === 0) {
                if (opts.ovShowSpecial && WorkspaceSettings.isSpecialName(name)) {
                    const key = "s:" + name
                    const count = root.countOn(monName, key)
                    if (Config.showOnlyActive && count <= 0)
                        continue
                    specials.push(root.decorateCard({
                        key: key,
                        id: id,
                        wsId: id,
                        name: name.replace(/^special:/, ""),
                        special: name,
                        phantom: false,
                        all: false,
                        count: count
                    }))
                }
                continue
            }
            if (id <= 0)
                continue
            byId[id] = {
                key: "w:" + id,
                id: id,
                wsId: id,
                name: name,
                special: "",
                phantom: false,
                all: false,
                count: root.countOn(monName, "w:" + id)
            }
        }
        const slots = WorkspaceSettings.effectiveSlots()
        const seen = {}
        let body = []
        for (let i = 0; i < slots.length; i++) {
            const id = Math.round(Number(slots[i] && slots[i].id))
            if (!(id >= 1) || seen[id])
                continue
            seen[id] = true
            let card = byId[id]
            if (!card) {
                card = {
                    key: "w:" + id,
                    id: id,
                    wsId: id,
                    name: String(id),
                    special: "",
                    phantom: false,
                    all: false,
                    count: root.countOn(monName, "w:" + id)
                }
            }
            body.push(root.decorateCard(card))
        }
        const extraIds = []
        const idKeys = Object.keys(byId)
        for (let i = 0; i < idKeys.length; i++) {
            const id = Number(idKeys[i])
            if (!seen[id])
                extraIds.push(id)
        }
        extraIds.sort(function (a, b) { return a - b })
        const dynamic = !!opts.ovDynamic
        const onlyActive = !!Config.showOnlyActive
        const active = root.activeKey(monName)
        for (let i = 0; i < extraIds.length; i++) {
            const card = byId[extraIds[i]]
            if (onlyActive) {
                if (card.count > 0)
                    body.push(root.decorateCard(card))
                continue
            }
            // Persistent slot cards stay. Autodelete drops empty workspaces that are not slots.
            if (dynamic && opts.ovAutodelete) {
                if (card.count > 0 || card.key === active)
                    body.push(root.decorateCard(card))
                continue
            }
            if (card.count > 0 || card.key === active || opts.ovShowEmpty || dynamic)
                body.push(root.decorateCard(card))
        }
        if (onlyActive) {
            let maxOcc = 0
            const occupied = []
            for (let i = 0; i < body.length; i++) {
                if (body[i].count > 0) {
                    occupied.push(body[i])
                    if (body[i].id > maxOcc)
                        maxOcc = body[i].id
                }
            }
            let blank = null
            for (let i = 0; i < body.length; i++) {
                if (body[i].count === 0 && body[i].id > maxOcc) {
                    blank = body[i]
                    break
                }
            }
            if (!blank) {
                for (let i = 0; i < body.length; i++) {
                    if (body[i].count === 0) {
                        blank = body[i]
                        break
                    }
                }
            }
            if (!blank) {
                let next = root.nextWorkspaceId()
                const used = {}
                for (let i = 0; i < body.length; i++)
                    used[body[i].id] = true
                while (used[next])
                    next++
                blank = root.decorateCard(root.phantomCard(next))
            }
            const merged = []
            let placed = false
            for (let i = 0; i < occupied.length; i++) {
                if (!placed && blank.id < occupied[i].id) {
                    merged.push(blank)
                    placed = true
                }
                merged.push(occupied[i])
            }
            if (!placed)
                merged.push(blank)
            body = merged
        } else {
            const tail = body.length ? body[body.length - 1] : null
            if (dynamic && (!tail || tail.count > 0)) {
                let next = root.nextWorkspaceId()
                const used = {}
                for (let i = 0; i < body.length; i++)
                    used[body[i].id] = true
                while (used[next])
                    next++
                body.push(root.decorateCard(root.phantomCard(next)))
            }
        }
        const out = []
        if (opts.ovStripAllCard) {
            out.push(root.decorateCard({
                key: "all",
                id: 0,
                name: "All",
                special: "",
                phantom: false,
                all: true,
                count: root.windowsOn(monName).length
            }))
        }
        for (let i = 0; i < body.length; i++)
            out.push(body[i])
        for (let i = 0; i < specials.length; i++)
            out.push(specials[i])
        return out
    }

    function visibleWindows(monName, key, mode) {
        const wins = root.windowsOn(monName)
        const opts = OverviewSettings.live
        const out = []
        if (mode === "all") {
            for (let i = 0; i < wins.length; i++) {
                if (wins[i].special && !opts.ovShowSpecial)
                    continue
                out.push(wins[i])
            }
            return out
        }
        for (let i = 0; i < wins.length; i++) {
            if (root.windowMatches(wins[i], key))
                out.push(wins[i])
        }
        return out
    }

    function effectiveLayout() {
        const opts = OverviewSettings.live
        if (root.viewMode === "desktop")
            return "natural"
        if (root.viewMode === "all" && opts.ovLayout === "natural")
            return "rows"
        return root.ovLayoutNormSafe(opts.ovLayout)
    }

    function ovLayoutNormSafe(layout) {
        if (layout === "grid" || layout === "natural")
            return layout
        return "rows"
    }

    function unitFor(mon, screenW) {
        const hw = Number(mon && mon.width) || 0
        const sw = Number(screenW) || 0
        if (hw <= 0 || sw <= 0)
            return 1
        const unit = sw / hw
        if (unit < 0.2 || unit > 5)
            return 1
        return unit
    }

    function place(wins, mon, areaW, areaH, screenW) {
        const width = Math.max(0, areaW)
        const height = Math.max(0, areaH)
        if (!wins.length || width < Theme.space || height < Theme.space)
            return []
        const opts = OverviewSettings.live
        const unit = root.unitFor(mon, screenW)
        const maxScale = Math.max(0.05, Number(opts.ovMaxScale) || 1)
        const gap = Math.max(0, Number(opts.ovGap) || 0)
        const items = []
        for (let i = 0; i < wins.length; i++) {
            items.push({
                addr: wins[i].addr,
                title: wins[i].title,
                appId: wins[i].appId,
                realW: Math.max(1, wins[i].w * unit),
                realH: Math.max(1, wins[i].h * unit),
                gx: wins[i].x,
                gy: wins[i].y
            })
        }
        const mode = root.effectiveLayout()
        if (mode === "natural")
            return root.placeNatural(items, mon, width, height, unit, maxScale)
        if (mode === "grid")
            return root.placeGrid(items, width, height, gap, maxScale)
        return root.placeRows(items, width, height, gap, maxScale)
    }

    function placeNatural(items, mon, areaW, areaH, unit, maxScale) {
        const monW = Math.max(1, (Number(mon && mon.width) || areaW) * unit)
        const monH = Math.max(1, (Number(mon && mon.height) || areaH) * unit)
        const monX = (Number(mon && mon.x) || 0) * unit
        const monY = (Number(mon && mon.y) || 0) * unit
        const fit = Math.min(areaW / monW, areaH / monH)
        const scale = Math.min(Math.max(0.01, fit), maxScale)
        const ox = (areaW - monW * scale) / 2
        const oy = (areaH - monH * scale) / 2
        const out = []
        const minSide = Theme.space
        for (let i = 0; i < items.length; i++) {
            const it = items[i]
            out.push({
                addr: it.addr,
                title: it.title,
                appId: it.appId,
                x: ox + (it.gx * unit - monX) * scale,
                y: oy + (it.gy * unit - monY) * scale,
                w: Math.max(minSide, it.realW * scale),
                h: Math.max(minSide, it.realH * scale)
            })
        }
        return out
    }

    function placeGrid(items, areaW, areaH, gap, maxScale) {
        const n = items.length
        let best = null
        let bestScore = -1
        for (let cols = 1; cols <= n; cols++) {
            const rows = Math.ceil(n / cols)
            const cellW = (areaW - gap * (cols - 1)) / cols
            const cellH = (areaH - gap * (rows - 1)) / rows
            if (cellW < Theme.space || cellH < Theme.space)
                continue
            const score = Math.min(cellW, cellH)
            if (score > bestScore) {
                bestScore = score
                best = { cols: cols, rows: rows, cellW: cellW, cellH: cellH }
            }
        }
        if (!best)
            return []
        const gridW = best.cols * best.cellW + gap * (best.cols - 1)
        const gridH = best.rows * best.cellH + gap * (best.rows - 1)
        const ox = (areaW - gridW) / 2
        const oy = (areaH - gridH) / 2
        const out = []
        for (let i = 0; i < n; i++) {
            const col = i % best.cols
            const row = Math.floor(i / best.cols)
            const it = items[i]
            const fit = Math.min(best.cellW / it.realW, best.cellH / it.realH, maxScale)
            const w = Math.max(Theme.space, it.realW * fit)
            const h = Math.max(Theme.space, it.realH * fit)
            const cx = ox + col * (best.cellW + gap)
            const cy = oy + row * (best.cellH + gap)
            out.push({
                addr: it.addr,
                title: it.title,
                appId: it.appId,
                x: cx + (best.cellW - w) / 2,
                y: cy + (best.cellH - h) / 2,
                w: w,
                h: h
            })
        }
        return out
    }

    function placeRows(items, areaW, areaH, gap, maxScale) {
        const n = items.length
        let bestScale = -1
        let bestCounts = null
        for (let rows = 1; rows <= n; rows++) {
            const base = Math.floor(n / rows)
            const extra = n % rows
            const counts = []
            for (let r = 0; r < rows; r++)
                counts.push(base + (r < extra ? 1 : 0))
            let lo = 0
            let hi = maxScale
            for (let step = 0; step < 22; step++) {
                const mid = (lo + hi) / 2
                if (root.rowsFit(items, counts, areaW, areaH, gap, mid))
                    lo = mid
                else
                    hi = mid
            }
            if (lo > bestScale) {
                bestScale = lo
                bestCounts = counts
            }
        }
        if (!bestCounts || bestScale <= 0)
            return root.placeGrid(items, areaW, areaH, gap, maxScale)
        const rowH = []
        const rowW = []
        let idx = 0
        for (let r = 0; r < bestCounts.length; r++) {
            let rh = 0
            let rw = 0
            const count = bestCounts[r]
            for (let c = 0; c < count; c++) {
                const it = items[idx++]
                rh = Math.max(rh, it.realH * bestScale)
                rw += it.realW * bestScale
            }
            if (count > 1)
                rw += gap * (count - 1)
            rowH.push(rh)
            rowW.push(rw)
        }
        let totalH = 0
        for (let r = 0; r < rowH.length; r++)
            totalH += rowH[r]
        if (rowH.length > 1)
            totalH += gap * (rowH.length - 1)
        let y = Math.max(0, (areaH - totalH) / 2)
        idx = 0
        const out = []
        for (let r = 0; r < bestCounts.length; r++) {
            let x = Math.max(0, (areaW - rowW[r]) / 2)
            const count = bestCounts[r]
            for (let c = 0; c < count; c++) {
                const it = items[idx++]
                const w = Math.max(Theme.space, it.realW * bestScale)
                const h = Math.max(Theme.space, it.realH * bestScale)
                out.push({
                    addr: it.addr,
                    title: it.title,
                    appId: it.appId,
                    x: x,
                    y: y + (rowH[r] - h) / 2,
                    w: w,
                    h: h
                })
                x += w + gap
            }
            y += rowH[r] + gap
        }
        return out
    }

    function rowsFit(items, counts, areaW, areaH, gap, scale) {
        let idx = 0
        let usedH = 0
        for (let r = 0; r < counts.length; r++) {
            let rowW = 0
            let rowH = 0
            const count = counts[r]
            for (let c = 0; c < count; c++) {
                const it = items[idx++]
                rowW += it.realW * scale
                rowH = Math.max(rowH, it.realH * scale)
            }
            if (count > 1)
                rowW += gap * (count - 1)
            if (rowW > areaW + 0.5)
                return false
            usedH += rowH
            if (r < counts.length - 1)
                usedH += gap
            if (usedH > areaH + 0.5)
                return false
        }
        return true
    }

    function followCard(card, monName, createPhantom) {
        if (!card)
            return
        if (card.all) {
            root.viewMode = root.viewMode === "all" ? "workspace" : "all"
            return
        }
        root.viewMode = "workspace"
        if (card.phantom && createPhantom)
            root.dispatchFocusWorkspace(card.id, monName)
        else if (!card.phantom && card.special)
            root.dispatchFocusWorkspace(card.special, monName)
        else if (!card.phantom)
            root.dispatchFocusWorkspace(card.id, monName)
    }

    function dispatchFocusWorkspace(ws, monName) {
        if (monName)
            root.dispatch("hl.dsp.focus({ monitor = " + root.quote(monName) + " })")
        const numeric = typeof ws === "number" || (String(ws).length && String(Number(ws)) === String(ws) && String(ws).indexOf("special:") !== 0)
        if (numeric)
            root.dispatch("hl.dsp.focus({ workspace = " + Number(ws) + " })")
        else
            root.dispatch("hl.dsp.focus({ workspace = " + root.quote(ws) + " })")
    }

    function focusWindow(addr) {
        root.dispatch("hl.dsp.focus({ window = " + root.quote(root.addressOf(addr)) + " })")
    }

    function closeWindow(addr) {
        root.dispatch("hl.dsp.window.close({ window = " + root.quote(root.addressOf(addr)) + " })")
    }

    function moveWindow(addr, workspace, follow) {
        if (workspace === null || workspace === undefined || workspace === "")
            return
        const numeric = typeof workspace === "number" || (String(workspace).length > 0 && String(Number(workspace)) === String(workspace))
        const ws = numeric ? String(Number(workspace)) : root.quote(String(workspace))
        const window = root.quote(root.addressOf(addr))
        root.dispatch("hl.dsp.window.move({ window = " + window
            + ", workspace = " + ws
            + ", follow = " + (follow ? "true" : "false") + " })")
    }

    function swapWindow(fromAddr, toAddr) {
        root.focusWindow(fromAddr)
        root.dispatch("hl.dsp.window.swap({ target = " + root.quote(root.addressOf(toAddr)) + " })")
    }

    function toplevelFor(addr) {
        const vals = root.listOf(Hyprland.toplevels)
        const want = String(addr || "")
        for (let i = 0; i < vals.length; i++) {
            if (String(vals[i].address || "") === want)
                return vals[i]
        }
        return null
    }

    function waylandSource(addr) {
        if (!root.open)
            return null
        const tl = root.toplevelFor(addr)
        if (!tl || !tl.wayland)
            return null
        return tl.wayland
    }

    function hueColor(text, sat, light) {
        let h = 0
        const s = String(text || "")
        for (let i = 0; i < s.length; i++)
            h = (h * 33 + s.charCodeAt(i)) >>> 0
        return Qt.hsla((h % 360) / 360, sat, light, 1)
    }

    function minisFor(mon, monName, key, cardW, cardH) {
        if (!OverviewSettings.live.ovStripPreviews || !mon)
            return []
        const wins = root.visibleWindows(monName, key, "workspace")
        const inset = Theme.wsGap
        const aw = Math.max(Theme.space, cardW - inset * 2)
        const ah = Math.max(Theme.space, cardH - inset * 2)
        const items = []
        for (let i = 0; i < wins.length; i++) {
            items.push({
                addr: wins[i].addr,
                title: wins[i].title,
                appId: wins[i].appId,
                realW: wins[i].w,
                realH: wins[i].h,
                gx: wins[i].x,
                gy: wins[i].y
            })
        }
        const placed = root.placeNatural(items, mon, aw, ah, 1, 1)
        const out = []
        for (let i = 0; i < placed.length; i++) {
            out.push({
                x: placed[i].x + inset,
                y: placed[i].y + inset,
                w: placed[i].w,
                h: placed[i].h,
                addr: placed[i].addr,
                appId: placed[i].appId,
                title: placed[i].title
            })
        }
        return out
    }

    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged() {
            if (!root.open || !OverviewSettings.live.ovExitOnSwitch)
                return
            if (root.nowMs() < root.suppressUntil)
                return
            root.closeOverview()
        }
        function onRawEvent(event) {
            if (!root.open || !event)
                return
            const name = event.name
            if (name === "openwindow" || name === "closewindow" || name === "movewindow"
                    || name === "windowtitle" || name === "changefloatingmode"
                    || name === "fullscreen" || name === "workspace" || name === "createworkspace"
                    || name === "destroyworkspace" || name === "focusedmon")
                root.refreshSerial++
        }
    }

    Connections {
        target: Config
        function onOvBackdropBlurChanged() {
            if (root.open)
                root.syncBlur()
        }
    }

    IpcHandler {
        target: "overview"
        function toggle(): void { root.toggle() }
        function open(): void { root.openOverview("workspace") }
        function close(): void { root.closeOverview() }
        function desktop(): void { root.openMode("desktop") }
        function all(): void { root.openMode("all") }
        function next(): void { root.step(1) }
        function prev(): void { root.step(-1) }
    }
}
