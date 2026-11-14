#!/usr/bin/env python3
"""kreuzwort_start_strings.py: de/en/es/fr für die neue Startseite des Kreuzworträtsels (Wortpfeil, 10.11.2026).
Überschreibt nie vorhandene Übersetzungen. Aufruf aus dem Projektordner."""
import json
KAT = 'App/Ressourcen/Localizable.xcstrings'
U = {
"Neu hier?": ("New here?", "¿Primera vez?", "Nouveau ici ?"),
"Die Frage steht im Kästchen, der Pfeil zeigt die Richtung. Im ersten Rätsel ist jeder Anfangsbuchstabe schon eingetragen.": (
    "The clue is in the box, the arrow shows the direction. In your first puzzle, the first letter of every word is already filled in.",
    "La pista está en la casilla y la flecha indica la dirección. En el primer crucigrama, la primera letra de cada palabra ya está escrita.",
    "La définition est dans la case, la flèche indique le sens. Dans la première grille, la première lettre de chaque mot est déjà inscrite."),
"Falsche Buchstaben werden sofort rot, richtige Wörter leuchten kurz auf. Mit Starthilfe steht der erste Buchstabe jedes Wortes schon drin. Nichts davon zählt als Hilfe. Die Starthilfe gilt für neue Rätsel.": (
    "Wrong letters turn red right away, correct words briefly light up. With starter letters, the first letter of every word is already filled in. None of this counts as a hint. Starter letters apply to new puzzles.",
    "Las letras incorrectas se ponen rojas al instante y las palabras correctas brillan un momento. Con las letras iniciales, la primera letra de cada palabra ya está escrita. Nada de esto cuenta como ayuda. Las letras iniciales valen para los pasatiempos nuevos.",
    "Les lettres fausses deviennent rouges tout de suite, les mots justes brillent un instant. Avec les lettres de départ, la première lettre de chaque mot est déjà placée. Rien de tout cela ne compte comme une aide. Les lettres de départ valent pour les nouvelles grilles."),
"%@ · %lld von %lld gelöst": ("%1$@ · %2$lld of %3$lld solved", "%1$@ · %2$lld de %3$lld resueltos", "%1$@ · %2$lld sur %3$lld résolues"),
}
cat = json.load(open(KAT)); s = cat['strings']; n = 0
for k, t in U.items():
    loc = s.setdefault(k, {}).setdefault('localizations', {})
    loc.setdefault('de', {"stringUnit": {"state": "translated", "value": k.replace('%@ · %lld von %lld', '%1$@ · %2$lld von %3$lld')}})
    for sp, v in zip(('en', 'es', 'fr'), t):
        if sp not in loc: loc[sp] = {"stringUnit": {"state": "translated", "value": v}}; n += 1
orig = open(KAT).read()
open(KAT, 'w').write(json.dumps(cat, ensure_ascii=False, indent=2, separators=(',', ': ')) + ('\n' if orig.endswith('\n') else ''))
print('eingetragen:', n)
