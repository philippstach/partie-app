"""Lösungswort: markierte Felder im fertigen Gitter ergeben – der Reihe nach gelesen – ein Wort.

Wird nachträglich in die Pakete eingetragen (das Gitter bleibt unverändert):
  python3 loesungswort.py            alle Pakete in Shared/raetsel/ (Demo → testwoerter.tsv, sonst inhalt/woerter.tsv)
Zufall pro Rätsel aus crc32(id) → reproduzierbar.
"""
from __future__ import annotations

import json
import os
import random
import zlib

from generator import MAX_WORTSTUFE, Eintrag, lade_wortliste
from kreuzwort import Raetsel, pruefe

HIER = os.path.dirname(os.path.abspath(__file__))
PAKETE = os.path.join(HIER, "..", "Shared", "raetsel")
LAENGEN = {"leicht": (4, 6), "mittel": (5, 7), "schwer": (6, 9)}


def waehle(r: Raetsel, eintraege: dict[str, Eintrag], rng: random.Random,
          bevorzugt: set[str] | None = None) -> list[tuple[int, int]]:
    """Felder für ein Lösungswort, oder [] wenn keins passt.

    Regeln: Wort aus dem Bestand (Stufe ≤ Rätselstufe), nicht schon als Wort im Gitter, Länge je Stufe;
    jedes Feld höchstens einmal; Felder möglichst über das Gitter verteilt (größter Abstand zum Vorgänger).
    """
    im_gitter = {r.loesungswort(f) for f in r.fragen}
    nach_buchstabe: dict[str, list[tuple[int, int]]] = {}
    for z, s in r.buchstabenfelder():
        nach_buchstabe.setdefault(r.gitter[z][s], []).append((z, s))
    lo, hi = LAENGEN[r.stufe]
    kandidaten = sorted(
        w for w, e in eintraege.items()
        if lo <= len(w) <= hi and e.stufe <= MAX_WORTSTUFE[r.stufe] and w not in im_gitter
    )
    rng.shuffle(kandidaten)
    if bevorzugt:  # Themen-Rätsel: Lösungswort möglichst aus dem Thema
        kandidaten.sort(key=lambda w: w not in bevorzugt)
    for wort in kandidaten:
        bedarf: dict[str, int] = {}
        for ch in wort:
            bedarf[ch] = bedarf.get(ch, 0) + 1
        if any(len(nach_buchstabe.get(ch, ())) < n for ch, n in bedarf.items()):
            continue
        benutzt: list[tuple[int, int]] = []
        for ch in wort:
            frei = [f for f in nach_buchstabe[ch] if f not in benutzt]
            if benutzt:
                letzter = benutzt[-1]
                frei.sort(key=lambda f: -(abs(f[0] - letzter[0]) + abs(f[1] - letzter[1])))
                frei = frei[: max(1, len(frei) // 2)]  # aus der entfernteren Hälfte zufällig
            benutzt.append(rng.choice(frei))
        return benutzt
    return []


def trage_ein(paket_pfad: str, eintraege: dict[str, Eintrag]) -> tuple[int, int]:
    with open(paket_pfad, encoding="utf-8") as d:
        paket = json.load(d)
    ok = 0
    for i, rj in enumerate(paket["raetsel"]):
        r = Raetsel.aus_json(rj)
        r.loesung = waehle(r, eintraege, random.Random(zlib.crc32(r.id.encode())))
        if r.loesung:
            assert pruefe(r, eintraege) == [], (r.id, pruefe(r, eintraege))
            ok += 1
        paket["raetsel"][i] = r.als_json()
    with open(paket_pfad, "w", encoding="utf-8") as d:
        json.dump(paket, d, ensure_ascii=False, separators=(",", ":"))
        d.write("\n")
    return ok, len(paket["raetsel"])


if __name__ == "__main__":
    demo_woerter = lade_wortliste(os.path.join(HIER, "testwoerter.tsv"))
    echte = lade_wortliste(os.path.join(HIER, "inhalt", "woerter.tsv"))
    for name in sorted(os.listdir(PAKETE)):
        if not name.endswith(".json"):
            continue
        pfad = os.path.join(PAKETE, name)
        with open(pfad, encoding="utf-8") as d:
            demo = json.load(d).get("demo", False)
        ok, n = trage_ein(pfad, demo_woerter if demo else echte)
        print(f"{name}: {ok}/{n} Rätsel mit Lösungswort{' (Demo)' if demo else ''}")
