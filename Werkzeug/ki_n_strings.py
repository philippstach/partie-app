#!/usr/bin/env python3
"""ki_n_strings.py: KI-N (Blatt 18, Neue Partie sagen), de/en/es/fr. Überschreibt nichts. Aufruf aus dem Projektordner."""
import json
KAT = 'App/Ressourcen/Localizable.xcstrings'
U = {
"Alles andere bleibt, wie es eingestellt ist.": ("Everything else stays as it is set.", "Todo lo demás se queda como está ajustado.", "Tout le reste reste comme réglé."),
"Regeln lassen sich in %@ noch nicht ansagen. Alles andere bleibt, wie es eingestellt ist.": ("Rules can't be set by voice in %@ yet. Everything else stays as it is set.", "Las reglas de %@ aún no se pueden decir. Todo lo demás se queda como está ajustado.", "Les règles de %@ ne peuvent pas encore être dites. Tout le reste reste comme réglé."),
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
