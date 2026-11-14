#!/usr/bin/env python3
"""uebersetzungen_brett_ki.py: en/es/fr für die neuen VoiceOver-Texte von Backgammon. Überschreibt nie vorhandene Übersetzungen.
Aufruf aus dem Projektordner (Partie/Haupt)."""
import json
KAT = 'App/Ressourcen/Localizable.xcstrings'
U = {
"Punkt %lld, leer": ("Point %lld, empty", "Punto %lld, vacío", "Point %lld, vide"),
"Bar von %@: %lld": ("%@’s bar: %lld", "Barra de %@: %lld", "Barre de %@ : %lld"),
"kann ziehen": ("can move", "puede mover", "peut jouer"),
}
cat = json.load(open(KAT)); s = cat['strings']
n = 0
for k, t in U.items():
    loc = s.setdefault(k, {}).setdefault('localizations', {})
    if 'en' in loc: continue
    loc['de'] = {"stringUnit": {"state": "translated", "value": k}}
    for sp, v in zip(('en', 'es', 'fr'), t): loc[sp] = {"stringUnit": {"state": "translated", "value": v}}
    n += 1
orig = open(KAT).read()
open(KAT, 'w').write(json.dumps(cat, ensure_ascii=False, indent=2, separators=(',', ': ')) + ('\n' if orig.endswith('\n') else ''))
print('eingetragen:', n)
