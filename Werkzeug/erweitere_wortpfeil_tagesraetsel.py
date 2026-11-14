#!/usr/bin/env python3
"""Erweitert das Wortpfeil-Tagespaket (Pakete/SpielWortpfeil/Shared/raetsel/taeglich.json) auf ZIEL Rätsel,
ohne die vorhandenen anzutasten. Index = Tage seit 01.01.2026, also reichen 1100 Rätsel bis Anfang 2029.
Nutzt den Rätsel-Erzeuger aus Werkzeug/wortpfeil; neue Rätsel haben Seeds ab 100000, doppelte Gitter
(auch aus den anderen Paketen) werden übersprungen.  Aufruf:  python3 Werkzeug/erweitere_wortpfeil_tagesraetsel.py [ZIEL]"""
import json, os, sys
HIER = os.path.dirname(os.path.abspath(__file__))
REF = os.path.join(HIER, "wortpfeil")
sys.path.insert(0, REF)
from generator import erzeuge, lade_wortliste  # noqa: E402
from kreuzwort import pruefe  # noqa: E402

ZIEL = int(sys.argv[1]) if len(sys.argv) > 1 else 1100
PAKETE = os.path.join(HIER, "..", "Pakete", "SpielWortpfeil", "Shared", "raetsel")
pfad = os.path.join(PAKETE, "taeglich.json")
inhalt = json.load(open(pfad, encoding="utf-8"))
woerter = lade_wortliste(os.path.join(REF, "inhalt", "woerter.tsv"))

benutzt = set()
for n in ("leicht", "mittel", "schwer", "taeglich", "themen"):
    for r in json.load(open(os.path.join(PAKETE, n + ".json"), encoding="utf-8"))["raetsel"]:
        benutzt.add("".join(r["gitter"]))

neu, seed = [], 100_000
vorhanden = len(inhalt["raetsel"])
while vorhanden + len(neu) < ZIEL:
    r = erzeuge(woerter, "mittel", seed, f"T-{vorhanden + len(neu) + 1:04d}", versuche=12, dicht=True, rueckfall=False)
    seed += 1
    if r is None:
        continue
    k = "".join(r.gitter)
    if k in benutzt:
        continue
    assert pruefe(r, woerter) == [], (r.id, pruefe(r, woerter))
    benutzt.add(k)
    neu.append(r.als_json())
inhalt["raetsel"] += neu
with open(pfad, "w", encoding="utf-8") as f:
    json.dump(inhalt, f, ensure_ascii=False, separators=(",", ":")); f.write("\n")
print(f"{vorhanden} + {len(neu)} = {len(inhalt['raetsel'])} Tagesrätsel (Seeds 100000–{seed - 1})")
