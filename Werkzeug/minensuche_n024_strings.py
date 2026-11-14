#!/usr/bin/env python3
"""minensuche_n024_strings.py: de/en/es/fr für die Frage nach einer Mine (N-024). Überschreibt nichts. Aufruf aus dem Projektordner."""
import json
KAT = 'App/Ressourcen/Localizable.xcstrings'
U = {
"Mine getroffen. Weiterspielen?": ("Hit a mine. Keep playing?", "Mina pisada. ¿Seguir jugando?", "Mine touchée. Continuer ?"),
"Weiterspielen (+30 s)": ("Keep playing (+30 s)", "Seguir jugando (+30 s)", "Continuer (+30 s)"),
"Aufhören": ("Stop", "Parar", "Arrêter"),
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
