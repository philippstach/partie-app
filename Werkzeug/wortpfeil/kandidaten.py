#!/usr/bin/env python3
"""Zeigt, welche Kandidaten (stdin, durch Leerzeichen getrennt) noch nicht im Bestand sind und 2–8 Buchstaben haben."""
import sys
from kreuzwort import normalisiere
bestand = {normalisiere(z.split("\t")[0]) for z in open("inhalt/woerter.tsv", encoding="utf-8") if not z.startswith("#")}
neu, gesehen = [], set()
for w in sys.stdin.read().split():
    n = normalisiere(w)
    if 2 <= len(n) <= 8 and n not in bestand and n not in gesehen:
        gesehen.add(n); neu.append(w)
print(len(neu)); print(" ".join(neu))
