#!/usr/bin/env python3
"""huelle_b19_strings.py: de/en/es/fr für die Hülle-Funde von Build 19 (Chat 5). Idempotent, überschreibt nichts. Aufruf aus dem Projektordner."""
import json
KAT = 'App/Ressourcen/Localizable.xcstrings'
U = {
"Design": ("Design", "Diseño", "Design"),
"Dein Name": ("Your name", "Tu nombre", "Ton prénom"),
"Foto und mehr kannst du später unter „Spieler“ ergänzen. Du kannst auch ganz darauf verzichten.": (
 "You can add a photo and more later under “Players”. You can also skip this entirely.",
 "Puedes añadir una foto y más después en «Jugadores». También puedes omitirlo.",
 "Tu pourras ajouter une photo et plus tard sous « Joueurs ». Tu peux aussi t’en passer."),
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
