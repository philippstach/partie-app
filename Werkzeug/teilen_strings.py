#!/usr/bin/env python3
"""teilen_strings.py: en/es/fr für die Texte von D3 (Rätsel per Link teilen). Überschreibt nie vorhandene Übersetzungen.
Aufruf aus dem Projektordner."""
import json
KAT = 'App/Ressourcen/Localizable.xcstrings'
U = {
"Rätsel per Link teilen": ("Share puzzle by link", "Compartir rompecabezas por enlace", "Partager le casse-tête par lien"),
"Welche Stufe teilen?": ("Which level to share?", "¿Qué nivel compartir?", "Quel niveau partager ?"),
"Du bekommst einen Link. Wer ihn öffnet, löst dasselbe Brett.": ("You get a link. Whoever opens it solves the same board.", "Recibes un enlace. Quien lo abra resuelve el mismo tablero.", "Tu obtiens un lien. Qui l’ouvre résout la même grille."),
"Minensuche, Stufe %@: Schaffst du dieses Brett?": ("Minesweeper, level %@: Can you clear this board?", "Buscaminas, nivel %@: ¿Puedes con este tablero?", "Démineur, niveau %@ : Tu peux finir cette grille ?"),
"Sudoku %@, %@: Schaffst du dieses Rätsel?": ("Sudoku %@, %@: Can you solve this puzzle?", "Sudoku %@, %@: ¿Puedes resolver este rompecabezas?", "Sudoku %@, %@ : Tu sais résoudre cette grille ?"),
}
cat = json.load(open(KAT)); s = cat['strings']
n = 0
for k, t in U.items():
    loc = s.setdefault(k, {}).setdefault('localizations', {})
    if 'en' in loc and 'fr' in loc: continue
    for sp, v in zip(('en', 'es', 'fr'), t): loc[sp] = {"stringUnit": {"state": "translated", "value": v}}
    n += 1
orig = open(KAT).read()
open(KAT, 'w').write(json.dumps(cat, ensure_ascii=False, indent=2, separators=(',', ': ')) + ('\n' if orig.endswith('\n') else ''))
print('eingetragen:', n)
