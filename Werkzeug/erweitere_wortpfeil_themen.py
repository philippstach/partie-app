#!/usr/bin/env python3
"""Erweitert das Wortpfeil-Themenpaket (Pakete/SpielWortpfeil/Shared/raetsel/themen.json) auf JE_THEMA Rätsel pro Thema,
ohne die vorhandenen anzutasten. Nutzt Erzeuger und Themenwörter aus Werkzeug/wortpfeil (gleiche Regeln wie
paket.py --themen: mindestens 3 lange Themenwörter). Doppelte Gitter (auch aus anderen Paketen) werden übersprungen.
Aufruf:  python3 Werkzeug/erweitere_wortpfeil_themen.py [JE_THEMA]"""
import json, os, sys
HIER = os.path.dirname(os.path.abspath(__file__))
REF = os.path.join(HIER, "wortpfeil")
sys.path.insert(0, REF)
from generator import erzeuge, lade_wortliste  # noqa: E402
from kreuzwort import pruefe  # noqa: E402
from themen import themenwoerter  # noqa: E402

JE = int(sys.argv[1]) if len(sys.argv) > 1 else 30
PAKETE = os.path.join(HIER, "..", "Pakete", "SpielWortpfeil", "Shared", "raetsel")
pfad = os.path.join(PAKETE, "themen.json")
inhalt = json.load(open(pfad, encoding="utf-8"))
woerter = lade_wortliste(os.path.join(REF, "inhalt", "woerter.tsv"))
benutzt = set()
for n in ("leicht", "mittel", "schwer", "taeglich", "themen"):
    for r in json.load(open(os.path.join(PAKETE, n + ".json"), encoding="utf-8"))["raetsel"]:
        benutzt.add("".join(r["gitter"]))

neu = []
for nr, t in enumerate(inhalt["themen"]):
    tid = t["id"]
    th = themenwoerter(tid, woerter)
    vorhanden = sum(1 for r in inhalt["raetsel"] if r.get("thema") == tid)
    gefunden = vorhanden
    seed = 80_000 + nr * 10_000
    while gefunden < JE:
        r = erzeuge(woerter, "mittel", seed, f"TH-{tid}-{gefunden + 1:02d}", versuche=1, dicht=True, rueckfall=False, bevorzugt=th)
        seed += 1
        if r is None:
            continue
        lang = [r.loesungswort(f) for f in r.fragen if len(r.loesungswort(f)) >= 5]
        if sum(w in th for w in lang) < 3:
            continue
        k = "".join(r.gitter)
        if k in benutzt:
            continue
        assert pruefe(r, woerter) == [], (r.id, pruefe(r, woerter))
        benutzt.add(k)
        r.thema = tid
        neu.append(r.als_json())
        gefunden += 1
    print(f"{tid}: {vorhanden} -> {gefunden}", flush=True)
inhalt["raetsel"] += neu
with open(pfad, "w", encoding="utf-8") as f:
    json.dump(inhalt, f, ensure_ascii=False, separators=(",", ":")); f.write("\n")
print(f"themen: {len(inhalt['raetsel'])} Rätsel")
