#!/usr/bin/env python3
"""regellesen_erzeugen.py (Bauplan RL-K): macht aus plan/regeln-neu/<id>/regeln.md je Spiel App/RegelLesen/RegelLeseText_<id>.swift
und die Tabelle App/RegelLesen/RegelLeseTabelle.swift. Nur der Teil ab der ersten Zeile „## “ kommt hinein, „---“ fällt weg, Backticks fallen weg.
Vor Tabellen mit 3 oder mehr Spalten steht eine Zeile „@form A|B|C“ (A: kurze Zellen, B: Spalte „Standard“, C: übrige).
Aufruf aus dem Projektordner:  python3 Werkzeug/regellesen_erzeugen.py [/mnt/project-files/plan/regeln-neu]"""
import os, re, sys

QUELLE = sys.argv[1] if len(sys.argv) > 1 else '/mnt/project-files/plan/regeln-neu'
ZIEL = 'App/RegelLesen'
IDS = ["solitaer", "maumau", "schwimmen", "elferraus", "romme", "mogeln", "siebzehnundvier", "herzensjagd", "yacht", "schocken", "10k", "maexchen",
       "chicago", "pokerwurf", "koenigsweg", "sudoku", "minensuche", "kakuro", "schiebepuzzle", "irrgang", "farbflut", "viererreihe", "rauswurf",
       "muehle", "galgenmaennchen", "wortpfeil"]

def zellen(zeile):
    z = zeile.strip().strip('|')
    return [c.strip() for c in z.split('|')]

def ist_trenner(zeile):
    return all(re.fullmatch(r':?-{2,}:?', c) for c in zellen(zeile))

def bearbeiten(text):
    i = text.find('\n## ')
    text = text[i + 1:] if i >= 0 else text
    aus, zeilen, n = [], text.split('\n'), 0
    while n < len(zeilen):
        z = zeilen[n].replace('`', '')
        if z.strip() == '---': n += 1; continue
        if z.lstrip().startswith('|') and n + 1 < len(zeilen) and ist_trenner(zeilen[n + 1]):
            kopf = zellen(z); k = n + 2; reihen = []
            while k < len(zeilen) and zeilen[k].lstrip().startswith('|'): reihen.append(zellen(zeilen[k].replace('`', ''))); k += 1
            if len(kopf) >= 3:
                alle = [c for r in reihen for c in r] + kopf
                form = 'B' if kopf[1].lower().startswith('standard') else ('A' if max(len(c) for c in alle) <= 14 else 'C')
                aus.append('@form ' + form)
            aus.append(z)
            aus.append('|' + '|'.join('---' for _ in kopf) + '|')
            aus += ['|' + ' | '.join(r) + ' |' for r in reihen]
            n = k; continue
        aus.append(z); n += 1
    return re.sub(r'\n{3,}', '\n\n', '\n'.join(aus)).strip() + '\n'

os.makedirs(ZIEL, exist_ok=True)
tab = []
for sid in IDS:
    pfad = os.path.join(QUELLE, sid, 'regeln.md')
    if not os.path.exists(pfad): print('fehlt:', pfad); continue
    text = bearbeiten(open(pfad, encoding='utf-8').read())
    assert '"""#' not in text
    open(os.path.join(ZIEL, f'RegelLeseText_{sid}.swift'), 'w', encoding='utf-8').write(
        f'// Erzeugt von Werkzeug/regellesen_erzeugen.py aus plan/regeln-neu/{sid}/regeln.md. Nicht von Hand ändern.\nenum RegelLeseText_{sid} {{\n    static let quelle = #"""\n{text}"""#\n}}\n')
    tab.append(f'        "{sid}": RegelLeseText_{sid}.quelle,')
open(os.path.join(ZIEL, 'RegelLeseTabelle.swift'), 'w', encoding='utf-8').write(
    '// Erzeugt von Werkzeug/regellesen_erzeugen.py. Nicht von Hand ändern.\nenum RegelLeseTabelle {\n    static let eintraege: [String: String] = [\n' + '\n'.join(tab) + '\n    ]\n}\n')
print(len(tab), 'Spiele')
