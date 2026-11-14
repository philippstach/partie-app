#!/usr/bin/env python3
"""uebersetzungen_viererreihe_neu.py: en/es/fr für die Texte von „Viererreihe (neu)“ (Paket SpielViererreihe). Überschreibt nichts Vorhandenes."""
import json
KAT = 'App/Ressourcen/Localizable.xcstrings'
U = {
"Viererreihe (neu)": ("Connect Four (new)", "Cuatro en línea (nuevo)", "Puissance 4 (nouveau)"),
"Vier in einer Reihe – Neu": ("Four in a row – new", "Cuatro en línea – nuevo", "Quatre à la suite – nouveau"),
"Abwechselnd wirft jeder einen Stein in eine Spalte. Der Stein fällt bis ganz nach unten oder auf den obersten Stein. Wer zuerst vier eigene Steine in einer Reihe hat – waagerecht, senkrecht oder schräg –, gewinnt. Ist das Brett voll, endet die Partie unentschieden.":
  ("Players take turns dropping a disc into a column. The disc falls to the bottom or onto the topmost disc. Whoever first has four of their own discs in a row – horizontally, vertically or diagonally – wins. If the board is full, the game is a draw.",
   "Por turnos, cada jugador deja caer una ficha en una columna. La ficha cae hasta el fondo o sobre la ficha más alta. Gana quien consiga primero cuatro fichas propias en línea, en horizontal, vertical o diagonal. Si el tablero se llena, la partida termina en tablas.",
   "À tour de rôle, chacun lâche un jeton dans une colonne. Le jeton tombe tout en bas ou sur le jeton du dessus. Le premier à aligner quatre jetons à lui – à l’horizontale, à la verticale ou en diagonale – gagne. Si la grille est pleine, la partie est nulle."),
"Bring als Erster vier eigene Steine in eine Reihe.": ("Be the first to get four of your discs in a row.", "Sé el primero en alinear cuatro fichas propias.", "Sois le premier à aligner quatre de tes jetons."),
"Spalte wählen": ("Choose a column", "Elegir columna", "Choisir une colonne"),
"Lege den Finger auf eine Spalte: Dein Stein schwebt darüber. Lass los, und er fällt.": ("Put your finger on a column: your disc hovers above it. Let go and it drops.", "Pon el dedo en una columna: tu ficha flota encima. Suelta y cae.", "Pose le doigt sur une colonne : ton jeton flotte au-dessus. Relâche, et il tombe."),
"Steine fallen": ("Discs fall", "Las fichas caen", "Les jetons tombent"),
"Jeder Stein fällt bis ganz nach unten oder auf den obersten Stein der Spalte.": ("Every disc falls to the bottom or onto the topmost disc of the column.", "Cada ficha cae hasta el fondo o sobre la ficha más alta de la columna.", "Chaque jeton tombe tout en bas ou sur le jeton du dessus de la colonne."),
"Wer zuerst vier eigene Steine nebeneinander, übereinander oder schräg hat, gewinnt.": ("Whoever first has four of their discs side by side, stacked or diagonally wins.", "Gana quien consiga primero cuatro fichas propias en horizontal, vertical o diagonal.", "Le premier à aligner quatre jetons à lui, côte à côte, empilés ou en diagonale, gagne."),
"ist dran": ("is up", "tiene el turno", "joue"),
"Spalte %lld, voll": ("Column %lld, full", "Columna %lld, llena", "Colonne %lld, pleine"),
"Spalte %lld, frei": ("Column %lld, free", "Columna %lld, libre", "Colonne %lld, libre"),
"Noch kein Zug": ("No move yet", "Aún sin jugadas", "Pas encore de coup"),
"%lld : %lld Steine": ("%lld : %lld discs", "%lld : %lld fichas", "%lld : %lld jetons"),
"Noch keine Partie": ("No game yet", "Aún sin partidas", "Pas encore de partie"),
"%lld Siege in %lld Partien": ("%lld wins in %lld games", "%lld victorias en %lld partidas", "%lld victoires en %lld parties"),
"Neues Spiel beginnen?": ("Start a new game?", "¿Empezar una partida nueva?", "Commencer une nouvelle partie ?"),
}
cat = json.load(open(KAT)); s = cat['strings']; n = 0
for k, t in U.items():
    loc = s.setdefault(k, {}).setdefault('localizations', {})
    if 'en' in loc: continue
    for sp, v in zip(('en', 'es', 'fr'), t): loc[sp] = {"stringUnit": {"state": "translated", "value": v}}
    n += 1
text = json.dumps(cat, ensure_ascii=False, indent=2, separators=(',', ': '))
orig = open(KAT).read()
open(KAT, 'w').write(text + ('\n' if orig.endswith('\n') else ''))
print('eingetragen:', n)
