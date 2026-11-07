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
  and a day for its articles. ● marks unread, ★ starred, ▶ video.
- **Article pane**: the text (images show as links, so nothing loads from
  the network), plus Open in browser, Copy link, Play in mpv (video only),
  Mark read, Star, and Mark feed read / unread.
- Double-click an article to play its video or open it in the browser.
- Drag the bar between the panes to resize; the width is remembered.

## Keyboard

Not while typing in search, except Esc, Ctrl+F, and Ctrl+R.

| Keys | Action |
|---|---|
| `w` `s` or `↑` `↓` (`PgUp` `PgDn`) | Move the cursor |
| `Space` `a` `←` | Open or close the feed or day |
| `Enter` `d` `→` | Open the article (or open a header) |
| `j` `k` | Next / previous article |
| `/` or `Ctrl+F` | Search |
| `b` | Open in browser |
| `c` | Copy link |
| `v` | Play in mpv |
| `m` | Mark read / unread |
| `Shift+S` | Star / unstar |
| `Shift+R` / `Shift+U` | Mark the feed read / unread |
| `r` or `Ctrl+R` | Reload |
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
