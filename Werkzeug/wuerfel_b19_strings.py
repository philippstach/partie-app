#!/usr/bin/env python3
"""wuerfel_b19_strings.py: en/es/fr für neue Texte der Würfelspiele (Fix-Plan Build 19). Idempotent, überschreibt nie vorhandene Übersetzungen.
Aufruf aus dem Projektordner."""
import json
KAT = 'App/Ressourcen/Localizable.xcstrings'
U = {
"Computer würfelt …": ("Computer is throwing …", "Computer tira …", "L’ordinateur lance …"),
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
