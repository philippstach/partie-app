"""Nachbearbeitung fertiger Pakete (Gitter bleiben unverändert):
  1. Fragen wählen, die gut ins Fragefeld passen (Lesbarkeit auf dem iPhone)
  2. Lösungswort eintragen (loesungswort.py)

Aufruf (im Ordner Referenz/):  python3 nachbearbeitung.py leicht mittel …   (ohne Namen: alle echten Pakete)
"""
from __future__ import annotations

import json
import os
import random
import re
import sys
import zlib

from generator import Eintrag, lade_wortliste
from kreuzwort import Frage, Raetsel, pruefe
from loesungswort import waehle as waehle_loesung

HIER = os.path.dirname(os.path.abspath(__file__))
PAKETE = os.path.join(HIER, "..", "..", "Pakete", "SpielWortpfeil", "Shared", "raetsel")
MESSER = os.path.join(HIER, "messen", "fragefeld_messen.sh")
FELD_PT = {"leicht": 48, "mittel": 36, "schwer": 34}   # Feldgröße auf dem iPhone ohne Zoom (gemessen von 2 iOS)


def messe(anfragen: set[tuple[str, int, bool, str]]) -> dict[tuple[str, int, bool, str], bool]:
    """Fragt das Mac-Werkzeug der App (gleiche Satzlogik wie auf dem iPhone), ob ein Text ins Feld passt.
    Fehlt das Werkzeug, wird die Faustregel `passt` benutzt."""
    import subprocess

    liste = sorted(anfragen)
    if not os.path.exists(MESSER):
        return {a: passt(a[0], a[2]) for a in liste}
    eingabe = "".join(f"{t}\t{pt}\t{int(g)}\t{ri}\n" for t, pt, g, ri in liste)
    aus = subprocess.run([MESSER], input=eingabe, capture_output=True, text=True, check=True).stdout
    ergebnis = {}
    for zeile in aus.splitlines():
        teile = zeile.split("\t")
        if len(teile) >= 6 and teile[0] != "Text":
            ergebnis[(teile[0], int(float(teile[1])), teile[2] == "1", teile[5])] = teile[3] == "1"
    return {a: ergebnis.get(a, passt(a[0], a[2])) for a in liste}



def _zeilen(text: str, breite: int) -> int:
    """Wie viele Zeilen braucht der Text bei `breite` Zeichen je Zeile (lange Wörter werden getrennt)?"""
    zeilen, frei = 0, 0
    for wort in text.split():
        while len(wort) > breite:             # Silbentrennung: Stück + Bindestrich
            zeilen += 1
            wort = wort[breite - 1:]
            frei = 0
        if frei >= len(wort) + (1 if frei < breite else 0) and zeilen:
            frei -= len(wort) + 1
        else:
            zeilen += 1
            frei = breite - len(wort)
    return zeilen


def passt(text: str, geteilt: bool) -> bool:
    """Gemessen auf dem iPhone (2 iOS, 05.10.): geteiltes Feld = 1 Zeile ≤ 12 Zeichen oder 2 Zeilen ≤ 7;
    einzelnes Feld = 3 Zeilen ≤ 8 Zeichen."""
    if geteilt:
        return len(text) <= 12 or _zeilen(text, 7) <= 2
    return _zeilen(text, 8) <= 3


def platz_kosten(text: str, geteilt: bool) -> float:
    """Je kleiner, desto besser. Passt die Frage, zählt nur noch die Länge (kürzer = ruhiger)."""
    return (0 if passt(text, geteilt) else 100) + len(text) / 100


def _felder(r: Raetsel):
    """Je Frage: (Frage, geteilt?, Feldgröße)."""
    geteilt = {(f.zeile, f.spalte) for f in r.fragen if len(r.fragen_im_feld(f.zeile, f.spalte)) == 2}
    return [(f, (f.zeile, f.spalte) in geteilt, FELD_PT[r.stufe]) for f in r.fragen]


def waehle_fragen(r: Raetsel, eintraege: dict[str, Eintrag], gemessen: dict | None = None) -> int:
    """Setzt je Frage `text` (Frageleiste, ausführlich) und bei Bedarf `kurz` (fürs Kästchen).

    text: eine ausführliche Frage des Wortes (> 9 Zeichen, sonst irgendeine), je Rätsel/Wort fest per crc32 → Abwechslung.
    kurz: nur wenn `text` laut Messung nicht ins Kästchen passt: die längste (= informativste) Frage, die passt;
          passt keine, die kürzeste (wird dann mit „…“ gekürzt).
    Gibt die Anzahl geänderter Fragen zurück.
    """
    neu, geaendert = [], 0
    for f, geteilt, pt in _felder(r):
        wort = r.loesungswort(f)
        moeglich = eintraege[wort].fragen
        def ok(t):
            return gemessen[(t, pt, geteilt, f.richtung)] if gemessen is not None else passt(t, geteilt)
        ausfuehrlich = [t for t in moeglich if len(t) > 9] or list(moeglich)
        text = ausfuehrlich[zlib.crc32(f"{r.id}/{wort}".encode()) % len(ausfuehrlich)]
        kurz = ""
        if not ok(text):
            passend = [t for t in moeglich if ok(t)]
            kurz = max(passend, key=len) if passend else min(moeglich, key=len)
            if kurz == text or len(kurz) >= len(text):
                kurz = ""
        geaendert += (text, kurz) != (f.text, f.kurz)
        neu.append(Frage(f.zeile, f.spalte, f.richtung, text, kurz))
    r.fragen = neu
    return geaendert


def bearbeite(name: str, eintraege: dict[str, Eintrag]) -> None:
    pfad = os.path.join(PAKETE, f"{name}.json")
    with open(pfad, encoding="utf-8") as d:
        paket = json.load(d)
    alle = [Raetsel.aus_json(rj) for rj in paket["raetsel"]]
    anfragen = {(t, pt, g, f.richtung) for r in alle for f, g, pt in _felder(r)
                for t in eintraege[r.loesungswort(f)].fragen}
    gemessen = messe(anfragen)
    geaendert = schlecht = 0
    for i, r in enumerate(alle):
        geaendert += waehle_fragen(r, eintraege, gemessen)
        bevorzugt = None
        if r.thema:
            from themen import themenwoerter
            bevorzugt = themenwoerter(r.thema, eintraege)
        r.loesung = waehle_loesung(r, eintraege, random.Random(zlib.crc32(r.id.encode())), bevorzugt)
        schlecht += sum(not gemessen[(f.kurz or f.text, pt, g, f.richtung)] for f, g, pt in _felder(r))
        assert pruefe(r, eintraege) == [], (r.id, pruefe(r, eintraege))
        paket["raetsel"][i] = r.als_json()
    with open(pfad, "w", encoding="utf-8") as d:
        json.dump(paket, d, ensure_ascii=False, separators=(",", ":"))
        d.write("\n")
    gesamt = sum(len(rj["fragen"]) for rj in paket["raetsel"])
    print(f"{name}: {geaendert} Fragen getauscht · {schlecht}/{gesamt} ({100 * schlecht / gesamt:.1f} %) passen laut Messung nicht ins Feld")


if __name__ == "__main__":
    eintraege = lade_wortliste(os.path.join(HIER, "inhalt", "woerter.tsv"))
    namen = sys.argv[1:] or ["leicht", "mittel", "schwer", "taeglich", "themen"]
    for name in namen:
        with open(os.path.join(PAKETE, f"{name}.json"), encoding="utf-8") as d:
            if json.load(d).get("demo"):
                print(f"{name}: Demo-Paket, übersprungen")
                continue
        bearbeite(name, eintraege)
