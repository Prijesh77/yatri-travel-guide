#!/usr/bin/env python3
"""Builds assets/data/routes.json from the transport data pack.

Inputs (in data_sources/):
  Yatri_Transport_Data.xlsx  - the data pack (Bus_Routes, Hubs, Fares,
                               Taxi_RideHailing sheets)
  stop_coordinates.csv       - lat/lng for stop names (the sheet has none)

Usage:
  python3 tool/import_transport.py [--xlsx PATH] [--coords PATH] [--out PATH]

Only the Python standard library is used, so it runs anywhere Python 3.8+
is installed. Stops without coordinates are dropped from their route (and
reported); routes left with fewer than two located stops are skipped.
"""

import argparse
import csv
import datetime
import json
import re
import sys
import unicodedata
import xml.etree.ElementTree as ET
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
NS = {"m": "http://schemas.openxmlformats.org/spreadsheetml/2006/main"}
REL_NS = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"

# Different spellings of the same place in the source data.
ALIASES = {
    "Kaushaltar": "Kausaltar",
    "Madhyapur Thimi": "Thimi",
    "Nala Bus Station (Chyamasingh)": "Chyamasingh",
}

# Hub name in the Hubs sheet -> stop name it sits at.
HUB_STOPS = {
    "Ratnapark": "Ratnapark",
    "Bhaktapur Bus Park (Bagbazar)": "Bagbazar Stop",
    "Purano (Old) Bus Park": "Purano Bus Park",
    "New Bus Park, Gongabu": "Gongabu Bus Park",
    "Lagankhel Bus Park": "Lagankhel",
    "Kamalbinayak": "Kamalbinayak",
    "Chyamasingh Bus Station": "Chyamasingh",
    "Nala Bus Station (Chyamasingh)": "Chyamasingh",
    "Changu Narayan Bus Station (Dekocha)": "Changu Narayan Bus Station (Dekocha)",
    "Suryabinayak Bus Stop": "Suryabinayak",
    "Kalanki": "Kalanki",
}

STATUS_MAP = [
    ("verified", "verified"),
    ("announced", "announced"),
    ("reported", "reported"),
    ("historical", "historical"),
    ("osm", "osm"),
    ("local site", "local"),
]

# Kathmandu Valley bounding box (matches ValleyBounds in lib/core/geo).
VALLEY = (27.52, 27.82, 85.15, 85.58)


def read_xlsx(path):
    """Returns {sheet_name: [[cell, ...], ...]} with cells as strings."""
    z = zipfile.ZipFile(path)
    shared = []
    if "xl/sharedStrings.xml" in z.namelist():
        for si in ET.fromstring(z.read("xl/sharedStrings.xml")).findall("m:si", NS):
            shared.append("".join(t.text or "" for t in si.iter("{%s}t" % NS["m"])))
    workbook = ET.fromstring(z.read("xl/workbook.xml"))
    rels = ET.fromstring(z.read("xl/_rels/workbook.xml.rels"))
    targets = {r.get("Id"): r.get("Target") for r in rels}
    sheets = {}
    for sheet in workbook.find("m:sheets", NS):
        target = targets[sheet.get("{%s}id" % REL_NS)]
        target = target if target.startswith("xl/") else "xl/" + target.lstrip("/")
        rows = []
        for row in ET.fromstring(z.read(target)).iter("{%s}row" % NS["m"]):
            cells = {}
            for c in row.findall("m:c", NS):
                col = re.match(r"[A-Z]+", c.get("r")).group(0)
                v, inline = c.find("m:v", NS), c.find("m:is", NS)
                if c.get("t") == "s" and v is not None:
                    value = shared[int(v.text)]
                elif inline is not None:
                    value = "".join(t.text or "" for t in inline.iter("{%s}t" % NS["m"]))
                else:
                    value = v.text if v is not None else ""
                cells[_col_index(col)] = (value or "").strip()
            width = max(cells) + 1 if cells else 0
            rows.append([cells.get(i, "") for i in range(width)])
        sheets[sheet.get("name")] = rows
    return sheets


def _col_index(col):
    n = 0
    for ch in col:
        n = n * 26 + ord(ch) - 64
    return n - 1


def table(rows):
    """First row is the header; returns a list of dicts."""
    header = rows[0]
    return [
        {header[i]: (r[i] if i < len(r) else "") for i in range(len(header))}
        for r in rows[1:]
        if any(r)
    ]


def slug(name):
    s = unicodedata.normalize("NFKD", name).encode("ascii", "ignore").decode()
    s = re.sub(r"[^a-zA-Z0-9]+", "-", s).strip("-").lower()
    return s


def canonical(name):
    name = name.strip()
    return ALIASES.get(name, name)


def parse_status(raw):
    low = raw.lower()
    for needle, status in STATUS_MAP:
        if needle in low:
            return status
    return "unverified"


def parse_hours(raw):
    """'20:00–23:00, every 20 min' -> ({start,end}|None, 20|None)."""
    freq = None
    m = re.search(r"every\s+(\d+)\s*min", raw)
    if m:
        freq = int(m.group(1))
    window = None
    m = re.search(r"(last\D{0,15})?(\d{1,2}:\d{2})\s*[–-]\s*(\d{1,2}:\d{2})", raw, re.I)
    if m and m.group(1):
        # "last return ~18:45-20:00": be conservative, stop at the earlier time.
        window = {"start": "06:00", "end": _hhmm(m.group(2))}
    elif m:
        window = {"start": _hhmm(m.group(2)), "end": _hhmm(m.group(3))}
    else:
        first = re.search(r"first\s*~?(\d{1,2}:\d{2})", raw, re.I)
        last = re.search(r"last(?:\s+departure)?\s*~?(\d{1,2}:\d{2})", raw, re.I)
        if first or last:
            window = {
                "start": _hhmm(first.group(1)) if first else "06:00",
                "end": _hhmm(last.group(1)) if last else "20:00",
            }
    return window, freq


def _hhmm(value):
    h, m = value.split(":")
    return "%02d:%02d" % (int(h), int(m))


def load_coords(path):
    coords = {}
    with open(path, newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            name = canonical(row["stop_name"])
            lat, lng = float(row["lat"]), float(row["lng"])
            if not (VALLEY[0] <= lat <= VALLEY[1] and VALLEY[2] <= lng <= VALLEY[3]):
                sys.exit("%s is outside the valley: %s, %s" % (name, lat, lng))
            coords[name] = {
                "lat": lat,
                "lng": lng,
                "accuracy": row.get("accuracy") or "approx",
            }
    return coords


def parse_fares(rows):
    slabs, taxi = [], {}
    for r in rows:
        if len(r) < 2:
            continue
        label, value = r[0], r[1]
        if re.fullmatch(r"\d+(\.\d+)?", label) and re.fullmatch(r"\d+(\.\d+)?", value):
            slabs.append({"upToKm": float(label), "fare": int(float(value))})
        elif label.startswith("20+") and re.fullmatch(r"\d+", value):
            slabs.append({"upToKm": 999, "fare": int(value)})
        elif label.lower().startswith("flag-down"):
            taxi["flagDown"] = float(value)
        elif label.lower().startswith("per 200 m"):
            taxi["per200m"] = float(value)
    if not slabs or "flagDown" not in taxi or "per200m" not in taxi:
        sys.exit("Could not read fare slabs / taxi meter from the Fares sheet")
    return slabs, taxi


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--xlsx", default=ROOT / "data_sources/Yatri_Transport_Data.xlsx")
    ap.add_argument("--coords", default=ROOT / "data_sources/stop_coordinates.csv")
    ap.add_argument("--out", default=ROOT / "assets/data/routes.json")
    ap.add_argument("--version", type=int, help="dataset version (default: previous + 1)")
    args = ap.parse_args()

    sheets = read_xlsx(args.xlsx)
    coords = load_coords(args.coords)
    slabs, meter = parse_fares(sheets["Fares"])

    stops, routes, warnings = {}, [], []

    def stop_id(name):
        info = coords[name]
        sid = slug(name)
        stops.setdefault(sid, {"id": sid, "name": name, "lat": info["lat"],
                               "lng": info["lng"], "accuracy": info["accuracy"]})
        return sid

    for r in table(sheets["Bus_Routes"]):
        names = [canonical(s) for s in r["stops_in_order"].split("→") if s.strip()]
        kept, skipped = [], []
        for n in names:
            (kept if n in coords else skipped).append(n)
        if skipped:
            warnings.append("%s: no coordinates for %s" % (r["route_id"], ", ".join(skipped)))
        if len(kept) < 2:
            warnings.append("%s: skipped (fewer than 2 located stops)" % r["route_id"])
            continue
        window, freq = parse_hours(r.get("hours_frequency", ""))
        route = {
            "id": r["route_id"],
            "name": r["route_name"],
            "operator": r["operator"],
            "vehicle": r["vehicle"],
            "status": parse_status(r["data_status"]),
            "statusLabel": r["data_status"],
            "completeness": r["stop_list_completeness"],
            "stops": [stop_id(n) for n in kept],
            "source": r["source"],
            "notes": r["notes"],
        }
        if skipped:
            route["missingStops"] = skipped
        if freq:
            route["frequencyMinutes"] = freq
        if window:
            route["serviceHours"] = window
        routes.append(route)

    hubs = []
    for h in table(sheets["Hubs"]):
        hub = {"name": h["hub"], "district": h["district"], "notes": h["what departs / notes"]}
        stop_name = HUB_STOPS.get(h["hub"])
        if stop_name in coords:
            hub["stopId"] = stop_id(stop_name)
        else:
            warnings.append("hub %s: no matching stop" % h["hub"])
        hubs.append(hub)

    operators = []
    for o in table(sheets["Taxi_RideHailing"]):
        if o["operator"].lower().startswith("regulation"):
            continue
        operators.append({
            "name": o["operator"],
            "modes": o["modes"],
            "pricing": o["pricing model"],
            "fareInfo": o["fare / commission info"],
            "status": o["status"],
        })

    out_path = Path(args.out)
    previous = 0
    if out_path.exists():
        try:
            previous = json.loads(out_path.read_text(encoding="utf-8")).get("version", 0)
        except ValueError:
            pass
    compiled = sheets["README"][0][0] if sheets.get("README") else ""

    data = {
        "version": args.version or previous + 1,
        "updated": datetime.date.today().isoformat(),
        "currency": "NPR",
        "source": compiled,
        "disclaimer": "Bus fares are the official Kathmandu Valley slabs effective 11 Apr 2026. "
                      "Only Sajha Yatayat 2026 routes are verified; other routes and all stop "
                      "positions are approximate - check locally.",
        "network": {
            "roadDistanceFactor": 1.35,
            "routeDistanceFactor": 1.15,
            "maxWalkToStopKm": 1.5,
            "transferWalkKm": 0.4,
            "rushHours": [{"start": "08:00", "end": "10:30"}, {"start": "17:00", "end": "19:00"}],
            "rushHourSpeedFactor": 0.7,
        },
        "modes": {
            "walk": {"speedKmh": 4.5, "maxKm": 3.0},
            "bikeTaxi": {
                "label": "Bike taxi (Pathao, inDrive, Yango, Uber, Tootle)",
                "speedKmh": 22, "pickupMinutes": 6,
                "baseFare": 40, "perKm": 22, "minFare": 70, "fareSpread": 0.2,
            },
            "taxi": {
                "label": "Metered taxi",
                "speedKmh": 18, "pickupMinutes": 5,
                "baseFare": meter["flagDown"],
                "perKm": meter["per200m"] * 5,
                "minFare": meter["flagDown"],
                "fareSpreadLow": 0.0, "fareSpreadHigh": 0.3,
                "night": {"start": "21:00", "end": "06:00", "multiplier": 1.3},
            },
            "bus": {
                "label": "Local bus",
                "speedKmh": 14, "waitMinutes": 10,
                "serviceHours": {"start": "06:00", "end": "20:00"},
                "fareSlabs": sorted(slabs, key=lambda s: s["upToKm"]),
            },
        },
        "operators": operators,
        "hubs": hubs,
        "stops": sorted(stops.values(), key=lambda s: s["name"]),
        "routes": routes,
    }
    out_path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("Wrote %s: %d routes, %d stops (version %d)" % (out_path, len(routes), len(stops), data["version"]))
    for w in warnings:
        print("  note:", w)


if __name__ == "__main__":
    main()
