#!/usr/bin/env python3
"""spielnamen_deutsch.py: Spielnamen bleiben in en/es/fr deutsch (Philipp 14.11., Funde 114/120/194). Aufruf aus dem Projektordner."""
import json
KAT = 'App/Ressourcen/Localizable.xcstrings'
N = "Solitär,Schwimmen,Rommé,Mogeln,Siebzehn und Vier,Zehntausend,Königsweg,Schiebepuzzle,Labyrinth,Farbfüller,Viererreihe,Mühle,Kreuzworträtsel".split(',')
cat = json.load(open(KAT)); s = cat['strings']; n = 0
for k in N:
    loc = s[k]['localizations']
    for l in ('en', 'es', 'fr'):
        if l in loc and loc[l].get('stringUnit', {}).get('value') != k:
            loc[l]['stringUnit']['value'] = k; n += 1
orig = open(KAT).read()
open(KAT, 'w').write(json.dumps(cat, ensure_ascii=False, indent=2, separators=(',', ': ')) + ('\n' if orig.endswith('\n') else ''))
print('geändert:', n)
