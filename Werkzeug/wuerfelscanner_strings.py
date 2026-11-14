#!/usr/bin/env python3
"""wuerfelscanner_strings.py: de/en/es/fr für die Würfelscanner-Funde (fix-cloud-wuerfelscanner, T-004/T-006/T-013/T-014). Idempotent, überschreibt nichts. Aufruf aus dem Projektordner."""
import json
KAT = 'App/Ressourcen/Localizable.xcstrings'
U = {
"Trennen": ("Disconnect", "Desconectar", "Déconnecter"),
"Kopplung beenden?": ("End pairing?", "¿Terminar el emparejamiento?", "Mettre fin au jumelage ?"),
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
