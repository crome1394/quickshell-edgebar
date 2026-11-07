#!/usr/bin/env bash
# install-deps.sh — set up the bar on a fresh system, and back up or
# restore your settings.
#
# Install (the default) reads config/dependencies.json (the list Settings →
# System → Dependencies shows), then:
#   1. installs missing required programs and fonts, and asks about each
#      group of optional ones by feature (Tailscale, screenshot editor, …),
#      with pacman, or paru/yay for AUR packages,
#   2. enables and starts stopped services (user ones with systemctl --user,
#      system ones with sudo),
#   3. links the bar's helper scripts into ~/.local/bin for keybinds and
#      hypridle (an existing real file is moved aside to .bak, never lost).
# It shows each step and asks first.
#
# Usage:
#   scripts/install-deps.sh [--required] [--yes] [--dry-run]
#       --required  only required items; skip every optional group
#       --yes       take each default without asking
#       --dry-run   show what would happen, change nothing
#   scripts/install-deps.sh --backup [FILE]
#       Save your settings to FILE (default ~/quickshell-backup-<date>.tar.gz):
#       the bar's state/, the FreshRSS server file, notification history,
#       and your own scripts in ~/.local/bin. The file holds passwords, so it
#       is made readable only by you.
#   scripts/install-deps.sh --restore FILE
#       Put a backup back. Only the paths above are accepted from the file.
#
# Arch-based systems (pacman). Elsewhere the install prints the plan and stops.

set -euo pipefail

here="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo="$(cd -- "$here/.." && pwd)"
list="$repo/config/dependencies.json"

# Scripts in scripts/ that keybinds and hypridle call through ~/.local/bin.
helpers=(capture-screenshot ocr-region screensaver.sh screensaver-config.sh)

# What a backup holds, relative to $HOME. Restore accepts nothing else.
backup_paths=(".config/quickshell/state" ".config/freshrss-quickshell" ".local/state/quickshell")

mode=install
only_required=0
assume_yes=0
dry_run=0
archive=""
while (( $# )); do
    case "$1" in
        --required) only_required=1 ;;
        --yes|-y) assume_yes=1 ;;
        --dry-run|-n) dry_run=1 ;;
        --backup)
            mode=backup
            if [[ $# -gt 1 && "$2" != -* ]]; then archive="$2"; shift; fi
            ;;
        --restore)
            mode=restore
            [[ $# -gt 1 ]] || { printf 'Usage: --restore FILE\n' >&2; exit 2; }
            archive="$2"
            shift
            ;;
        -h|--help) sed -n '2,31p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) printf 'Unknown option: %s (try --help)\n' "$1" >&2; exit 2 ;;
    esac
    shift
done

if [[ -t 1 ]]; then
    bold=$'\e[1m'; dim=$'\e[2m'; red=$'\e[31m'; green=$'\e[32m'; yellow=$'\e[33m'; reset=$'\e[0m'
else
    bold=""; dim=""; red=""; green=""; yellow=""; reset=""
fi

say() { printf '%s\n' "$*"; }
die() { printf '%sError:%s %s\n' "$red" "$reset" "$*" >&2; exit 1; }

# ask "question" [y|n]: the second argument is the default (Enter).
ask() {
    local default="${2:-y}" reply hint="[Y/n]"
    [[ "$default" == n ]] && hint="[y/N]"
    if (( assume_yes )); then
        [[ "$default" == y ]]
        return
    fi
    # Printed by hand: read -p stays silent when input is not a terminal.
    printf '%s %s ' "$1" "$hint"
    read -r reply || return 1
    [[ -z "$reply" ]] && { [[ "$default" == y ]]; return; }
    [[ "$reply" =~ ^[Yy] ]]
}

run() {
    printf '%s$ %s%s\n' "$dim" "$*" "$reset"
    (( dry_run )) && return 0
    "$@"
}

# ── Backup ────────────────────────────────────────────────────────────────
# Your own scripts in ~/.local/bin: regular text files only, not symlinks
# (the bar's helpers are links into the repo) and not big binaries.
own_scripts() {
    local f
    [[ -d "$HOME/.local/bin" ]] || return 0
    for f in "$HOME"/.local/bin/*; do
        [[ -f "$f" && ! -L "$f" ]] || continue
        (( $(stat -c %s -- "$f") <= 1048576 )) || continue
        file -b --mime-type -- "$f" | grep -q '^text/' || continue
        printf '%s\n' ".local/bin/${f##*/}"
    done
}

do_backup() {
    local out="${archive:-$HOME/quickshell-backup-$(date +%Y%m%d-%H%M%S).tar.gz}"
    local items=() p
    for p in "${backup_paths[@]}"; do
        [[ -e "$HOME/$p" ]] && items+=("$p")
    done
    while IFS= read -r p; do items+=("$p"); done < <(own_scripts)
    (( ${#items[@]} )) || die "Nothing to back up."
    say "${bold}Backing up to${reset} $out"
    for p in "${items[@]}"; do say "  ~/$p"; done
    (( dry_run )) && { say "${dim}Dry run: nothing written.${reset}"; return 0; }
    # Written where only you can read it: the FreshRSS file has a password.
    ( umask 077 && tar -czf "$out" -C "$HOME" -- "${items[@]}" )
    chmod 600 -- "$out"
    say "${green}Saved.${reset} Keep it somewhere safe; restore with: scripts/install-deps.sh --restore $out"
    say "${dim}Your Hyprland config is not in it; it lives in its own git repo.${reset}"
}

# A path from an archive is allowed only under the backup paths or as a
# script directly in .local/bin. No absolute paths, no "..".
allowed() {
    local p="${1%/}" b
    [[ "$p" != /* && "$p" != *..* ]] || return 1
    for b in "${backup_paths[@]}"; do
        [[ "$p" == "$b" || "$p" == "$b"/* ]] && return 0
    done
    [[ "$p" =~ ^\.local/bin/[^/]+$ ]]
}

do_restore() {
    [[ -r "$archive" ]] || die "Cannot read $archive"
    local e bad=0
    while IFS= read -r e; do
        [[ -n "$e" ]] || continue
        # Directory entries for the parents of allowed paths are fine.
        if ! allowed "$e" && ! [[ "$e" =~ ^\.(config|local(/state|/bin)?)/?$ || "$e" == ".config/quickshell/" ]]; then
            say "  ${red}refused:${reset} $e"
            bad=1
        fi
    done < <(tar -tzf "$archive")
    (( bad )) && die "The archive has paths outside a bar backup; nothing was restored."
    # Links in an archive could point a later file outside these paths.
    if tar -tvzf "$archive" | grep -q '^[lh]'; then
        die "The archive contains links; nothing was restored."
    fi
    say "${bold}Restoring from${reset} $archive"
    tar -tzf "$archive" | grep -v '/$' | sed 's/^/  ~\//'
    ask "Put these back (files with the same name are replaced)?" y || { say "Nothing restored."; return 0; }
    (( dry_run )) && { say "${dim}Dry run: nothing written.${reset}"; return 0; }
    # Every entry was checked above, so the whole archive goes back.
    tar -xzf "$archive" -C "$HOME" --no-same-owner
    say "${green}Restored.${reset} Restart the bar: qs kill; qs -d"
}

case "$mode" in
    backup) do_backup; exit 0 ;;
    restore) do_restore; exit 0 ;;
esac

# ── Install ───────────────────────────────────────────────────────────────
[[ -r "$list" ]] || die "Cannot read $list"
command -v python3 >/dev/null 2>&1 || die "python3 is needed to read the dependency list (install the 'python' package)."

# Rows as tab-separated fields: name, pkg, need, scope, area, ask. Every
# value is checked against a strict pattern, so nothing odd from the file
# reaches a command line. SwayNC-only tools are never installed: the bar
# uses SwayNC when it is already there, and its own server otherwise.
rows() {
    python3 -I - "$list" "$1" <<'PY'
import json, re, sys
path, kind = sys.argv[1], sys.argv[2]
safe = re.compile(r"^[A-Za-z0-9@._+ -]{1,64}$")
with open(path, encoding="utf-8") as f:
    data = json.load(f)
for row in data.get(kind, []):
    if row.get("when") == "swaync":
        continue
    need = row.get("need", "optional")
    name, pkg = str(row.get("name", "")), str(row.get("pkg", ""))
    scope = str(row.get("scope", "")) or "-"
    area = str(row.get("area", "Other"))
    ask = "n" if row.get("ask") == "no" else "y"
    if not safe.match(name) or (pkg and not safe.match(pkg)) or " " in pkg or not safe.match(area):
        print(f"skip\t{name!r}", file=sys.stderr)
        continue
    if kind == "services" and (" " in name or scope not in ("user", "system")):
        continue
    print("\t".join([name, pkg or "-", need, scope, area, ask]))
PY
}

have_pacman=0
command -v pacman >/dev/null 2>&1 && have_pacman=1

declare -a missing_pkgs=()
add_pkg() {
    local p="$1" x
    [[ -n "$p" && "$p" != "-" ]] || return 0
    for x in "${missing_pkgs[@]:-}"; do [[ "$x" == "$p" ]] && return 0; done
    missing_pkgs+=("$p")
}

# Optional missing packages, grouped by area: area → "pkg pkg …".
declare -A opt_pkgs=() opt_names=() opt_default=()
declare -a opt_order=()

say "${bold}Programs${reset}"
while IFS=$'\t' read -r name pkg need _ area ask_default; do
    if command -v -- "$name" >/dev/null 2>&1; then
        say "  ${green}✓${reset} $name"
        continue
    fi
    say "  ${red}✗${reset} $name ${dim}($need, $area, package: $pkg)${reset}"
    if [[ "$need" == "required" ]]; then
        add_pkg "$pkg"
        continue
    fi
    (( only_required )) && continue
    if [[ -z "${opt_pkgs[$area]+x}" ]]; then
        opt_order+=("$area")
        opt_pkgs[$area]=""
        opt_names[$area]=""
        opt_default[$area]="$ask_default"
    fi
    [[ " ${opt_pkgs[$area]} " == *" $pkg "* ]] || opt_pkgs[$area]+="$pkg "
    opt_names[$area]+="$name "
    # Any "no" in a group makes the whole group default to No.
    [[ "$ask_default" == n ]] && opt_default[$area]=n
done < <(rows programs)

say "${bold}Fonts${reset}"
fonts_now=""
command -v fc-list >/dev/null 2>&1 && fonts_now="$(fc-list : family 2>/dev/null || true)"
while IFS=$'\t' read -r name pkg need _; do
    if grep -Fq -- "$name" <<<"$fonts_now"; then
        say "  ${green}✓${reset} $name"
    else
        say "  ${red}✗${reset} $name ${dim}($need, package: $pkg)${reset}"
        add_pkg "$pkg"
    fi
done < <(rows fonts)

# ── Optional groups ───────────────────────────────────────────────────────
if (( ${#opt_order[@]} )); then
    say ""
    say "${bold}Optional features${reset} ${dim}(each needs only its own packages)${reset}"
    for area in "${opt_order[@]}"; do
        if ask "Install $area (${opt_pkgs[$area]% })?" "${opt_default[$area]}"; then
            for p in ${opt_pkgs[$area]}; do add_pkg "$p"; done
        fi
    done
fi

# ── Packages ──────────────────────────────────────────────────────────────
say ""
if (( ${#missing_pkgs[@]} == 0 )); then
    say "${green}Nothing to install.${reset}"
elif (( ! have_pacman )); then
    say "${yellow}pacman was not found. Install these with your package manager:${reset} ${missing_pkgs[*]}"
else
    declare -a repo_pkgs=() aur_pkgs=()
    for p in "${missing_pkgs[@]}"; do
        if pacman -Si -- "$p" >/dev/null 2>&1; then repo_pkgs+=("$p"); else aur_pkgs+=("$p"); fi
    done
    if (( ${#repo_pkgs[@]} )); then
        say "From the repositories: ${repo_pkgs[*]}"
        if ask "Install them with pacman?"; then
            run sudo pacman -S --needed -- "${repo_pkgs[@]}"
        fi
    fi
    if (( ${#aur_pkgs[@]} )); then
        helper=""
        for h in paru yay; do command -v "$h" >/dev/null 2>&1 && { helper="$h"; break; }; done
        say ""
        say "Not in the repositories (AUR?): ${aur_pkgs[*]}"
        if [[ -n "$helper" ]] && ask "Install them with $helper?"; then
            run "$helper" -S --needed -- "${aur_pkgs[@]}"
        elif [[ -z "$helper" ]]; then
            say "${dim}No AUR helper found (paru or yay). Install these by hand.${reset}"
        fi
    fi
fi

# ── Services ──────────────────────────────────────────────────────────────
say ""
say "${bold}Services${reset}"
command -v systemctl >/dev/null 2>&1 || die "systemctl was not found, so services cannot be checked."

declare -a start_user=() start_system=()
while IFS=$'\t' read -r name pkg need scope _ ask_default; do
    if [[ "$scope" == "user" ]]; then ctl=(systemctl --user); else ctl=(systemctl); fi
    unit="$name.service"
    if ! "${ctl[@]}" list-unit-files -- "$unit" 2>/dev/null | grep -q -- "^$unit"; then
        say "  ${dim}–${reset} $name ${dim}($scope, not installed; package: $pkg)${reset}"
        continue
    fi
    active="$("${ctl[@]}" is-active -- "$unit" 2>/dev/null || true)"
    enabled="$("${ctl[@]}" is-enabled -- "$unit" 2>/dev/null || true)"
    # Socket-activated services (pipewire) start on demand from their .socket.
    if [[ "$enabled" == "disabled" ]] \
        && [[ "$("${ctl[@]}" is-enabled -- "$name.socket" 2>/dev/null || true)" == "enabled" ]]; then
        enabled="via socket"
    fi
    if [[ "$active" == "active" && ( "$enabled" == "enabled" || "$enabled" == "static" || "$enabled" == "indirect" || "$enabled" == "alias" || "$enabled" == "via socket" ) ]]; then
        say "  ${green}✓${reset} $name ${dim}($scope, $active, $enabled)${reset}"
        continue
    fi
    say "  ${yellow}!${reset} $name ${dim}($scope, $need: ${active:-unknown}, ${enabled:-unknown})${reset}"
    # Optional services that default to No (tailscaled) are asked one by one.
    if [[ "$need" != "required" && "$ask_default" == n ]]; then
        ask "Enable and start $name?" n || continue
        if [[ "$scope" == "user" ]]; then run systemctl --user enable --now -- "$unit"; else run sudo systemctl enable --now -- "$unit"; fi
        continue
    fi
    if [[ "$scope" == "user" ]]; then start_user+=("$unit"); else start_system+=("$unit"); fi
done < <(rows services)

if (( ${#start_user[@]} )) && ask "Enable and start user services: ${start_user[*]}?"; then
    run systemctl --user enable --now -- "${start_user[@]}"
fi
if (( ${#start_system[@]} )) && ask "Enable and start system services: ${start_system[*]}? (needs sudo)"; then
    run sudo systemctl enable --now -- "${start_system[@]}"
fi

# ── Helper links ──────────────────────────────────────────────────────────
say ""
say "${bold}Helper scripts${reset} ${dim}(~/.local/bin → $repo/scripts)${reset}"
declare -a to_link=()
for h in "${helpers[@]}"; do
    target="$repo/scripts/$h"
    link="$HOME/.local/bin/$h"
    if [[ -L "$link" && "$(readlink -f -- "$link")" == "$(readlink -f -- "$target")" ]]; then
        say "  ${green}✓${reset} $h"
    else
        say "  ${yellow}!${reset} $h ${dim}($( [[ -e "$link" ]] && echo "a different file is there; it will be kept as $h.bak" || echo "not linked yet"))${reset}"
        to_link+=("$h")
    fi
done
if (( ${#to_link[@]} )) && ask "Link them into ~/.local/bin?"; then
    run mkdir -p -- "$HOME/.local/bin"
    for h in "${to_link[@]}"; do
        link="$HOME/.local/bin/$h"
        if [[ -e "$link" && ! -L "$link" ]]; then
            run mv -f -- "$link" "$link.bak"
        fi
        run ln -sfn -- "$repo/scripts/$h" "$link"
    done
fi

say ""
(( dry_run )) && say "${dim}Dry run: nothing was changed.${reset}"
say "Done. Settings → System → Dependencies shows the same list; press Recheck there."
