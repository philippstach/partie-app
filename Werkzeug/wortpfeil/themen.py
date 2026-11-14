"""Themen-Rätsel: welche Wortstapel zu welchem Thema gehören (SPEZIFIKATION, Abschnitt „Themen-Rätsel“)."""
from __future__ import annotations

import glob
import os

from kreuzwort import normalisiere

HIER = os.path.dirname(os.path.abspath(__file__))

# id → (Name DE, Name EN, SF-Symbol, Stapel-Nummern)
THEMEN = {
    "tiere": ("Tiere", "Animals", "pawprint", ("001", "002")),
    "natur": ("Pflanzen & Natur", "Plants & Nature", "leaf", ("003", "010")),
    "essen": ("Essen & Trinken", "Food & Drink", "fork.knife", ("004",)),
    "erdkunde": ("Erdkunde", "Geography", "globe.europe.africa", ("011", "012", "013")),
    "musik": ("Musik", "Music", "music.note", ("014",)),
    "sport": ("Sport & Spiel", "Sports & Games", "figure.run", ("016",)),
    "mythologie": ("Mythologie", "Mythology", "bolt", ("017",)),
    "geschichte": ("Geschichte", "History", "building.columns", ("018",)),
}


def themenwoerter(thema: str, bestand: set[str] | dict) -> set[str]:
    """Alle Wörter (normalisiert) aus den Stapeln des Themas, die im Bestand sind."""
    woerter: set[str] = set()
    for nr in THEMEN[thema][3]:
        for pfad in glob.glob(os.path.join(HIER, "inhalt", "stapel", f"{nr}-*.tsv")):
            with open(pfad, encoding="utf-8") as d:
                for zeile in d:
                    if zeile.startswith("#") or not zeile.strip():
                        continue
                    w = normalisiere(zeile.split("\t")[0])
                    if w in bestand:
                        woerter.add(w)
    return woerter
