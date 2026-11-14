#!/usr/bin/env python3
"""design_runde5_eb2_raetsel_strings.py: Runde 5, Blatt 22, Schritt 2, Paket EB2-3 (Farbfüller, Viererreihe, Mühle), de/en/es/fr.
Trägt nur ein, was es noch nicht gibt. Aufruf aus dem Projektordner."""
import json
KAT = 'App/Ressourcen/Localizable.xcstrings'
U = {
"Am Anfang": ("At the start", "Al empezar", "Au début"),
"Das Feld am Anfang": ("The board at the start", "El tablero al empezar", "Le plateau au début"),
"Vier in einer Reihe nach %lld Zügen.": ("Four in a row after %lld moves.", "Cuatro en raya tras %lld jugadas.", "Quatre alignés après %lld coups."),
"Mühlen geschlossen": ("Mills formed", "Molinos formados", "Moulins formés"),
}
cat = json.load(open(KAT)); s = cat['strings']; n = 0
for k, t in U.items():
    loc = s.setdefault(k, {}).setdefault('localizations', {})
    if all(sp in loc for sp in ('en', 'es', 'fr')): continue
    loc.setdefault('de', {"stringUnit": {"state": "translated", "value": k}})
    for sp, v in zip(('en', 'es', 'fr'), t): loc.setdefault(sp, {"stringUnit": {"state": "translated", "value": v}})
    n += 1
orig = open(KAT).read()
open(KAT, 'w').write(json.dumps(cat, ensure_ascii=False, indent=2, separators=(',', ': ')) + ('\n' if orig.endswith('\n') else ''))
print('eingetragen:', n)
