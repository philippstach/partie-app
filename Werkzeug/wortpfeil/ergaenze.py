#!/usr/bin/env python3
"""Hängt an ein Paket weitere Rätsel an und bevorzugt dabei Wörter, die in noch keinem Rätsel vorkommen.
So landet ein möglichst großer Teil des Wortbestands tatsächlich im Spiel. Vorhandene Rätsel bleiben unverändert.

Aufruf im Ordner Werkzeug/wortpfeil:  python3 ergaenze.py <paket> <zielzahl>     z. B.  python3 ergaenze.py leicht 300
Danach wie immer: nachbearbeitung.py, eindeutig.py, pruefe_pakete.py.
Gleiche Wortliste + gleiche Pakete = gleiches Ergebnis (feste Seeds, Übernahme in Seed-Reihenfolge)."""
import json, multiprocessing, os, sys
from generator import MAX_WORTSTUFE, erzeuge, lade_wortliste
from kreuzwort import Raetsel, pruefe
from nachbearbeitung import PAKETE

HIER = os.path.dirname(os.path.abspath(__file__))
PROZESSE = int(os.environ.get("WORTPFEIL_PROZESSE", "5"))
# Paket → (Stufe, ID-Präfix, Seed-Basis)
ART = {"leicht": ("leicht", "L", 210_000), "mittel": ("mittel", "M", 220_000), "schwer": ("schwer", "S", 230_000),
       "taeglich": ("mittel", "T", 240_000)}
# Leicht: mehr lange Lücken als im Grundpaket (das kleine Gitter verträgt es). Mittel und Schwer: Grundmischung,
# längere Lücken lassen sich dort kaum noch füllen. ZUERST = wie viele lange Lücken vorab mit ungenutzten Wörtern belegt werden.
LAENGEN = {"leicht": (7, {3: 3, 4: 3, 5: 3, 6: 3, 7: 2}), "mittel": None, "schwer": None}
ZUERST = {"leicht": 8, "mittel": 3, "schwer": 4}
_W = _STUFE = _BEV = None


def _ein_seed(seed):
    return erzeuge(_W, _STUFE, seed, "x", versuche=1, dicht=True, rueckfall=False, bevorzugt=_BEV,
                   laengen=LAENGEN[_STUFE], zuerst_max=ZUERST[_STUFE])


def main(name, ziel):
    global _W, _STUFE, _BEV
    stufe, praefix, seed = ART[name]
    _W, _STUFE = lade_wortliste(os.path.join(HIER, "inhalt", "woerter.tsv")), stufe
    benutzt, gitter = set(), set()
    for n in ("leicht", "mittel", "schwer", "taeglich", "themen"):
        for rj in json.load(open(os.path.join(PAKETE, n + ".json"), encoding="utf-8"))["raetsel"]:
            r = Raetsel.aus_json(rj)
            gitter.add("".join(r.gitter))
            benutzt.update(r.loesungswort(f) for f in r.fragen)
    pfad = os.path.join(PAKETE, name + ".json")
    paket = json.load(open(pfad, encoding="utf-8"))
    start = len(paket["raetsel"])
    while len(paket["raetsel"]) < ziel:
        # Wörter der passenden Stufe, die noch nirgends vorkommen
        _BEV = {w for w, e in _W.items() if e.stufe <= MAX_WORTSTUFE[stufe] and 3 <= len(w) <= 8 and w not in benutzt}
        with multiprocessing.get_context("fork").Pool(PROZESSE) as pool:
            ergebnisse = pool.map(_ein_seed, range(seed, seed + PROZESSE), chunksize=1)
        seed += PROZESSE
        for r in ergebnisse:
            if r is None or "".join(r.gitter) in gitter or len(paket["raetsel"]) >= ziel:
                continue
            r.id = f"{praefix}-{len(paket['raetsel']) + 1:04d}"
            assert pruefe(r, _W) == [], (r.id, pruefe(r, _W))
            gitter.add("".join(r.gitter))
            benutzt.update(r.loesungswort(f) for f in r.fragen)
            paket["raetsel"].append(r.als_json())
        print(f"  {name}: {len(paket['raetsel'])}/{ziel} · noch ungenutzte Wörter dieser Stufe: {len(_BEV)}", flush=True)
    with open(pfad, "w", encoding="utf-8") as d:
        json.dump(paket, d, ensure_ascii=False, separators=(",", ":"))
        d.write("\n")
    print(f"{name}: {start} → {len(paket['raetsel'])} Rätsel (Seeds bis {seed - 1})")


if __name__ == "__main__":
    main(sys.argv[1], int(sys.argv[2]))
