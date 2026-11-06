#!/usr/bin/env python3
"""Print zone1970.tab as JSON: id, city, coordinates, standard UTC offset.

No arguments. The offset is the lesser of the January and July values so a
daylight-saving zone keeps its standard band, matching the map masks.
"""

import json
import os
import re
import sys
import time
from pathlib import Path

ZONE_TAB = Path("/usr/share/zoneinfo/zone1970.tab")
COORD_RE = re.compile(
    r"^([+-])(\d{2})(\d{2})(\d{2})?([+-])(\d{3})(\d{2})(\d{2})?$"
)
TZ_RE = re.compile(r"^[A-Za-z0-9/_+\-]+$")


def dms(sign, deg, minutes, seconds):
    val = int(deg) + int(minutes) / 60.0
    if seconds:
        val += int(seconds) / 3600.0
    return val if sign == "+" else -val


def parse_coord(text):
    match = COORD_RE.match(text.strip())
    if not match:
        return None
    slat, dlat, mlat, slatsec, slon, dlon, mlon, slonsec = match.groups()
    return (
        dms(slat, dlat, mlat, slatsec),
        dms(slon, dlon, mlon, slonsec),
    )


def offset_at(year, month, day):
    stamp = time.mktime((year, month, day, 12, 0, 0, 0, 0, 0))
    text = time.strftime("%z", time.localtime(stamp))
    sign = 1 if text[0] != "-" else -1
    return sign * (int(text[1:3]) + int(text[3:5]) / 60.0)


def standard_offset(tz):
    old = os.environ.get("TZ")
    os.environ["TZ"] = tz
    time.tzset()
    try:
        january = offset_at(2024, 1, 15)
        july = offset_at(2024, 7, 15)
    except (OverflowError, OSError, ValueError):
        january = july = 0.0
    finally:
        if old is None:
            os.environ.pop("TZ", None)
        else:
            os.environ["TZ"] = old
        time.tzset()
    return january if january <= july else july


def main():
    rows = []
    if ZONE_TAB.is_file():
        for line in ZONE_TAB.read_text(encoding="utf-8", errors="replace").splitlines():
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            parts = line.split("\t")
            if len(parts) < 3:
                continue
            coord = parse_coord(parts[1])
            tz = parts[2].strip()
            if coord is None or not TZ_RE.fullmatch(tz):
                continue
            bits = tz.split("/")
            rows.append({
                "id": tz,
                "lat": round(coord[0], 4),
                "lon": round(coord[1], 4),
                "city": bits[-1].replace("_", " "),
                "region": bits[0].replace("_", " ") if len(bits) > 1 else "Other",
                "comment": parts[3].strip() if len(parts) > 3 else "",
                "offset": standard_offset(tz),
            })
    json.dump(rows, sys.stdout, ensure_ascii=False)
    sys.stdout.write("\n")


if __name__ == "__main__":
    main()
