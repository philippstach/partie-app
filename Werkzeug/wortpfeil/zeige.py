"""Zeigt ein Rätsel aus einem Paket als Text.  python3 Referenz/zeige.py [paket] [nummer]"""
import json
import os
import sys

HIER = os.path.dirname(os.path.abspath(__file__))
paket = sys.argv[1] if len(sys.argv) > 1 else "mittel"
nr = int(sys.argv[2]) if len(sys.argv) > 2 else 1
with open(os.path.join(HIER, "..", "Shared", "raetsel", f"{paket}.json"), encoding="utf-8") as d:
    r = json.load(d)["raetsel"][nr - 1]
print(f"{r['id']} · {r['stufe']} · {r['breite']}×{r['hoehe']}\n")
for zeile in r["gitter"]:
    print("  " + " ".join({"#": "▪", "-": "·"}.get(f, f) for f in zeile))
print("\n▪ = Fragefeld   · = Leerfeld\n")
for f in r["fragen"]:
    pfeil = "→" if f["richtung"] == "rechts" else "↓"
    print(f"  Zeile {f['zeile'] + 1:>2}, Spalte {f['spalte'] + 1:>2} {pfeil}  {f['text']}")
