#!/usr/bin/env python3
"""Abschlusskontrolle der Rätselpakete: Regeln (pruefe), Wörter und Fragen stammen aus dem Bestand, keine doppelten
Gitter, keine gleichwertigen Fragen im selben Rätsel, Anteil der Fragen, die ins Fragefeld passen.
Aufruf im Ordner Werkzeug/wortpfeil:  python3 pruefe_pakete.py     (Rückgabewert 1 bei Fehlern)"""
import collections, json, os, sys
from eindeutig import marken
from generator import lade_wortliste
from kreuzwort import Raetsel, pruefe
from nachbearbeitung import PAKETE, _felder, messe

HIER = os.path.dirname(os.path.abspath(__file__))
w = lade_wortliste(os.path.join(HIER, "inhalt", "woerter.tsv"))
fehler, gitter, woerter, texte, anfragen, felder = [], {}, collections.Counter(), set(), set(), []
doppelfragen = 0
for name in ("leicht", "mittel", "schwer", "taeglich", "themen"):
    paket = json.load(open(os.path.join(PAKETE, name + ".json"), encoding="utf-8"))
    ids = set()
    for rj in paket["raetsel"]:
        r = Raetsel.aus_json(rj)
        if r.id in ids:
            fehler.append(f"{name}: ID doppelt {r.id}")
        ids.add(r.id)
        for f in pruefe(r, w):
            fehler.append(f"{r.id}: {f}")
        k = "".join(r.gitter)
        if k in gitter:
            fehler.append(f"{r.id}: gleiches Gitter wie {gitter[k]}")
        gitter[k] = r.id
        if not r.loesung:
            fehler.append(f"{r.id}: kein Lösungswort")
        belegt = set()
        for f, geteilt, pt in _felder(r):
            wort = r.loesungswort(f)
            woerter[wort] += 1
            if wort not in w:
                fehler.append(f"{r.id}: {wort} nicht im Bestand")
                continue
            for t in (f.text, f.kurz):
                if t and t not in w[wort].fragen:
                    fehler.append(f"{r.id}: Frage „{t}“ gehört nicht zu {wort}")
            texte.add((wort, f.text))
            if marken(f.text) & belegt:
                doppelfragen += 1
            belegt |= marken(f.text)
            anfragen.add((f.kurz or f.text, pt, geteilt, f.richtung))
            felder.append((f.kurz or f.text, pt, geteilt, f.richtung))
    print(f"{name}: {len(paket['raetsel'])} Rätsel")
gemessen = messe(anfragen)
passt_nicht = sum(not gemessen[a] for a in felder)
nutzbar = sum(1 for x in w if len(x) <= 8)
print(f"Rätsel gesamt {len(gitter)} · verschiedene Wörter {len(woerter)} von {nutzbar} nutzbaren im Bestand ({len(w)} gesamt) · "
      f"verschiedene Fragetexte {len(texte)}")
print(f"Fragen gesamt {len(felder)} · passen nicht ins Feld {passt_nicht} ({100 * passt_nicht / max(1, len(felder)):.1f} %) · "
      f"gleichwertige Fragen im selben Rätsel {doppelfragen}")
print("häufigste Wörter:", ", ".join(f"{x} {n}" for x, n in woerter.most_common(12)))
for f in fehler[:40]:
    print("FEHLER:", f)
print(f"{len(fehler)} Fehler")
sys.exit(1 if fehler else 0)
