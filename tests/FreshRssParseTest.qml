import QtQuick
import Quickshell
import Quickshell.Io
import qs.freshrss
import qs.services
import "tests"

// FreshRssService: reading the env file like a shell (without running it),
// cleaning article HTML, and turning API items into reader items.
ShellRoot {
    Check { id: t }
    PageReader { id: reader }

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
            t.ok("html: image becomes a link", S.cleanHtml("<img src=\"https://i.example/x.png\">") === "<a href=\"https://i.example/x.png\">[image]</a>")
            t.eq("lead image from the text", z.image, "https://t.example/p.gif")
            t.ok("lead image not repeated as a link", z.html.indexOf("<img") < 0 && z.html.indexOf("p.gif") < 0)
            t.eq("lead image: YouTube still", list[1].image, "")
            t.eq("youtube id from watch", S.youtubeId("https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=1"), "dQw4w9WgXcQ")
            t.eq("youtube id from short link", S.youtubeId("https://youtu.be/dQw4w9WgXcQ"), "dQw4w9WgXcQ")
            t.eq("youtube id from shorts", S.youtubeId("https://youtube.com/shorts/dQw4w9WgXcQ"), "dQw4w9WgXcQ")
            t.eq("no youtube id elsewhere", S.youtubeId("https://example.com/watch?v=dQw4w9WgXcQ"), "")
            t.eq("still frame url", S.leadImage({}, "", "https://youtu.be/dQw4w9WgXcQ", ""), "https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg")
            t.eq("icon url kept", S.iconUrl("https://rss.example/f.php?h=1"), "https://rss.example/f.php?h=1")
            t.eq("icon url rejects junk", S.iconUrl("javascript:x"), "")

            const page = "<html><head><title>x</title><script>bad()</script></head><body><nav><p>Menu menu menu menu menu menu menu menu</p></nav>"
                + "<article><h1>Big title</h1><p onclick=\"x()\">" + "First paragraph of the real story. ".repeat(6) + "</p>"
                + "<div class=\"ad\"><p>" + "Second paragraph keeps going here. ".repeat(6) + "</p></div>"
                + "<img src=\"/pic.jpg\"><a href=\"/more\">more</a></article><footer><p>Footer footer footer footer footer footer</p></footer></body></html>"
            const out = reader.extract(page, "https://news.example/story/1")
            t.ok("page: keeps the article text", out.indexOf("First paragraph") >= 0 && out.indexOf("Second paragraph") >= 0)
            t.ok("page: drops nav, footer, script", out.indexOf("Menu") < 0 && out.indexOf("Footer") < 0 && out.indexOf("bad()") < 0)
            t.ok("page: drops divs and handlers", out.indexOf("<div") < 0 && out.indexOf("onclick") < 0)
            t.ok("page: links made absolute", out.indexOf("https://news.example/more") >= 0)
            t.ok("page: images stay links", out.indexOf("<img") < 0 && out.indexOf("https://news.example/pic.jpg") >= 0)
            t.eq("page: too little text is nothing", reader.extract("<p>Short.</p>", "https://x.example/"), "")
            t.ok("search text is lowercase", list[2].search.indexOf("searchable") >= 0 && list[2].search === list[2].search.toLowerCase())
            t.done()
        }
    }
}
