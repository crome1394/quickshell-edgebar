# Clipboard

A history of what you copy, and a viewer to copy any of it again.

## Set up

1. Install cliphist: `sudo pacman -S cliphist` (`wl-clipboard` is needed too).
2. Add a keybind in Hyprland (`config/keybindings.lua`):

   ```lua
   hl.bind("SUPER + V", hl.dsp.exec_cmd("qs ipc call clipboard toggle")) --#Tools# Clipboard history
   ```

   To let your close keys close the viewer (instead of the window under
   it), bind them to a function that checks for it first:

   ```lua
   barOverlays = { ["quickshell-clipboard"] = "qs ipc call clipboard close" }
   function closeOverlayOrWindow()
       for _, layer in ipairs(hl.get_layers()) do
           local close = barOverlays[layer.namespace]
           if close then
               hl.exec_cmd(close)
               return
           end
       end
       hl.dispatch(hl.dsp.window.close())
   end
   hl.bind("SUPER + C", closeOverlayOrWindow) --#Windows# Close the window (or the clipboard viewer)
   ```

3. Optional: turn on the **Clipboard** widget under **Widgets** for a bar
   button.

History is on by default (**Settings → Tools → Clipboard**). While it is
on, one `wl-paste --watch` process saves each copy with cliphist; nothing
else runs until you open the viewer. Copies a password manager marks as
secret are skipped.

## The viewer

The search box has focus as soon as it opens: type to filter, by words in
the text or by kind (`image`, `link`, `code`, `path`, `color`, `text`).
The list is newest first; the highlighted entry shows in full on the
right, where you can also select just part of it.

Pick an entry and it is copied and the viewer closes, so `Ctrl+V` pastes
it where you were.

| Keys | Action |
|---|---|
| `↑` `↓`, `Ctrl+N` `Ctrl+P`, `Ctrl+J` `Ctrl+K` | Move |
| `PgUp` `PgDn`, `Ctrl+Home` `Ctrl+End` | Move faster, first, last |
| `Enter` or click | Copy and close |
| `Alt+1` … `Alt+9` | Copy that entry and close |
| `Shift+Del` or ✕ | Delete the entry from the history |
| `Tab` or `Alt+Z` | Zoom: the preview fills the window |
| `Esc` | Leave zoom, clear the search, then close |

### Zoom

For long text and big pictures. While zoomed, `↑` `↓` still step through
the results (the header shows "3 of 12"), `PgUp` `PgDn` scroll, and
`Enter` copies. Click a picture to switch between fitted and full size;
at full size, drag or scroll to look around. `Tab`, `Alt+Z`, or `Esc` go
back to the list.

Moving the mouse over a row highlights it, the same highlight the keys
move. A click outside the card closes it.

## Settings

**Settings → Tools → Clipboard**: history on or off, how many copies to
keep (500 by default), whether pictures are kept, and Clear history.

## From a keybind or script

`qs ipc call clipboard toggle`, `open`, or `close`.
