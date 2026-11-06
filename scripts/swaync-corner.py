#!/usr/bin/env python3
"""Point SwayNC toasts at a screen corner and set how long they stay.

Usage: swaync-corner.py topLeft|topRight|bottomLeft|bottomRight SECONDS

Writes positionX, positionY, and the normal-priority timeout in
~/.config/swaync/config.json, then reloads SwayNC only when a value
changes. A bottom corner stacks new toasts upward. Timeout is 0 to 60
seconds. 0 keeps a toast up until it is closed. Missing config or a
missing swaync-client exits quietly.
"""

import json
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

CORNERS = {
    "topLeft": ("left", "top"),
    "topRight": ("right", "top"),
    "bottomLeft": ("left", "bottom"),
    "bottomRight": ("right", "bottom"),
}


def replace_value(text, key, value):
    pattern = re.compile(rf'("{re.escape(key)}"\s*:\s*")([^"]*)(")')
    match = pattern.search(text)
    if not match:
        raise KeyError(key)
    if match.group(2) == value:
        return text, False
    start, end = match.span(2)
    return text[:start] + value + text[end:], True


def replace_int(text, key, value):
    pattern = re.compile(rf'("{re.escape(key)}"\s*:\s*)(-?\d+)')
    match = pattern.search(text)
    if not match:
        raise KeyError(key)
    if match.group(2) == str(value):
        return text, False
    start, end = match.span(2)
    return text[:start] + str(value) + text[end:], True


def write_atomic(path: Path, text: str) -> None:
    """Write via a unique temp file in the same folder, then rename."""
    fd, tmp = tempfile.mkstemp(dir=str(path.parent), prefix="." + path.name + ".")
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            handle.write(text)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(tmp, path)
    except BaseException:
        try:
            os.unlink(tmp)
        except OSError:
            pass
        raise


def apply_json(path: Path, position_x: str, position_y: str, timeout: int) -> bool:
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        return False
    changed = False
    if data.get("positionX") != position_x:
        data["positionX"] = position_x
        changed = True
    if data.get("positionY") != position_y:
        data["positionY"] = position_y
        changed = True
    if data.get("timeout") != timeout:
        data["timeout"] = timeout
        changed = True
    if not changed:
        return False
    write_atomic(path, json.dumps(data, indent=2) + "\n")
    return True


def apply_text(path: Path, position_x: str, position_y: str, timeout: int) -> bool:
    text = path.read_text(encoding="utf-8")
    text, changed_x = replace_value(text, "positionX", position_x)
    text, changed_y = replace_value(text, "positionY", position_y)
    text, changed_t = replace_int(text, "timeout", timeout)
    if not changed_x and not changed_y and not changed_t:
        return False
    write_atomic(path, text)
    return True


def main() -> int:
    if len(sys.argv) != 3 or sys.argv[1] not in CORNERS:
        names = ", ".join(CORNERS)
        print(f"usage: swaync-corner.py {names} SECONDS", file=sys.stderr)
        return 2
    try:
        timeout = int(sys.argv[2])
    except ValueError:
        print("timeout must be a whole number of seconds", file=sys.stderr)
        return 2
    if timeout < 0 or timeout > 60:
        print("timeout must be from 0 to 60", file=sys.stderr)
        return 2

    path = Path.home() / ".config" / "swaync" / "config.json"
    if not path.is_file():
        return 0
    position_x, position_y = CORNERS[sys.argv[1]]
    changed = False
    try:
        changed = apply_json(path, position_x, position_y, timeout)
    except Exception:
        try:
            changed = apply_text(path, position_x, position_y, timeout)
        except Exception:
            return 0
    if changed:
        subprocess.run(["swaync-client", "-R", "-sw"], check=False)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
