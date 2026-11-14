"""Generator für Schwedenrätsel (läuft nur auf dem Mac, nie in der App).

Vorgehen (Spezifikation Abschnitt „Generator“):
  1. Leeres Gitter. Ein erstes Wort waagerecht in Zeile 1, Frage links davor.
  2. Wiederholt: alle Wörter suchen, die ein vorhandenes Wort kreuzen und regelkonform passen,
     das beste nach Punktzahl nehmen (Gleichstand entscheidet der Seed).
  3. Wenn nichts mehr kreuzt: Lücken mit freien Wörtern ohne Kreuzung füllen.
  4. Restfelder werden Leerfelder. Mehrere Versuche, der beste gewinnt.
Der Zufall kommt ausschließlich aus random.Random(seed) → gleicher Seed, gleiches Rätsel.
"""
from __future__ import annotations

import random
from dataclasses import dataclass

from kreuzwort import FRAGEFELD, LEERFELD, SCHRITT, Frage, Raetsel, kennzahlen, normalisiere, pruefe

GROESSEN = {"leicht": (7, 9), "mittel": (9, 12), "schwer": (11, 15)}
MAX_WORTSTUFE = {"leicht": 1, "mittel": 2, "schwer": 3}
SPERRE = "x"  # Arbeitszeichen: hier darf kein Buchstabe hin (Wortende); wird Fragefeld oder Leerfeld


@dataclass(frozen=True)
class Eintrag:
    wort: str            # normalisiert, z. B. "LOEWE"
    stufe: int
    fragen: tuple[str, ...]


def lade_wortliste(pfad: str) -> dict[str, Eintrag]:
    """TSV: Wort <TAB> Stufe <TAB> Frage|Frage. Doppelte Wörter werden zusammengeführt."""
    eintraege: dict[str, Eintrag] = {}
    with open(pfad, encoding="utf-8") as datei:
        for zeile in datei:
            zeile = zeile.rstrip("\n")
            if not zeile or zeile.startswith("#"):
                continue
            roh, stufe, fragen = zeile.split("\t")
            wort = normalisiere(roh)
            neu = tuple(f.strip() for f in fragen.split("|") if f.strip())
            if wort in eintraege:
                alt = eintraege[wort]
                neu = alt.fragen + tuple(f for f in neu if f not in alt.fragen)
                eintraege[wort] = Eintrag(wort, min(alt.stufe, int(stufe)), neu)
            else:
                eintraege[wort] = Eintrag(wort, int(stufe), neu)
    return eintraege


class _Bau:
    """Arbeitsgitter während der Erzeugung."""

    def __init__(self, breite: int, hoehe: int):
        self.b, self.h = breite, hoehe
        self.g: list[list[str | None]] = [[None] * breite for _ in range(hoehe)]
        self.belegt: dict[tuple[int, int], set[str]] = {}   # Buchstabenfeld → Richtungen
        self.fragen: dict[tuple[int, int, str], str] = {}  # (z, s, richtung) → Wort
        self.woerter: set[str] = set()

    def innen(self, z: int, s: int) -> bool:
        return 0 <= z < self.h and 0 <= s < self.b

    def buchstabe(self, z: int, s: int) -> bool:
        return self.innen(z, s) and self.g[z][s] is not None and self.g[z][s] not in (FRAGEFELD, SPERRE)

    def passt(self, wort: str, z: int, s: int, richtung: str) -> int | None:
        """Anzahl Kreuzungen, wenn das Wort regelkonform passt, sonst None."""
        dz, ds = SCHRITT[richtung]
        qz, qs = z - dz, s - ds                       # Fragefeld davor
        if not self.innen(qz, qs) or (qz, qs, richtung) in self.fragen:
            return None
        if self.g[qz][qs] not in (None, SPERRE, FRAGEFELD):
            return None
        ez, es = z + len(wort) * dz, s + len(wort) * ds  # Feld hinter dem Wort
        if self.buchstabe(ez, es):
            return None
        kreuz = 0
        for i, ch in enumerate(wort):
            fz, fs = z + i * dz, s + i * ds
            if not self.innen(fz, fs):
                return None
            vorhanden = self.g[fz][fs]
            if vorhanden is None:
                # quer daneben darf kein Buchstabe stehen, sonst entsteht ein Wort ohne Frage
                if self.buchstabe(fz + ds, fs + dz) or self.buchstabe(fz - ds, fs - dz):
                    return None
            elif vorhanden == ch and richtung not in self.belegt.get((fz, fs), set()):
                kreuz += 1
            else:
                return None
        return kreuz

    def setze(self, wort: str, z: int, s: int, richtung: str) -> None:
        dz, ds = SCHRITT[richtung]
        self.g[z - dz][s - ds] = FRAGEFELD
        self.fragen[(z - dz, s - ds, richtung)] = wort
        for i, ch in enumerate(wort):
            fz, fs = z + i * dz, s + i * ds
            self.g[fz][fs] = ch
            self.belegt.setdefault((fz, fs), set()).add(richtung)
        ez, es = z + len(wort) * dz, s + len(wort) * ds
        if self.innen(ez, es) and self.g[ez][es] is None:
            self.g[ez][es] = SPERRE
        self.woerter.add(wort)


def _index(woerter: list[str]) -> dict[str, list[tuple[str, int]]]:
    """Buchstabe → alle (Wort, Position), an denen er vorkommt."""
    idx: dict[str, list[tuple[str, int]]] = {}
    for w in woerter:
        for i, ch in enumerate(w):
            idx.setdefault(ch, []).append((w, i))
    return idx


def _kreuzende(bau: _Bau, idx):
    """Wörter, die mindestens einen vorhandenen Buchstaben kreuzen."""
    gesehen = set()
    for (z, s), richtungen in list(bau.belegt.items()):
        for richtung in ("rechts", "unten"):
            if richtung in richtungen:
                continue
            dz, ds = SCHRITT[richtung]
            for wort, i in idx.get(bau.g[z][s], ()):
                if wort in bau.woerter:
                    continue
                start = (z - i * dz, s - i * ds, richtung)
                if (wort, start) in gesehen:
                    continue
                gesehen.add((wort, start))
                kreuz = bau.passt(wort, *start)
                if kreuz:
                    yield kreuz, wort, *start


def _freie(bau: _Bau, nach_laenge: dict[int, list[str]], rng: random.Random):
    """Wörter ohne Kreuzung für freie Flächen: je Startfeld das längste passende."""
    for richtung in ("rechts", "unten"):
        dz, ds = SCHRITT[richtung]
        for z in range(bau.h):
            for s in range(bau.b):
                if bau.g[z][s] is not None:
                    continue
                platz = 0
                while bau.innen(z + platz * dz, s + platz * ds) and bau.g[z + platz * dz][s + platz * ds] is None:
                    platz += 1
                for n in range(platz, 1, -1):
                    kandidaten = [w for w in nach_laenge.get(n, ()) if w not in bau.woerter]
                    rng.shuffle(kandidaten)
                    treffer = next((w for w in kandidaten[:40] if bau.passt(w, z, s, richtung) == 0), None)
                    if treffer:
                        yield 0, treffer, z, s, richtung
                        break


def _ein_versuch(breite, hoehe, woerter, rng: random.Random) -> _Bau:
    bau = _Bau(breite, hoehe)
    idx = _index(woerter)
    nach_laenge: dict[int, list[str]] = {}
    for w in woerter:
        nach_laenge.setdefault(len(w), []).append(w)
    lange = [w for w in woerter if 4 <= len(w) <= breite - 1]
    erstes = rng.choice(lange or woerter)
    bau.setze(erstes, 1, 1, "rechts")

    while True:
        # erst kreuzende Wörter; nur wenn keins mehr passt, ein freies Wort in eine Lücke
        for quelle in (_kreuzende(bau, idx), _freie(bau, nach_laenge, rng)):
            besten, beste_punkte = [], None
            for kreuz, wort, z, s, richtung in quelle:
                # Punkte: Kreuzungen zählen am meisten, dann Länge; kleiner Rand-Bonus,
                # damit Fragefelder an den Rand oben/links wandern (typisches Bild)
                punkte = kreuz * 10 + len(wort) * 2 + (2 if z <= 1 or s <= 1 else 0)
                if beste_punkte is None or punkte > beste_punkte:
                    besten, beste_punkte = [(wort, z, s, richtung)], punkte
                elif punkte == beste_punkte and len(besten) < 8:
                    besten.append((wort, z, s, richtung))
            if besten:
                bau.setze(*rng.choice(besten))
                break
        else:
            break
    return bau


def _zu_raetsel(bau: _Bau, eintraege: dict[str, Eintrag], rid: str, stufe: str, rng: random.Random) -> Raetsel:
    gitter = []
    for z in range(bau.h):
        zeile = ""
        for s in range(bau.b):
            f = bau.g[z][s]
            if f is None or f == SPERRE:
                zeile += LEERFELD
            else:
                zeile += f
        gitter.append(zeile)
    fragen = [
        Frage(z, s, richtung, rng.choice(eintraege[wort].fragen))
        for (z, s, richtung), wort in sorted(bau.fragen.items())
    ]
    return Raetsel(rid, stufe, bau.b, bau.h, gitter, fragen)


def bewertung(r: Raetsel) -> float:
    k = kennzahlen(r)
    return k["buchstabenanteil"] + k["kreuzanteil"] * 0.5 - k["leeranteil"]


# Wortlängen im dichten Muster: Gewichte je Länge und längstes Wort je Stufe
DICHT_LAENGEN = {
    "leicht": (6, {2: 1, 3: 3, 4: 3, 5: 2, 6: 1}),
    "mittel": (7, {2: 1, 3: 3, 4: 3, 5: 2, 6: 1, 7: 1}),
    "schwer": (8, {2: 1, 3: 3, 4: 3, 5: 3, 6: 2, 7: 1, 8: 1}),
}


def _dicht_zu_bau(breite, hoehe, g, fragen) -> _Bau:
    bau = _Bau(breite, hoehe)
    bau.g = g
    bau.fragen = fragen
    bau.woerter = set(fragen.values())
    return bau


def erzeuge(eintraege: dict[str, Eintrag], stufe: str, seed: int, rid: str = "", versuche: int = 12,
            dicht: bool = False, rueckfall: bool = True, bevorzugt: set[str] | None = None,
            laengen: tuple[int, dict[int, int]] | None = None, zuerst_max: int = 3) -> Raetsel | None:
    """Erzeugt ein gültiges Rätsel der Stufe. Gleicher Seed + gleiche Wortliste = gleiches Rätsel.

    dicht=True: zuerst der dichte Generator (dicht.py, Zeitschriften-Bild); gelingt er nicht,
    der lockere Generator als Rückfall.
    """
    breite, hoehe = GROESSEN[stufe]
    rng = random.Random(seed)
    erlaubt = sorted(
        w for w, e in eintraege.items()
        if e.stufe <= MAX_WORTSTUFE[stufe] and 2 <= len(w) <= max(breite, hoehe) - 1
    )
    rid = rid or f"{stufe[0].upper()}-{seed}"
    if dicht:
        from dicht import dichter_versuch

        max_laenge, gewichte = laengen or DICHT_LAENGEN[stufe]  # laengen: andere Wortlängen-Mischung (ergaenze.py)
        # Dicht braucht Breite: Wörter bis eine Stufe darüber, aber mit Zuschlag → nur wenn nötig
        ziel = MAX_WORTSTUFE[stufe]
        breit = sorted(w for w, e in eintraege.items() if e.stufe <= ziel + 1 and 2 <= len(w) <= max_laenge)
        strafe = {w: 1.5 for w in breit if eintraege[w].stufe > ziel}
        if bevorzugt:  # Themen-Rätsel: Wörter außerhalb des Themas nur, wenn nötig
            for w in breit:
                if w not in bevorzugt:
                    strafe[w] = strafe.get(w, 0.0) + 0.9
        ergebnis = dichter_versuch(breite, hoehe, breit, rng, max_laenge, gewichte, strafe=strafe,
                                   zuerst=set(bevorzugt) & set(breit) if bevorzugt else None, zuerst_max=zuerst_max)
        if ergebnis is not None:
            r = _zu_raetsel(_dicht_zu_bau(breite, hoehe, *ergebnis), eintraege, rid, stufe, rng)
            if not pruefe(r, eintraege):
                return r
        if not rueckfall:
            return None  # nur dichte Rätsel gewünscht → Aufrufer nimmt den nächsten Seed
    bestes, beste_note = None, None
    for _ in range(versuche):
        bau = _ein_versuch(breite, hoehe, list(erlaubt), rng)
        r = _zu_raetsel(bau, eintraege, rid, stufe, rng)
        if pruefe(r, eintraege):
            continue  # darf nicht passieren; Tests sichern das ab
        note = bewertung(r)
        if bestes is None or note > beste_note:
            bestes, beste_note = r, note
    if bestes is None:
        raise RuntimeError(f"kein gültiges Rätsel für Seed {seed}")
    return bestes
