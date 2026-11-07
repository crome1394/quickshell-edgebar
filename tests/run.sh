#!/usr/bin/env bash
# run.sh: run the bar's logic tests.
#
# Each tests/*Test.qml is a small Quickshell config. For each one this
# copies the bar into a temporary folder, swaps in the test as shell.qml,
# runs it with a throwaway HOME (so nothing touches your settings or
# ~/.config), and reads its PASS / FAIL / DONE lines.
#
# Usage: tests/run.sh [NameTest ...]    (default: every test)
# Needs a Wayland session (Quickshell connects to it; tests open no windows).
set -euo pipefail

here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo=$(dirname -- "$here")
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT

if (( $# )); then
    tests=("$@")
else
    tests=()
    for f in "$here"/*Test.qml; do
        tests+=("$(basename -- "$f" .qml)")
    done
fi

failed=0

# Load check: start the real shell.qml (bars off, so nothing shows) and
# fail if Quickshell cannot load it. Catches errors lint misses, such as
# a property that clashes with one Qt already defines.
load="$work/ShellLoad"
mkdir -p -- "$load/home" "$load/state"
(cd -- "$repo" && tar --exclude=./.git --exclude=./state --exclude=./tests -cf - .) | tar -xf - -C "$load"
printf '{"showTopBar": false, "showBottomBar": false, "showLeftBar": false, "showRightBar": false}\n' >"$load/state/bar-layout.json"
HOME="$load/home" XDG_CONFIG_HOME="$load/home/.config" timeout 8 qs -p "$load" >"$load/run.log" 2>&1 || true
if grep -qE 'Failed to load configuration|is not a type|unavailable|Cannot override' "$load/run.log"; then
    printf '%-22s failed to load\n' "ShellLoad"
    grep -E 'ERROR|caused by' "$load/run.log" | sed 's/^/    /' | head -10
    failed=1
else
    printf '%-22s loaded\n' "ShellLoad"
fi

for name in "${tests[@]}"; do
    if [[ ! "$name" =~ ^[A-Za-z0-9]+Test$ || ! -f "$here/$name.qml" ]]; then
        printf 'unknown test: %s\n' "$name" >&2
        failed=1
        continue
    fi
    dir="$work/$name"
    mkdir -p -- "$dir/home"
    (cd -- "$repo" && tar --exclude=./.git --exclude=./state --exclude=./tests -cf - .) | tar -xf - -C "$dir"
    cp -r -- "$here" "$dir/tests"
    cp -- "$here/$name.qml" "$dir/shell.qml"
    log="$dir/run.log"
    HOME="$dir/home" XDG_CONFIG_HOME="$dir/home/.config" timeout 30 qs -p "$dir" >"$log" 2>&1 || true
    pass=$(grep -c 'qml.*: PASS ' "$log" || true)
    fail=$(grep -c 'qml.*: FAIL ' "$log" || true)
    errors=$(grep -cE 'TypeError|ReferenceError|is not a type|is not defined' "$log" || true)
    if ! grep -q 'qml.*: DONE' "$log"; then
        printf '%-22s did not finish\n' "$name"
        grep -E 'FAIL|Error|error' "$log" | sed 's/^/    /' | head -10
        failed=1
    elif (( fail > 0 || errors > 0 )); then
        printf '%-22s %d passed, %d failed, %d errors\n' "$name" "$pass" "$fail" "$errors"
        grep -E 'FAIL |TypeError|ReferenceError|is not a type|is not defined' "$log" | sed 's/^.*qml[^:]*: /    /' | head -20
        failed=1
    else
        printf '%-22s %d passed\n' "$name" "$pass"
    fi
done

exit "$failed"
