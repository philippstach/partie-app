#!/usr/bin/env python3
"""yacht_neu_strings.py: en/es/fr für die neuen Texte von „Yacht (neu)“. Überschreibt nie vorhandene Übersetzungen.
Aufruf aus dem Projektordner (Partie/Haupt)."""
import json
KAT = 'App/Ressourcen/Localizable.xcstrings'
U = {
"1 × Yacht": ("1 × Yacht", "1 × Yacht", "1 × Yacht"),
"%lld × Yacht": ("%lld × Yacht", "%lld × Yacht", "%lld × Yacht"),
"Ein Paar": ("One pair", "Una pareja", "Une paire"),
"Zwei Paare": ("Two pairs", "Dos parejas", "Deux paires"),
"Yatzy": ("Yatzy", "Yatzy", "Yatzy"),
"Klassisch": ("Classic", "Clásico", "Classique"),
"Original-Yacht": ("Original Yacht", "Yacht original", "Yacht d’origine"),
"Zwei gleiche: Summe der beiden (das höchste Paar)": ("Two of a kind: sum of the two (the highest pair)", "Dos iguales: suma de ambos (la pareja más alta)", "Deux identiques : somme des deux (la plus haute paire)"),
"Zwei verschiedene Paare: Summe der vier Würfel": ("Two different pairs: sum of the four dice", "Dos parejas distintas: suma de los cuatro dados", "Deux paires différentes : somme des quatre dés"),
"Drei gleiche: Summe dieser drei Würfel": ("Three of a kind: sum of those three dice", "Tres iguales: suma de esos tres dados", "Trois identiques : somme de ces trois dés"),
"Vier gleiche: Summe dieser vier Würfel": ("Four of a kind: sum of those four dice", "Cuatro iguales: suma de esos cuatro dados", "Quatre identiques : somme de ces quatre dés"),
"Drei und zwei gleiche: Summe aller Würfel": ("Three and two of a kind: sum of all dice", "Tres y dos iguales: suma de todos los dados", "Trois et deux identiques : somme de tous les dés"),
"1-2-3-4-5: 15 Punkte": ("1-2-3-4-5: 15 points", "1-2-3-4-5: 15 puntos", "1-2-3-4-5 : 15 points"),
"2-3-4-5-6: 20 Punkte": ("2-3-4-5-6: 20 points", "2-3-4-5-6: 20 puntos", "2-3-4-5-6 : 20 points"),
"1-2-3-4-5: 30 Punkte": ("1-2-3-4-5: 30 points", "1-2-3-4-5: 30 puntos", "1-2-3-4-5 : 30 points"),
"2-3-4-5-6: 30 Punkte": ("2-3-4-5-6: 30 points", "2-3-4-5-6: 30 puntos", "2-3-4-5-6 : 30 points"),
"Fünf gleiche: 50 Punkte": ("Five of a kind: 50 points", "Cinco iguales: 50 puntos", "Cinq identiques : 50 points"),
"13 Felder, Bonus 35, Chance und Full House 25": ("13 boxes, bonus 35, chance and full house 25", "13 casillas, bono 35, azar y full 25", "13 cases, bonus 35, chance et full 25"),
"15 Felder, Paare, Bonus 50, Straßen 15 und 20": ("15 boxes, pairs, bonus 50, straights 15 and 20", "15 casillas, parejas, bono 50, escaleras 15 y 20", "15 cases, paires, bonus 50, suites 15 et 20"),
"11 Felder, ohne Chance und Bonus, Straßen 30": ("11 boxes, no chance and no bonus, straights 30", "11 casillas, sin azar ni bono, escaleras 30", "11 cases, sans chance ni bonus, suites 30"),
"%@, am Zug": ("%@, their turn", "%@, su turno", "%@, à son tour"),
"%@, %@: %lld Punkte": ("%@, %@: %lld points", "%@, %@: %lld puntos", "%@, %@ : %lld points"),
"%@, %@: frei, bringt %lld Punkte": ("%@, %@: free, scores %lld points", "%@, %@: libre, da %lld puntos", "%@, %@ : libre, rapporte %lld points"),
"%@, %@: frei": ("%@, %@: free", "%@, %@: libre", "%@, %@ : libre"),
"%@, %@: %@": ("%@, %@: %@", "%@, %@: %@", "%@, %@ : %@"),
"Doppeltippen zum Wählen": ("Double-tap to choose", "Toca dos veces para elegir", "Appuie deux fois pour choisir"),
"Tipp: die markierten Würfel halten": ("Hint: hold the marked dice", "Pista: guarda los dados marcados", "Indice : garde les dés marqués"),
"Runde %lld von %lld": ("Round %lld of %lld", "Ronda %lld de %lld", "Manche %lld sur %lld"),
"Wertung und Regeln ändern": ("Change scoring and rules", "Cambiar puntuación y reglas", "Changer le décompte et les règles"),
"Rekord %lld": ("Record %lld", "Récord %lld", "Record %lld"),
"Neuer Rekord!": ("New record!", "¡Nuevo récord!", "Nouveau record !"),
"Punkteverlauf": ("Score history", "Evolución de puntos", "Évolution des points"),
"Wertung": ("Scoring", "Puntuación", "Décompte"),
"Zusatzregeln": ("Extra rules", "Reglas adicionales", "Règles supplémentaires"),
"Joker": ("Joker", "Comodín", "Joker"),
"Yacht-Bonus (100 Punkte)": ("Yacht bonus (100 points)", "Bono de Yacht (100 puntos)", "Bonus Yacht (100 points)"),
"Wertung und Regeln": ("Scoring and rules", "Puntuación y reglas", "Décompte et règles"),
"Fünf Würfel, drei Würfe, drei Wertungen": ("Five dice, three rolls, three scorings", "Cinco dados, tres tiradas, tres puntuaciones", "Cinq dés, trois lancers, trois décomptes"),
"Hole die meisten Punkte. Allein: schlage deinen Rekord.": ("Score the most points. Playing alone: beat your record.", "Consigue más puntos. En solitario: bate tu récord.", "Marque le plus de points. Seul : bats ton record."),
"Du würfelst bis zu dreimal mit fünf Würfeln und hältst dazwischen die Würfel, die du behalten willst. Danach trägst du das Ergebnis in ein freies Feld des Blocks ein: Einser bis Sechser zählen die Augen, dazu kommen Pasch, Full House, Straßen und Yacht (fünf gleiche). Passt nichts, streichst du ein Feld. Wer nach allen Runden die meisten Punkte hat, gewinnt. Vor dem ersten Wurf wählst du die Wertung: Kniffel, Yatzy oder die Original-Yacht.":
 ("You roll up to three times with five dice and hold the dice you want to keep in between. Then you enter the result in a free box of the sheet: ones to sixes count the pips, plus kinds, full house, straights and Yacht (five of a kind). If nothing fits, you cross out a box. Whoever has the most points after all rounds wins. Before the first roll you choose the scoring: Yahtzee-style, Yatzy or the original Yacht.",
  "Tiras hasta tres veces con cinco dados y entre tiradas guardas los dados que quieres conservar. Después anotas el resultado en una casilla libre de la hoja: de los unos a los seises cuentan los puntos, además hay póker, full, escaleras y Yacht (cinco iguales). Si nada encaja, tachas una casilla. Gana quien tenga más puntos tras todas las rondas. Antes de la primera tirada eliges la puntuación: estilo Yahtzee, Yatzy o el Yacht original.",
  "Tu lances jusqu’à trois fois cinq dés et tu gardes entre les lancers les dés que tu veux conserver. Puis tu inscris le résultat dans une case libre de la feuille : de un à six, on compte les points, plus brelan, full, suites et Yacht (cinq identiques). Si rien ne convient, tu barres une case. Celui qui a le plus de points après toutes les manches gagne. Avant le premier lancer, tu choisis le décompte : style Yahtzee, Yatzy ou le Yacht d’origine."),
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
