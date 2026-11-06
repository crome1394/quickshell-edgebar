#!/usr/bin/env bash
# install-deps.sh — install what the bar needs and turn on its services.
#
# Reads config/dependencies.json (the same list Settings → System →
# Dependencies shows), then:
#   1. finds missing programs and fonts and installs their packages with
#      pacman (packages pacman does not know are listed for an AUR helper),
#   2. checks each systemd service and enables + starts the stopped ones
#      (user services with systemctl --user, system ones with sudo).
# It shows the plan and asks before changing anything.
#
# Usage: scripts/install-deps.sh [--required] [--yes] [--dry-run]
#   --required  only required items (default: required and optional)
#   --yes       do not ask before each step
#   --dry-run   show what would happen, change nothing
#
# Arch-based systems (pacman). On others it prints the plan and stops.

set -euo pipefail

here="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
list="$here/../config/dependencies.json"

only_required=0
assume_yes=0
dry_run=0
for arg in "$@"; do
    case "$arg" in
        --required) only_required=1 ;;
        --yes|-y) assume_yes=1 ;;
        --dry-run|-n) dry_run=1 ;;
        -h|--help) sed -n '2,19p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) printf 'Unknown option: %s (try --help)\n' "$arg" >&2; exit 2 ;;
    esac
done

if [[ -t 1 ]]; then
    bold=$'\e[1m'; dim=$'\e[2m'; red=$'\e[31m'; green=$'\e[32m'; yellow=$'\e[33m'; reset=$'\e[0m'
else
    bold=""; dim=""; red=""; green=""; yellow=""; reset=""
fi

say() { printf '%s\n' "$*"; }
die() { printf '%sError:%s %s\n' "$red" "$reset" "$*" >&2; exit 1; }

ask() {
    (( assume_yes )) && return 0
    local reply
    read -r -p "$1 [Y/n] " reply || return 1
    [[ -z "$reply" || "$reply" =~ ^[Yy] ]]
}

run() {
    printf '%s$ %s%s\n' "$dim" "$*" "$reset"
    (( dry_run )) && return 0
    "$@"
}

[[ -r "$list" ]] || die "Cannot read $list"
command -v python3 >/dev/null 2>&1 || die "python3 is needed to read the dependency list (install the 'python' package)."

# Rows as tab-separated fields. Every value is checked against a strict
# pattern, so nothing odd from the file reaches a command line.
rows() {
    python3 -I - "$list" "$1" "$only_required" <<'PY'
import json, re, sys
path, kind, only_required = sys.argv[1], sys.argv[2], sys.argv[3] == "1"
safe = re.compile(r"^[A-Za-z0-9@._+ -]{1,64}$")
with open(path, encoding="utf-8") as f:
    data = json.load(f)
for row in data.get(kind, []):
    need = row.get("need", "optional")
    if only_required and need != "required":
        continue
    name, pkg = str(row.get("name", "")), str(row.get("pkg", ""))
    scope = str(row.get("scope", ""))
    if not safe.match(name) or (pkg and not safe.match(pkg)) or " " in pkg:
        print(f"skip\t{name!r}", file=sys.stderr)
        continue
    if kind == "services" and (" " in name or scope not in ("user", "system")):
        continue
    print("\t".join([name, pkg, need, scope]))
PY
}

have_pacman=0
command -v pacman >/dev/null 2>&1 && have_pacman=1

declare -a missing_pkgs=()
add_pkg() {
    local p="$1" x
    [[ -n "$p" ]] || return 0
    for x in "${missing_pkgs[@]:-}"; do [[ "$x" == "$p" ]] && return 0; done
    missing_pkgs+=("$p")
}

say "${bold}Programs${reset}"
while IFS=$'\t' read -r name pkg need _; do
    if command -v -- "$name" >/dev/null 2>&1; then
        say "  ${green}✓${reset} $name"
    else
        say "  ${red}✗${reset} $name ${dim}($need, package: ${pkg:-unknown})${reset}"
        add_pkg "$pkg"
    fi
done < <(rows programs)

say "${bold}Fonts${reset}"
fonts_now=""
command -v fc-list >/dev/null 2>&1 && fonts_now="$(fc-list : family 2>/dev/null || true)"
while IFS=$'\t' read -r name pkg need _; do
    if grep -Fq -- "$name" <<<"$fonts_now"; then
        say "  ${green}✓${reset} $name"
    else
        say "  ${red}✗${reset} $name ${dim}($need, package: ${pkg:-unknown})${reset}"
        add_pkg "$pkg"
    fi
done < <(rows fonts)

# ── Packages ──────────────────────────────────────────────────────────────
if (( ${#missing_pkgs[@]} == 0 )); then
    say "${green}All programs and fonts are installed.${reset}"
elif (( ! have_pacman )); then
    say "${yellow}pacman was not found. Install these with your package manager:${reset} ${missing_pkgs[*]}"
else
    declare -a repo_pkgs=() aur_pkgs=()
    for p in "${missing_pkgs[@]}"; do
        if pacman -Si -- "$p" >/dev/null 2>&1; then repo_pkgs+=("$p"); else aur_pkgs+=("$p"); fi
    done
    if (( ${#repo_pkgs[@]} )); then
        say ""
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
while IFS=$'\t' read -r name pkg need scope; do
    if [[ "$scope" == "user" ]]; then ctl=(systemctl --user); else ctl=(systemctl); fi
    unit="$name.service"
    if ! "${ctl[@]}" list-unit-files -- "$unit" 2>/dev/null | grep -q -- "^$unit"; then
        say "  ${dim}–${reset} $name ${dim}($scope, not installed; package: ${pkg:-unknown})${reset}"
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
    if [[ "$scope" == "user" ]]; then start_user+=("$unit"); else start_system+=("$unit"); fi
done < <(rows services)

if (( ${#start_user[@]} )) && ask "Enable and start user services: ${start_user[*]}?"; then
    run systemctl --user enable --now -- "${start_user[@]}"
fi
if (( ${#start_system[@]} )) && ask "Enable and start system services: ${start_system[*]}? (needs sudo)"; then
    run sudo systemctl enable --now -- "${start_system[@]}"
fi
if (( ! ${#start_user[@]} && ! ${#start_system[@]} )); then
    say "${green}All installed services are enabled and running.${reset}"
fi

say ""
(( dry_run )) && say "${dim}Dry run: nothing was changed.${reset}"
say "Done. Settings → System → Dependencies shows the same list; press Recheck there."
