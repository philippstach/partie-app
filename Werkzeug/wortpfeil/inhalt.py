"""Werkzeug für den Wortbestand (Ablauf: Doku/SPEZIFIKATION.md, Abschnitt „Inhalte erzeugen“).

Aufruf (im Ordner Referenz/):
  python3 inhalt.py pruefen [datei.tsv …]   automatische Prüfung (Standard: alle Stapel)
  python3 inhalt.py zusammenfuehren         Stapel + Prüfurteile → inhalt/woerter.tsv
  python3 inhalt.py stichprobe <n>          100 zufällige Fragen → Doku/STICHPROBE-<n>.md
  python3 inhalt.py statistik               Mengen nach Stufe und Länge
"""
from __future__ import annotations

import glob
import os
import random
import re
import subprocess
import sys
from collections import Counter

from kreuzwort import MAX_FRAGENLAENGE, normalisiere

HIER = os.path.dirname(os.path.abspath(__file__))
INHALT = os.path.join(HIER, "inhalt")
STAPEL = os.path.join(INHALT, "stapel")
PRUEFUNG = os.path.join(INHALT, "pruefung")
BESTAND = os.path.join(INHALT, "woerter.tsv")
DOKU = os.path.join(HIER, "..", "Doku")

MIN_LAENGE, MAX_LAENGE = 2, 14
_OHNE_UMLAUT = str.maketrans("ÄÖÜäöü", "AOUaou")
MAX_FRAGEN = 7  # 3 aus dem Stapel + Kurzfrage + Mini-Fragen (≤ 8 und ≤ 7 Zeichen)


# ---------------------------------------------------------------------------
def lies_tsv(pfad: str) -> list[list[str]]:
    zeilen = []
    with open(pfad, encoding="utf-8") as datei:
        for nr, zeile in enumerate(datei, 1):
            zeile = zeile.rstrip("\n")
            if zeile.strip() and not zeile.startswith("#"):
                zeilen.append([nr] + zeile.split("\t"))
    return zeilen


def unbekannte_woerter(woerter: set[str]) -> set[str]:
    """Wörter, die die macOS-Rechtschreibprüfung nicht kennt (leer, falls swift fehlt)."""
    if not woerter:
        return set()
    try:
        ergebnis = subprocess.run(
            ["swift", os.path.join(INHALT, "rechtschreibung.swift")],
            input="\n".join(sorted(woerter)), capture_output=True, text=True, timeout=600,
        )
    except (FileNotFoundError, subprocess.TimeoutExpired):
        print("Hinweis: Rechtschreibprüfung nicht verfügbar (swift fehlt)")
        return set()
    return set(ergebnis.stdout.split())


def stamm_in_frage(wort: str, frage: str) -> bool:
    """Lösungswort oder Wortstamm (erste 4 Buchstaben) steckt in der Frage."""
    n = normalisiere(frage)
    if len(wort) >= 4:
        return wort[:4] in n
    return any(normalisiere(t) == wort for t in re.split(r"[\s,;:.()/-]+", frage))


# ---------------------------------------------------------------------------
def pruefe_dateien(dateien: list[str], rechtschreibung: bool = True) -> tuple[list[str], list[str]]:
    """Gibt (Fehler, Hinweise) zurück. Fehler blockieren das Zusammenführen."""
    fehler, hinweise = [], []
    gesehen: dict[str, str] = {}
    fragewoerter: set[str] = set()
    woerter: set[str] = set()
    for pfad in dateien:
        name = os.path.basename(pfad)
        for nr, *spalten in lies_tsv(pfad):
            ort = f"{name}:{nr}"
            if len(spalten) != 3:
                fehler.append(f"{ort}: braucht 3 Spalten (Wort, Stufe, Fragen), hat {len(spalten)}")
                continue
            roh, stufe, fragen_text = spalten
            wort = normalisiere(roh)
            if not MIN_LAENGE <= len(wort) <= MAX_LAENGE:
                fehler.append(f"{ort}: {roh} hat {len(wort)} Buchstaben (erlaubt {MIN_LAENGE}–{MAX_LAENGE})")
            if stufe not in ("1", "2", "3"):
                fehler.append(f"{ort}: {roh} Stufe '{stufe}' (erlaubt 1–3)")
            if " " in roh.strip() or "-" in roh:
                fehler.append(f"{ort}: {roh} enthält Leerzeichen oder Bindestrich")
            if wort in gesehen:
                hinweise.append(f"{ort}: {roh} kommt schon in {gesehen[wort]} vor (Fragen werden zusammengeführt)")
            gesehen.setdefault(wort, ort)
            woerter.add(roh.strip())
            fragen = [f.strip() for f in fragen_text.split("|") if f.strip()]
            if not 1 <= len(fragen) <= MAX_FRAGEN:
                fehler.append(f"{ort}: {roh} hat {len(fragen)} Fragen (erlaubt 1–{MAX_FRAGEN})")
            for frage in fragen:
                if len(frage) > MAX_FRAGENLAENGE:
                    fehler.append(f"{ort}: Frage zu lang ({len(frage)}): {frage}")
                elif len(frage) > 20:
                    hinweise.append(f"{ort}: Frage über 20 Zeichen: {frage}")
                if stamm_in_frage(wort, frage):
                    fehler.append(f"{ort}: Lösung/Wortstamm in der Frage: {roh} – {frage}")
                elif len(wort) >= 4 and wort[:4] in normalisiere(frage.translate(_OHNE_UMLAUT)):
                    hinweise.append(f"{ort}: Wortstamm steckt über Umlaut in der Frage: {roh} – {frage}")
                elif len(wort) < 4 and wort in normalisiere(frage):
                    hinweise.append(f"{ort}: Lösung steckt evtl. in einem Wort der Frage: {roh} – {frage}")
                if re.match(r"(der|die|das|ein|eine|einer|eines|dem|den)\s", frage, re.IGNORECASE):
                    hinweise.append(f"{ort}: Frage beginnt mit Artikel: {frage}")
                for teil in re.findall(r"[A-Za-zÄÖÜäöüß]+", frage):
                    if len(teil) > 2:
                        fragewoerter.add(teil)
    if rechtschreibung:
        unbekannt = unbekannte_woerter(woerter | fragewoerter)
        for w in sorted(unbekannt & woerter):
            hinweise.append(f"Rechtschreibung kennt das Lösungswort nicht (Sichtprüfung): {w}")
        for w in sorted(unbekannt & (fragewoerter - woerter)):
            hinweise.append(f"Rechtschreibung kennt ein Wort in einer Frage nicht: {w}")
    return fehler, hinweise


def stapel_dateien() -> list[str]:
    return sorted(glob.glob(os.path.join(STAPEL, "*.tsv")))


def befehl_pruefen(args: list[str]) -> int:
    dateien = args or stapel_dateien()
    fehler, hinweise = pruefe_dateien(dateien)
    for h in hinweise:
        print("Hinweis:", h)
    for f in fehler:
        print("FEHLER: ", f)
    print(f"\n{len(dateien)} Datei(en) · {len(fehler)} Fehler · {len(hinweise)} Hinweise")
    return 1 if fehler else 0


# ---------------------------------------------------------------------------
def befehl_zusammenfuehren() -> int:
    """Wendet die Prüfurteile an. Stapel ohne vollständige Prüfung werden ausgelassen."""
    bestand: dict[str, dict] = {}
    for pfad in stapel_dateien():
        name = os.path.basename(pfad)
        pruefpfad = os.path.join(PRUEFUNG, name)
        if not os.path.exists(pruefpfad):
            print(f"übersprungen (noch nicht geprüft): {name}")
            continue
        urteile = {}
        for nr, *sp in lies_tsv(pruefpfad):
            if len(sp) < 2 or sp[1] not in ("ok", "aendern", "streichen"):
                print(f"FEHLER {name} Prüfung Zeile {nr}: Urteil muss ok/aendern/streichen sein")
                return 1
            urteile[normalisiere(sp[0])] = sp
        zeilen_stapel = lies_tsv(pfad)
        fehlend = [roh for _, roh, *_ in zeilen_stapel if normalisiere(roh) not in urteile]
        if fehlend:
            # Prüfung noch nicht komplett (läuft evtl. gerade) → ganzen Stapel auslassen, nie halb übernehmen
            print(f"übersprungen (Prüfung unvollständig, {len(fehlend)} Wörter ohne Urteil): {name}")
            continue
        for _, roh, stufe, fragen_text in zeilen_stapel:
            wort = normalisiere(roh)
            urteil = urteile[wort]
            if urteil[1] == "streichen":
                continue
            if urteil[1] == "aendern":
                fragen_text = urteil[2] if len(urteil) > 2 and urteil[2].strip() else fragen_text
            fragen = [f.strip() for f in fragen_text.split("|") if f.strip()]
            if len(urteil) > 4 and urteil[4].strip() in ("1", "2", "3"):
                stufe = urteil[4].strip()  # Prüfer hat die Stufe korrigiert
            eintrag = bestand.setdefault(wort, {"roh": roh.strip(), "stufe": int(stufe), "fragen": []})
            eintrag["stufe"] = min(eintrag["stufe"], int(stufe))
            for f in fragen:
                if f not in eintrag["fragen"] and len(eintrag["fragen"]) < MAX_FRAGEN:
                    eintrag["fragen"].append(f)
    zeilen = [f"{e['roh']}\t{e['stufe']}\t{'|'.join(e['fragen'])}" for _, e in sorted(bestand.items())]
    kopf = "# Wortbestand Kreuzworträtsel – erzeugt mit inhalt.py zusammenfuehren, nicht von Hand ändern\n"
    with open(BESTAND, "w", encoding="utf-8") as datei:
        datei.write(kopf + "\n".join(zeilen) + "\n")
    fehler, _ = pruefe_dateien([BESTAND], rechtschreibung=False)
    for f in fehler:
        print("FEHLER: ", f)
    print(f"{len(zeilen)} Wörter → {os.path.relpath(BESTAND, HIER)}")
    return 1 if fehler else 0


# ---------------------------------------------------------------------------
def befehl_stichprobe(n: int) -> int:
    paare = [(roh, stufe, f) for _, roh, stufe, fr in lies_tsv(BESTAND) for f in fr.split("|")]
    auswahl = random.Random(n).sample(paare, min(100, len(paare)))
    zeilen = [
        f"# Stichprobe {n} – Fragen prüfen",
        "",
        "Für Philipp: Bei jeder Zeile, die **nicht** stimmt oder holpert, ein `x` in die letzte Spalte und kurz warum.",
        "Mehr als 3 Fehler in 100 → die betroffenen Stapel werden neu geprüft.",
        "",
        "| Nr | Frage | Lösung | Stufe | Fehler? |",
        "|---|---|---|---|---|",
    ]
    zeilen += [f"| {i} | {f} | {roh} | {st} |  |" for i, (roh, st, f) in enumerate(auswahl, 1)]
    ziel = os.path.join(DOKU, f"STICHPROBE-{n}.md")
    with open(ziel, "w", encoding="utf-8") as datei:
        datei.write("\n".join(zeilen) + "\n")
    print(f"{len(auswahl)} Fragen → Doku/STICHPROBE-{n}.md")
    return 0


def befehl_statistik() -> int:
    pfad = BESTAND if os.path.exists(BESTAND) else None
    dateien = [pfad] if pfad else stapel_dateien()
    stufen, laengen, gesamt = Counter(), Counter(), 0
    for d in dateien:
        for _, roh, stufe, _ in lies_tsv(d):
            gesamt += 1
            stufen[stufe] += 1
            n = len(normalisiere(roh))
            laengen["2–5" if n <= 5 else "6–8" if n <= 8 else "9+"] += 1
    print(f"Quelle: {'woerter.tsv' if pfad else 'Stapel (ungeprüft)'} · {gesamt} Wörter")
    print("Stufen:", dict(sorted(stufen.items())), "· Längen:", dict(laengen))
    return 0


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(2)
    befehl, rest = sys.argv[1], sys.argv[2:]
    if befehl == "pruefen":
        sys.exit(befehl_pruefen(rest))
    if befehl == "zusammenfuehren":
        sys.exit(befehl_zusammenfuehren())
    if befehl == "stichprobe":
        sys.exit(befehl_stichprobe(int(rest[0]) if rest else 1))
    if befehl == "statistik":
        sys.exit(befehl_statistik())
    print(__doc__)
    sys.exit(2)
