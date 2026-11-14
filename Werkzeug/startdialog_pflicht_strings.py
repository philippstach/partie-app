#!/usr/bin/env python3
"""startdialog_pflicht_strings.py: de/en/es/fr für die Pflichtfeld-Meldungen im Blatt „Neues Spiel“ (Build 10, Philipps Rückmeldung).
Überschreibt nie vorhandene Übersetzungen. Aufruf aus dem Projektordner."""
import json
KAT = 'App/Ressourcen/Localizable.xcstrings'
U = {
"Es fehlen Spieler": ("Players missing", "Faltan jugadores", "Il manque des joueurs"),
"Bitte zuerst alle Namen eintragen – oder „Computer“ wählen.": ("Please enter all names first – or choose “Computer”.", "Escribe primero todos los nombres, o elige «Ordenador».", "Saisis d’abord tous les noms – ou choisis « Ordinateur »."),
"Bitte füge mehr Spieler hinzu.": ("Please add more players.", "Añade más jugadores.", "Ajoute d’autres joueurs."),
}
cat = json.load(open(KAT)); s = cat['strings']; n = 0
for k, t in U.items():
    loc = s.setdefault(k, {}).setdefault('localizations', {})
    loc.setdefault('de', {"stringUnit": {"state": "translated", "value": k}})
    for sp, v in zip(('en', 'es', 'fr'), t):
        if sp not in loc: loc[sp] = {"stringUnit": {"state": "translated", "value": v}}; n += 1
orig = open(KAT).read()
open(KAT, 'w').write(json.dumps(cat, ensure_ascii=False, indent=2, separators=(',', ': ')) + ('\n' if orig.endswith('\n') else ''))
print('eingetragen:', n)
