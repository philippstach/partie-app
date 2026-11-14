#!/usr/bin/env python3
"""Baut den Wortbestand inhalt/woerter.tsv neu auf (Stand 11/2026, Ziel: nur bekannte, familientaugliche Wörter).

Quellen, in dieser Reihenfolge:
  inhalt/alt/woerter-alt.tsv          alter Bestand (8.069 Wörter, Oktober 2026)
  inhalt/auswahl/stufe3-behalten.txt  Stufe-3-Wörter, die bleiben (alle anderen Stufe-3-Wörter fallen weg)
  inhalt/auswahl/streichen.txt        weitere gestrichene Wörter
  inhalt/korrektur/*.tsv              Wort <TAB> Stufe <TAB> Fragen  → ersetzt Stufe und ALLE Fragen des Wortes
  inhalt/neu/*.txt                    neue Wörter (Wort;Stufe;Frage|Frage); bei vorhandenem Wort werden Fragen ergänzt

Aufruf (im Ordner Werkzeug/wortpfeil):  python3 bestand.py        danach: python3 inhalt.py pruefen inhalt/woerter.tsv
"""
import glob, os, sys
from kreuzwort import normalisiere
from inhalt import stamm_in_frage

HIER = os.path.dirname(os.path.abspath(__file__))
I = os.path.join(HIER, "inhalt")
MAX_FRAGEN = 7


def zeilen(pfad):
    with open(pfad, encoding="utf-8") as d:
        for z in d:
            z = z.rstrip("\n")
            if z.strip() and not z.startswith("#"):
                yield z


def wortmenge(pfad):
    aus = {}
    for z in zeilen(pfad):
        for teil in z.split():
            w, _, st = teil.partition("=")
            aus[normalisiere(w)] = int(st) if st else None
    return aus


def baue():
    behalten = wortmenge(os.path.join(I, "auswahl", "stufe3-behalten.txt"))
    streichen = wortmenge(os.path.join(I, "auswahl", "streichen.txt"))
    bestand, weg = {}, 0
    for z in zeilen(os.path.join(I, "alt", "woerter-alt.tsv")):
        roh, stufe, fragen = z.split("\t")
        w, stufe = normalisiere(roh), int(stufe)
        if w in streichen or (stufe == 3 and w not in behalten):
            weg += 1
            continue
        if behalten.get(w):
            stufe = behalten[w]
        bestand[w] = [roh, stufe, [f.strip() for f in fragen.split("|") if f.strip()]]
    alt = len(bestand)
    korr = 0
    for pfad in sorted(glob.glob(os.path.join(I, "korrektur", "*.tsv"))):
        for z in zeilen(pfad):
            roh, stufe, fragen = z.split("\t")
            w = normalisiere(roh)
            if w not in bestand:
                sys.exit(f"{os.path.basename(pfad)}: {roh} ist nicht im Bestand")
            bestand[w] = [roh, int(stufe), [f.strip() for f in fragen.split("|") if f.strip()]]
            korr += 1
    neu = 0
    doppelt = []
    ohne = []
    for pfad in sorted(glob.glob(os.path.join(I, "neu", "*.txt"))):
        for z in zeilen(pfad):
            try:
                roh, stufe, fragen = [t.strip() for t in z.split(";", 2)]
            except ValueError:
                sys.exit(f"{os.path.basename(pfad)}: Zeile ohne 3 Spalten: {z}")
            w = normalisiere(roh)
            alle = [f.strip() for f in fragen.split("|") if f.strip()]
            # Sicherheitsnetz: Fragen mit Lösungsstamm oder Überlänge fallen weg, wenn eine andere bleibt
            fr = [f for f in alle if len(f) <= 30 and not stamm_in_frage(w, f)]
            if not fr:
                ohne.append(f"{roh}: {' | '.join(alle)}")
                continue
            if w in streichen:
                continue
            if w in bestand:
                doppelt.append(roh)
                e = bestand[w]
                e[1] = min(e[1], int(stufe))
                e[2] += [f for f in fr if f not in e[2]]
                e[2] = e[2][:MAX_FRAGEN]
            else:
                bestand[w] = [roh, int(stufe), fr]
                neu += 1
    with open(os.path.join(I, "woerter.tsv"), "w", encoding="utf-8") as d:
        d.write("# Wortbestand Kreuzworträtsel – erzeugt mit bestand.py, nicht von Hand ändern\n")
        for w in sorted(bestand):
            roh, stufe, fr = bestand[w]
            d.write(f"{roh}\t{stufe}\t{'|'.join(fr)}\n")
    for o in ohne:
        print("OHNE GÜLTIGE FRAGE:", o)
    if "-v" in sys.argv:
        print("schon vorhanden:", " ".join(doppelt))
    kurz = sum(1 for w in bestand if len(w) <= 8)
    print(f"alt behalten {alt} (gestrichen {weg}) · korrigiert {korr} · neu {neu} · gesamt {len(bestand)} · davon 2–8 Buchstaben {kurz}")
    return bestand


if __name__ == "__main__":
    baue()
