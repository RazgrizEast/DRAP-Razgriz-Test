"""Derive source/data/drdr_doors.json from the apworld's EMBEDDED_DOOR_DATA.

The runtime has no door table of its own. Anchors reach it only through
slot_data.door_anchors, which is empty in a vanilla run -- so the debug warp
picker, which is meant to work with no slot connected, had nothing to list.

This ships the same records as a data file. The apworld copy stays
authoritative; test_door_warp_table.py fails if the two drift.

Deliberately parsed with ast rather than imported: importing the apworld pulls
in Archipelago's BaseClasses, which is not available from a plain checkout.

Usage: py -3.12 build_door_table.py
"""
import ast
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
SRC = os.path.join(REPO, "apworld", "drdr", "DoorRandomization.py")
OUT = os.path.join(REPO, "source", "data", "drdr_doors.json")


def load_embedded():
    tree = ast.parse(open(SRC, encoding="utf-8").read())
    for node in tree.body:
        if isinstance(node, ast.Assign) and \
                getattr(node.targets[0], "id", "") == "EMBEDDED_DOOR_DATA":
            return ast.literal_eval(node.value)
    raise SystemExit("EMBEDDED_DOOR_DATA not found in %s" % SRC)


def build(embedded):
    rows = []
    for door_id, d in embedded.items():
        pos, ang = d.get("position") or {}, d.get("angle") or {}
        rows.append({
            "id": door_id,
            "from": d["from_area_code"],
            "to": d["to_area_code"],
            "door_no": d.get("door_no", 0),
            "position": {k: round(float(pos.get(k, 0.0)), 3) for k in "xyz"},
            "angle": {k: round(float(ang.get(k, 0.0)), 3) for k in "xyz"},
        })
    # Stable order so a rebuild is a no-op unless the data actually changed.
    rows.sort(key=lambda r: (r["from"], r["to"], r["door_no"]))
    return rows


def main() -> int:
    rows = build(load_embedded())
    payload = {"schema_version": 1, "doors": rows}
    text = json.dumps(payload, indent=2, ensure_ascii=False) + "\n"
    with open(OUT, "w", encoding="utf-8", newline="\r\n") as f:
        f.write(text)
    froms = sorted({r["from"] for r in rows})
    print("  %d door(s) across %d area(s) -> %s"
          % (len(rows), len(froms), os.path.relpath(OUT, REPO)))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
