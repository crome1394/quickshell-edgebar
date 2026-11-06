#!/usr/bin/env python3
"""Copy one local image to the clipboard.

The path is a single argument. It is never placed in a shell command.
"""

import subprocess
import sys
from pathlib import Path

SUFFIXES = {
    ".png": "image/png",
    ".jpg": "image/jpeg",
    ".jpeg": "image/jpeg",
    ".webp": "image/webp",
    ".gif": "image/gif",
    ".bmp": "image/bmp",
}
MAX_BYTES = 20 * 1024 * 1024


def main() -> int:
    if len(sys.argv) != 2:
        return 2
    raw = sys.argv[1]
    if not raw.startswith("/") or "\x00" in raw or raw.startswith("//"):
        return 2
    path = Path(raw)
    mime = SUFFIXES.get(path.suffix.lower())
    if mime is None or not path.is_file():
        return 2
    try:
        if path.stat().st_size > MAX_BYTES:
            return 2
        data = path.read_bytes()
    except OSError:
        return 2
    try:
        proc = subprocess.run(["wl-copy", "--type", mime], input=data, check=False)
    except OSError:
        return 2
    return proc.returncode


if __name__ == "__main__":
    raise SystemExit(main())
