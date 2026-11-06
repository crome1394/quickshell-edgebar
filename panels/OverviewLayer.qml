pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.config
import qs.services
import qs.theme

// Fullscreen workspace overview. Loaded only while OverviewService.surfaceLive is true.
Variants {
    id: root
    model: Quickshell.screens

    // qmllint disable uncreatable-type
    PanelWindow {
    // qmllint enable uncreatable-type
        id: panel
        required property var modelData
        screen: modelData

        property var cards: []
        property var placements: []
        property string displayedKey: ""
        property string selectedAddr: ""
        property string layoutSig: ""
        property bool shiftChord: false
        property real slideX: 0
        property bool flying: false
        property real flyT: 0
        property real flyX: 0
        property real flyY: 0
        property real flyW: 0
        property real flyH: 0
        property real flyTx: 0
        property real flyTy: 0
        property real flyTw: 0
        property real flyTh: 0
        property string flyTitle: ""
        property var drag: null
        property string dropKey: ""

        readonly property var hyprMonitor: Hyprland.monitorFor(modelData)
        readonly property string monName: hyprMonitor ? String(hyprMonitor.name || "") : ""
        readonly property bool takesKeys: {
            if (!OverviewService.open || !panel.hyprMonitor)
                return false
            const focused = Hyprland.focusedMonitor
            return !!focused && focused.name === panel.monName
        }
        readonly property string anchor: Config.ovLive().ovAnchor
        readonly property bool stripHorizontal: panel.anchor === "top" || panel.anchor === "bottom"
        readonly property real thickness: panel.stripHorizontal ? Config.ovLive().ovStripHeight : Config.ovLive().ovStripWidth
        readonly property real stripOffset: Config.ovLive().ovStripOffset
        readonly property color backdrop: {
            const opts = Config.ovLive()
            const dim = Math.max(0, Math.min(1, opts.ovBlur))
            const alpha = opts.ovBackdropBlur ? (0.10 + 0.25 * dim) : (0.28 + 0.50 * dim)
            return Qt.rgba(Theme.pageBg.r, Theme.pageBg.g, Theme.pageBg.b, alpha)
        }
        readonly property string watchKey: {
            const opts = Config.ovLive()
            return [
                OverviewService.refreshSerial, OverviewService.viewMode, panel.anchor,
                opts.ovLayout, opts.ovGap, opts.ovPadding, opts.ovPaddingTop, opts.ovPaddingBottom,
                opts.ovMaxScale, opts.ovDynamic, opts.ovAutodelete, opts.ovShowEmpty, opts.ovShowSpecial,
                opts.ovStripAllCard, opts.ovShowWsLabels, opts.ovStripPreviews, opts.ovNumberLabels,
                opts.ovLivePreviews, opts.ovStripHeight, opts.ovStripWidth, opts.ovStripCardMax,
                opts.ovStripMargin, opts.ovStripGap, opts.ovStripOffset, opts.ovShowWindowLabels,
                Config.showOnlyActive, Config.revision
            ].join("|")
        }

        function pad(edge) {
            const opts = Config.ovLive()
            const side = Math.max(0, opts.ovPadding)
            const near = Math.max(0, opts.ovPaddingTop)
            const far = Math.max(0, opts.ovPaddingBottom)
            if (edge === "left")
                return panel.anchor === "left" ? near : (panel.anchor === "right" ? far : side)
            if (edge === "right")
                return panel.anchor === "right" ? near : (panel.anchor === "left" ? far : side)
            if (edge === "top")
                return panel.anchor === "top" ? near : (panel.anchor === "bottom" ? far : side)
            return panel.anchor === "bottom" ? near : (panel.anchor === "top" ? far : side)
        }

        function cardSize() {
            const opts = Config.ovLive()
            const margin = Math.max(Theme.barPad, opts.ovStripMargin)
            const labelH = opts.ovShowWsLabels ? (Theme.smallPx + Theme.space) : 0
            const mon = panel.hyprMonitor
            const aspect = (mon && mon.width > 0 && mon.height > 0) ? (mon.width / mon.height) : (16 / 9)
            const minW = Theme.wsButtonWidth + Theme.barPad
            const minH = Theme.fieldHeight + Theme.borderWidth * 2
            let cardW = minW
            let cardH = minH
            if (panel.stripHorizontal) {
                const inner = Math.max(minH, panel.thickness - margin * 2 - labelH - Theme.space)
                cardH = inner
                cardW = cardH * aspect
                if (cardW > opts.ovStripCardMax) {
                    cardW = opts.ovStripCardMax
                    cardH = cardW / aspect
                }
            } else {
                const inner = Math.max(minW, panel.thickness - margin * 2)
                cardW = inner
                cardH = cardW / aspect
                if (cardH > opts.ovStripCardMax) {
                    cardH = opts.ovStripCardMax
                    cardW = cardH * aspect
                }
            }
            return { w: Math.max(minW, cardW), h: Math.max(minH, cardH) }
        }

        function cardPitch() {
            const opts = Config.ovLive()
            const size = panel.cardSize()
            const gap = Math.max(0, opts.ovStripGap)
            const label = opts.ovShowWsLabels ? (Theme.fontPx + Theme.space) : 0
            if (panel.stripHorizontal)
                return { w: size.w + gap, h: Math.max(1, stripFlick.height) }
            return { w: Math.max(1, stripFlick.width), h: size.h + label + gap }
        }

        function captureOpen() {
            panel.displayedKey = OverviewService.activeKey(panel.monName)
            panel.selectedAddr = ""
            panel.slideX = 0
            panel.drag = null
            panel.dropKey = ""
            panel.rebuild(true)
            if (panel.takesKeys)
                keyItem.forceActiveFocus()
        }

        function commitDisplayed() {
            if (!panel.takesKeys || OverviewService.viewMode === "all")
                return
            const key = panel.displayedKey
            const live = OverviewService.activeKey(panel.monName)
            if (!key || key === live || key === "all")
                return
            if (key.indexOf("s:") === 0)
                OverviewService.dispatchFocusWorkspace(key.slice(2), panel.monName)
            else if (key.indexOf("w:") === 0)
                OverviewService.dispatchFocusWorkspace(Number(key.slice(2)), panel.monName)
        }

        function rebuild(force) {
            if (!panel.monName || !area)
                return
            const opts = Config.ovLive()
            const nextCards = OverviewService.cardsFor(panel.monName)
            let shown = false
            for (let i = 0; i < nextCards.length; i++) {
                if (nextCards[i].key === panel.displayedKey)
                    shown = true
            }
            if (!panel.displayedKey || !shown) {
                const key = OverviewService.activeKey(panel.monName)
                let use = ""
                for (let i = 0; i < nextCards.length; i++) {
                    if (nextCards[i].key === key)
                        use = key
                }
                if (!use) {
                    for (let i = 0; i < nextCards.length; i++) {
                        if (!nextCards[i].all) {
                            use = nextCards[i].key
                            break
                        }
                    }
                }
                if (use)
                    panel.displayedKey = use
            }
            const size = panel.cardSize()
            const mon = panel.hyprMonitor || OverviewService.monitorByName(panel.monName)
            for (let i = 0; i < nextCards.length; i++) {
                const card = nextCards[i]
                card.minis = (card.all || card.phantom || !opts.ovStripPreviews)
                    ? []
                    : OverviewService.minisFor(mon, panel.monName, card.key, size.w, size.h)
            }
            const wins = OverviewService.visibleWindows(panel.monName, panel.displayedKey, OverviewService.viewMode)
            const placed = OverviewService.place(wins, mon, area.width, area.height, panel.width)
            let sig = OverviewService.viewMode + "|" + panel.displayedKey + "|" + area.width + "x" + area.height
            const allWins = OverviewService.windowsOn(panel.monName)
            for (let i = 0; i < allWins.length; i++)
                sig += "/" + allWins[i].addr + ":" + allWins[i].x + "," + allWins[i].y + "," + allWins[i].w + "x" + allWins[i].h
            for (let i = 0; i < nextCards.length; i++) {
                const card = nextCards[i]
                sig += ";" + card.key + ":" + card.count + (card.phantom ? "?" : "")
            }
            for (let i = 0; i < placed.length; i++) {
                const spot = placed[i]
                sig += "|" + spot.addr + "@" + Math.round(spot.x) + "," + Math.round(spot.y) + "," + Math.round(spot.w) + "," + Math.round(spot.h)
            }
            if (!force && sig === panel.layoutSig)
                return
            panel.layoutSig = sig
            panel.cards = nextCards
            panel.placements = placed
            if (panel.selectedAddr) {
                let still = false
                for (let i = 0; i < placed.length; i++) {
                    if (placed[i].addr === panel.selectedAddr)
                        still = true
                }
                if (!still)
                    panel.selectedAddr = placed.length ? placed[0].addr : ""
            } else if (placed.length) {
                panel.selectedAddr = placed[0].addr
            }
        }

        function stepDisplayed(dir) {
            const cards = []
            for (let i = 0; i < panel.cards.length; i++) {
                if (!panel.cards[i].all)
                    cards.push(panel.cards[i])
            }
            if (!cards.length)
                return
            let idx = 0
            for (let i = 0; i < cards.length; i++) {
                if (cards[i].key === panel.displayedKey)
                    idx = i
            }
            const prevId = cards[idx] ? cards[idx].id : 0
            let next = idx + dir
            if (next < 0)
                next = cards.length - 1
            if (next >= cards.length)
                next = 0
            OverviewService.switchDir = cards[next].id >= prevId ? 1 : -1
            panel.chooseCard(cards[next], true)
        }

        function chooseCard(card, fromKey) {
            if (!card)
                return
            const opts = Config.ovLive()
            if (card.all) {
                OverviewService.viewMode = OverviewService.viewMode === "all" ? "workspace" : "all"
                panel.rebuild(true)
                return
            }
            OverviewService.viewMode = "workspace"
            const prev = panel.displayedKey
            if (card.phantom && (fromKey || opts.ovSwitchOnNew))
                OverviewService.dispatchFocusWorkspace(card.id, panel.monName)
            panel.displayedKey = card.key
            if (prev !== card.key && opts.ovSwitchAnimation && area) {
                panel.slideX = OverviewService.switchDir * Math.min(Theme.settingsWidth * 0.15, area.width * 0.18)
                slideAnim.restart()
            }
            panel.selectedAddr = ""
            panel.rebuild(true)
        }

        function chooseIndex(index) {
            if (index < 0 || index >= panel.cards.length)
                return
            OverviewService.switchDir = 1
            panel.chooseCard(panel.cards[index], false)
        }

        function moveSelection(dx, dy) {
            const items = panel.placements
            if (!items.length)
                return
            let cur = null
            for (let i = 0; i < items.length; i++) {
                if (items[i].addr === panel.selectedAddr)
                    cur = items[i]
            }
            if (!cur)
                cur = items[0]
            const cx = cur.x + cur.w / 2
            const cy = cur.y + cur.h / 2
            let best = null
            let bestScore = 1e12
            for (let i = 0; i < items.length; i++) {
                const it = items[i]
                if (it.addr === cur.addr)
                    continue
                const vx = (it.x + it.w / 2) - cx
                const vy = (it.y + it.h / 2) - cy
                if (dx !== 0 && (vx === 0 || (vx > 0) !== (dx > 0)))
                    continue
                if (dy !== 0 && (vy === 0 || (vy > 0) !== (dy > 0)))
                    continue
                const primary = dx !== 0 ? Math.abs(vx) : Math.abs(vy)
                const secondary = dx !== 0 ? Math.abs(vy) : Math.abs(vx)
                const score = primary + secondary * 2
                if (score < bestScore) {
                    bestScore = score
                    best = it
                }
            }
            if (best)
                panel.selectedAddr = best.addr
        }

        function activateSelected() {
            if (!panel.selectedAddr)
                return
            OverviewService.skipCommit = true
            OverviewService.focusWindow(panel.selectedAddr)
            OverviewService.closeOverview()
        }

        function closeSelected() {
            if (!panel.selectedAddr)
                return
            OverviewService.closeWindow(panel.selectedAddr)
        }

        function toggleDesktop() {
            OverviewService.viewMode = OverviewService.viewMode === "desktop" ? "workspace" : "desktop"
            panel.rebuild(true)
        }

        function clearDrag() {
            panel.drag = null
            panel.dropKey = ""
        }

        function cardAtStage(sx, sy) {
            const slop = Theme.iconPx
            const cards = panel.cards || []
            let best = null
            let bestD = 1e12
            const n = Math.min(cardRepeater.count, cards.length)
            for (let i = 0; i < n; i++) {
                const it = cardRepeater.itemAt(i)
                const card = cards[i]
                if (!it || !card)
                    continue
                const local = it.mapFromItem(stage, sx, sy)
                if (local.x < -slop || local.y < -slop || local.x > it.width + slop || local.y > it.height + slop)
                    continue
                const d = Math.abs(local.x - it.width / 2) + Math.abs(local.y - it.height / 2)
                if (d < bestD) {
                    bestD = d
                    best = { item: it, card: card }
                }
            }
            return best
        }

        function previewAtStage(sx, sy) {
            const list = panel.placements || []
            const n = Math.min(previewRepeater.count, list.length)
            for (let i = 0; i < n; i++) {
                const it = previewRepeater.itemAt(i)
                const placed = list[i]
                if (!it || !placed)
                    continue
                const local = it.mapFromItem(stage, sx, sy)
                if (local.x >= 0 && local.y >= 0 && local.x < it.width && local.y < it.height)
                    return { item: it, placement: placed }
            }
            return null
        }

        function finishDrag(item, sx, sy) {
            const opts = Config.ovLive()
            const cardHit = panel.cardAtStage(sx, sy)
            if (cardHit && cardHit.card) {
                const target = cardHit.card
                const ws = OverviewService.workspaceTarget(target)
                if (ws !== null && target.key !== panel.displayedKey) {
                    OverviewService.moveWindow(item.addr, ws, !!opts.ovSwitchOnDrop)
                    panel.startFlight(item, cardHit.item)
                    if (opts.ovSwitchOnDrop) {
                        OverviewService.viewMode = "workspace"
                        panel.displayedKey = target.key
                    }
                    panel.clearDrag()
                    panel.rebuild(true)
                    return
                }
            }
            if (opts.ovDragToSwap && OverviewService.effectiveLayout() === "grid") {
                const hit = panel.previewAtStage(sx, sy)
                if (hit && hit.placement && hit.placement.addr && hit.placement.addr !== item.addr) {
                    panel.startFlight(item, hit.item)
                    OverviewService.swapWindow(item.addr, hit.placement.addr)
                }
            }
            panel.clearDrag()
        }

        function startFlight(item, target) {
            if (!Config.ovLive().ovMoveAnimation || !target)
                return
            const drag = panel.drag
            const center = stage.mapFromItem(target, target.width / 2, target.height / 2)
            panel.flyX = drag ? drag.x : item.x
            panel.flyY = drag ? drag.y : item.y
            panel.flyW = drag ? drag.w : item.w
            panel.flyH = drag ? drag.h : item.h
            panel.flyTw = Math.max(Theme.barHeight, target.width * 0.42)
            panel.flyTh = Math.max(Theme.fieldHeight, target.height * 0.34)
            panel.flyTx = center.x - panel.flyTw / 2
            panel.flyTy = center.y - panel.flyTh / 2
            panel.flyTitle = (drag && drag.title) || item.title || ""
            panel.flying = true
            panel.flyT = 0
            flyAnim.restart()
            flyDone.restart()
        }

        anchors.left: true
        anchors.right: true
        anchors.top: true
        anchors.bottom: true
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-overview"
        WlrLayershell.keyboardFocus: panel.takesKeys ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        color: "transparent"
        visible: panel.monName !== "" && (OverviewService.open || OverviewService.reveal > 0.02)

        Component.onCompleted: {
            if (OverviewService.open)
                panel.captureOpen()
        }
        onWatchKeyChanged: panel.rebuild(false)
        onTakesKeysChanged: {
            if (panel.takesKeys && OverviewService.open)
                keyItem.forceActiveFocus()
        }
        onVisibleChanged: {
            if (visible && panel.takesKeys && OverviewService.open)
                keyItem.forceActiveFocus()
        }
        onWidthChanged: panel.rebuild(false)
        onHeightChanged: panel.rebuild(false)

        NumberAnimation {
            id: slideAnim
            target: panel
            property: "slideX"
            to: 0
            duration: Math.max(1, Config.ovLive().ovSwitchDuration)
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            id: flyAnim
            target: panel
            property: "flyT"
            from: 0
            to: 1
            duration: Math.max(1, Config.ovLive().ovMoveDuration)
            easing.type: Easing.InOutCubic
            onFinished: panel.flying = false
        }
        Timer {
            id: flyDone
            interval: Math.max(Theme.specialSyncMs, Config.ovLive().ovMoveDuration + Theme.persistDelayMs)
            onTriggered: panel.flying = false
        }

        Rectangle {
            id: scrim
            anchors.fill: parent
            color: panel.backdrop
            opacity: OverviewService.reveal
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            onClicked: {
                if (Config.ovLive().ovExitOnClick)
                    OverviewService.closeOverview()
            }
        }

        Connections {
            target: OverviewService
            function onOpenSerialChanged() {
                if (OverviewService.open)
                    panel.captureOpen()
            }
            function onCommitSerialChanged() {
                panel.commitDisplayed()
            }
            function onStepSerialChanged() {
                if (panel.takesKeys)
                    panel.stepDisplayed(OverviewService.stepDir)
            }
        }

        Item {
            id: keyItem
            anchors.fill: parent
            focus: panel.takesKeys && OverviewService.open
            Keys.onPressed: function (event) {
                panel.shiftChord = panel.shiftChord || !!(event.modifiers & Qt.ShiftModifier)
                if (event.key === Qt.Key_Shift) {
                    panel.shiftChord = false
                    event.accepted = true
                    return
                }
                const mods = event.modifiers
                const superDown = !!(mods & Qt.MetaModifier)
                if ((event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) && superDown) {
                    OverviewService.toggle()
                    event.accepted = true
                    return
                }
                if (event.key === Qt.Key_Escape) {
                    OverviewService.closeOverview()
                    event.accepted = true
                    return
                }
                if (event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && (mods & Qt.ShiftModifier))) {
                    panel.stepDisplayed(-1)
                    event.accepted = true
                    return
                }
                if (event.key === Qt.Key_Tab) {
                    panel.stepDisplayed(1)
                    event.accepted = true
                    return
                }
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    panel.activateSelected()
                    event.accepted = true
                    return
                }
                if (event.key === Qt.Key_Left) {
                    panel.moveSelection(-1, 0)
                    event.accepted = true
                    return
                }
                if (event.key === Qt.Key_Right) {
                    panel.moveSelection(1, 0)
                    event.accepted = true
                    return
                }
                if (event.key === Qt.Key_Up) {
                    panel.moveSelection(0, -1)
                    event.accepted = true
                    return
                }
                if (event.key === Qt.Key_Down) {
                    panel.moveSelection(0, 1)
                    event.accepted = true
                    return
                }
                if ((event.key === Qt.Key_D || event.text === "d" || event.text === "D") && !(mods & (Qt.ControlModifier | Qt.MetaModifier | Qt.AltModifier))) {
                    panel.closeSelected()
                    event.accepted = true
                    return
                }
                if ((event.text === "a" || event.text === "A") && !(mods & (Qt.ControlModifier | Qt.MetaModifier | Qt.AltModifier))) {
                    OverviewService.viewMode = OverviewService.viewMode === "all" ? "workspace" : "all"
                    panel.rebuild(true)
                    event.accepted = true
                    return
                }
                if (event.key >= Qt.Key_0 && event.key <= Qt.Key_9 && !(mods & (Qt.ControlModifier | Qt.MetaModifier | Qt.AltModifier))) {
                    const digit = event.key === Qt.Key_0 ? 9 : (event.key - Qt.Key_1)
                    panel.chooseIndex(digit)
                    event.accepted = true
                    return
                }
                event.accepted = true
            }
            Keys.onReleased: function (event) {
                if (event.key === Qt.Key_Shift && !panel.shiftChord)
                    panel.toggleDesktop()
                if (event.key === Qt.Key_Shift)
                    panel.shiftChord = false
            }
        }

        Item {
            id: stage
            anchors.fill: parent
            opacity: OverviewService.reveal

            WheelHandler {
                onWheel: function (event) {
                    if (!OverviewService.open || !Config.ovLive().ovScrollSwitches || !panel.takesKeys)
                        return
                    if (event.angleDelta.y > 0)
                        panel.stepDisplayed(-1)
                    else if (event.angleDelta.y < 0)
                        panel.stepDisplayed(1)
                }
            }

            Item {
                id: stripHost
                x: panel.anchor === "right" ? parent.width - width - panel.stripOffset : (panel.anchor === "left" ? panel.stripOffset : 0)
                y: panel.anchor === "bottom" ? parent.height - height - panel.stripOffset : (panel.anchor === "top" ? panel.stripOffset : 0)
                width: panel.stripHorizontal ? parent.width : panel.thickness
                height: panel.stripHorizontal ? panel.thickness : parent.height

                Rectangle {
                    anchors.fill: parent
                    color: Theme.sectionBg
                    opacity: 0.92
                }

                Flickable {
                    id: stripFlick
                    anchors.fill: parent
                    anchors.leftMargin: Math.max(Theme.barPad, Config.ovLive().ovStripMargin)
                    anchors.rightMargin: Math.max(Theme.barPad, Config.ovLive().ovStripMargin)
                    anchors.topMargin: Math.max(Theme.barPad, Config.ovLive().ovStripMargin)
                    anchors.bottomMargin: Math.max(Theme.barPad, Config.ovLive().ovStripMargin)
                    clip: true
                    contentWidth: cardBox.width
                    contentHeight: cardBox.height
                    flickableDirection: panel.stripHorizontal ? Flickable.HorizontalFlick : Flickable.VerticalFlick
                    boundsBehavior: Flickable.StopAtBounds
                    interactive: panel.drag === null

                    Item {
                        id: cardBox
                        width: panel.stripHorizontal
                            ? Math.max(stripFlick.width, panel.cards.length * panel.cardPitch().w)
                            : stripFlick.width
                        height: panel.stripHorizontal
                            ? stripFlick.height
                            : Math.max(stripFlick.height, panel.cards.length * panel.cardPitch().h)

                        Repeater {
                            id: cardRepeater
                            model: panel.cards
                            delegate: OverviewCard {
                                id: cardItem
                                active: cardItem.modelData.all
                                    ? OverviewService.viewMode === "all"
                                    : (OverviewService.viewMode !== "all" && cardItem.modelData.key === panel.displayedKey)
                                drop: panel.dropKey === String(cardItem.modelData.key || "")
                                horizontal: panel.stripHorizontal
                                pitchW: panel.cardPitch().w
                                pitchH: panel.cardPitch().h
                                cardW: panel.cardSize().w
                                cardH: panel.cardSize().h
                                cornerRadius: Config.ovLive().ovStripCardRound
                                showLabel: Config.ovLive().ovShowWsLabels
                                numbers: Config.ovLive().ovNumberLabels
                                livePreview: Config.ovLive().ovLivePreviews && Config.ovLive().ovStripPreviews
                                onChosen: panel.chooseCard(cardItem.modelData, false)
                            }
                        }
                    }
                }
            }

            Item {
                id: canvas
                x: panel.anchor === "left" ? panel.thickness + panel.stripOffset : 0
                y: panel.anchor === "top" ? panel.thickness + panel.stripOffset : 0
                width: parent.width - (panel.stripHorizontal ? 0 : panel.thickness + panel.stripOffset)
                height: parent.height - (panel.stripHorizontal ? panel.thickness + panel.stripOffset : 0)

                Item {
                    id: area
                    anchors.fill: parent
                    anchors.leftMargin: panel.pad("left")
                    anchors.rightMargin: panel.pad("right")
                    anchors.topMargin: panel.pad("top")
                    anchors.bottomMargin: panel.pad("bottom")
                    onWidthChanged: panel.rebuild(false)
                    onHeightChanged: panel.rebuild(false)

                    Item {
                        id: slideHost
                        x: panel.slideX
                        width: parent.width
                        height: parent.height

                        Text {
                            anchors.centerIn: parent
                            visible: panel.placements.length === 0 && OverviewService.open
                            text: OverviewService.viewMode === "all" ? "No windows on this monitor" : "Empty workspace"
                            color: Theme.text
                            font.pixelSize: Theme.fontPx + Theme.space
                            font.family: Theme.uiFont
                        }

                        Repeater {
                            id: previewRepeater
                            model: panel.placements
                            delegate: OverviewPreview {
                                id: tile
                                required property var modelData
                                required property int index
                                placement: modelData
                                selected: panel.selectedAddr === String(modelData.addr || "")
                                cornerRadius: Config.ovLive().ovPreviewRound
                                hoverBorder: Config.ovLive().ovHoverBorder
                                selectBorder: Config.ovLive().ovSelectBorder
                                showLabel: Config.ovLive().ovShowWindowLabels
                                desktopMode: OverviewService.viewMode === "desktop"
                                livePreview: Config.ovLive().ovLivePreviews
                                onHoverOn: {
                                    if (Config.ovLive().ovFocusFollowsMouse)
                                        panel.selectedAddr = String(modelData.addr || "")
                                }
                                onActivate: panel.activateSelected()
                                onCloseRequested: OverviewService.closeWindow(modelData.addr)
                                onDragMoved: (lx, ly) => {
                                    const p = stage.mapFromItem(previewRepeater.itemAt(tile.index), lx, ly)
                                    panel.drag = {
                                        addr: tile.modelData.addr,
                                        title: tile.modelData.title,
                                        x: p.x - tile.width / 2,
                                        y: p.y - tile.height / 2,
                                        w: tile.width,
                                        h: tile.height
                                    }
                                    const hit = panel.cardAtStage(p.x, p.y)
                                    panel.dropKey = (hit && hit.card) ? String(hit.card.key || "") : ""
                                }
                                onDragFinished: (lx, ly) => {
                                    const p = stage.mapFromItem(previewRepeater.itemAt(tile.index), lx, ly)
                                    panel.finishDrag(tile.modelData, p.x, p.y)
                                    panel.clearDrag()
                                }
                                onDragCanceled: panel.clearDrag()
                            }
                        }
                    }
                }
            }

            Rectangle {
                visible: panel.drag !== null
                x: panel.drag ? panel.drag.x : 0
                y: panel.drag ? panel.drag.y : 0
                width: panel.drag ? panel.drag.w : 0
                height: panel.drag ? panel.drag.h : 0
                radius: Config.ovLive().ovPreviewRound
                color: Theme.fieldBg
                border.width: Theme.borderWidth * 2
                border.color: Theme.text
                opacity: 0.9
                z: 40

                Text {
                    anchors.centerIn: parent
                    width: parent.width - Theme.space
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: panel.drag ? panel.drag.title : ""
                    color: Theme.text
                    font.pixelSize: Theme.smallPx
                    font.family: Theme.uiFont
                }
            }

            Rectangle {
                visible: panel.flying
                x: panel.flyX + (panel.flyTx - panel.flyX) * panel.flyT
                y: panel.flyY + (panel.flyTy - panel.flyY) * panel.flyT
                width: panel.flyW + (panel.flyTw - panel.flyW) * panel.flyT
                height: panel.flyH + (panel.flyTh - panel.flyH) * panel.flyT
                radius: Config.ovLive().ovPreviewRound
                color: Theme.fieldBg
                border.width: Theme.borderWidth * 2
                border.color: Theme.accent
                opacity: 0.92
                z: 41

                Text {
                    anchors.centerIn: parent
                    width: parent.width - Theme.space
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: panel.flyTitle
                    color: Theme.text
                    font.pixelSize: Theme.smallPx
                    font.family: Theme.uiFont
                }
            }
        }
    }
}
