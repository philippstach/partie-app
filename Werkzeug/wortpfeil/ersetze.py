#!/usr/bin/env python3
"""Hilfswerkzeug: ersetzt Fragetexte in inhalt/neu/*.txt und inhalt/korrektur/*.tsv.  Eingabe (stdin): alt => neu je Zeile."""
import glob, sys
paare = [z.rstrip("\n").split(" => ") for z in sys.stdin if " => " in z]
for pfad in glob.glob("inhalt/neu/*.txt") + glob.glob("inhalt/korrektur/*.tsv"):
    s = open(pfad, encoding="utf-8").read(); t = s
    for alt, neu in paare:
        t = t.replace(alt, neu)
    if t != s:
        open(pfad, "w", encoding="utf-8").write(t)
