#!/usr/bin/env python3
"""grundfehler_strings.py: de/en/es/fr für die neuen Texte der Einzelspiel-Ausgänge (S1: Niederlage, Punktespiel).
Überschreibt nie vorhandene Übersetzungen. Aufruf aus dem Projektordner."""
import json
KAT = 'App/Ressourcen/Localizable.xcstrings'
U = {
"Partie beendet": ("Game finished", "Partida terminada", "Partie terminée"),
"%@: Partie beendet": ("%@: Game finished", "%@: Partida terminada", "%@ : partie terminée"),
"gespielt": ("played", "jugado", "joué"),
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
