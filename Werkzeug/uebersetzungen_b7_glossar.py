#!/usr/bin/env python3
"""uebersetzungen_b7_glossar.py (Build 7): Glossar der Spielbegriffe (App/Glossar.swift) in en/es/fr.
Der deutsche Text wird aus Glossar.swift gelesen (Schlüssel = Text bzw. Begriff), die Übersetzung steht hier je Begriff-ID.
Überschreibt nie vorhandene Übersetzungen. Aufruf aus dem Projektordner: python3 Werkzeug/uebersetzungen_b7_glossar.py"""
import json, re

KAT = 'App/Ressourcen/Localizable.xcstrings'
# id: (Begriff en/es/fr oder None wenn schon im Katalog, Erklärung en, es, fr)
G = {
"Partie": (None,
  ("A complete game from start to finish. Partie counts every finished round in the statistics.", "Una partida completa de principio a fin. Partie cuenta cada ronda terminada en las estadísticas.", "Une partie complète du début à la fin. Partie compte chaque manche terminée dans les statistiques.")),
"Zug": (None,
  ("An action a player takes on their turn: playing a card, placing a piece, rolling the dice.", "Una acción que hace un jugador cuando es su turno: jugar una carta, colocar una ficha, tirar los dados.", "Une action qu’un joueur effectue quand c’est son tour : jouer une carte, poser un pion, lancer les dés.")),
"Runde": (None,
  ("One go around the table: every player has had exactly one turn. Many games count points per round.", "Una vuelta a la mesa: cada jugador ha tenido exactamente un turno. Muchos juegos cuentan puntos por ronda.", "Un tour de table : chaque joueur a joué exactement une fois. Beaucoup de jeux comptent les points par manche.")),
"Bluffen": (("Bluffing", "Farol", "Bluffer"),
  ("Claiming something that isn’t true so the others react wrongly. Allowed in Mäxchen, Liar’s Dice, Cheat and Truco.", "Afirmar algo que no es cierto para que los demás reaccionen mal. Permitido en Mäxchen, Dados mentirosos, Mogeln y Truco.", "Affirmer quelque chose de faux pour que les autres réagissent mal. Permis à Mäxchen, Dés menteurs, Mogeln et Truco.")),
"Anzweifeln": (None,
  ("Not believing the previous player’s claim. Whoever is right wins the round, whoever is wrong loses it.", "No creer la afirmación del jugador anterior. Quien tiene razón gana la ronda y quien se equivoca la pierde.", "Ne pas croire l’affirmation du joueur précédent. Celui qui a raison gagne la manche, celui qui se trompe la perd.")),
"Computerstufe": (("Computer level", "Nivel del ordenador", "Niveau de l’ordinateur"),
  ("Strength of the computer opponent: easy, medium, hard. Selectable in the “New game” sheet.", "Nivel del rival controlado por el ordenador: fácil, medio, difícil. Se elige en la hoja «Nueva partida».", "Force de l’adversaire ordinateur : facile, moyen, difficile. À choisir dans la feuille « Nouvelle partie ».")),
"Weiterspielen": (None,
  ("Continue an interrupted game later. The card at the top of the home screen takes you straight back in.", "Continuar más tarde una partida interrumpida. La tarjeta de la parte superior de la pantalla de inicio te lleva directamente.", "Reprendre plus tard une partie interrompue. La carte en haut de l’écran d’accueil te ramène directement dedans.")),
"Stich": (("Trick", "Baza", "Pli"),
  ("All cards of one round together. The highest card (or the trump) wins the trick.", "Todas las cartas de una ronda juntas. La carta más alta (o el triunfo) gana la baza.", "Toutes les cartes d’un tour ensemble. La carte la plus haute (ou l’atout) remporte le pli.")),
"Trumpf": (("Trump", "Triunfo", "Atout"),
  ("A suit that beats all other suits in this game, no matter how high the card is.", "Un palo que en esta partida gana a todos los demás, sin importar lo alta que sea la carta.", "Une couleur qui bat toutes les autres dans cette partie, quelle que soit la valeur de la carte.")),
"Farbe (Karten)": (("Suit (cards)", "Palo (cartas)", "Couleur (cartes)"),
  ("Clubs, spades, hearts, diamonds – in the Spanish deck coins, cups, swords, batons. Not the colour of the ink.", "Tréboles, picas, corazones, diamantes; en la baraja española oros, copas, espadas, bastos. No el color de la tinta.", "Trèfle, pique, cœur, carreau – dans le jeu espagnol deniers, coupes, épées, bâtons. Ce n’est pas la couleur d’impression.")),
"Bedienen": (("Following suit", "Servir", "Fournir"),
  ("Play a card of the suit that was led, if you have one. Usually mandatory in trick-taking games.", "Jugar una carta del palo de salida si se tiene. Suele ser obligatorio en los juegos de bazas.", "Jouer une carte de la couleur demandée si on en a une. Généralement obligatoire dans les jeux de levées.")),
"Ablegen": (None,
  ("Play a matching card onto the open pile to get rid of your hand (Mau-Mau, Farbwechsel, Crazy Eights).", "Poner una carta que encaje sobre el montón abierto para quedarte sin cartas (Mau-Mau, Farbwechsel, Crazy Eights).", "Poser une carte qui convient sur la pile ouverte pour se débarrasser de sa main (Mau-Mau, Farbwechsel, Crazy Eights).")),
"Folge": (("Run", "Escalera", "Suite"),
  ("Several cards of the same suit in sequence, for example 7-8-9 (Rummy, Chinchón).", "Varias cartas del mismo palo en orden, por ejemplo 7-8-9 (Rummy, Chinchón).", "Plusieurs cartes de la même couleur à la suite, par exemple 7-8-9 (Rami, Chinchón).")),
"Satz": (("Set", "Trío", "Brelan"),
  ("Three or four cards of equal value in different suits, for example three queens.", "Tres o cuatro cartas del mismo valor en palos distintos, por ejemplo tres reinas.", "Trois ou quatre cartes de même valeur dans des couleurs différentes, par exemple trois dames.")),
"Joker": (None,
  ("A card that can stand in for any other.", "Una carta que puede sustituir a cualquier otra.", "Une carte qui peut remplacer n’importe quelle autre.")),
"Klopfen": (None,
  ("In Schwimmen: announce that the last round has started. Then everyone gets one more turn.", "En Schwimmen: anunciar que empieza la última ronda. Después cada uno juega una vez más.", "À Schwimmen : annoncer que le dernier tour commence. Ensuite, chacun joue encore une fois.")),
"Schieben": (None,
  ("In Schwimmen: don’t swap a card and pass to the next player.", "En Schwimmen: no cambiar ninguna carta y pasar al siguiente.", "À Schwimmen : ne pas échanger de carte et passer au suivant.")),
"Patience": (("Patience", "Solitario", "Patience"),
  ("A card game for one person; Solitaire is the best-known form.", "Un juego de cartas para una persona; el solitario es la forma más conocida.", "Un jeu de cartes pour une personne ; le solitaire en est la forme la plus connue.")),
"Tableau": (("Tableau", "Tablero", "Tableau"),
  ("The rows of cards laid out in Solitaire, built downward in alternating red and black.", "Las hileras de cartas colocadas en el solitario, que se construyen en orden descendente alternando rojo y negro.", "Les colonnes de cartes disposées au solitaire, sur lesquelles on pose en descendant en alternant rouge et noir.")),
"Escoba": (None,
  ("In Escoba: take all cards from the table at once by making a total of 15. Earns an extra point.", "En la Escoba: llevarse todas las cartas de la mesa de una vez sumando 15. Da un punto extra.", "À l’Escoba : prendre toutes les cartes de la table d’un coup en faisant 15. Rapporte un point en plus.")),
"Envido": (None,
  ("In Truco: a bet on the highest point total of two cards of the same suit in your hand.", "En el Truco: una apuesta sobre la mayor suma de puntos de dos cartas del mismo palo en la mano.", "Au Truco : un pari sur le total de points le plus élevé de deux cartes de même couleur en main.")),
"Pasch": (("Doubles", "Pares", "Brelan de dés"),
  ("Several dice show the same number: pair, three of a kind, four of a kind.", "Varios dados muestran el mismo número: pareja, trío, póquer.", "Plusieurs dés montrent le même chiffre : paire, brelan, carré.")),
"Straße": (None,
  ("Consecutive pips, for example 1-2-3-4-5 (small straight) or 2-3-4-5-6 (large straight).", "Puntos consecutivos, por ejemplo 1-2-3-4-5 (escalera pequeña) o 2-3-4-5-6 (escalera grande).", "Des points qui se suivent, par exemple 1-2-3-4-5 (petite suite) ou 2-3-4-5-6 (grande suite).")),
"Full House": (None,
  ("Three of one kind and two of another, for example 4-4-4-2-2.", "Tres dados iguales y dos iguales, por ejemplo 4-4-4-2-2.", "Trois dés identiques et deux autres identiques, par exemple 4-4-4-2-2.")),
"Niete": (None,
  ("A roll with no scoring dice. In 10k, all points of the round are then lost.", "Una tirada sin dados que puntúen. En 10k se pierden entonces todos los puntos de la ronda.", "Un lancer sans dé qui compte. À 10k, tous les points du tour sont alors perdus.")),
"Sichern": (None,
  ("Bank the points collected so far in the round instead of risking more.", "Anotarte los puntos acumulados hasta ahora en la ronda en vez de arriesgar más.", "Mettre à l’abri les points du tour accumulés jusque-là au lieu de risquer davantage.")),
"Becher": (None,
  ("Dice cup: throw the dice hidden so the others can’t see the result (Mäxchen, Schocken, Liar’s Dice).", "Cubilete: tirar los dados ocultos para que los demás no vean el resultado (Mäxchen, Schocken, Dados mentirosos).", "Gobelet : lancer les dés cachés pour que les autres ne voient pas le résultat (Mäxchen, Schocken, Dés menteurs).")),
"Mäxchen": (None,
  ("In Mäxchen the highest roll: a 2 and a 1. Beats everything.", "En Mäxchen, la tirada más alta: un 2 y un 1. Gana a todo.", "À Mäxchen, le meilleur lancer : un 2 et un 1. Bat tout.")),
"Schock": (("Schock", "Schock", "Schock"),
  ("In Schocken a roll with two ones; “Schock out” (three ones) ends the round immediately.", "En Schocken, una tirada con dos unos; «Schock aus» (tres unos) termina la ronda de inmediato.", "À Schocken, un lancer avec deux as ; « Schock aus » (trois as) termine la manche aussitôt.")),
"Deckel": (None,
  ("Penalty tokens in Schocken. Whoever ends up with all the lids loses.", "Fichas de penalización en Schocken. Quien se queda con todas las tapas pierde.", "Jetons de pénalité à Schocken. Celui qui se retrouve avec tous les couvercles perd.")),
"Echte Würfel": (None,
  ("Instead of letting the app roll, you roll at the table and type in the pips. Switchable before the game.", "En lugar de dejar que la app tire los dados, los tiras en la mesa y escribes los puntos. Se puede cambiar antes de la partida.", "Au lieu de laisser l’app lancer les dés, tu lances à table et tu saisis les points. Modifiable avant la partie.")),
"Schlagen": (None,
  ("Remove an opponent’s piece from the board, usually by moving onto its square or jumping over it.", "Quitar una ficha del rival del tablero, normalmente moviéndote a su casilla o saltando sobre ella.", "Retirer un pion adverse du plateau, en général en allant sur sa case ou en sautant par-dessus.")),
"Schlagzwang": (("Forced capture", "Captura obligatoria", "Prise obligatoire"),
  ("If you can capture, you must capture. Applies in Draughts.", "Si puedes capturar, debes capturar. Se aplica en las Damas.", "Si tu peux prendre, tu dois prendre. S’applique au jeu de dames.")),
"Dame (Figur)": (("King (draughts)", "Dama (ficha)", "Dame (pion)"),
  ("In Draughts, a piece that has reached the last row and then moves in both directions.", "En las Damas, una ficha que ha llegado a la última fila y después se mueve en ambas direcciones.", "Au jeu de dames, un pion qui a atteint la dernière rangée et se déplace ensuite dans les deux sens.")),
"Mühle": (None,
  ("Three of your own pieces in a row. Whoever closes a mill takes an opponent’s piece.", "Tres fichas propias en línea. Quien cierra un molino quita una ficha del rival.", "Trois pions à soi alignés. Celui qui ferme un moulin prend un pion adverse.")),
"Matt": (("Checkmate", "Jaque mate", "Échec et mat"),
  ("The king is in check and can no longer escape. The game is over.", "El rey está en jaque y ya no puede escapar. La partida ha terminado.", "Le roi est en échec et ne peut plus s’échapper. La partie est terminée.")),
"Patt": (None,
  ("The player to move has no legal move but is not in check. A draw.", "El jugador al que le toca mover no tiene ningún movimiento legal pero no está en jaque. Tablas.", "Le joueur qui doit jouer n’a aucun coup légal mais n’est pas en échec. Partie nulle.")),
"Rochade": (("Castling", "Enroque", "Roque"),
  ("A special chess move: king and rook swap places at the same time to protect the king.", "Movimiento especial del ajedrez: el rey y la torre cambian de sitio a la vez para proteger al rey.", "Coup spécial aux échecs : le roi et la tour échangent leurs places en même temps pour mettre le roi à l’abri.")),
"Säen": (("Sowing", "Sembrar", "Semer"),
  ("In Kalaha and Oware: distribute the seeds of a pit one by one into the following pits.", "En Kalaha y Oware: repartir las semillas de un hoyo de una en una por los hoyos siguientes.", "À Kalaha et Oware : distribuer les graines d’une fosse une par une dans les fosses suivantes.")),
"Haus": (None,
  ("Target squares your own pieces have to be brought to (Rauswurf, Backgammon).", "Casillas de meta a las que hay que llevar las fichas propias (Rauswurf, Backgammon).", "Cases d’arrivée où il faut amener ses propres pions (Rauswurf, Backgammon).")),
"Rauswerfen": (("Sending home", "Echar", "Renvoyer"),
  ("Send an opponent’s piece back to the start by landing on its square.", "Mandar una ficha del rival de vuelta a la salida cayendo en su casilla.", "Renvoyer un pion adverse au départ en tombant sur sa case.")),
"Wenden": (None,
  ("In Reversi: flip trapped opponent pieces so they show your own colour.", "En el Reversi: dar la vuelta a las fichas rivales atrapadas para que muestren tu propio color.", "Au Reversi : retourner les pions adverses encerclés pour qu’ils montrent ta couleur.")),
"Sprungkette": (("Jump chain", "Cadena de saltos", "Rafle"),
  ("Several jumps in a row in one move (Halma, Draughts).", "Varios saltos seguidos en un mismo movimiento (Halma, Damas).", "Plusieurs sauts d’affilée en un seul coup (Halma, Dames).")),
"Notizen": (None,
  ("Small digits as a memory aid showing which numbers are still possible in a cell (Sudoku, Kakuro).", "Cifras pequeñas como ayuda de memoria que indican qué números aún son posibles en una casilla (Sudoku, Kakuro).", "Petits chiffres en aide-mémoire indiquant quels nombres sont encore possibles dans une case (Sudoku, Kakuro).")),
"Tipp": (None,
  ("The app shows the next safe step. Costs nothing but is counted.", "La app muestra el siguiente paso seguro. No cuesta nada, pero se cuenta.", "L’app montre la prochaine étape sûre. Ne coûte rien, mais est comptée.")),
"Hinweiszahl": (("Clue number", "Número de pista", "Chiffre indice"),
  ("A number at the edge or in a cell that says how many cells, mines or bridges are meant (Nonogram, Minesweeper, Bridges).", "Un número en el borde o en la casilla que indica cuántas casillas, minas o puentes se refieren (Nonograma, Buscaminas, Puentes).", "Un nombre au bord ou dans la case qui indique combien de cases, de mines ou de ponts sont concernés (Nonogramme, Démineur, Ponts).")),
"Markieren": (None,
  ("Mark a cell as a mine or as safe without uncovering it.", "Marcar una casilla como mina o como segura sin descubrirla.", "Marquer une case comme mine ou comme sûre sans la découvrir.")),
"Tagesrätsel": (None,
  ("The same puzzle for everyone every day. The streak counts how many days in a row you have solved it.", "El mismo puzle para todos cada día. La racha cuenta cuántos días seguidos lo has resuelto.", "La même grille pour tout le monde chaque jour. La série compte combien de jours d’affilée tu l’as résolue.")),
"Pfeilrätsel": (("Arrow crossword", "Crucigrama de flechas", "Mots fléchés"),
  ("A crossword where the clues sit in the grid and an arrow shows the direction of the answer.", "Un crucigrama en el que las pistas están dentro de la cuadrícula y una flecha indica la dirección de la respuesta.", "Des mots croisés dont les définitions sont dans la grille et dont une flèche indique le sens de la réponse.")),
"Kategorie": (None,
  ("In Stadt, Land, Fluss, a column such as animal or occupation for which a word starting with the letter is needed.", "En Stadt, Land, Fluss, una columna como animal u oficio para la que se busca una palabra con la letra.", "À Stadt, Land, Fluss, une colonne comme animal ou métier pour laquelle on cherche un mot commençant par la lettre.")),
"Rekord": (None,
  ("Highest score ever reached in an arcade game. Shown on the game’s home screen.", "La puntuación más alta alcanzada en un juego arcade. Aparece en la pantalla de inicio del juego.", "Le meilleur score jamais atteint dans un jeu d’arcade. Affiché sur l’écran d’accueil du jeu.")),
"Leben": (None,
  ("How many more times you may lose before the game ends.", "Cuántas veces más puedes perder antes de que termine la partida.", "Combien de fois tu peux encore perdre avant la fin de la partie.")),
"Reihe auflösen": (None,
  ("In Steinfall: a full row disappears and earns points.", "En Steinfall: una fila completa desaparece y da puntos.", "À Steinfall : une ligne complète disparaît et rapporte des points.")),
}

d = json.load(open(KAT))
src = open('App/Glossar.swift').read()
paare = re.findall(r'\.init\(id: "([^"]+)", text: "([^"]+)"', src)
neu = 0
def eintragen(schluessel, dreier):
    global neu
    l = d['strings'].setdefault(schluessel, {}).setdefault('localizations', {})
    for sprache, wert in zip(('en', 'es', 'fr'), dreier):
        if sprache not in l:
            l[sprache] = {"stringUnit": {"state": "translated", "value": wert}}
            neu += 1
fehlt = []
for i, text in paare:
    if i not in G:
        fehlt.append(i); continue
    begriff, erkl = G[i]
    if begriff:
        eintragen(i, begriff)
    eintragen(text, erkl)
open(KAT, 'w').write(json.dumps(d, ensure_ascii=False, indent=2) + "\n")
print(f"{neu} neue Glossar-Übersetzungen; ohne Eintrag: {fehlt}")
