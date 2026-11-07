import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import "tests"

// FreshRssService: reading the env file like a shell (without running it),
// cleaning article HTML, and turning API items into reader items.
ShellRoot {
    Check { id: t }

    FileView {
        id: items
        path: Quickshell.shellDir + "/tests/fixtures/greader-items.json"
        onLoaded: {
            const S = FreshRssService
            t.eq("unquote plain", S.unquote("abc"), "abc")
            t.eq("unquote backslash escapes", S.unquote("a\\&b\\$c"), "a&b$c")
            t.eq("unquote single quotes", S.unquote("'a b$c'"), "a b$c")
            t.eq("unquote double quotes", S.unquote("\"a \\\"b\\\" $c\""), "a \"b\" $c")
            t.eq("unquote mixed quoting", S.unquote("'it'\\''s'"), "it's")
            t.eq("unquote stops at a comment", S.unquote("abc # note"), "abc")
            t.eq("unquote never expands", S.unquote("$(rm -rf ~)"), "$(rm")
            const env = S.parseEnv("# c\nexport FRESHRSS_USER=me\nFRESHRSS_BASE_URL='https://x.example/'\nJUNK LINE\n")
            t.eq("parseEnv keys", env, { FRESHRSS_USER: "me", FRESHRSS_BASE_URL: "https://x.example/" })
            t.eq("shellQuote round trip", S.unquote(S.shellQuote("it's \"$x\" \\")), "it's \"$x\" \\")
            t.ok("urlOk https", S.urlOk("https://rss.example.com"))
            t.ok("urlOk rejects javascript", !S.urlOk("javascript:alert(1)"))
            t.ok("urlOk rejects spaces", !S.urlOk("https://a b"))
            t.eq("cleanBase strips api path", S.cleanBase("https://x.example/api/greader.php/"), "https://x.example")

            const list = JSON.parse(items.text()).map((x) => S.itemNorm(x, {}))
            const z = list[0]
            t.eq("title decodes entities", z.title, "Zeta article & more")
            t.eq("read flag", [z.read, list[2].read], [true, false])
            t.eq("starred flag", list[1].starred, true)
            t.eq("url from alternate", z.url, "https://example.com/z")
            t.eq("url from canonical", list[2].url, "https://example.com/a")
            t.eq("video from YouTube link", list[1].videoUrl, "https://www.youtube.com/watch?v=abc")
            t.eq("no video otherwise", z.videoUrl, "")
            t.ok("html: no script", z.html.indexOf("script") < 0 && z.html.indexOf("bad()") < 0)
            t.ok("html: no event handlers", z.html.indexOf("onclick") < 0)
            t.ok("html: no javascript links", z.html.indexOf("javascript:") < 0)
            t.ok("html: image becomes a link", z.html.indexOf("<img") < 0 && z.html.indexOf("[image]") >= 0)
            t.ok("search text is lowercase", list[2].search.indexOf("searchable") >= 0 && list[2].search === list[2].search.toLowerCase())
            t.done()
        }
    }
}
