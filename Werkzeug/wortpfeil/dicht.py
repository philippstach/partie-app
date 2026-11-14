"""Dichter Generator: erst Muster aus Fragefeldern, dann alle Wörter per Suche einpassen.

So entstehen Schwedenrätsel wie in Zeitschriften: fast keine Leerfelder, die meisten Buchstaben gekreuzt.
Ablauf:
  1. Muster: oberste Zeile und linke Spalte sind Fragefelder (Frage zeigt nach unten bzw. rechts),
     innen werden Fragefelder so verteilt, dass jede Buchstabenfolge 2..max_laenge lang ist.
  2. Füllen: Suche mit Rücksetzen. Immer zuerst die Lücke mit den wenigsten passenden Wörtern
     (meist gekreuzt, also schwer), Kandidaten in Zufallsreihenfolge aus dem Seed.
  3. Klappt es nicht innerhalb des Knotenlimits → neues Muster.
Ergebnis ist ein _Bau wie beim lockeren Generator, damit Prüfung und Umwandlung gleich bleiben.
"""
from __future__ import annotations

import random

from kreuzwort import FRAGEFELD, SCHRITT

FREI = "."  # Buchstabenfeld, noch ohne Buchstaben


def _laeufe(g, b, h):
    """Alle Folgen von Buchstabenfeldern (Länge ≥ 2): (richtung, start, länge)."""
    aus = []
    for richtung in ("rechts", "unten"):
        dz, ds = SCHRITT[richtung]
        for z in range(h):
            for s in range(b):
                if g[z][s] == FRAGEFELD:
                    continue
                vz, vs = z - dz, s - ds
                if 0 <= vz < h and 0 <= vs < b and g[vz][vs] != FRAGEFELD:
                    continue
                n = 0
                while z + n * dz < h and s + n * ds < b and g[z + n * dz][s + n * ds] != FRAGEFELD:
                    n += 1
                if n >= 2:
                    aus.append((richtung, (z, s), n))
    return aus


def muster(b: int, h: int, rng: random.Random, max_laenge: int, laengen_gewicht: dict[int, int]) -> list[list[str]] | None:
    """Fragefeld-Muster. Rand oben/links = Fragefelder, innen zufällig getrennt."""
    g = [[FREI] * b for _ in range(h)]
    for s in range(b):
        g[0][s] = FRAGEFELD
    for z in range(h):
        g[z][0] = FRAGEFELD
    laengen = [n for n, w in laengen_gewicht.items() for _ in range(w)]
    # Zeilen innen zerlegen
    for z in range(1, h):
        s = 1
        while s < b:
            n = rng.choice(laengen)
            if b - s - n == 1:      # sonst bliebe ein einzelnes Feld am Rand
                n += 1
            s += n
            if s < b:
                g[z][s] = FRAGEFELD
                s += 1
    # Reparieren, bis alle Regeln stimmen
    for _ in range(200):
        geaendert = False
        for richtung, (z, s), n in _laeufe(g, b, h):
            if n > max_laenge:
                dz, ds = SCHRITT[richtung]
                k = rng.randint(2, min(n - 3, max_laenge))
                g[z + k * dz][s + k * ds] = FRAGEFELD
                geaendert = True
                break
        if geaendert:
            continue
        # Buchstabenfeld ohne Wort (in beiden Richtungen allein) → Fragefeld
        abgedeckt = set()
        for richtung, (z, s), n in _laeufe(g, b, h):
            dz, ds = SCHRITT[richtung]
            abgedeckt.update((z + i * dz, s + i * ds) for i in range(n))
        allein = [(z, s) for z in range(h) for s in range(b) if g[z][s] == FREI and (z, s) not in abgedeckt]
        if allein:
            z, s = rng.choice(allein)
            g[z][s] = FRAGEFELD
            continue
        break
    else:
        return None
    return g


def fuelle(g, b, h, woerter: list[str], rng: random.Random, knoten_max: int = 20000, kandidaten_max: int = 400,
           strafe: dict[str, float] | None = None, zuerst: set[str] | None = None, zuerst_max: int = 3):
    """Füllt das Muster. Gibt {(richtung, start): wort} zurück oder None.

    strafe: Wort → Zuschlag in der Reihenfolge (z. B. für Wörter über der Zielstufe). Kandidaten werden nach
    Zuschlag + Zufall sortiert, also bevorzugt, aber nicht ausschließlich passende Wörter.
    """
    strafe = strafe or {}
    slots = _laeufe(g, b, h)
    if not slots:
        return None
    nach_laenge: dict[int, list[str]] = {}
    index: dict[tuple[int, int, str], set[str]] = {}
    for w in woerter:
        nach_laenge.setdefault(len(w), []).append(w)
        for i, ch in enumerate(w):
            index.setdefault((len(w), i, ch), set()).add(w)
    if any(n not in nach_laenge for _, _, n in slots):
        return None
    zellen = {}
    for k, (richtung, (z, s), n) in enumerate(slots):
        dz, ds = SCHRITT[richtung]
        zellen[k] = [(z + i * dz, s + i * ds) for i in range(n)]
    buchst = [[None] * b for _ in range(h)]
    belegt: dict[int, str] = {}
    benutzt: set[str] = set()
    knoten = [0]

    laenge_menge = {n: set(ws) for n, ws in nach_laenge.items()}

    def menge(k):
        """Alle Wörter, die zu den schon gesetzten Buchstaben der Lücke passen (ohne „benutzt“-Abzug)."""
        n = len(zellen[k])
        m = None
        for i, (z, s) in enumerate(zellen[k]):
            ch = buchst[z][s]
            if ch is not None:
                teil = index.get((n, i, ch), set())
                m = teil if m is None else m & teil
                if not m:
                    return m
        return laenge_menge[n] if m is None else m

    def suche():
        knoten[0] += 1
        if knoten[0] > knoten_max:
            return False
        offen = [k for k in zellen if k not in belegt]
        if not offen:
            return True
        # Nur zählen (schnell), die Liste wird nur für die gewählte Lücke gebaut
        best, best_m, best_n = None, None, None
        for k in offen:
            m = menge(k)
            anzahl = len(m) - sum(1 for w in benutzt if w in m)
            if best is None or anzahl < best_n:
                best, best_m, best_n = k, m, anzahl
                if anzahl == 0:
                    return False
        best_kand = sorted(best_m - benutzt)
        best_kand.sort(key=lambda w: strafe.get(w, 0.0) + rng.random())
        for w in best_kand[:kandidaten_max]:
            gesetzt = []
            for (z, s), ch in zip(zellen[best], w):
                if buchst[z][s] is None:
                    buchst[z][s] = ch
                    gesetzt.append((z, s))
            belegt[best] = w
            benutzt.add(w)
            if suche():
                return True
            del belegt[best]
            benutzt.discard(w)
            for z, s in gesetzt:
                buchst[z][s] = None
        return False

    if zuerst:
        # Themen-Rätsel: lange Lücken zuerst mit Themenwörtern belegen (gierig, kreuzungsverträglich)
        lange = sorted((k for k in zellen if len(zellen[k]) >= 5), key=lambda k: (-len(zellen[k]), rng.random()))
        gesetzt_thema = 0
        for k in lange:
            if gesetzt_thema >= zuerst_max:
                break
            passend = sorted(w for w in menge(k) if w in zuerst and w not in benutzt)
            if not passend:
                continue
            rng.shuffle(passend)
            for w in passend[:20]:
                neu_gesetzt = []
                for (z, s), ch in zip(zellen[k], w):
                    if buchst[z][s] is None:
                        buchst[z][s] = ch
                        neu_gesetzt.append((z, s))
                belegt[k] = w
                benutzt.add(w)
                # Vorausschau: jede andere offene Lücke muss noch mindestens ein Wort haben
                if all(len(menge(j) - benutzt) > 0 for j in zellen if j not in belegt):
                    gesetzt_thema += 1
                    break
                del belegt[k]
                benutzt.discard(w)
                for z, s in neu_gesetzt:
                    buchst[z][s] = None
    if not suche():
        return None
    return {(slots[k][0], slots[k][1]): w for k, w in belegt.items()}


def dichter_versuch(b, h, woerter, rng, max_laenge, laengen_gewicht, muster_versuche=4, strafe=None, zuerst=None,
                    zuerst_max=3):
    """Gibt (gitter_mit_buchstaben, fragen{(z,s,richtung): wort}) zurück oder None."""
    for _ in range(muster_versuche):
        g = muster(b, h, rng, max_laenge, laengen_gewicht)
        if g is None:
            continue
        loesung = fuelle(g, b, h, woerter, rng, strafe=strafe, zuerst=zuerst, zuerst_max=zuerst_max)
        if loesung is None:
            continue
        fragen = {}
        for (richtung, (z, s)), w in loesung.items():
            dz, ds = SCHRITT[richtung]
            fragen[(z - dz, s - ds, richtung)] = w
            for i, ch in enumerate(w):
                g[z + i * dz][s + i * ds] = ch
        # Fragefelder ohne Frage (z. B. Ecke oben links) werden Leerfelder
        for z in range(h):
            for s in range(b):
                if g[z][s] == FRAGEFELD and not any((z, s, r) in fragen for r in ("rechts", "unten")):
                    g[z][s] = None
        return g, fragen
    return None
