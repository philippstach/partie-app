#!/usr/bin/env python3
"""galgenmaennchen_paket_g_strings.py: de/en/es/fr für die neuen Texte aus Paket G (Galgenmännchen): Freies Spiel, Kinderleicht, Drei Leben, die Wörter werden schwerer, %lld Wörter in deiner Liste (Plural). Idempotent, überschreibt nichts Vorhandenes. Aufruf aus dem Projektordner."""
import json
KAT = 'App/Ressourcen/Localizable.xcstrings'
def su(v): return {"stringUnit": {"state": "translated", "value": v}}
U = {
"Freies Spiel": ("Free play", "Juego libre", "Partie libre"),
"Kinderleicht": ("Kids' mode", "Modo infantil", "Mode enfant"),
"Drei Leben, die Wörter werden schwerer": ("Three lives, the words get harder", "Tres vidas, las palabras se vuelven más difíciles", "Trois vies, les mots deviennent plus difficiles"),
}
P = {"%lld Wörter in deiner Liste": {
  "de": ("%lld Wort in deiner Liste", "%lld Wörter in deiner Liste"),
  "en": ("%lld word in your list", "%lld words in your list"),
  "es": ("%lld palabra en tu lista", "%lld palabras en tu lista"),
  "fr": ("%lld mot dans ta liste", "%lld mots dans ta liste")}}
cat = json.load(open(KAT)); s = cat['strings']; n = 0
for k, t in U.items():
    loc = s.setdefault(k, {}).setdefault('localizations', {})
    for sp, v in zip(('de', 'en', 'es', 'fr'), (k,) + t):
        if sp not in loc: loc[sp] = su(v); n += 1
for k, langs in P.items():
    loc = s.setdefault(k, {}).setdefault('localizations', {})
    for sp, (one, other) in langs.items():
        if sp not in loc: loc[sp] = {"variations": {"plural": {"one": su(one), "other": su(other)}}}; n += 1
orig = open(KAT).read()
open(KAT, 'w').write(json.dumps(cat, ensure_ascii=False, indent=2, separators=(',', ': ')) + ('\n' if orig.endswith('\n') else ''))
print('eingetragen:', n)
