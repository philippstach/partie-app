#!/usr/bin/env python3
"""abbruch_strings.py: de/en/es/fr für die Einstellung „Partie abbrechen“ (S3). Überschreibt nie vorhandene Übersetzungen.
Aufruf aus dem Projektordner."""
import json
KAT = 'App/Ressourcen/Localizable.xcstrings'
U = {
"Partie abbrechen": ("Quitting a game", "Abandonar una partida", "Abandonner une partie"),
"Zählt nicht": ("Doesn’t count", "No cuenta", "Ne compte pas"),
"Gegen den Computer als Niederlage": ("Counts as a loss against the computer", "Cuenta como derrota contra el ordenador", "Compte comme défaite contre l’ordinateur"),
"Immer als Niederlage": ("Always counts as a loss", "Siempre cuenta como derrota", "Compte toujours comme défaite"),
"Legt fest, ob „Beenden“ mitten in einer Partie als Niederlage zählt. Eine Partie gilt als begonnen, sobald ein Zug gemacht wurde, sie fortgesetzt wurde oder länger als 20 Sekunden läuft. Im Kinder-Modus und in Arcade-Spielen zählt ein Abbruch nie.": (
 "Sets whether “End” in the middle of a game counts as a loss. A game counts as started once a move was made, it was resumed, or it has been running for more than 20 seconds. In Kids mode and in arcade games quitting never counts.",
 "Define si «Terminar» en mitad de una partida cuenta como derrota. Una partida se considera empezada cuando se ha hecho una jugada, se ha reanudado o lleva más de 20 segundos. En el modo infantil y en los juegos arcade abandonar nunca cuenta.",
 "Définit si « Quitter » en cours de partie compte comme une défaite. Une partie est considérée comme commencée dès qu’un coup a été joué, qu’elle a été reprise ou qu’elle dure depuis plus de 20 secondes. En mode enfants et dans les jeux d’arcade, l’abandon ne compte jamais."),
}
cat = json.load(open(KAT)); s = cat['strings']
n = 0
for k, t in U.items():
    loc = s.setdefault(k, {}).setdefault('localizations', {})
    if 'en' in loc and 'fr' in loc: continue
    loc.setdefault('de', {"stringUnit": {"state": "translated", "value": k}})
    for sp, v in zip(('en', 'es', 'fr'), t): loc[sp] = {"stringUnit": {"state": "translated", "value": v}}
    n += 1
orig = open(KAT).read()
open(KAT, 'w').write(json.dumps(cat, ensure_ascii=False, indent=2, separators=(',', ': ')) + ('\n' if orig.endswith('\n') else ''))
print('eingetragen:', n)
