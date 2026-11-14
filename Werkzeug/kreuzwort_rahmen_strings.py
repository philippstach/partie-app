#!/usr/bin/env python3
"""kreuzwort_rahmen_strings.py: en/es/fr für die neuen Texte des Kreuzworträtsels im SpielRahmen und der Rückfrage beim Direktstart.
Überschreibt nie vorhandene Übersetzungen. Aufruf aus dem Projektordner."""
import json
KAT = 'App/Ressourcen/Localizable.xcstrings'
U = {
"Laufende Partie verwerfen?": ("Discard the game in progress?", "¿Descartar la partida en curso?", "Abandonner la partie en cours ?"),
"Archiv und Zeiten": ("Archive and times", "Archivo y tiempos", "Archives et temps"),
"Fragen im Gitter, Pfeile zeigen den Weg.": ("Clues inside the grid, arrows show the way.", "Las pistas están en la cuadrícula, las flechas indican el camino.", "Les définitions sont dans la grille, les flèches montrent le chemin."),
}
cat = json.load(open(KAT)); s = cat['strings']
n = 0
for k, t in U.items():
    loc = s.setdefault(k, {}).setdefault('localizations', {})
    if 'en' in loc and 'fr' in loc: continue
    loc.setdefault('de', {"stringUnit": {"state": "translated", "value": k}})
    for sp, v in zip(('en', 'es', 'fr'), t): loc[sp] = {"stringUnit": {"state": "translated", "value": v}}
    n += 1
orig = open(KAT).read()
open(KAT, 'w').write(json.dumps(cat, ensure_ascii=False, indent=2, separators=(',', ': ')) + ('\n' if orig.endswith('\n') else ''))
print('eingetragen:', n)
