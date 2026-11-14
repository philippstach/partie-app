#!/usr/bin/env python3
"""uebersetzungen_elferraus_neu.py: en/es/fr für die Texte von „Elfer raus (neu)“ (Paket SpielElferRaus). Überschreibt nichts Vorhandenes."""
import json
KAT = 'App/Ressourcen/Localizable.xcstrings'
U = {
"Elfer raus (neu)": ("Eleven Out (new)", "Fuera el once (nuevo)", "Onze dehors (nouveau)"),
"Vier Farben, Karten von 1 bis 20. Jeder bekommt zehn Karten, der Rest ist der Stapel. Die rote 11 liegt zuerst. Danach legst du Karten an: Jede Farbe beginnt mit ihrer 11 und wächst nach oben und unten, immer um genau eine Zahl. Du darfst so viele Karten anlegen, wie du kannst und willst, und beendest dann deinen Zug. Passt keine Karte, ziehst du eine vom Stapel; ist der Stapel leer, passt du. Wer als Erster keine Karten mehr hat, gewinnt. Die übrigen Karten zählen als Minuspunkte. In der Variante Kartendomino (Skatblatt 7 bis Ass) legst du nur eine Karte je Zug und passt, wenn nichts geht.":
  ("Four colours, cards from 1 to 20. Everyone gets ten cards, the rest is the draw pile. The red 11 is laid first. Then you add cards: each colour starts with its 11 and grows upwards and downwards, always by exactly one number. You may add as many cards as you can and want, then end your turn. If no card fits, you draw one from the pile; if the pile is empty, you pass. Whoever has no cards left first wins. The remaining cards count as minus points. In the Card Domino variant (32-card deck, 7 to ace) you play only one card per turn and pass if nothing fits.",
   "Cuatro colores, cartas del 1 al 20. Cada uno recibe diez cartas, el resto es el mazo. El 11 rojo se pone primero. Después se añaden cartas: cada color empieza con su 11 y crece hacia arriba y hacia abajo, siempre de uno en uno. Puedes añadir tantas cartas como puedas y quieras, y luego terminas tu turno. Si ninguna carta encaja, robas una del mazo; si el mazo está vacío, pasas. Gana quien se quede primero sin cartas. Las cartas restantes cuentan como puntos negativos. En la variante Dominó de cartas (baraja de 32, del 7 al as) juegas una sola carta por turno y pasas si nada encaja.",
   "Quatre couleurs, cartes de 1 à 20. Chacun reçoit dix cartes, le reste forme la pioche. Le 11 rouge est posé en premier. Ensuite, on pose des cartes : chaque couleur commence par son 11 et s’étend vers le haut et vers le bas, toujours d’un seul chiffre. Tu peux poser autant de cartes que tu peux et veux, puis tu termines ton tour. Si aucune carte ne convient, tu en piches une ; si la pioche est vide, tu passes. Le premier sans cartes gagne. Les cartes restantes comptent comme points négatifs. Dans la variante Domino de cartes (jeu de 32, du 7 à l’as), tu ne poses qu’une carte par tour et tu passes si rien ne va."),
"Werde alle deine Karten los, bevor es die anderen schaffen.": ("Get rid of all your cards before the others do.", "Quédate sin cartas antes que los demás.", "Débarrasse-toi de toutes tes cartes avant les autres."),
"Mit der Elf beginnen": ("Start with the eleven", "Empezar con el once", "Commencer par le onze"),
"Die rote 11 liegt zuerst. Jede Farbe beginnt mit ihrer 11.": ("The red 11 is laid first. Each colour starts with its 11.", "El 11 rojo se pone primero. Cada color empieza con su 11.", "Le 11 rouge est posé en premier. Chaque couleur commence par son 11."),
"Anlegen": ("Add cards", "Añadir cartas", "Poser des cartes"),
"Lege nach oben und unten an, immer die nächste Zahl. So viele Karten du kannst.": ("Add upwards and downwards, always the next number. As many cards as you can.", "Añade hacia arriba y hacia abajo, siempre el número siguiente. Tantas cartas como puedas.", "Pose vers le haut et le bas, toujours le chiffre suivant. Autant de cartes que tu peux."),
"Hand leeren": ("Empty your hand", "Vaciar la mano", "Vider sa main"),
"Passt nichts, ziehst du eine Karte. Wer zuerst keine Karten mehr hat, gewinnt.": ("If nothing fits, you draw a card. Whoever has no cards left first wins.", "Si nada encaja, robas una carta. Gana quien se quede primero sin cartas.", "Si rien ne convient, tu piches une carte. Le premier sans cartes gagne."),
"Neue Verteilung?": ("New deal?", "¿Repartir de nuevo?", "Nouvelle donne ?"),
"Elfer raus (1–20)": ("Eleven Out (1–20)", "Fuera el once (1–20)", "Onze dehors (1–20)"),
"Kartendomino (Skatblatt)": ("Card Domino (32-card deck)", "Dominó de cartas (baraja de 32)", "Domino de cartes (jeu de 32)"),
"Zug beenden": ("End turn", "Terminar turno", "Finir le tour"),
"%lld Karten": ("%lld cards", "%lld cartas", "%lld cartes"),
"Runde beendet": ("Round over", "Ronda terminada", "Manche terminée"),
"Die rote 11 liegt. Wer legt an?": ("The red 11 is down. Who adds a card?", "El 11 rojo está en la mesa. ¿Quién añade?", "Le 11 rouge est posé. Qui pose ?"),
"%@ legt %@ %@": ("%@ plays %@ %@", "%@ juega %@ %@", "%@ pose %@ %@"),
"%@ zieht eine Karte": ("%@ draws a card", "%@ roba una carta", "%@ pioche une carte"),
"%@ passt": ("%@ passes", "%@ pasa", "%@ passe"),
"%@ beendet den Zug": ("%@ ends the turn", "%@ termina el turno", "%@ termine le tour"),
"%@: noch nicht begonnen": ("%@: not started yet", "%@: aún sin empezar", "%@ : pas encore commencé"),
"%@: %lld bis %lld ausgelegt": ("%@: %lld to %lld laid", "%@: del %lld al %lld puestas", "%@ : de %lld à %lld posées"),
"Tipp: %@ %@ anlegen.": ("Hint: add %@ %@.", "Pista: añade %@ %@.", "Astuce : pose %@ %@."),
"Elfer raus: mehrere Karten je Zug, Karte ziehen statt passen.": ("Eleven Out: several cards per turn, draw a card instead of passing.", "Fuera el once: varias cartas por turno, robar en lugar de pasar.", "Onze dehors : plusieurs cartes par tour, piocher au lieu de passer."),
"Kartendomino: eine Karte je Zug, passen erlaubt.": ("Card Domino: one card per turn, passing allowed.", "Dominó de cartas: una carta por turno, se puede pasar.", "Domino de cartes : une carte par tour, passer autorisé."),
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
