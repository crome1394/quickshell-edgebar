# FreshRSS

A reader for a [FreshRSS](https://freshrss.org/) server, opened from the
FreshRSS pill or a keybind.

## Set up

1. In FreshRSS, enable the API (Settings → Authentication) and set an
   **API password** under Profile. It is not your login password.
2. In the bar: **Settings → Applications → FreshRSS**. Enter the address,
   user, and API password, press **Test**, then **Save server**.
3. Turn on the FreshRSS widget under **Widgets** and Apply.

The server is saved to `~/.config/freshrss-quickshell/freshrss.env`,
outside the repo and readable only by you. You can also write it by hand:

```sh
FRESHRSS_BASE_URL=https://rss.example.com
FRESHRSS_USER=me
FRESHRSS_API_PASSWORD='your-api-password'
```

The bar reads it as plain text and never runs it.

## The pill

Shows the unread count (99+ past 99, "RSS" at zero). It checks every few
minutes (Reader → Check every), and only while the pill is on a bar or the
reader is open.

## The reader

- **Chips**: All dates / Today / 7 days, Unread / All / Read / Starred,
  Any type / Video, Collapse all / Expand all, Filters.
- **Filters**: search (title, feed, author, text), max days, and per feed
  (All, Read) or max items (Unread, Starred).
- **List**: feeds A–Z with their unread count; open a feed for its days,
  and a day for its articles. ● marks unread, ★ starred, ▶ video. Long
  feed titles wrap to three lines. Only the cursor row is highlighted.
- **Article pane**: the text (images show as links; only the lead picture
  loads), plus Open in browser, Copy link, Play in mpv (video only),
  Mark read, Star, and Mark feed read / unread. Each button shows its key.
- **Lead picture**: the open article shows its video's still frame (YouTube)
  or its first picture. Click it to play or open. Only that one image loads.
- **Web page** (`f`): fetch the article's page and show its main text in
  place of the feed text. **Always for this feed** does this for every
  article of a feed (saved). Pages are kept only while the reader is open.
  Sites behind a browser check (Cloudflare) need `b` instead.
- Feed headers show the site icon from your FreshRSS server.
- Opening a feed or day scrolls it to the top of the list.
- Double-click an article to play its video or open it in the browser.
- Drag the bar between the panes to resize; the width is remembered.

## Keyboard

Press `?` in the reader for this list. Letters wait while you type in
search; Ctrl+F, Ctrl+R, and Esc always work. Shift is exact: `r` and
`Shift+R` do different things.

| Keys | Action |
|---|---|
| `↑` `↓` (`PgUp` `PgDn` `Home` `End`) | Move the cursor (the article under it shows on the right) |
| `j` `k` | Next / previous article |
| `Enter` `→` | Open a feed or day |
| `←` | Close a feed or day |
| `r` / `u` | Mark the article read / unread |
| `Space` | Article: read ↔ unread. Feed or day: all read ↔ all unread |
| `Shift+R` / `Shift+U` | Mark the whole feed read / unread |
| `s` | Star / unstar |
| `b` | Open in browser |
| `c` | Copy link |
| `v` | Play in mpv |
| `f` | Web page ↔ feed text |
| `Ctrl+F` or `/` | Find |
| `Ctrl+R` | Reload |
| `?` | Show or hide the shortcut list |
| `Esc` | Leave search, clear it, then close |

## From a keybind

```lua
hl.bind("SUPER + R", hl.dsp.exec_cmd("qs ipc call freshRss toggle"))
```

Also `open`, `close`, and `refresh` (check the unread count now).

## Needs

Nothing extra for reading. `mpv` (and `yt-dlp` for YouTube) for Play in
mpv. "Read" lists the read articles of each feed, because FreshRSS has no
read-only stream.
