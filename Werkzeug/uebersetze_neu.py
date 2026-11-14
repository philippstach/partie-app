#!/usr/bin/env python3
"""Fügt neue Übersetzungen (en, es, fr) in App/Ressourcen/Localizable.xcstrings ein, ohne bestehende Einträge zu ändern.
Aufruf: uebersetze_neu.py 'Schlüssel=en|es|fr' ..."""
import json, sys
p = 'App/Ressourcen/Localizable.xcstrings'
d = json.loads(open(p).read())
for a in sys.argv[1:]:
    k, v = a.split('=', 1); en, es, fr = v.split('|')
    if k in d['strings'] and 'localizations' in d['strings'][k] and 'fr' in d['strings'][k]['localizations']: continue
    d['strings'][k] = {"localizations": {l: {"stringUnit": {"state": "translated", "value": x}} for l, x in zip(["en", "es", "fr"], [en, es, fr])}}
open(p, 'w').write(json.dumps(d, ensure_ascii=False, indent=2) + "\n")
