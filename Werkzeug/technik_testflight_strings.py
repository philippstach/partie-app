#!/usr/bin/env python3
"""technik_testflight_strings.py: de/en/es/fr für den Hinweis T-024 (Ende von „Nur … nutzen“). Überschreibt nichts. Aufruf aus dem Projektordner."""
import json
KAT = 'App/Ressourcen/Localizable.xcstrings'
U = {
"Startet jetzt wieder auf der Startseite, nicht mehr direkt mit %@. Du hast mehrere Favoriten.": (
 "Partie now opens on the home page again, no longer straight into %@. You have several favorites.",
 "Ahora se abre en la pantalla de inicio, ya no directamente en %@. Tienes varios favoritos.",
 "S’ouvre maintenant sur l’accueil, plus directement sur %@. Tu as plusieurs favoris."),
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
