"""Kreuzworträtsel (Schwedenrätsel) – Python-Referenz.

Quelle der Wahrheit für die Logik ist Doku/SPEZIFIKATION.md. Dieses Modul setzt sie um und
erzeugt (über erzeuge_tests.py) die Testfälle in Shared/regeltests/, die iOS und Android
genauso bestehen müssen.

Begriffe (Code-Namen in Klammern):
  Gitter (gitter)        Liste von Zeilen-Strings. '#' Fragefeld, '-' Leerfeld, 'A'-'Z' Lösungsbuchstabe
  Frage (frage)          sitzt in einem Fragefeld, zeigt 'rechts' oder 'unten' auf ihr Wort
  Wort (wort)            Folge von Buchstabenfeldern direkt hinter dem Fragefeld in Pfeilrichtung
  Spielstand (Spiel)     Einträge, Cursor, Richtung, aufgedeckte Felder, markierte Fehler, Hilfen
"""
from __future__ import annotations

import datetime as _dt
from dataclasses import dataclass, field

FRAGEFELD = "#"
LEERFELD = "-"
RICHTUNGEN = ("rechts", "unten")
SCHRITT = {"rechts": (0, 1), "unten": (1, 0)}
TAGES_START = _dt.date(2026, 1, 1)

# ---------------------------------------------------------------------------
# Schreibweise
# ---------------------------------------------------------------------------

_ERSATZ = {"Ä": "AE", "Ö": "OE", "Ü": "UE", "ß": "SS", "ẞ": "SS"}


def normalisiere(text: str) -> str:
    """Wort in Rätselschreibweise: Großbuchstaben A–Z, Ä→AE, Ö→OE, Ü→UE, ß→SS.

    Alle anderen Zeichen (Leerzeichen, Bindestrich, Ziffern, Akzente …) fallen weg,
    Akzente werden auf den Grundbuchstaben zurückgeführt (é→E).
    """
    import unicodedata

    aus = []
    for zeichen in text:
        if zeichen in ("ß", "ẞ"):
            aus.append("SS")
            continue
        gross = zeichen.upper()
        if gross in _ERSATZ:
            aus.append(_ERSATZ[gross])
            continue
        basis = unicodedata.normalize("NFD", gross)[0]
        if "A" <= basis <= "Z":
            aus.append(basis)
    return "".join(aus)


def eingabe_zu_buchstaben(zeichen: str) -> str:
    """Ein getipptes Zeichen → 0, 1 oder 2 Rätselbuchstaben (ä → 'AE')."""
    return normalisiere(zeichen)


# ---------------------------------------------------------------------------
# Rätsel
# ---------------------------------------------------------------------------


@dataclass(frozen=True)
class Frage:
    zeile: int
    spalte: int
    richtung: str
    text: str
    kurz: str = ""   # optional: Kurztext fürs Kästchen, wenn `text` nicht hineinpasst (Frageleiste zeigt immer `text`)

    @property
    def start(self) -> tuple[int, int]:
        dz, ds = SCHRITT[self.richtung]
        return (self.zeile + dz, self.spalte + ds)


@dataclass
class Raetsel:
    id: str
    stufe: str
    breite: int
    hoehe: int
    gitter: list[str]
    fragen: list[Frage]
    loesung: list[tuple[int, int]] = field(default_factory=list)  # Lösungswort-Felder in Reihenfolge (optional)
    thema: str = ""   # optional: Themen-Rätsel (z. B. "tiere")

    # -- Grundzugriffe ------------------------------------------------------
    def feld(self, z: int, s: int) -> str | None:
        if 0 <= z < self.hoehe and 0 <= s < self.breite:
            return self.gitter[z][s]
        return None

    def ist_buchstabe(self, z: int, s: int) -> bool:
        f = self.feld(z, s)
        return f is not None and "A" <= f <= "Z"

    def buchstabenfelder(self) -> list[tuple[int, int]]:
        return [(z, s) for z in range(self.hoehe) for s in range(self.breite) if self.ist_buchstabe(z, s)]

    def wortfelder(self, frage: Frage) -> list[tuple[int, int]]:
        dz, ds = SCHRITT[frage.richtung]
        z, s = frage.start
        felder = []
        while self.ist_buchstabe(z, s):
            felder.append((z, s))
            z, s = z + dz, s + ds
        return felder

    def loesungswort(self, frage: Frage) -> str:
        return "".join(self.gitter[z][s] for z, s in self.wortfelder(frage))

    def loesungswort_text(self) -> str:
        """Das Lösungswort aus den markierten Feldern (leer, wenn das Rätsel keins hat)."""
        return "".join(self.gitter[z][s] for z, s in self.loesung)

    def sortierte_fragen(self) -> list[Frage]:
        """Reihenfolge für „nächste/vorige Frage“: Fragefeld zeilenweise, 'rechts' vor 'unten'."""
        return sorted(self.fragen, key=lambda f: (f.zeile, f.spalte, RICHTUNGEN.index(f.richtung)))

    def frage_bei(self, z: int, s: int, richtung: str) -> Frage | None:
        """Die Frage, deren Wort in `richtung` durch das Buchstabenfeld (z, s) läuft."""
        if not self.ist_buchstabe(z, s):
            return None
        dz, ds = SCHRITT[richtung]
        while self.ist_buchstabe(z - dz, s - ds):
            z, s = z - dz, s - ds
        for f in self.fragen:
            if f.richtung == richtung and f.start == (z, s):
                return f
        return None

    def fragen_im_feld(self, z: int, s: int) -> list[Frage]:
        return sorted(
            (f for f in self.fragen if (f.zeile, f.spalte) == (z, s) and f.richtung in RICHTUNGEN),
            key=lambda f: RICHTUNGEN.index(f.richtung),
        )

    # -- JSON ----------------------------------------------------------------
    def als_json(self) -> dict:
        return {
            "id": self.id,
            "stufe": self.stufe,
            "breite": self.breite,
            "hoehe": self.hoehe,
            "gitter": list(self.gitter),
            "fragen": [
                {"zeile": f.zeile, "spalte": f.spalte, "richtung": f.richtung, "text": f.text,
                 **({"kurz": f.kurz} if f.kurz else {})}
                for f in self.sortierte_fragen()
            ],
            **({"loesung": [list(f) for f in self.loesung]} if self.loesung else {}),
            **({"thema": self.thema} if self.thema else {}),
        }

    @staticmethod
    def aus_json(d: dict) -> "Raetsel":
        return Raetsel(
            id=d["id"],
            stufe=d.get("stufe", "mittel"),
            breite=d["breite"],
            hoehe=d["hoehe"],
            gitter=list(d["gitter"]),
            fragen=[Frage(f["zeile"], f["spalte"], f["richtung"], f["text"], f.get("kurz", "")) for f in d["fragen"]],
            loesung=[(z, s) for z, s in d.get("loesung", [])],
            thema=d.get("thema", ""),
        )


# ---------------------------------------------------------------------------
# Prüfer: ist ein Rätsel gültig?
# ---------------------------------------------------------------------------

MAX_FRAGENLAENGE = 30


def laeufe(raetsel: Raetsel) -> list[tuple[str, tuple[int, int], int]]:
    """Alle zusammenhängenden Buchstabenfolgen der Länge ≥ 2: (richtung, start, länge)."""
    gefunden = []
    for richtung in RICHTUNGEN:
        dz, ds = SCHRITT[richtung]
        for z, s in raetsel.buchstabenfelder():
            if raetsel.ist_buchstabe(z - dz, s - ds):
                continue  # nicht der Anfang einer Folge
            laenge = 0
            while raetsel.ist_buchstabe(z + laenge * dz, s + laenge * ds):
                laenge += 1
            if laenge >= 2:
                gefunden.append((richtung, (z, s), laenge))
    return gefunden


def pruefe(raetsel: Raetsel, wortliste: dict[str, object] | None = None) -> list[str]:
    """Gibt eine Liste von Fehlercodes zurück; leer = gültig. Codes stehen in der Spezifikation."""
    fehler: list[str] = []
    r = raetsel
    if r.stufe not in ("leicht", "mittel", "schwer"):
        fehler.append("stufe_unbekannt")
    if len(r.gitter) != r.hoehe or any(len(zeile) != r.breite for zeile in r.gitter):
        return fehler + ["gitter_groesse"]
    for zeile in r.gitter:
        for f in zeile:
            if not (f in (FRAGEFELD, LEERFELD) or "A" <= f <= "Z"):
                return fehler + ["gitter_zeichen"]

    gesehen = set()
    woerter = []
    for frage in r.fragen:
        if frage.richtung not in RICHTUNGEN:
            fehler.append("richtung_unbekannt")
            continue
        if r.feld(frage.zeile, frage.spalte) != FRAGEFELD:
            fehler.append("frage_nicht_im_fragefeld")
            continue
        schluessel = (frage.zeile, frage.spalte, frage.richtung)
        if schluessel in gesehen:
            fehler.append("frage_doppelt")
        gesehen.add(schluessel)
        if not frage.text.strip():
            fehler.append("fragetext_leer")
        if len(frage.text) > MAX_FRAGENLAENGE:
            fehler.append("fragetext_zu_lang")
        if frage.kurz and not frage.kurz.strip():
            fehler.append("fragetext_leer")
        if len(frage.kurz) > MAX_FRAGENLAENGE:
            fehler.append("fragetext_zu_lang")
        felder = r.wortfelder(frage)
        if len(felder) < 2:
            fehler.append("wort_zu_kurz")
            continue
        woerter.append(r.loesungswort(frage))

    starts = {(f.richtung, f.start) for f in r.fragen if f.richtung in RICHTUNGEN}
    abgedeckt = set()
    for richtung, start, laenge in laeufe(r):
        if (richtung, start) not in starts:
            fehler.append("wort_ohne_frage")
        dz, ds = SCHRITT[richtung]
        for i in range(laenge):
            abgedeckt.add((start[0] + i * dz, start[1] + i * ds))
    if any(feld not in abgedeckt for feld in r.buchstabenfelder()):
        fehler.append("buchstabe_ohne_wort")

    for z in range(r.hoehe):
        for s in range(r.breite):
            if r.gitter[z][s] == FRAGEFELD and not r.fragen_im_feld(z, s):
                fehler.append("fragefeld_ohne_frage")

    if len(set(woerter)) != len(woerter):
        fehler.append("wort_doppelt")
    if wortliste is not None and any(w not in wortliste for w in woerter):
        fehler.append("wort_unbekannt")
    # Reihenfolge stabil und ohne Wiederholung, damit Testfälle vergleichbar sind
    if r.loesung:
        if (len(set(r.loesung)) != len(r.loesung) or not 3 <= len(r.loesung) <= 12
                or any(not r.ist_buchstabe(z, s) for z, s in r.loesung)):
            fehler.append("loesung_ungueltig")
        elif wortliste is not None and r.loesungswort_text() not in wortliste:
            fehler.append("loesung_unbekannt")
    return sorted(set(fehler))


def kennzahlen(raetsel: Raetsel) -> dict:
    """Qualitätswerte (keine Gültigkeit): Anteil Leerfelder, gekreuzte Buchstaben."""
    felder = raetsel.breite * raetsel.hoehe
    leer = sum(zeile.count(LEERFELD) for zeile in raetsel.gitter)
    buchstaben = raetsel.buchstabenfelder()
    gekreuzt = sum(
        1 for z, s in buchstaben
        if raetsel.frage_bei(z, s, "rechts") and raetsel.frage_bei(z, s, "unten")
    )
    return {
        "woerter": len(raetsel.fragen),
        "leeranteil": round(leer / felder, 3),
        "buchstabenanteil": round(len(buchstaben) / felder, 3),
        "kreuzanteil": round(gekreuzt / max(1, len(buchstaben)), 3),
    }


# ---------------------------------------------------------------------------
# Spiellogik
# ---------------------------------------------------------------------------


@dataclass
class Spiel:
    raetsel: Raetsel
    eintraege: dict[tuple[int, int], str] = field(default_factory=dict)
    cursor: tuple[int, int] | None = None
    richtung: str = "rechts"
    aufgedeckt: set[tuple[int, int]] = field(default_factory=set)
    markiert: set[tuple[int, int]] = field(default_factory=set)  # von „prüfen“ als falsch markiert
    hilfen: int = 0
    unsicher: set[tuple[int, int]] = field(default_factory=set)  # mit Bleistift eingetragen
    bleistift: bool = False

    @staticmethod
    def neu(raetsel: Raetsel, starthilfe: bool = False) -> "Spiel":
        """starthilfe: Anfangsbuchstabe jedes Wortes ist vorgegeben (gesperrt, zählt nicht als Hilfe)."""
        spiel = Spiel(raetsel)
        if starthilfe:
            for f in raetsel.fragen:
                z, s = raetsel.wortfelder(f)[0]
                spiel.eintraege[(z, s)] = raetsel.gitter[z][s]
                spiel.aufgedeckt.add((z, s))
        erste = raetsel.sortierte_fragen()[0]
        spiel._springe_zu_frage(erste)
        return spiel

    # -- abgeleitete Werte ---------------------------------------------------
    def aktive_frage(self) -> Frage | None:
        if self.cursor is None:
            return None
        return self.raetsel.frage_bei(*self.cursor, self.richtung)

    def aktive_felder(self) -> list[tuple[int, int]]:
        frage = self.aktive_frage()
        return self.raetsel.wortfelder(frage) if frage else []

    def falsche_felder(self) -> list[tuple[int, int]]:
        """Felder mit Eintrag, der nicht zur Lösung passt (für „Fehler sofort zeigen“)."""
        return sorted(
            feld for feld, b in self.eintraege.items() if b != self.raetsel.gitter[feld[0]][feld[1]]
        )

    def status(self) -> str:
        """'laeuft' | 'voll_mit_fehlern' | 'geloest'."""
        felder = self.raetsel.buchstabenfelder()
        if any(feld not in self.eintraege for feld in felder):
            return "laeuft"
        if self.falsche_felder():
            return "voll_mit_fehlern"
        return "geloest"

    def fortschritt(self) -> float:
        felder = self.raetsel.buchstabenfelder()
        return round(sum(1 for f in felder if f in self.eintraege) / len(felder), 3)

    # -- Aktionen ------------------------------------------------------------
    def tippe(self, z: int, s: int) -> None:
        r = self.raetsel
        if r.ist_buchstabe(z, s):
            if self.cursor == (z, s):
                andere = "unten" if self.richtung == "rechts" else "rechts"
                if r.frage_bei(z, s, andere):
                    self.richtung = andere
                return
            self.cursor = (z, s)
            if not r.frage_bei(z, s, self.richtung):
                self.richtung = "unten" if self.richtung == "rechts" else "rechts"
            return
        fragen = r.fragen_im_feld(z, s)
        if not fragen:
            return  # Leerfeld oder Rand: nichts passiert
        ziel = fragen[0]
        if len(fragen) == 2 and self.aktive_frage() == fragen[0]:
            ziel = fragen[1]
        self._springe_zu_frage(ziel)

    def buchstabe(self, zeichen: str) -> None:
        for b in eingabe_zu_buchstaben(zeichen):
            if not self._setze(b):
                break  # Wortende erreicht: Rest von „AE“ usw. verfällt

    def loeschen(self) -> None:
        if self.cursor is None:
            return
        if self.cursor in self.eintraege and self.cursor not in self.aufgedeckt:
            self._leere(self.cursor)
            return
        felder = self.aktive_felder()
        i = felder.index(self.cursor)
        if i > 0:
            self.cursor = felder[i - 1]
            if self.cursor not in self.aufgedeckt:
                self._leere(self.cursor)

    def naechste_frage(self, schritt: int = 1) -> None:
        fragen = self.raetsel.sortierte_fragen()
        aktiv = self.aktive_frage()
        i = fragen.index(aktiv) if aktiv in fragen else -1
        self._springe_zu_frage(fragen[(i + schritt) % len(fragen)])

    def buchstabe_aufdecken(self) -> None:
        if self.cursor is None or self.cursor in self.aufgedeckt:
            return
        z, s = self.cursor
        self.eintraege[self.cursor] = self.raetsel.gitter[z][s]
        self.aufgedeckt.add(self.cursor)
        self.markiert.discard(self.cursor)
        self.unsicher.discard(self.cursor)
        self.hilfen += 1

    def wort_aufdecken(self) -> None:
        """Alle noch nicht aufgedeckten Felder des aktiven Wortes bekommen die Lösung (gesperrt). Hilfen +1,
        nur wenn sich etwas ändert. Der Cursor springt danach wie nach einem vollen Wort (nächste Lücke)."""
        felder = [f for f in self.aktive_felder() if f not in self.aufgedeckt]
        if not felder:
            return
        for z, s in felder:
            self.eintraege[(z, s)] = self.raetsel.gitter[z][s]
            self.aufgedeckt.add((z, s))
            self.markiert.discard((z, s))
            self.unsicher.discard((z, s))
        self.hilfen += 1
        fragen = self.raetsel.sortierte_fragen()
        start = fragen.index(self.aktive_frage())
        for k in range(1, len(fragen) + 1):
            f = fragen[(start + k) % len(fragen)]
            if any(feld not in self.eintraege for feld in self.raetsel.wortfelder(f)):
                self._springe_zu_frage(f)
                break

    def wort_pruefen(self) -> int:
        falsch = [f for f in self.aktive_felder() if f in self.eintraege and f in set(self.falsche_felder())]
        self.markiert.update(falsch)
        self.hilfen += 1
        return len(falsch)

    def raetsel_pruefen(self) -> int:
        falsch = self.falsche_felder()
        self.markiert.update(falsch)
        self.hilfen += 1
        return len(falsch)

    # -- intern --------------------------------------------------------------
    def _springe_zu_frage(self, frage: Frage) -> None:
        felder = self.raetsel.wortfelder(frage)
        self.richtung = frage.richtung
        self.cursor = next((f for f in felder if f not in self.eintraege), felder[0])

    def bleistift_umschalten(self) -> None:
        self.bleistift = not self.bleistift

    def _setze(self, b: str) -> bool:
        """Schreibt b und bewegt den Cursor (kluger Cursor). False = Rest einer Mehrfacheingabe verfällt.

        - Wort war schon voll (Korrektur): Cursor ein Feld weiter im Wort, am Ende bleibt er stehen.
        - Sonst: Cursor aufs nächste leere Feld im Wort (hinter der Position, sonst das erste leere).
        - Ist das Wort danach voll: Sprung zur nächsten Frage (Sortierreihenfolge, ringförmig) mit Lücke,
          Cursor auf deren erstes leeres Feld. Gibt es keine Lücke mehr, bleibt der Cursor stehen.
        """
        if self.cursor is None:
            return False
        felder = self.aktive_felder()
        i = felder.index(self.cursor)
        while i < len(felder) and felder[i] in self.aufgedeckt:
            i += 1  # aufgedeckte Felder sind gesperrt und werden übersprungen
        if i == len(felder):
            return False
        war_voll = all(f in self.eintraege for f in felder)
        self.eintraege[felder[i]] = b
        self.markiert.discard(felder[i])
        if self.bleistift:
            self.unsicher.add(felder[i])
        else:
            self.unsicher.discard(felder[i])
        if war_voll:
            self.cursor = felder[min(i + 1, len(felder) - 1)]
            return i + 1 < len(felder)
        leer = [j for j, f in enumerate(felder) if f not in self.eintraege]
        if leer:
            danach = [j for j in leer if j > i]
            self.cursor = felder[danach[0] if danach else leer[0]]
            return True
        self.cursor = felder[i]
        fragen = self.raetsel.sortierte_fragen()
        start = fragen.index(self.aktive_frage())
        for k in range(1, len(fragen) + 1):
            f = fragen[(start + k) % len(fragen)]
            if any(feld not in self.eintraege for feld in self.raetsel.wortfelder(f)):
                self._springe_zu_frage(f)
                break
        return False

    def _leere(self, feld: tuple[int, int]) -> None:
        self.eintraege.pop(feld, None)
        self.markiert.discard(feld)
        self.unsicher.discard(feld)

    # -- Zustand für Testfälle -----------------------------------------------
    def zustand(self) -> dict:
        r = self.raetsel
        zeilen = []
        for z in range(r.hoehe):
            zeile = ""
            for s in range(r.breite):
                if r.ist_buchstabe(z, s):
                    zeile += self.eintraege.get((z, s), ".")
                else:
                    zeile += r.gitter[z][s]
            zeilen.append(zeile)
        aktiv = self.aktive_frage()
        return {
            "eintraege": zeilen,
            "cursor": list(self.cursor) if self.cursor else None,
            "richtung": self.richtung,
            "aktiveFrage": [aktiv.zeile, aktiv.spalte, aktiv.richtung] if aktiv else None,
            "aufgedeckt": sorted([list(f) for f in self.aufgedeckt]),
            "markiert": sorted([list(f) for f in self.markiert]),
            "hilfen": self.hilfen,
            "unsicher": sorted([list(f) for f in self.unsicher]),
            "bleistift": self.bleistift,
            "status": self.status(),
            **({"loesung": "".join(self.eintraege.get(f, ".") for f in self.raetsel.loesung)}
               if self.raetsel.loesung else {}),
        }


# ---------------------------------------------------------------------------
# Tagesrätsel und Serie
# ---------------------------------------------------------------------------


def tagesindex(datum: _dt.date, anzahl: int) -> int:
    """Index im Tagespaket: Tage seit 01.01.2026, immer positiv modulo anzahl."""
    return (datum - TAGES_START).days % anzahl


def serie(geloeste_tage: list[_dt.date], heute: _dt.date) -> int:
    """Aktuelle Serie gelöster Tagesrätsel. Heute noch offen bricht die Serie nicht."""
    tage = set(geloeste_tage)
    tag = heute if heute in tage else heute - _dt.timedelta(days=1)
    n = 0
    while tag in tage:
        n += 1
        tag -= _dt.timedelta(days=1)
    return n


# ---------------------------------------------------------------------------
# Erfolge (lokal, ohne Konto) – Testfälle: erfolge.json
# ---------------------------------------------------------------------------

STUFEN = ("leicht", "mittel", "schwer")

# id → (Name DE, Name EN, Bedingung als Funktion über die Statistik)
ERFOLGE = {
    "erstes_raetsel": ("Erstes Rätsel", "First puzzle", lambda s: _summe(s, "geloest") >= 1),
    "zehn_raetsel": ("Zehn gelöst", "Ten solved", lambda s: _summe(s, "geloest") >= 10),
    "hundert_raetsel": ("Hundert gelöst", "One hundred solved", lambda s: _summe(s, "geloest") >= 100),
    "ohne_hilfe": ("Ganz allein", "No help needed", lambda s: _summe(s, "ohneHilfe") >= 1),
    "ohne_hilfe_25": ("Rätselprofi", "Puzzle pro", lambda s: _summe(s, "ohneHilfe") >= 25),
    "erstes_schwer": ("Mutig", "Brave", lambda s: s["geloest"].get("schwer", 0) >= 1),
    "serie_7": ("Eine Woche", "One week", lambda s: s.get("besteSerie", 0) >= 7),
    "serie_30": ("Ein Monat", "One month", lambda s: s.get("besteSerie", 0) >= 30),
    "tages_30": ("Treuer Gast", "Regular", lambda s: s.get("tagesGeloest", 0) >= 30),
    "blitz_leicht": ("Flink", "Quick", lambda s: 0 < s["bestzeit"].get("leicht", 0) <= 180),
    "blitz_mittel": ("Schnell", "Fast", lambda s: 0 < s["bestzeit"].get("mittel", 0) <= 420),
    "blitz_schwer": ("Blitz", "Lightning", lambda s: 0 < s["bestzeit"].get("schwer", 0) <= 900),
    "alle_leicht": ("Leicht gemeistert", "Easy mastered",
                    lambda s: s["geloest"].get("leicht", 0) >= s["paketgroesse"].get("leicht", 10**9)),
    "thema_1": ("Themenfreund", "Theme fan", lambda s: s.get("themenGeloest", 0) >= 1),
}


def _summe(s: dict, schluessel: str) -> int:
    return sum(s[schluessel].get(st, 0) for st in STUFEN)


def erfolge(statistik: dict) -> list[str]:
    """Alle erreichten Erfolge (ids, in fester Reihenfolge von ERFOLGE). Statistik-Felder siehe SPEZIFIKATION;
    fehlende Felder gelten als 0 bzw. leer."""
    s = {"geloest": {}, "ohneHilfe": {}, "bestzeit": {}, "paketgroesse": {}, **statistik}
    return [eid for eid, (_, _, bedingung) in ERFOLGE.items() if bedingung(s)]


# ---------------------------------------------------------------------------
# Stufen-Empfehlung („Lernkurve“) – Testfälle: empfehlung.json
# ---------------------------------------------------------------------------

def empfehlung(stufe: str, letzte: list[dict]) -> str | None:
    """Empfiehlt eine andere Stufe nach den letzten gelösten Rätseln DIESER Stufe (neueste zuletzt,
    je {"hilfen": n}). Drei in Folge ohne Hilfe → nächstschwerere Stufe; drei in Folge mit je ≥ 3 Hilfen →
    nächstleichtere. Sonst None. Schwer empfiehlt nie „schwerer“, Leicht nie „leichter“."""
    if len(letzte) < 3:
        return None
    drei = letzte[-3:]
    i = STUFEN.index(stufe)
    if all(r.get("hilfen", 0) == 0 for r in drei) and i < 2:
        return STUFEN[i + 1]
    if all(r.get("hilfen", 0) >= 3 for r in drei) and i > 0:
        return STUFEN[i - 1]
    return None
