#!/usr/bin/env python3
"""NetworkManager facts and a few actions for the network menu.

The bar uses Quickshell.Networking for Wi-Fi scan, connect, and forget.
This script covers what that module does not: link facts, VPN profiles,
airplane radios, hidden networks, DNS flush, and DHCP reapply.

Usage:
  network.py status
  network.py radio on|off
  network.py device connect|disconnect IFACE...
  network.py vpn up|down UUID...
  network.py reapply IFACE
  network.py flush-dns
  network.py editor
  network.py hidden IFACE SSID [PSK]

Prints one JSON object. A password is accepted only as an argv for a hidden
network and is never written to the JSON or the log.
"""

import json
import os
import re
import shutil
import subprocess
import sys

IFACE_OK = re.compile(r"^[A-Za-z0-9_.:-]{1,32}$")
UUID_OK = re.compile(
    r"^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$"
)
VPN_TYPES = {"vpn", "wireguard"}


def emit(payload):
    print(json.dumps(payload, ensure_ascii=False))


def fail(message, code=1):
    emit({"ok": False, "error": message})
    sys.exit(code)


def safe_error(text, secret):
    message = " ".join(str(text or "").split())
    if secret:
        message = message.replace(secret, "••••")
    if not message:
        return "command failed"
    return message[:180]


def check_iface(iface):
    if not IFACE_OK.match(iface) or ".." in iface:
        fail("invalid interface")


def check_uuid(value):
    if not UUID_OK.match(value):
        fail("invalid VPN id")


def check_ssid(ssid):
    if not ssid or ssid.startswith("-") or len(ssid) > 32:
        fail("invalid network name")
    for char in ssid:
        if ord(char) < 32:
            fail("invalid network name")


def check_psk(psk):
    if len(psk) < 8 or len(psk) > 63:
        fail("password must be 8 to 63 characters")
    for char in psk:
        if ord(char) < 32 or ord(char) == 127:
            fail("invalid password")


def run_cmd(args, timeout, secret=""):
    try:
        proc = subprocess.run(
            args,
            capture_output=True,
            text=True,
            timeout=timeout,
            check=False,
        )
    except subprocess.TimeoutExpired:
        fail("timed out")
    except OSError as exc:
        fail(safe_error(str(exc), secret))
    return proc.returncode, proc.stdout or "", proc.stderr or ""


def need_nmcli():
    if shutil.which("nmcli") is None:
        fail("nmcli is not installed")


def split_nmcli(line):
    parts = []
    buf = []
    index = 0
    while index < len(line):
        char = line[index]
        if char == "\\" and index + 1 < len(line):
            buf.append(line[index + 1])
            index += 2
            continue
        if char == ":":
            parts.append("".join(buf))
            buf = []
            index += 1
            continue
        buf.append(char)
        index += 1
    parts.append("".join(buf))
    return parts


def short_state(text):
    raw = str(text or "").strip()
    if "(" in raw and raw.endswith(")"):
        return raw[raw.find("(") + 1 : -1].strip()
    return raw


def method_label(value):
    key = str(value or "").strip().lower()
    labels = {
        "auto": "Automatic",
        "manual": "Manual",
        "disabled": "Disabled",
        "shared": "Shared",
        "link-local": "Link-local",
    }
    return labels.get(key, str(value or "").strip())


def band_label(value):
    key = str(value or "").strip().lower()
    if key == "a":
        return "5 GHz"
    if key in ("bg", "b", "g"):
        return "2.4 GHz"
    if "6" in key:
        return "6 GHz"
    return str(value or "").strip()


def security_label(value):
    raw = str(value or "").strip()
    if not raw or raw == "--":
        return ""
    return raw.replace("-", " ").upper()


def link_speed(iface):
    check_iface(iface)
    base = os.path.join("/sys/class/net", iface)
    try:
        raw = open(os.path.join(base, "speed"), encoding="utf-8").read().strip()
    except OSError:
        return ""
    if not raw.isdigit():
        return ""
    speed = int(raw)
    if speed <= 0:
        return ""
    label = f"{speed} Mb/s"
    try:
        duplex = open(os.path.join(base, "duplex"), encoding="utf-8").read().strip()
    except OSError:
        duplex = ""
    if duplex in ("full", "half"):
        label += " " + duplex
    return label


def connection_facts(name):
    if not name or name == "--" or "\n" in name or "\r" in name:
        return {}
    code, out, _err = run_cmd(["nmcli", "-t", "connection", "show", name], 8)
    if code != 0:
        return {}
    found = {}
    for line in out.splitlines():
        if ":" not in line:
            continue
        key, value = line.split(":", 1)
        value = value.replace("\\:", ":").strip()
        if value == "--":
            value = ""
        found[key] = value
    return {
        "method": method_label(found.get("ipv4.method", "")),
        "ssid": found.get("802-11-wireless.ssid", ""),
        "band": band_label(found.get("802-11-wireless.band", "")),
        "channel": found.get("802-11-wireless.channel", ""),
        "security": security_label(found.get("802-11-wireless-security.key-mgmt", "")),
    }


def parse_devices(text):
    devices = []
    current = {}

    def flush():
        iface = str(current.get("iface") or "")
        if not iface or iface == "lo" or current.get("type") == "loopback":
            return
        state = short_state(current.get("state", ""))
        carrier = str(current.get("carrier") or "")
        if current.get("type") == "ethernet" and carrier == "off" and "connected" not in state:
            state = "Cable unplugged"
        dns = current.get("dns") or []
        row = {
            "iface": iface,
            "type": str(current.get("type") or ""),
            "state": state,
            "connection": str(current.get("connection") or ""),
            "ipv4": str(current.get("ipv4") or ""),
            "ipv6": str(current.get("ipv6") or ""),
            "gateway": str(current.get("gateway") or ""),
            "dns": ", ".join(dns),
            "mac": str(current.get("mac") or ""),
            "mtu": str(current.get("mtu") or ""),
            "speed": link_speed(iface),
            "method": "",
            "ssid": "",
            "band": "",
            "channel": "",
            "security": "",
        }
        if "connected" in state and row["connection"]:
            extra = connection_facts(row["connection"])
            row.update(extra)
        devices.append(row)

    for raw in text.splitlines():
        line = raw.strip()
        if not line:
            if current:
                flush()
                current = {}
            continue
        if ":" not in line:
            continue
        key, value = line.split(":", 1)
        value = value.replace("\\:", ":").strip()
        if key == "GENERAL.DEVICE":
            current["iface"] = value
        elif key == "GENERAL.TYPE":
            current["type"] = value
        elif key == "GENERAL.STATE":
            current["state"] = value
        elif key == "GENERAL.CONNECTION":
            current["connection"] = "" if value == "--" else value
        elif key == "GENERAL.HWADDR":
            current["mac"] = "" if value == "--" else value
        elif key == "GENERAL.MTU":
            current["mtu"] = value
        elif key == "WIRED-PROPERTIES.CARRIER":
            current["carrier"] = value
        elif key.startswith("IP4.ADDRESS"):
            current.setdefault("ipv4", value.split("/")[0])
        elif key == "IP4.GATEWAY":
            current["gateway"] = "" if value == "--" else value
        elif key.startswith("IP4.DNS") and value and value != "--":
            current.setdefault("dns", []).append(value)
        elif key.startswith("IP6.ADDRESS"):
            addr = value.split("/")[0]
            if not addr or addr == "--":
                continue
            if addr.lower().startswith("fe80"):
                current.setdefault("ipv6", addr)
            else:
                current["ipv6"] = addr
    if current:
        flush()
    return devices


def radio_flags():
    code, out, err = run_cmd(["nmcli", "-t", "-f", "WIFI,WWAN", "radio"], 8)
    if code != 0:
        fail(safe_error(err or out, ""))
    line = ""
    for raw in out.splitlines():
        if raw.strip():
            line = raw.strip()
            break
    parts = split_nmcli(line) if line else []
    wifi = bool(parts) and parts[0] == "enabled"
    wwan = len(parts) > 1 and parts[1] == "enabled"
    return wifi, wwan


def vpn_rows():
    code, out, err = run_cmd(
        ["nmcli", "-t", "-f", "NAME,UUID,TYPE,DEVICE", "connection", "show"],
        8,
    )
    if code != 0:
        fail(safe_error(err or out, ""))
    rows = []
    for raw in out.splitlines():
        line = raw.strip()
        if not line:
            continue
        parts = split_nmcli(line)
        if len(parts) < 4:
            continue
        name, uuid, kind, device = parts[0], parts[1], parts[2], parts[3]
        if kind.lower() not in VPN_TYPES:
            continue
        if not UUID_OK.match(uuid):
            continue
        active = device not in ("", "--")
        rows.append({
            "name": name,
            "uuid": uuid,
            "type": kind.lower(),
            "active": active,
        })
    return rows


def status():
    need_nmcli()
    code, out, err = run_cmd(["nmcli", "-t", "device", "show"], 8)
    if code != 0:
        fail(safe_error(err or out, ""))
    wifi, wwan = radio_flags()
    emit({
        "ok": True,
        "wifiRadio": wifi,
        "wwanRadio": wwan,
        "devices": parse_devices(out),
        "vpns": vpn_rows(),
    })


def radio(mode):
    if mode not in ("on", "off"):
        fail("radio must be on or off")
    need_nmcli()
    code, out, err = run_cmd(["nmcli", "radio", "all", mode], 15)
    if code != 0:
        fail(safe_error(err or out, ""))
    emit({"ok": True, "message": "Airplane off" if mode == "on" else "Airplane on"})


def devices(action, ifaces):
    if action not in ("connect", "disconnect"):
        fail("unknown device action")
    if not ifaces:
        fail("missing interface")
    need_nmcli()
    errors = []
    for iface in ifaces:
        check_iface(iface)
        code, out, err = run_cmd(["nmcli", "device", action, iface], 20)
        if code != 0:
            errors.append(safe_error(err or out, ""))
    if errors:
        fail("; ".join(errors))
    emit({"ok": True})


def vpn(action, uuids):
    if action not in ("up", "down"):
        fail("unknown VPN action")
    if not uuids:
        fail("missing VPN id")
    need_nmcli()
    errors = []
    for uuid in uuids:
        check_uuid(uuid)
        code, out, err = run_cmd(["nmcli", "connection", action, "uuid", uuid], 25)
        if code != 0:
            errors.append(safe_error(err or out, ""))
    if errors:
        fail("; ".join(errors))
    emit({"ok": True})


def reapply(iface):
    check_iface(iface)
    need_nmcli()
    code, out, err = run_cmd(["nmcli", "device", "reapply", iface], 20)
    if code != 0:
        fail(safe_error(err or out, ""))
    emit({"ok": True, "message": "Refreshing IP"})


def flush_dns():
    tool = shutil.which("resolvectl")
    args = ["resolvectl", "flush-caches"]
    if tool is None:
        tool = shutil.which("systemd-resolve")
        args = ["systemd-resolve", "--flush-caches"]
    if tool is None:
        fail("resolvectl is not installed")
    code, out, err = run_cmd(args, 10)
    if code != 0:
        fail(safe_error(err or out, ""))
    emit({"ok": True, "message": "Flushed DNS"})


def editor():
    binary = shutil.which("nm-connection-editor")
    if binary is None:
        fail("nm-connection-editor is not installed")
    try:
        subprocess.Popen(
            [binary],
            stdin=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
        )
    except OSError as exc:
        fail(safe_error(str(exc), ""))
    emit({"ok": True, "message": "Opened connection editor"})


def hidden(iface, ssid, psk):
    check_iface(iface)
    check_ssid(ssid)
    secret = ""
    if psk:
        check_psk(psk)
        secret = psk
    need_nmcli()
    command = ["nmcli", "-w", "25", "device", "wifi", "connect", ssid]
    if secret:
        command.extend(["password", secret])
    command.extend(["hidden", "yes", "ifname", iface])
    code, out, err = run_cmd(command, 30, secret)
    if code != 0:
        fail(safe_error(err or out, secret))
    emit({"ok": True, "message": "Connecting"})


def main(argv):
    if len(argv) < 2:
        fail("missing command")
    command = argv[1]
    if command == "status":
        status()
    elif command == "radio" and len(argv) == 3:
        radio(argv[2])
    elif command == "device" and len(argv) >= 4:
        devices(argv[2], argv[3:])
    elif command == "vpn" and len(argv) >= 4:
        vpn(argv[2], argv[3:])
    elif command == "reapply" and len(argv) == 3:
        reapply(argv[2])
    elif command == "flush-dns" and len(argv) == 2:
        flush_dns()
    elif command == "editor" and len(argv) == 2:
        editor()
    elif command == "hidden" and len(argv) in (4, 5):
        hidden(argv[2], argv[3], argv[4] if len(argv) == 5 else "")
    else:
        fail("unknown command")


if __name__ == "__main__":
    main(sys.argv)
