#!/usr/bin/env python3
"""design_grosse_runde_k_strings.py: de/en/es/fr für die neuen Texte der großen Tinte-Runde, Paket K (Spielseite: laufende Partie). Idempotent, überschreibt nichts. Aufruf aus dem Projektordner."""
import json
KAT = 'App/Ressourcen/Localizable.xcstrings'
U = {
"Laufende Partie": ("Game in progress", "Partida en curso", "Partie en cours"),
"Neue Partie beginnen": ("Start a new game", "Empezar una partida nueva", "Commencer une nouvelle partie"),
}
cat = json.load(open(KAT)); s = cat['strings']; n = 0
for k, t in U.items():
    loc = s.setdefault(k, {}).setdefault('localizations', {})
    if 'en' in loc and 'fr' in loc: continue
    loc.setdefault('de', {"stringUnit": {"state": "translated", "value": k}})
    for sp, v in zip(('en', 'es', 'fr'), t): loc.setdefault(sp, {"stringUnit": {"state": "translated", "value": v}})
    n += 1
orig = open(KAT).read()
open(KAT, 'w').write(json.dumps(cat, ensure_ascii=False, indent=2, separators=(',', ': ')) + ('\n' if orig.endswith('\n') else ''))
print('eingetragen:', n)
