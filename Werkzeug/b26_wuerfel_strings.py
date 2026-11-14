#!/usr/bin/env python3
"""b26_wuerfel_strings.py: T-078 Mäxchen, zwei Leben bei echtem Mäxchen, de/en/es/fr. Trägt einen Text nur ein, wenn es ihn noch nicht in en und fr gibt. Aufruf aus dem Projektordner. Übersetzungen sind Vorschläge."""
import json
KAT = 'App/Ressourcen/Localizable.xcstrings'
U = {
"Aufgedeckt: %@ – %@ verliert zwei Leben. (Ansage von %@: %@)": ("Revealed: %@ – %@ loses two lives. (Announcement by %@: %@)", "Descubierto: %@ – %@ pierde dos vidas. (Anuncio de %@: %@)", "Dévoilé : %@ – %@ perd deux vies. (Annonce de %@ : %@)"),
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
