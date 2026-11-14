#!/usr/bin/env python3
"""spieleabend_start_strings.py: en/es/fr für die Texte von Spieleabend-Startkarte (Build 10). Überschreibt nie vorhandene Übersetzungen.
Aufruf aus dem Projektordner."""
import json
KAT = 'App/Ressourcen/Localizable.xcstrings'
U = {
"Spieleabend starten": ("Start a game night", "Empezar una noche de juegos", "Lancer une soirée jeux"),
"Mehrere Spiele, ein Sieger": ("Several games, one winner", "Varios juegos, un ganador", "Plusieurs jeux, un vainqueur"),
}
cat = json.load(open(KAT)); s = cat['strings']
n = 0
for k, t in U.items():
    loc = s.setdefault(k, {}).setdefault('localizations', {})
    if 'en' in loc and 'fr' in loc: continue
    for sp, v in zip(('en', 'es', 'fr'), t): loc[sp] = {"stringUnit": {"state": "translated", "value": v}}
    n += 1
orig = open(KAT).read()
open(KAT, 'w').write(json.dumps(cat, ensure_ascii=False, indent=2, separators=(',', ': ')) + ('\n' if orig.endswith('\n') else ''))
print('eingetragen:', n)
