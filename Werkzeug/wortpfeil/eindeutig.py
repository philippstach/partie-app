"""Gleiche oder gleichwertige Fragen im selben Rätsel auflösen (Gitter bleiben unverändert).

Problem: Steht „Ägyptischer Sonnengott“ für RA und für RE im selben Rätsel (oder „Weiblicher Vorname“ für EVA und UTE),
passen beide Wörter an beide Stellen, die App wertet aber nur die gespeicherte Reihenfolge als richtig.
Lösung: Die zweite (und jede weitere) Frage bekommt eine andere Frage desselben Wortes aus dem Wortbestand.

Aufruf (im Ordner Referenz/):  python3 eindeutig.py [paket …]      (ohne Namen: alle echten Pakete)
"""
from __future__ import annotations

import json
import os
import sys
import zlib

from generator import Eintrag, lade_wortliste
from kreuzwort import Frage, Raetsel, pruefe
from nachbearbeitung import FELD_PT, PAKETE, _felder, messe

HIER = os.path.dirname(os.path.abspath(__file__))

# Allgemeine Namensfragen: gleichwertig, wenn sie dasselbe Geschlecht meinen („Vorname“ meint beide)
_WEIBLICH = {"weiblicher vorname", "vorname, weibl.", "frauenname", "mädchenname", "kurzer frauenname",
             "altmodischer frauenname", "nordischer frauenname", "norddeutscher frauenname"}
_MAENNLICH = {"männlicher vorname", "vorname, männl.", "männername", "nordischer männername", "jungenname",
              "kurzer jungenname", "kurzer männername", "nordischer jungenname"}
_BEIDE = {"vorname", "skandinavischer vorname", "norddeutscher vorname", "nord. vorname", "nordischer vorname"}


def marken(text: str) -> set[str]:
    """Gleichwertige Fragen teilen sich eine Marke: der Text selbst, bei Namensfragen zusätzlich das Geschlecht."""
    t = text.strip().lower()
    out = {t}
    if t in _WEIBLICH: out.add("#weiblich")
    if t in _MAENNLICH: out.add("#maennlich")
    if t in _BEIDE: out |= {"#weiblich", "#maennlich"}
    return out


def loese(r: Raetsel, eintraege: dict[str, Eintrag], gemessen: dict | None) -> tuple[int, int]:
    """Gibt (ersetzt, ungelöst) zurück."""
    belegt: set[str] = set()
    neu, ersetzt, offen = [], 0, 0
    for f, geteilt, pt in _felder(r):
        if not marken(f.text) & belegt:
            belegt |= marken(f.text)
            neu.append(f)
            continue
        wort = r.loesungswort(f)

        def ok(t):
            return gemessen[(t, pt, geteilt, f.richtung)] if gemessen is not None else False

        frei = [t for t in eintraege[wort].fragen if not marken(t) & belegt]
        if not frei:
            offen += 1
            belegt |= marken(f.text)
            neu.append(f)
            continue
        ausfuehrlich = [t for t in frei if len(t) > 9] or frei
        text = ausfuehrlich[zlib.crc32(f"{r.id}/{wort}/eindeutig".encode()) % len(ausfuehrlich)]
        kurz = ""
        if not ok(text):
            passend = [t for t in frei if ok(t)]
            kurz = max(passend, key=len) if passend else min(frei, key=len)
            if kurz == text or len(kurz) >= len(text):
                kurz = ""
        belegt |= marken(text)
        neu.append(Frage(f.zeile, f.spalte, f.richtung, text, kurz))
        ersetzt += 1
    r.fragen = neu
    return ersetzt, offen


def bearbeite(name: str, eintraege: dict[str, Eintrag]) -> None:
    pfad = os.path.join(PAKETE, f"{name}.json")
    with open(pfad, encoding="utf-8") as d:
        paket = json.load(d)
    alle = [Raetsel.aus_json(rj) for rj in paket["raetsel"]]
    # Nur Rätsel mit Doppelungen brauchen Messungen
    anfragen = set()
    for r in alle:
        belegt: set[str] = set()
        for f, g, pt in _felder(r):
            m = marken(f.text)
            if m & belegt:
                anfragen |= {(t, pt, g, f.richtung) for t in eintraege[r.loesungswort(f)].fragen}
            belegt |= m
    gemessen = messe(anfragen) if anfragen else {}
    ersetzt = offen = rae = 0
    for i, r in enumerate(alle):
        e, o = loese(r, eintraege, gemessen)
        assert pruefe(r, eintraege) == [], (r.id, pruefe(r, eintraege))
        if e or o:
            rae += 1
        ersetzt += e
        offen += o
        paket["raetsel"][i] = r.als_json()
    with open(pfad, "w", encoding="utf-8") as d:
        json.dump(paket, d, ensure_ascii=False, separators=(",", ":"))
        d.write("\n")
    print(f"{name}: {rae} Rätsel mit Doppelung · {ersetzt} Fragen ersetzt · {offen} ohne Ersatz")


if __name__ == "__main__":
    eintraege = lade_wortliste(os.path.join(HIER, "inhalt", "woerter.tsv"))
    for name in sys.argv[1:] or ["leicht", "mittel", "schwer", "taeglich", "themen"]:
        bearbeite(name, eintraege)
