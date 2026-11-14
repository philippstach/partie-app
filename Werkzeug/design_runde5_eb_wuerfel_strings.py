#!/usr/bin/env python3
"""design_runde5_eb_wuerfel_strings.py: Runde 5, Paket EB-2 (Ergebnisseite Würfel), de/en/es/fr. Überschreibt nichts. Aufruf aus dem Projektordner."""
import json
KAT = 'App/Ressourcen/Localizable.xcstrings'
U = {
"Bonus oben": ("Upper bonus", "Bonus superior", "Bonus supérieur"),
"niemand": ("nobody", "nadie", "personne"),
"Bester Zug": ("Best turn", "Mejor turno", "Meilleur tour"),
"Runden": ("Rounds", "Rondas", "Manches"),
"Ziel %@ erreicht.": ("Target of %@ reached.", "Objetivo de %@ alcanzado.", "Objectif de %@ atteint."),
"Zettel am Ende": ("Score sheet at the end", "Hoja de puntos al final", "Feuille de score à la fin"),
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
