#!/usr/bin/env python3
"""uebersetzungen_schwimmen_neu.py: en/es/fr für die Texte von „Schwimmen (neu)“ (Paket SpielSchwimmen). Überschreibt nichts Vorhandenes."""
import json, re
KAT = 'App/Ressourcen/Localizable.xcstrings'
REGEL = re.search(r'regeln: "(Jeder hat drei Karten.*?)",\n', open('Pakete/SpielSchwimmen/Sources/SpielSchwimmen/Modul.swift').read()).group(1)
U = {
"Schwimmen (neu)": ("Thirty-one (new)", "Treinta y uno (nuevo)", "Trente et un (nouveau)"),
REGEL: ("Everyone has three cards, three lie face up in the middle. You swap one card, all three, pass or knock. Only the suit with the highest total counts (ace 11, face card 10); three of a kind is 30.5, and 31 ends the round at once. After a knock everyone gets one more turn. The lowest hand loses a life; whoever loses at zero lives is out. The last one standing wins. In the “More” menu you set house rules: lives, 31, 33 with three aces, pass limit, value of three of a kind and the points mode (total over several rounds).",
        "Cada uno tiene tres cartas y tres están boca arriba en el centro. Cambias una carta, las tres, pasas o golpeas. Solo cuenta el palo con la suma más alta (as 11, figura 10); tres iguales valen 30,5 y 31 termina la ronda al instante. Tras golpear, todos juegan una vez más. La mano más baja pierde una vida; quien pierde con cero vidas queda fuera. Gana el último que queda. En el menú «Más» ajustas reglas de la casa: vidas, 31, 33 con tres ases, límite de pasar, valor de tres iguales y el modo por puntos (suma de varias rondas).",
        "Chacun a trois cartes, trois sont visibles au milieu. Tu échanges une carte, les trois, tu passes ou tu frappes. Seule compte la couleur dont le total est le plus élevé (as 11, figure 10) ; trois identiques valent 30,5 et 31 met fin à la manche aussitôt. Après avoir frappé, chacun joue encore une fois. La main la plus basse perd une vie ; qui perd à zéro vie est éliminé. Le dernier en jeu gagne. Dans le menu « Plus », tu règles des règles maison : vies, 31, 33 avec trois as, limite de passes, valeur de trois identiques et le mode par points (total sur plusieurs manches)."),
"Tippe eine Handkarte und eine Tischkarte an: Du siehst vorher, was der Tausch bringt.": ("Tap a hand card and a table card: you see what the swap brings first.", "Toca una carta de la mano y una de la mesa: ves antes lo que aporta el cambio.", "Touche une carte de ta main et une du tapis : tu vois d’abord ce que l’échange rapporte."),
"Punkte (5 Runden)": ("Points (5 rounds)", "Puntos (5 rondas)", "Points (5 manches)"),
"4 Leben": ("4 lives", "4 vidas", "4 vies"),
"31 beendet die Runde sofort": ("31 ends the round at once", "31 termina la ronda al instante", "31 met fin à la manche aussitôt"),
"33 mit drei Assen": ("33 with three aces", "33 con tres ases", "33 avec trois as"),
"Beliebig oft": ("As often as you like", "Tantas veces como quieras", "Aussi souvent que l’on veut"),
"Höchstens einmal": ("At most once", "Como máximo una vez", "Une fois au plus"),
"Drei Gleiche": ("Three of a kind", "Tres iguales", "Trois identiques"),
"30,5 Punkte": ("30.5 points", "30,5 puntos", "30,5 points"),
"30 Punkte": ("30 points", "30 puntos", "30 points"),
"schwimmt": ("swimming", "nada", "nage"),
"Tischkarte %lld: %@": ("Table card %lld: %@", "Carta de la mesa %lld: %@", "Carte du tapis %lld : %@"),
"Handkarte %lld: %@": ("Hand card %lld: %@", "Carta de la mano %lld: %@", "Carte de la main %lld : %@"),
"Tisch zählt %@": ("Table counts %@", "La mesa suma %@", "Le tapis vaut %@"),
"Drei Gleiche %@": ("Three of a kind %@", "Tres iguales %@", "Trois identiques %@"),
"Alle drei tauschen → %@": ("Swap all three → %@", "Cambiar las tres → %@", "Échanger les trois → %@"),
"Tausch: %@ gegen %@ → %@": ("Swap: %@ for %@ → %@", "Cambio: %@ por %@ → %@", "Échange : %@ contre %@ → %@"),
"Wähle noch eine Karte.": ("Pick one more card.", "Elige una carta más.", "Choisis encore une carte."),
"%@ hat %@!": ("%@ has %@!", "¡%@ tiene %@!", "%@ a %@ !"),
"Verliert ein Leben": ("Loses a life", "Pierde una vida", "Perd une vie"),
"%@ tauscht %@ gegen %@": ("%@ swaps %@ for %@", "%@ cambia %@ por %@", "%@ échange %@ contre %@"),
"%@ tauscht alle drei": ("%@ swaps all three", "%@ cambia las tres", "%@ échange les trois"),
"%@ schiebt": ("%@ passes", "%@ pasa", "%@ passe"),
"%@ klopft": ("%@ knocks", "%@ golpea", "%@ frappe"),
"%@ hat Feuer": ("%@ has 31", "%@ tiene 31", "%@ a 31"),
"Punkte, %lld Runden": ("Points, %lld rounds", "Puntos, %lld rondas", "Points, %lld manches"),
"31 beendet sofort": ("31 ends at once", "31 termina al instante", "31 termine aussitôt"),
"31 zählt nur beim Klopfen": ("31 only counts on a knock", "31 solo cuenta al golpear", "31 ne compte qu’en frappant"),
"Drei Asse = 33": ("Three aces = 33", "Tres ases = 33", "Trois as = 33"),
"Drei Gleiche = %@": ("Three of a kind = %@", "Tres iguales = %@", "Trois identiques = %@"),
"Schieben höchstens %lld×": ("Pass at most %lld×", "Pasar como máximo %lld×", "Passer %lld× au plus"),
"Schieben beliebig oft": ("Pass as often as you like", "Pasar sin límite", "Passer sans limite"),
"Tipp: Handkarte %lld gegen Tischkarte %lld tauschen bringt %@ Punkte.": ("Hint: swapping hand card %lld for table card %lld gives %@ points.", "Pista: cambiar la carta %lld de la mano por la %lld de la mesa da %@ puntos.", "Astuce : échanger la carte %lld de la main contre la %lld du tapis donne %@ points."),
"Tipp: Klopfen – %@ Punkte sind gut.": ("Hint: knock – %@ points are good.", "Pista: golpea – %@ puntos son buenos.", "Astuce : frappe – %@ points, c’est bien."),
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
