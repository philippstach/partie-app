#!/usr/bin/env python3
"""startspiele_nacharbeit_strings.py: de/en/es/fr für die neuen Texte der Startspiele-Nacharbeit
(Mogeln: Meldung beim Aufdecken als ganze Sätze; Farbflut: Grund der Niederlage).
Überschreibt nie vorhandene Übersetzungen. Aufruf aus dem Projektordner."""
import json
KAT = 'App/Ressourcen/Localizable.xcstrings'
U = {
"Gelogen! Aufgedeckt: %@. %@ nimmt den Haufen.": ("That was a lie! Revealed: %1$@. %2$@ takes the pile.", "¡Mentira! Descubierto: %1$@. %2$@ se lleva el montón.", "Menti ! Révélé : %1$@. %2$@ prend le tas."),
"Stimmte! Aufgedeckt: %@. %@ nimmt den Haufen.": ("It was true! Revealed: %1$@. %2$@ takes the pile.", "¡Era verdad! Descubierto: %1$@. %2$@ se lleva el montón.", "C’était vrai ! Révélé : %1$@. %2$@ prend le tas."),
"Keine Züge mehr": ("No moves left", "No quedan movimientos", "Plus de coups"),
}
DE = {
"Gelogen! Aufgedeckt: %@. %@ nimmt den Haufen.": "Gelogen! Aufgedeckt: %1$@. %2$@ nimmt den Haufen.",
"Stimmte! Aufgedeckt: %@. %@ nimmt den Haufen.": "Stimmte! Aufgedeckt: %1$@. %2$@ nimmt den Haufen.",
}
cat = json.load(open(KAT)); s = cat['strings']
n = 0
for k, t in U.items():
    loc = s.setdefault(k, {}).setdefault('localizations', {})
    if 'en' in loc and 'fr' in loc: continue
    loc.setdefault('de', {"stringUnit": {"state": "translated", "value": DE.get(k, k)}})
    for sp, v in zip(('en', 'es', 'fr'), t): loc.setdefault(sp, {"stringUnit": {"state": "translated", "value": v}})
    n += 1
orig = open(KAT).read()
open(KAT, 'w').write(json.dumps(cat, ensure_ascii=False, indent=2, separators=(',', ': ')) + ('\n' if orig.endswith('\n') else ''))
print('eingetragen:', n)
