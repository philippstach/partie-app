#!/usr/bin/env python3
"""glossar_t9_strings.py: Glossar-Sätze nennen nur noch die 26 freigegebenen Spiele (T-9). Ersetzt die alten Texte in App/Glossar.swift
und im Katalog durch die neuen, mit en/es/fr. Aufruf aus dem Projektordner."""
import json
SW = 'App/Glossar.swift'; KAT = 'App/Ressourcen/Localizable.xcstrings'
# alt -> (neu de, en, es, fr)
T = {
"Etwas behaupten, was nicht stimmt, damit die anderen falsch reagieren. Erlaubt in Mäxchen, Lügenwürfel, Mogeln, Truco.":
 ("Etwas behaupten, was nicht stimmt, damit die anderen falsch reagieren. Erlaubt in Mäxchen und Mogeln.",
  "Claiming something that isn’t true so the others react wrongly. Allowed in Mäxchen and Cheat.",
  "Afirmar algo que no es cierto para que los demás reaccionen mal. Permitido en Mäxchen y Mogeln.",
  "Affirmer quelque chose de faux pour que les autres réagissent mal. Permis à Mäxchen et Mogeln."),
"Eine passende Karte auf den offenen Stapel legen, um die eigene Hand loszuwerden (Mau-Mau, Farbwechsel, Crazy Eights).":
 ("Eine passende Karte auf den offenen Stapel legen, um die eigene Hand loszuwerden (Mau-Mau).",
  "Play a matching card onto the open pile to get rid of your hand (Mau-Mau).",
  "Poner una carta que encaje sobre el montón abierto para quedarte sin cartas (Mau-Mau).",
  "Poser une carte qui convient sur la pile ouverte pour se débarrasser de sa main (Mau-Mau)."),
"Mehrere Karten derselben Farbe in Reihe, zum Beispiel 7-8-9 (Rommé, Chinchón).":
 ("Mehrere Karten derselben Farbe in Reihe, zum Beispiel 7-8-9 (Rommé).",
  "Several cards of the same suit in sequence, for example 7-8-9 (Rummy).",
  "Varias cartas del mismo palo en orden, por ejemplo 7-8-9 (Rummy).",
  "Plusieurs cartes de la même couleur à la suite, par exemple 7-8-9 (Rami)."),
"Würfelbecher: Würfel verdeckt werfen, damit die anderen das Ergebnis nicht sehen (Mäxchen, Schocken, Lügenwürfel).":
 ("Würfelbecher: Würfel verdeckt werfen, damit die anderen das Ergebnis nicht sehen (Mäxchen, Schocken).",
  "Dice cup: throw the dice hidden so the others can’t see the result (Mäxchen, Schocken).",
  "Cubilete: tirar los dados ocultos para que los demás no vean el resultado (Mäxchen, Schocken).",
  "Gobelet : lancer les dés cachés pour que les autres ne voient pas le résultat (Mäxchen, Schocken)."),
"Zielfelder, in die die eigenen Figuren gebracht werden müssen (Rauswurf, Backgammon).":
 ("Zielfelder, in die die eigenen Figuren gebracht werden müssen (Rauswurf).",
  "Target squares your own pieces have to be brought to (Rauswurf).",
  "Casillas de meta a las que hay que llevar las fichas propias (Rauswurf).",
  "Cases d’arrivée où il faut amener ses propres pions (Rauswurf)."),
"Zahl am Rand oder im Feld, die sagt, wie viele Felder, Minen oder Brücken gemeint sind (Nonogramm, Minensuche, Brücken).":
 ("Zahl im Feld, die einen Hinweis gibt: bei der Minensuche, wie viele Minen in den Nachbarfeldern liegen, bei Kakuro, welche Summe die Ziffern ergeben.",
  "A number in a cell that gives a clue: in Minesweeper, how many mines are in the neighbouring cells; in Kakuro, what the digits add up to.",
  "Un número en la casilla que da una pista: en Buscaminas, cuántas minas hay en las casillas vecinas; en Kakuro, a cuánto suman las cifras.",
  "Un nombre dans la case qui donne un indice : au Démineur, combien de mines se trouvent dans les cases voisines ; au Kakuro, la somme que font les chiffres."),
}
sw = open(SW).read()
for alt, neu in T.items():
    assert alt in sw or neu[0] in sw, alt
    sw = sw.replace(alt, neu[0])
sw = sw.replace('spiele: ["maexchen", "luegenwuerfel", "mogeln", "truco"]', 'spiele: ["maexchen", "mogeln"]')
sw = sw.replace('spiele: ["maumau", "farbwechsel", "crazyeights"]', 'spiele: ["maumau"]')
sw = sw.replace('spiele: ["romme", "chinchon"]', 'spiele: ["romme"]')
sw = sw.replace('spiele: ["maexchen", "schocken", "luegenwuerfel"]', 'spiele: ["maexchen", "schocken"]')
sw = sw.replace('spiele: ["rauswurf", "backgammon"]', 'spiele: ["rauswurf"]')
sw = sw.replace('spiele: ["nonogramm", "minensuche", "bruecken"]', 'spiele: ["minensuche", "kakuro"]')
open(SW, 'w').write(sw)
cat = json.load(open(KAT)); s = cat['strings']
for alt, neu in T.items():
    s.pop(alt, None)
    loc = s.setdefault(neu[0], {}).setdefault('localizations', {})
    for sp, v in zip(('en', 'es', 'fr'), neu[1:]): loc[sp] = {"stringUnit": {"state": "translated", "value": v}}
orig = open(KAT).read()
open(KAT, 'w').write(json.dumps(cat, ensure_ascii=False, indent=2, separators=(',', ': ')) + ('\n' if orig.endswith('\n') else ''))
print('ersetzt:', len(T))
