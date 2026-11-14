#!/usr/bin/env python3
"""farbraetsel_rahmen_strings.py: de/en/es/fr für den Regeltext des Farbrätsels im SpielRahmen. Überschreibt nie vorhandene Übersetzungen.
Aufruf aus dem Projektordner."""
import json
KAT = 'App/Ressourcen/Localizable.xcstrings'
U = {
"Die Kacheln bilden einen sanften Farbverlauf zwischen den vier Ecken. Jemand hat sie durcheinandergebracht. Stelle den Verlauf wieder her. Tippe eine Kachel an und dann eine zweite. Beide tauschen die Plätze. Kacheln mit weißem Punkt sind fest. Je weniger Züge, desto besser. Der Tipp bringt eine Kachel an ihren Platz und zählt als Zug; mit Tipp gelöste Rätsel zählen aber nicht für den Bestwert. Jeden Tag gibt es ein Rätsel für alle. Löse es an mehreren Tagen hintereinander für eine Serie.": (
 "The tiles form a smooth colour gradient between the four corners. Someone has mixed them up. Restore the gradient. Tap one tile and then a second one. They swap places. Tiles with a white dot are fixed. The fewer moves, the better. The hint puts one tile in its place and counts as a move; puzzles solved with a hint do not count for the best score, though. Every day there is a puzzle for everyone. Solve it on several days in a row for a streak.",
 "Las fichas forman un suave degradado de color entre las cuatro esquinas. Alguien las ha desordenado. Restablece el degradado. Toca una ficha y luego una segunda. Intercambian sus posiciones. Las fichas con un punto blanco son fijas. Cuantos menos movimientos, mejor. La pista coloca una ficha en su sitio y cuenta como un movimiento; los puzles resueltos con pista no cuentan para el mejor resultado. Cada día hay un puzle para todos. Resuélvelo varios días seguidos para lograr una racha.",
 "Les tuiles forment un doux dégradé de couleurs entre les quatre coins. Quelqu’un les a mélangées. Rétablis le dégradé. Touche une tuile, puis une seconde. Elles échangent leurs places. Les tuiles avec un point blanc sont fixes. Moins il y a de coups, mieux c’est. L’indice place une tuile à sa place et compte comme un coup ; les énigmes résolues avec indice ne comptent toutefois pas pour le meilleur score. Chaque jour, il y a une énigme pour tous. Résous-la plusieurs jours de suite pour une série."),
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
