#!/usr/bin/env python3
"""design_runde5_se_strings.py: Blatt 24, Paket SE-1 (Yacht, gesperrter Joker), de/en/es/fr. Trägt einen Text nur ein, wenn es ihn noch nicht in en und fr gibt. Aufruf aus dem Projektordner. Übersetzungen sind Vorschläge."""
import json
KAT = 'App/Ressourcen/Localizable.xcstrings'
U = {
"Gehört zum Yacht-Bonus": ("Part of the Yacht bonus", "Forma parte del bono de Yacht", "Fait partie du bonus Yacht"),
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
