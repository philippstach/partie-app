#!/usr/bin/env python3
"""design_runde5_rl_strings.py: neuer Text „Inhalt“ (Blatt 26, Bauplan RL). Aufruf aus dem Projektordner."""
import json
KAT = 'App/Ressourcen/Localizable.xcstrings'
cat = json.load(open(KAT)); s = cat['strings']
loc = s.setdefault('Inhalt', {}).setdefault('localizations', {})
for sp, v in {'de': 'Inhalt', 'en': 'Contents', 'es': 'Contenido', 'fr': 'Sommaire'}.items():
    loc.setdefault(sp, {"stringUnit": {"state": "translated", "value": v}})
orig = open(KAT).read()
open(KAT, 'w').write(json.dumps(cat, ensure_ascii=False, indent=2, separators=(',', ': ')) + ('\n' if orig.endswith('\n') else ''))
