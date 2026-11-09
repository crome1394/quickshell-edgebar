#!/usr/bin/env python3
"""List and apply wallpapers through hyprpaper.

Usage:
  wallpaper.py list <directory>
  wallpaper.py apply <image> [<monitor> [<fit>]]
  wallpaper.py status
  wallpaper.py add <directory> <file...>
  wallpaper.py rename <directory> <old-name> <new-name>
  wallpaper.py delete <directory> <name>

Prints one JSON object. Errors go to stderr and a non-zero status.

apply sets the wallpaper on one monitor (the focused one unless named)
and saves it in hyprpaper.conf next to every other monitor's entry, so
each monitor keeps its own. fit is cover, contain, tile, or fill.
status prints each monitor's saved path and fit from hyprpaper.conf.
"""

import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

EXTS = {".jpg", ".jpeg", ".png", ".webp", ".gif", ".bmp", ".jxl"}
MONITOR_OK = re.compile(r"^[A-Za-z0-9_.-]+$")
FITS = ("cover", "contain", "tile", "fill")


def fail(message, code=1):
    print(json.dumps({"ok": False, "error": message}, ensure_ascii=False))
    print(f"error: {message}", file=sys.stderr)
    sys.exit(code)


def emit(payload):
    print(json.dumps(payload, ensure_ascii=False))


def directory(text, create=False):
    raw = os.path.expanduser(text)
    if not raw or "\n" in raw or "\r" in raw:
        fail("invalid directory")
    if create:
        os.makedirs(raw, exist_ok=True)
    path = os.path.realpath(raw)
    if not os.path.isdir(path):
        fail("directory not found")
    return path


def image_file(text):
    if not text or "\n" in text or "\r" in text:
        fail("invalid image")
    path = os.path.realpath(os.path.expanduser(text))
    if not os.path.isfile(path):
        fail("file not found")
    if os.path.splitext(path)[1].lower() not in EXTS:
        fail("not an image file")
    return path


def safe_name(text, need_ext):
    name = os.path.basename(text or "")
    if name != (text or "") or name in (".", "..") or name.startswith("."):
        fail("invalid name")
    if any(mark in name for mark in ("/", "\\", "\n", "\r", "\x00")):
        fail("invalid name")
    if len(name) > 180:
        fail("invalid name")
    if need_ext and os.path.splitext(name)[1].lower() not in EXTS:
        fail("not an image file")
    return name


def inside(root, name):
    path = os.path.realpath(os.path.join(root, name))
    if os.path.dirname(path) != root or not os.path.isfile(path):
        fail("file not found in wallpaper folder")
    if os.path.splitext(path)[1].lower() not in EXTS:
        fail("not an image file")
    return path


def focused_monitor():
    override = os.environ.get("HYPR_WALLPAPER_MONITOR", "").strip()
    if override:
        if not MONITOR_OK.match(override):
            fail("refusing monitor name")
        return override
    try:
        done = subprocess.run(
            ["hyprctl", "monitors", "-j"],
            check=False,
            capture_output=True,
            text=True,
            timeout=5,
        )
        rows = json.loads(done.stdout or "[]")
    except (OSError, subprocess.TimeoutExpired, json.JSONDecodeError):
        fail("could not read monitors")
    chosen = ""
    if isinstance(rows, list):
        for row in rows:
            if isinstance(row, dict) and row.get("focused"):
                chosen = str(row.get("name") or "")
                break
        if not chosen and rows and isinstance(rows[0], dict):
            chosen = str(rows[0].get("name") or "")
    if not MONITOR_OK.match(chosen):
        fail("no monitor")
    return chosen


def atomic_write(path, text):
    folder = os.path.dirname(path) or "."
    os.makedirs(folder, exist_ok=True)
    target = os.path.realpath(path) if os.path.islink(path) else path
    os.makedirs(os.path.dirname(target) or ".", exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=os.path.dirname(target) or ".", prefix=".wallpaper-")
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            handle.write(text)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(tmp, target)
    except Exception:
        try:
            os.unlink(tmp)
        except OSError:
            pass
        raise


def cmd_list(root):
    names = []
    try:
        names = os.listdir(root)
    except OSError:
        fail("could not read directory")
    images = []
    for name in names:
        ext = os.path.splitext(name)[1].lower()
        if ext not in EXTS:
            continue
        path = os.path.join(root, name)
        if not os.path.isfile(path):
            continue
        try:
            size = os.path.getsize(path)
        except OSError:
            size = 0
        images.append({"path": path, "name": name, "size": size})
    images.sort(key=lambda row: row["name"].lower())
    emit({"ok": True, "dir": root, "count": len(images), "images": images})


def conf_path():
    return os.environ.get("HYPR_WALLPAPER_CONF", os.path.expanduser("~/.config/hypr/hyprpaper.conf"))


def read_conf(path):
    """Other settings lines, and monitor -> {path, fit}, in file order.

    Reads both the block form (wallpaper { monitor = … }) and the older
    "wallpaper = monitor,path" lines; preload lines are dropped.
    """
    try:
        with open(path, encoding="utf-8") as handle:
            lines = handle.read().splitlines()
    except OSError:
        lines = []
    other = []
    monitors = {}
    block = None
    for line in lines:
        text = line.strip()
        if block is not None:
            if text == "}":
                name = block.get("monitor", "")
                if MONITOR_OK.match(name) and block.get("path"):
                    fit = block.get("fit_mode", "cover")
                    monitors[name] = {"path": block["path"], "fit": fit if fit in FITS else "cover"}
                block = None
            elif "=" in text:
                key, _, value = text.partition("=")
                block[key.strip()] = value.strip()
            continue
        if re.match(r"^wallpaper\s*\{$", text):
            block = {}
            continue
        key, _, value = text.partition("=")
        key = key.strip()
        if key == "preload":
            continue
        if key == "wallpaper" and "," in value:
            name, _, img = value.strip().partition(",")
            name = name.strip()
            if MONITOR_OK.match(name) and name not in monitors:
                monitors[name] = {"path": img.strip(), "fit": "cover"}
            continue
        other.append(line)
    while other and not other[-1].strip():
        other.pop()
    return other, monitors


def write_conf(path, other, monitors):
    keep = [line for line in other if line.strip()]
    if not any(line.strip().startswith("splash") for line in keep):
        keep.append("splash = false")
    if not any(line.strip().startswith("ipc") for line in keep):
        keep.append("ipc = true")
    body = "\n".join(keep) + "\n"
    for name, row in monitors.items():
        body += f"\nwallpaper {{\n\tmonitor = {name}\n\tpath = {row['path']}\n\tfit_mode = {row['fit']}\n}}\n"
    atomic_write(path, body)


def cmd_apply(path, monitor="", fit=""):
    if monitor and not MONITOR_OK.match(monitor):
        fail("refusing monitor name")
    if fit and fit not in FITS:
        fail("fit must be cover, contain, tile, or fill")
    monitor = monitor or focused_monitor()
    conf = conf_path()
    other, monitors = read_conf(conf)
    if not fit:
        fit = monitors.get(monitor, {}).get("fit", "cover")
    first = subprocess.run(
        ["hyprctl", "hyprpaper", "wallpaper", f"{monitor},{path},{fit}"],
        check=False,
        capture_output=True,
        text=True,
        timeout=8,
    )
    if first.returncode != 0:
        second = subprocess.run(
            ["hyprctl", "hyprpaper", "wallpaper", f"{monitor},{path}"],
            check=False,
            capture_output=True,
            text=True,
            timeout=8,
        )
        if second.returncode != 0:
            fail("hyprpaper did not accept the image")
    monitors[monitor] = {"path": path, "fit": fit}
    write_conf(conf, other, monitors)
    emit({"ok": True, "path": path, "monitor": monitor, "fit": fit})


def cmd_status():
    _, monitors = read_conf(conf_path())
    emit({"ok": True, "monitors": monitors})


def unique_dest(root, name):
    dest = os.path.join(root, name)
    if not os.path.exists(dest):
        return dest
    stem, ext = os.path.splitext(name)
    number = 2
    while True:
        cand = os.path.join(root, f"{stem}-{number}{ext}")
        if not os.path.exists(cand):
            return cand
        number += 1


def cmd_add(root, files):
    added = []
    skipped = 0
    for raw in files:
        if not raw or "\n" in raw or "\r" in raw:
            skipped += 1
            continue
        src = os.path.realpath(os.path.expanduser(raw))
        if not os.path.isfile(src) or os.path.splitext(src)[1].lower() not in EXTS:
            skipped += 1
            continue
        dest = unique_dest(root, os.path.basename(src))
        try:
            shutil.copy2(src, dest)
        except OSError:
            skipped += 1
            continue
        added.append(dest)
    emit({"ok": True, "dir": root, "added": added, "count": len(added), "skipped": skipped})


def cmd_rename(root, old, new):
    src = inside(root, old)
    new_name = safe_name(os.path.basename(new), False)
    if not os.path.splitext(new_name)[1]:
        new_name = new_name + os.path.splitext(old)[1]
    if os.path.splitext(new_name)[1].lower() not in EXTS:
        fail("invalid new name")
    dest = os.path.realpath(os.path.join(root, new_name))
    if os.path.dirname(dest) != root:
        fail("invalid new name")
    if os.path.exists(dest):
        fail("that name is already used")
    os.rename(src, dest)
    emit({"ok": True, "path": dest, "name": new_name, "from": src})


def cmd_delete(root, name):
    src = inside(root, name)
    os.unlink(src)
    emit({"ok": True, "path": src, "name": name, "deleted": True})


def main():
    if len(sys.argv) < 2:
        fail("usage", 2)
    command = sys.argv[1]
    if command == "list" and len(sys.argv) == 3:
        cmd_list(directory(sys.argv[2], True))
        return 0
    if command == "apply" and 3 <= len(sys.argv) <= 5:
        monitor = sys.argv[3] if len(sys.argv) >= 4 else ""
        fit = sys.argv[4] if len(sys.argv) == 5 else ""
        cmd_apply(image_file(sys.argv[2]), monitor, fit)
        return 0
    if command == "status" and len(sys.argv) == 2:
        cmd_status()
        return 0
    if command == "add" and len(sys.argv) >= 4:
        cmd_add(directory(sys.argv[2], True), sys.argv[3:])
        return 0
    if command == "rename" and len(sys.argv) == 5:
        cmd_rename(directory(sys.argv[2]), safe_name(sys.argv[3], True), sys.argv[4])
        return 0
    if command == "delete" and len(sys.argv) == 4:
        cmd_delete(directory(sys.argv[2]), safe_name(sys.argv[3], True))
        return 0
    fail("usage", 2)


if __name__ == "__main__":
    sys.exit(main() or 0)
