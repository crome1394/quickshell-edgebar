#!/usr/bin/env bash
# Installed terminal emulators, one safe name per line.
# Known names come first. Other TerminalEmulator desktop entries follow.
# Names are a single token so the stats pill can pass them as argv.
set -u

known=(
    kitty foot alacritty wezterm ghostty ptyxis kgx
    gnome-terminal konsole xfce4-terminal mate-terminal deepin-terminal
    tilix terminator terminology rio st xterm urxvt lxterminal
    sakura roxterm tilda
)

safe_name() {
    [[ "$1" =~ ^[A-Za-z0-9._+-]{1,64}$ ]]
}

{
    for t in "${known[@]}"; do
        if command -v "$t" >/dev/null 2>&1 && safe_name "$t"; then
            printf '%s\n' "$t"
        fi
    done

    for d in /usr/share/applications "$HOME/.local/share/applications"; do
        [ -d "$d" ] || continue
        for f in "$d"/*.desktop; do
            [ -f "$f" ] || continue
            grep -q "TerminalEmulator" "$f" 2>/dev/null || continue
            exe=$(sed -n 's/^Exec=\([^ ]*\).*/\1/p' "$f" | head -n 1)
            [ -n "$exe" ] || continue
            bin=${exe##*/}
            case "$bin" in
                flatpak|env|sh|bash|gdbus|xdg-terminal-exec) continue ;;
            esac
            if command -v "$bin" >/dev/null 2>&1 && safe_name "$bin"; then
                printf '%s\n' "$bin"
            fi
        done
    done
} | awk '!seen[$0]++'
