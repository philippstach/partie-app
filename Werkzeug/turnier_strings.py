#!/usr/bin/env python3
"""turnier_strings.py: en/es/fr für B1 (Spieleabend-Turnier) und B5 (Rivalitäten). Überschreibt nie vorhandene Übersetzungen.
Aufruf aus dem Projektordner."""
import json
KAT = 'App/Ressourcen/Localizable.xcstrings'
U = {
"Spieleabend": ("Game night", "Noche de juegos", "Soirée jeux"),
"Mehrere Spiele nacheinander, eine Gesamtwertung. Platz 1 bekommt so viele Punkte wie Mitspieler, der Letzte einen.": ("Several games in a row, one overall ranking. First place gets as many points as there are players, last place gets one.", "Varios juegos seguidos, una clasificación general. El primer puesto recibe tantos puntos como jugadores; el último, uno.", "Plusieurs jeux d’affilée, un classement général. La 1re place rapporte autant de points que de joueurs, la dernière un seul."),
"Wer spielt mit?": ("Who is playing?", "¿Quién juega?", "Qui joue ?"),
"mindestens zwei": ("at least two", "al menos dos", "au moins deux"),
"Lege zuerst zwei Personen unter „Spieler“ an.": ("First add two people under “Players”.", "Primero añade dos personas en «Jugadores».", "Ajoute d’abord deux personnes sous « Joueurs »."),
"Welche Spiele?": ("Which games?", "¿Qué juegos?", "Quels jeux ?"),
"in dieser Reihenfolge": ("in this order", "en este orden", "dans cet ordre"),
"Spieleabend starten": ("Start game night", "Empezar la noche de juegos", "Lancer la soirée jeux"),
"gewinnt den Spieleabend": ("wins the game night", "gana la noche de juegos", "gagne la soirée jeux"),
"Runde %lld von %lld": ("Round %lld of %lld", "Ronda %lld de %lld", "Manche %lld sur %lld"),
"Gesamtwertung": ("Overall ranking", "Clasificación general", "Classement général"),
"Platz %lld: %@, %lld Punkte": ("Place %lld: %@, %lld points", "Puesto %lld: %@, %lld puntos", "Place %lld : %@, %lld points"),
"%lld von %lld gespielt": ("%lld of %lld played", "%lld de %lld jugados", "%lld sur %lld joués"),
"Ergebnis teilen": ("Share result", "Compartir resultado", "Partager le résultat"),
"Neuen Spieleabend einrichten": ("Set up a new game night", "Preparar una nueva noche de juegos", "Préparer une nouvelle soirée jeux"),
"Weiter mit %@": ("Continue with %@", "Continuar con %@", "Continuer avec %@"),
"Diese Runde überspringen": ("Skip this round", "Saltar esta ronda", "Passer cette manche"),
"Spieleabend abbrechen": ("Cancel game night", "Cancelar la noche de juegos", "Annuler la soirée jeux"),
"Spieleabend in Partie": ("Game night in Partie", "Noche de juegos en Partie", "Soirée jeux dans Partie"),
"Spieleabend läuft": ("Game night in progress", "Noche de juegos en curso", "Soirée jeux en cours"),
"Fertig – Ergebnis ansehen": ("Done – see the result", "Terminado: ver el resultado", "Terminé – voir le résultat"),
" (%lld unentschieden)": (" (%lld drawn)", " (%lld empates)", " (%lld nuls)"),
"%@ gewinnt %lld Mal in Folge": ("%@ wins %lld times in a row", "%@ gana %lld veces seguidas", "%@ gagne %lld fois de suite"),
"%lld Partien, %lld unentschieden": ("%lld games, %lld drawn", "%lld partidas, %lld empates", "%lld parties, %lld nuls"),
"Je Spiel": ("By game", "Por juego", "Par jeu"),
"Siege : Niederlagen": ("Wins : losses", "Victorias : derrotas", "Victoires : défaites"),
"%@: %lld Siege, %lld Niederlagen": ("%@: %lld wins, %lld losses", "%@: %lld victorias, %lld derrotas", "%@ : %lld victoires, %lld défaites"),
"Art": ("Type", "Tipo", "Type"),
"Duell": ("Duel", "Duelo", "Duel"),
"genau zwei": ("exactly two", "exactamente dos", "exactement deux"),
"Zwei Personen, bis zu 15 Spiele. Das erste Spiel bringt einen Punkt, das zweite zwei, das dritte drei und so weiter. Wer nicht mehr einzuholen ist, hat gewonnen.": ("Two people, up to 15 games. The first game is worth one point, the second two, the third three, and so on. Whoever can no longer be caught has won.", "Dos personas, hasta 15 juegos. El primer juego vale un punto, el segundo dos, el tercero tres y así sucesivamente. Quien ya no pueda ser alcanzado gana.", "Deux personnes, jusqu’à 15 jeux. Le premier jeu vaut un point, le deuxième deux, le troisième trois, et ainsi de suite. Qui ne peut plus être rattrapé a gagné."),
"Spiele und Reihenfolge": ("Games and order", "Juegos y orden", "Jeux et ordre"),
"Zufällige Spiele, zufällige Reihenfolge": ("Random games, random order", "Juegos al azar, orden al azar", "Jeux au hasard, ordre au hasard"),
"Eigene Spiele, zufällige Reihenfolge": ("Own games, random order", "Juegos propios, orden al azar", "Jeux choisis, ordre au hasard"),
"Eigene Spiele, eigene Reihenfolge": ("Own games, own order", "Juegos propios, orden propio", "Jeux choisis, ordre choisi"),
"Anzahl der Spiele: %lld": ("Number of games: %lld", "Número de juegos: %lld", "Nombre de jeux : %lld"),
"Reihenfolge wird gelost": ("order is drawn at random", "el orden se sortea", "l’ordre est tiré au sort"),
"Nach oben": ("Move up", "Subir", "Monter"),
"Duell starten": ("Start duel", "Empezar el duelo", "Lancer le duel"),
"gewinnt das Duell": ("wins the duel", "gana el duelo", "gagne le duel"),
"Neues Duell einrichten": ("Set up a new duel", "Preparar un nuevo duelo", "Préparer un nouveau duel"),
"Duell abbrechen": ("Cancel duel", "Cancelar el duelo", "Annuler le duel"),
"Duell läuft": ("Duel in progress", "Duelo en curso", "Duel en cours"),
"Vorzeitig entschieden: Der Vorsprung ist nicht mehr einzuholen.": ("Decided early: the lead can no longer be caught.", "Decidido antes de tiempo: la ventaja ya no se puede alcanzar.", "Décidé d’avance : l’avance ne peut plus être rattrapée."),
"Noch %lld Punkte zu holen · nächstes Spiel zählt %lld": ("%lld points still to win · next game counts %lld", "Quedan %lld puntos · el próximo juego vale %lld", "Encore %lld points à gagner · le prochain jeu compte %lld"),
"Stand %lld zu %lld, noch %lld Punkte zu holen, nächstes Spiel %@": ("Score %lld to %lld, %lld points still to win, next game %@", "Marcador %lld a %lld, quedan %lld puntos, próximo juego %@", "Score %lld à %lld, encore %lld points à gagner, prochain jeu %@"),
"Verlauf": ("Progress", "Evolución", "Évolution"),
"Punkte nach jedem Spiel": ("points after each game", "puntos tras cada juego", "points après chaque jeu"),
"Punkteanteile": ("Share of points", "Reparto de puntos", "Répartition des points"),
"von %lld möglichen": ("of %lld possible", "de %lld posibles", "sur %lld possibles"),
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
