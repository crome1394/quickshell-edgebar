import QtQuick
import qs.services
import qs.theme

// Reader view for an article's web page: fetch the page, drop comment
// sections and share bars, and keep its main text (the <article>, <main>,
// or post-content block with the most paragraph text, else every real
// paragraph), cleaned like feed text, so no scripts run and images stay
// links. Lives only while the reader window is open.
QtObject {
    id: root

    // Tags kept from the page; everything else is dropped, text kept.
    readonly property var keepTags: ["p", "h1", "h2", "h3", "h4", "ul", "ol", "li", "blockquote", "a", "b", "strong", "i", "em", "br", "pre", "code", "img", "figcaption"]

    // Text inside <p> tags, as a rough score for how much article a block holds.
    function paragraphText(block) {
        const paras = String(block).match(/<p\b[^>]*>[\s\S]*?<\/p>/gi) || []
        let n = 0
        for (let i = 0; i < paras.length; i++)
            n += FreshRssService.plainText(paras[i]).length
        return n
    }

    // End of the element whose opening tag starts at `at`: the matching
    // closing tag, counting nested ones of the same name. A tag with no
    // closing one ends after its opening tag.
    function elementEnd(page, at) {
        const open = page.substring(at).match(/^<([a-z][a-z0-9]*)\b[^>]*>/i)
        if (!open)
            return at + 1
        const tag = open[1].toLowerCase()
        const re = new RegExp("<(\\/)?" + tag + "\\b[^>]*>", "gi")
        re.lastIndex = at + open[0].length
        let depth = 1
        let m
        while ((m = re.exec(page)) !== null) {
            depth += m[1] ? -1 : 1
            if (depth === 0)
                return m.index + m[0].length
        }
        return at + open[0].length
    }

    // Every whole element whose opening tag matches `test(tag, attrs)`.
    function elements(page, test) {
        const out = []
        const re = /<([a-z][a-z0-9]*)\b([^>]*)>/gi
        let m
        while ((m = re.exec(page)) !== null) {
            if (!test(m[1].toLowerCase(), m[2]))
                continue
            const end = root.elementEnd(page, m.index)
            out.push({ start: m.index, end: end, html: page.substring(m.index, end) })
            re.lastIndex = end
        }
        return out
    }

    // Comment sections, share bars, and related-post lists, by class or id.
    readonly property var junkName: /\b(?:class|id)\s*=\s*["'][^"']*(?:comment|share|social|related|newsletter|subscribe|sidebar|promo|advert)/i
    // Blocks that usually hold the story.
    readonly property var storyName: /\b(?:class|id|itemprop)\s*=\s*["'][^"']*(?:(?:post|entry|article|story)[-_]?(?:content|body|text)|articleBody)/i

    function withoutJunk(page) {
        const junk = root.elements(page, (tag, attrs) => root.junkName.test(attrs))
        let out = page
        for (let i = junk.length - 1; i >= 0; i--)
            out = out.substring(0, junk[i].start) + out.substring(junk[i].end)
        return out
    }

    // Links and images relative to the page made absolute.
    function absolute(html, pageUrl) {
        const origin = String(pageUrl).match(/^https?:\/\/[^\/]+/i)
        if (!origin)
            return html
        return html.replace(/\b(href|src)\s*=\s*(["'])\/(?!\/)/gi, "$1=$2" + origin[0] + "/")
            .replace(/\b(href|src)\s*=\s*(["'])\/\//gi, "$1=$2https://")
    }

    // The page's main text as reader HTML, or "" when none was found.
    function extract(page, pageUrl) {
        let s = String(page || "")
        if (s.length > Theme.freshRssPageMax)
            s = s.substring(0, Theme.freshRssPageMax)
        s = s.replace(/<!--[\s\S]*?-->/g, "")
        s = s.replace(/<(head|script|style|noscript|svg|nav|header|footer|aside|form|iframe|template|button|select)\b[\s\S]*?<\/\1\s*>/gi, "")
        s = root.withoutJunk(s)
        let best = ""
        let bestScore = 0
        const candidates = root.elements(s, (tag, attrs) => tag === "article" || tag === "main" || root.storyName.test(attrs))
        for (let i = 0; i < candidates.length; i++) {
            const score = root.paragraphText(candidates[i].html)
            if (score > bestScore) {
                best = candidates[i].html
                bestScore = score
            }
        }
        if (bestScore < Theme.freshRssPageMinText) {
            const paras = (s.match(/<p\b[^>]*>[\s\S]*?<\/p>/gi) || [])
                .filter((p) => FreshRssService.plainText(p).length >= Theme.freshRssPageMinParagraph)
            best = paras.join("\n")
        }
        if (FreshRssService.plainText(best).length < Theme.freshRssPageMinText)
            return ""
        const keep = new RegExp("<(?!\\/?(?:" + root.keepTags.join("|") + ")\\b)\\/?[a-z][^>]*>", "gi")
        best = best.replace(keep, "")
        best = root.absolute(best, pageUrl)
        return FreshRssService.cleanHtml(best).replace(/\n\s*\n+/g, "\n").trim()
    }

    // One fetch at a time: a new one cancels the last, so moving quickly
    // through articles does not pile up requests.
    property var request: null
    property int generation: 0

    property Timer timeout: Timer {
        interval: Theme.freshRssRequestMs
        onTriggered: {
            if (root.request)
                root.request.abort()
        }
    }

    function cancel() {
        root.generation++
        root.timeout.stop()
        if (root.request)
            root.request.abort()
        root.request = null
    }

    // Fetch a page. done(ok, htmlOrMessage). Only http(s) links.
    function fetch(url, done) {
        root.cancel()
        if (!/^https?:\/\//i.test(String(url || ""))) {
            done(false, "This article has no web page.")
            return
        }
        const gen = root.generation
        const xhr = new XMLHttpRequest()
        root.request = xhr
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE || gen !== root.generation)
                return
            root.timeout.stop()
            root.request = null
            if (xhr.status === 403 || xhr.status === 503) {
                done(false, "The site only lets a full browser in (HTTP " + xhr.status + "). Open it with b.")
                return
            }
            if (xhr.status !== 200) {
                done(false, xhr.status ? "The page did not load (HTTP " + xhr.status + ")." : "The page did not load.")
                return
            }
            const html = root.extract(xhr.responseText || "", url)
            done(html.length > 0, html.length ? html : "No article text was found on the page. Open it in the browser (b).")
        }
        xhr.open("GET", url)
        root.timeout.start()
        xhr.send()
    }
}
