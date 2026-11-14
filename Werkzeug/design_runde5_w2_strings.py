#!/usr/bin/env python3
"""design_runde5_w2_strings.py: Runde 5 Paket W2-S (Würfeltische Chicago, Schocken, Königsweg), de/en/es/fr. Überschreibt nichts. Aufruf aus dem Projektordner."""
import json
KAT = 'App/Ressourcen/Localizable.xcstrings'
U = {
"%lld von 4 Münzen zeigen den Punkt": ("%lld of 4 coins show the dot", "%lld de 4 monedas muestran el punto", "%lld pièces sur 4 montrent le point"),
"%lld Felder ziehen": ("Move %lld squares", "Mueve %lld casillas", "Avance de %lld cases"),
"1 Feld ziehen": ("Move 1 square", "Mueve 1 casilla", "Avance d’une case"),
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
