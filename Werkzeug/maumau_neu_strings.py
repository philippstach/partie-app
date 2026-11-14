#!/usr/bin/env python3
"""Mau-Mau (neu): trägt die neuen Texte (de/en/es/fr) in App/Ressourcen/Localizable.xcstrings ein.
Fehlende Schlüssel werden angelegt, vorhandene bleiben unberührt. Aufruf: python3 Werkzeug/maumau_neu_strings.py"""
import json, os

PFAD = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "App", "Ressourcen", "Localizable.xcstrings")

T = {
 "Mau-Mau (neu)": ("Mau-Mau (new)", "Mau-Mau (nuevo)", "Mau-Mau (nouveau)"),
 "Jeder bekommt fünf Karten (wählbar: fünf bis sieben). Lege eine Karte gleicher Farbe oder gleichen Werts wie die oberste Karte ab. Kannst du nicht, ziehst du eine Karte. Besondere Karten: 7 – der Nächste zieht zwei (mit einer 7 weitergeben, dann zieht er vier …), 8 – der Nächste setzt aus, Bube – du wünschst dir eine Farbe. Wer als Erster keine Karten mehr hat, gewinnt. Hausregeln kombinierst du frei im Menü: „Mau“ sagen, die 9 wechselt die Richtung, Bube auf Bube, gezogene Karte gleich legen und mehrere Runden mit Punkten. Ab fünf Personen wird mit zwei Blättern gespielt.":
   ("Everyone gets five cards (selectable: five to seven). Play a card of the same suit or the same value as the top card. If you can't, draw a card. Special cards: 7 – the next player draws two (pass it on with a 7, then they draw four …), 8 – the next player skips a turn, Jack – you choose a suit. The first player with no cards left wins. You can combine house rules freely in the menu: saying “Mau”, the 9 reverses direction, Jack on Jack, playing a drawn card right away and several rounds with points. From five players on, two decks are used.",
    "Cada jugador recibe cinco cartas (se puede elegir de cinco a siete). Juega una carta del mismo palo o del mismo valor que la carta de arriba. Si no puedes, robas una carta. Cartas especiales: 7 – el siguiente roba dos (se puede pasar con otro 7, entonces roba cuatro …), 8 – el siguiente pierde el turno, Jota – eliges un palo. Gana quien se quede primero sin cartas. Las reglas de la casa se combinan libremente en el menú: decir «Mau», el 9 invierte el sentido, jota sobre jota, jugar enseguida la carta robada y varias rondas con puntos. A partir de cinco jugadores se juega con dos barajas.",
    "Chacun reçoit cinq cartes (au choix : de cinq à sept). Pose une carte de la même couleur ou de la même valeur que la carte du dessus. Si tu ne peux pas, tu piques une carte. Cartes spéciales : 7 – le suivant pique deux cartes (on peut passer avec un 7, il en pique alors quatre …), 8 – le suivant passe son tour, Valet – tu choisis une couleur. Le premier sans cartes gagne. Les règles maison se combinent librement dans le menu : dire « Mau », le 9 inverse le sens, valet sur valet, poser tout de suite la carte piochée et plusieurs manches avec des points. À partir de cinq joueurs, on joue avec deux jeux."),
 "Hausregeln wählst du im Menü.": ("You choose house rules in the menu.", "Las reglas de la casa se eligen en el menú.", "Tu choisis les règles maison dans le menu."),
 "Hausregeln": ("House rules", "Reglas de la casa", "Règles maison"),
 "Die Regeln lassen sich nur vor dem ersten Zug ändern.": ("The rules can only be changed before the first move.", "Las reglas solo se pueden cambiar antes de la primera jugada.", "Les règles ne peuvent être modifiées qu'avant le premier coup."),
 "Schnellwahl": ("Quick choice", "Selección rápida", "Choix rapide"),
 "Standard (7 zieht, 8 setzt aus)": ("Standard (7 draws, 8 skips)", "Estándar (7 roba, 8 salta)", "Standard (7 pique, 8 passe)"),
 "Ass setzt aus": ("Ace skips", "El as salta", "L'as passe"),
 "Sieben Karten auf die Hand": ("Seven cards in hand", "Siete cartas en la mano", "Sept cartes en main"),
 "Schlicht (ohne 7 und 8)": ("Plain (without 7 and 8)", "Sencillo (sin 7 ni 8)", "Simple (sans 7 ni 8)"),
 "Streng (Bube nicht zuletzt)": ("Strict (no Jack as last card)", "Estricto (sin jota como última)", "Strict (pas de valet en dernier)"),
 "Wild (9 dreht, Mau, sofort legen)": ("Wild (9 reverses, Mau, play at once)", "Salvaje (9 invierte, Mau, jugar enseguida)", "Sauvage (9 inverse, Mau, poser aussitôt)"),
 "Karten und Sonderkarten": ("Cards and special cards", "Cartas y cartas especiales", "Cartes et cartes spéciales"),
 "Karten auf der Hand": ("Cards in hand", "Cartas en la mano", "Cartes en main"),
 "7 lässt ziehen (stapelbar)": ("7 makes the next player draw (stackable)", "El 7 hace robar (acumulable)", "Le 7 fait piquer (cumulable)"),
 "Aussetzen": ("Skip", "Saltar turno", "Passer son tour"),
 "Mit der 8": ("With the 8", "Con el 8", "Avec le 8"),
 "Mit dem Ass": ("With the ace", "Con el as", "Avec l'as"),
 "Niemand setzt aus": ("Nobody skips", "Nadie salta", "Personne ne passe"),
 "Bube darf die letzte Karte sein": ("Jack may be the last card", "La jota puede ser la última carta", "Le valet peut être la dernière carte"),
 "Bube auf Bube erlaubt": ("Jack on Jack allowed", "Jota sobre jota permitida", "Valet sur valet autorisé"),
 "Weitere Hausregeln": ("More house rules", "Más reglas de la casa", "Autres règles maison"),
 "9 wechselt die Richtung (ab drei Personen)": ("9 reverses direction (three or more players)", "El 9 invierte el sentido (desde tres jugadores)", "Le 9 inverse le sens (à partir de trois joueurs)"),
 "„Mau“ sagen (sonst Strafkarte)": ("Say “Mau” (otherwise penalty card)", "Decir «Mau» (si no, carta de castigo)", "Dire « Mau » (sinon carte de pénalité)"),
 "Gezogene Karte gleich legen": ("Play a drawn card right away", "Jugar enseguida la carta robada", "Poser aussitôt la carte piochée"),
 "Runden": ("Rounds", "Rondas", "Manches"),
 "Mehrere Runden mit Punkten": ("Several rounds with points", "Varias rondas con puntos", "Plusieurs manches avec des points"),
 "Spielende bei": ("Game ends at", "El juego termina en", "Fin de partie à"),
 "%lld Punkten": ("%lld points", "%lld puntos", "%lld points"),
 "Wer die Runde gewinnt, bekommt nichts; die anderen die Augen ihrer Restkarten (Bube 20, Ass 11, Dame und König 10, Zahlen ihre Augen). Wer zuerst die Zielsumme erreicht, verliert.":
   ("Whoever wins the round gets nothing; the others get the points of their remaining cards (Jack 20, Ace 11, Queen and King 10, number cards their value). The first to reach the target loses.",
    "Quien gana la ronda no recibe nada; los demás reciben los puntos de sus cartas restantes (jota 20, as 11, reina y rey 10, números su valor). Quien primero alcance la meta, pierde.",
    "Celui qui gagne la manche ne reçoit rien ; les autres reçoivent les points de leurs cartes restantes (valet 20, as 11, dame et roi 10, chiffres leur valeur). Le premier à atteindre l'objectif perd."),
 "Ab fünf Personen wird mit zwei Blättern gespielt (64 Karten).": ("From five players on, two decks are used (64 cards).", "A partir de cinco jugadores se juega con dos barajas (64 cartas).", "À partir de cinq joueurs, on joue avec deux jeux (64 cartes)."),
 "Fertig": ("Done", "Listo", "Terminé"),
 "Mehr": ("More", "Más", "Plus"),
 "Spiel beenden": ("End game", "Terminar partida", "Terminer la partie"),
 "Farbe wünschen": ("Choose a suit", "Elige un palo", "Choisis une couleur"),
 "Kreuz": ("Clubs", "Tréboles", "Trèfle"),
 "Pik": ("Spades", "Picas", "Pique"),
 "Herz": ("Hearts", "Corazones", "Cœur"),
 "Karo": ("Diamonds", "Diamantes", "Carreau"),
 "Stapel": ("Draw pile", "Mazo", "Pioche"),
 "Ablage": ("Discard pile", "Descarte", "Défausse"),
 "Ablage, oben %@ %@, %lld Karten": ("Discard pile, top card %@ %@, %lld cards", "Descarte, arriba %@ %@, %lld cartas", "Défausse, dessus %@ %@, %lld cartes"),
 "+%lld für %@": ("+%lld for %@", "+%lld para %@", "+%lld pour %@"),
 "%@ setzt aus": ("%@ skips", "%@ pierde el turno", "%@ passe son tour"),
 "Wunsch: %@ %@": ("Wish: %@ %@", "Deseo: %@ %@", "Souhait : %@ %@"),
 "Farbe oder Wert": ("Suit or value", "Palo o valor", "Couleur ou valeur"),
 "Richtung gedreht": ("Direction reversed", "Sentido invertido", "Sens inversé"),
 "Die Partie beginnt.": ("The game begins.", "Empieza la partida.", "La partie commence."),
 "Partie zu Ende": ("Game over", "Partida terminada", "Partie terminée"),
 "Runde %lld · %@": ("Round %lld · %@", "Ronda %lld · %@", "Manche %lld · %@"),
 "%@ ist dran": ("%@'s turn", "Turno de %@", "C'est à %@"),
 "%@ legt %@ %@.": ("%@ plays %@ %@.", "%@ juega %@ %@.", "%@ pose %@ %@."),
 "%@ zieht %lld Karten.": ("%@ draws %lld cards.", "%@ roba %lld cartas.", "%@ pioche %lld cartes."),
 "%@ setzt aus.": ("%@ skips a turn.", "%@ pierde el turno.", "%@ passe son tour."),
 "%@ hat „Mau“ vergessen und zieht eine Strafkarte.": ("%@ forgot “Mau” and draws a penalty card.", "%@ olvidó «Mau» y roba una carta de castigo.", "%@ a oublié « Mau » et pioche une carte de pénalité."),
 "%@ wünscht sich %@.": ("%@ wishes for %@.", "%@ pide %@.", "%@ choisit %@."),
 "%@ dreht die Richtung.": ("%@ reverses direction.", "%@ invierte el sentido.", "%@ inverse le sens."),
 "%@ gewinnt die Runde": ("%@ wins the round", "%@ gana la ronda", "%@ gagne la manche"),
 "+%lld → %lld": ("+%lld → %lld", "+%lld → %lld", "+%lld → %lld"),
 "%@ denkt nach …": ("%@ is thinking …", "%@ está pensando …", "%@ réfléchit …"),
 "Gerät übergeben, dann aufdecken.": ("Hand over the device, then reveal.", "Pasa el dispositivo y luego descubre las cartas.", "Passe l'appareil, puis dévoile les cartes."),
 "Karten aufdecken": ("Reveal cards", "Descubrir cartas", "Dévoiler les cartes"),
 "%@ %@, Karte %lld von %lld": ("%@ %@, card %lld of %lld", "%@ %@, carta %lld de %lld", "%@ %@, carte %lld sur %lld"),
 "Tipp: Karte %lld von %lld, %@ %@.": ("Hint: card %lld of %lld, %@ %@.", "Pista: carta %lld de %lld, %@ %@.", "Indice : carte %lld sur %lld, %@ %@."),
 "%@ gewinnt mit den wenigsten Punkten": ("%@ wins with the fewest points", "%@ gana con menos puntos", "%@ gagne avec le moins de points"),
 "%@ gewinnt": ("%@ wins", "%@ gana", "%@ gagne"),
 "Ergebnis": ("Result", "Resultado", "Résultat"),
 "Nächste Runde": ("Next round", "Siguiente ronda", "Manche suivante"),
 "Mau!": ("Mau!", "¡Mau!", "Mau !"),
 "Mau sagen": ("Say Mau", "Decir Mau", "Dire Mau"),
 "gesagt": ("said", "dicho", "dit"),
 "noch nicht gesagt": ("not said yet", "aún no dicho", "pas encore dit"),
 "Tipp": ("Hint", "Pista", "Indice"),
 "%lld Karten ziehen": ("Draw %lld cards", "Robar %lld cartas", "Piocher %lld cartes"),
 "Weitergeben": ("Pass", "Pasar", "Passer"),
 "Karte ziehen": ("Draw a card", "Robar una carta", "Piocher une carte"),
 "Verlauf": ("History", "Historial", "Historique"),
 "Noch nichts passiert.": ("Nothing has happened yet.", "Todavía no ha pasado nada.", "Rien ne s'est encore passé."),
 "Regeln dieser Partie": ("Rules of this game", "Reglas de esta partida", "Règles de cette partie"),
 "%lld Karten auf der Hand": ("%lld cards in hand", "%lld cartas en la mano", "%lld cartes en main"),
 "7 lässt ziehen": ("7 makes the next player draw", "El 7 hace robar", "Le 7 fait piquer"),
 "8 setzt aus": ("8 skips", "El 8 salta", "Le 8 passe"),
 "9 wechselt die Richtung": ("9 reverses direction", "El 9 invierte el sentido", "Le 9 inverse le sens"),
 "„Mau“ sagen": ("Say “Mau”", "Decir «Mau»", "Dire « Mau »"),
 "Mehrere Runden bis %lld Punkte": ("Several rounds up to %lld points", "Varias rondas hasta %lld puntos", "Plusieurs manches jusqu'à %lld points"),
 "Zwei Blätter": ("Two decks", "Dos barajas", "Deux jeux"),
}

with open(PFAD, encoding="utf-8") as f:
    katalog = json.load(f)
s = katalog["strings"]
neu = 0
for de, (en, es, fr) in T.items():
    if de in s: continue
    s[de] = {"localizations": {l: {"stringUnit": {"state": "translated", "value": v}} for l, v in (("de", de), ("en", en), ("es", es), ("fr", fr))}}
    neu += 1
with open(PFAD, "w", encoding="utf-8") as f:
    json.dump(katalog, f, ensure_ascii=False, indent=2, separators=(",", ": "))
    f.write("\n")
print("neu eingetragen:", neu)
