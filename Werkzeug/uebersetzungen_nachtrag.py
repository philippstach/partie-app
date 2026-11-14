#!/usr/bin/env python3
"""uebersetzungen_nachtrag.py: ergänzt fehlende en/es/fr-Texte älterer Spiele (Truco, Escoba, Chinchón, Crazy Eights, Oware, Patolli, Perudo,
Brisca, Bunco, Spit, Minensuche, Übergabe-Seite …). Überschreibt nie vorhandene Übersetzungen. Aufruf aus dem Projektordner."""
import json, re, glob
KAT = 'App/Ressourcen/Localizable.xcstrings'
U = {
"Gerät weitergeben": ("Pass the device", "Pasa el dispositivo", "Passe l’appareil"),
"%@ ist dran.": ("It’s %@’s turn.", "Es el turno de %@.", "C’est au tour de %@."),
"Bereit": ("Ready", "Listo", "Prêt"),
"Partie fortsetzen": ("Continue game", "Continuar partida", "Reprendre la partie"),
"Letzte Runde wieder: %@": ("Same again: %@", "Repetir la última ronda: %@", "Même partie : %@"),
"Die App würfelt für dich.": ("The app rolls for you.", "La app tira los dados por ti.", "L’app lance les dés pour toi."),
"Du würfelst am Tisch und tippst die Augen ein.": ("You roll at the table and type in the pips.", "Tiras en la mesa y escribes los puntos.", "Tu lances à table et tu saisis les points."),
"Nardy": ("Long Nardy", "Nardy largo", "Nardy long"),
"Acey-Deucey! Wähle einen Pasch.": ("Acey-Deucey! Choose a double.", "¡Acey-Deucey! Elige un doble.", "Acey-Deucey ! Choisis un double."),
"Trumpf stechen, Augen sammeln": ("Trump and collect points", "Fallar con triunfo y sumar puntos", "Couper à l’atout et ramasser des points"),
"Atout · %lld im Stapel": ("Trump · %lld in the deck", "Triunfo · %lld en el mazo", "Atout · %lld dans la pioche"),
"Letzter Stich: %@ (%lld Augen)": ("Last trick: %@ (%lld points)", "Última baza: %@ (%lld puntos)", "Dernier pli : %@ (%lld points)"),
"Wähle eine Karte.": ("Choose a card.", "Elige una carta.", "Choisis une carte."),
"Tipp: Spiele die %lld (Farbe %lld).": ("Hint: play the %lld (suit %lld).", "Pista: juega el %lld (palo %lld).", "Indice : joue le %lld (couleur %lld)."),
"Sechs Runden, drei Würfel": ("Six rounds, three dice", "Seis rondas, tres dados", "Six manches, trois dés"),
"Runde %lld von 6 · Ziel: %lld": ("Round %lld of 6 · target: %lld", "Ronda %lld de 6 · objetivo: %lld", "Manche %lld sur 6 · cible : %lld"),
"Punkte in dieser Runde · gewonnene Runden": ("Points this round · rounds won", "Puntos en esta ronda · rondas ganadas", "Points de cette manche · manches gagnées"),
"%@ gewinnt die Runde!": ("%@ wins the round!", "¡%@ gana la ronda!", "%@ gagne la manche !"),
"Kein Treffer": ("No hit", "Sin acierto", "Raté"),
"Reihen und Sätze legen, Karten loswerden": ("Make runs and sets, get rid of your cards", "Forma escaleras y tríos, quédate sin cartas", "Fais des suites et des brelans, débarrasse-toi de tes cartes"),
"Strafpunkte (bei 100 ist Schluss)": ("Penalty points (out at 100)", "Puntos de penalización (eliminado a los 100)", "Points de pénalité (éliminé à 100)"),
"Stapel %lld": ("Deck %lld", "Mazo %lld", "Pioche %lld"),
"Offene Punkte: %lld (Schließen ab höchstens 5)": ("Open points: %lld (you may close at 5 or less)", "Puntos sueltos: %lld (puedes cerrar con 5 o menos)", "Points restants : %lld (tu peux fermer à 5 ou moins)"),
"%@ schließt. Punkte: %lld : %lld": ("%@ closes. Points: %lld : %lld", "%@ cierra. Puntos: %lld : %lld", "%@ ferme. Points : %lld : %lld"),
"Tippe eine Karte zum Ablegen.": ("Tap a card to discard.", "Toca una carta para descartar.", "Touche une carte à défausser."),
"Ziehe vom Stapel oder von der Ablage.": ("Draw from the deck or the discard pile.", "Roba del mazo o del descarte.", "Pioche dans la pioche ou la défausse."),
"%@ schließt!": ("%@ closes!", "¡%@ cierra!", "%@ ferme !"),
"Chinchón!": ("Chinchón!", "¡Chinchón!", "Chinchón !"),
"Farbe oder Zahl bedienen, Achter sind Joker": ("Match suit or number, eights are wild", "Sigue el palo o el número, los ochos son comodines", "Fournis la couleur ou le chiffre, les huit sont des jokers"),
"Zahl: Karten in der Hand": ("Number: cards in hand", "Número: cartas en la mano", "Nombre : cartes en main"),
"Farbe:": ("Suit:", "Palo:", "Couleur :"),
"Karte ziehen (%lld übrig)": ("Draw a card (%lld left)", "Robar carta (quedan %lld)", "Piocher une carte (%lld restantes)"),
"Tippe eine passende Karte.": ("Tap a card that fits.", "Toca una carta que encaje.", "Touche une carte qui convient."),
"%@ wünscht sich %@": ("%@ wishes for %@", "%@ pide %@", "%@ demande %@"),
"%@ setzt aus.": ("%@ skips a turn.", "%@ pierde el turno.", "%@ passe son tour."),
"Mach 15 und fege den Tisch": ("Make 15 and sweep the table", "Haz 15 y barre la mesa", "Fais 15 et balaie la table"),
"Gegner: %lld Karten · Stapel: %lld": ("Opponent: %lld cards · deck: %lld", "Rival: %lld cartas · mazo: %lld", "Adversaire : %lld cartes · pioche : %lld"),
"Summe: %lld von 15": ("Total: %lld of 15", "Suma: %lld de 15", "Somme : %lld sur 15"),
"%@ legt %lld ab.": ("%@ discards the %lld.", "%@ descarta el %lld.", "%@ défausse le %lld."),
"%@ sammelt mit der %lld ein.": ("%@ captures with the %lld.", "%@ captura con el %lld.", "%@ ramasse avec le %lld."),
"Ablegen": ("Discard", "Descartar", "Défausser"),
"Einsammeln": ("Capture", "Capturar", "Ramasser"),
"Wähle eine Handkarte.": ("Choose a card from your hand.", "Elige una carta de tu mano.", "Choisis une carte de ta main."),
"Tipp: Lege diese Karte ab.": ("Hint: discard this card.", "Pista: descarta esta carta.", "Indice : défausse cette carte."),
"Tipp: Sammle die markierten Karten ein.": ("Hint: capture the marked cards.", "Pista: captura las cartas marcadas.", "Indice : ramasse les cartes marquées."),
"Perudo": ("Perudo", "Perudo", "Perudo"),
"Bluffen mit Jokern": ("Bluffing with wilds", "Faroles con comodines", "Bluffer avec des jokers"),
"Palifico: Augenzahl bleibt, Einser sind keine Joker": ("Palifico: the number stays, ones are not wild", "Palifico: el número se mantiene, los unos no son comodines", "Palifico : le chiffre reste, les as ne sont pas des jokers"),
"Würfle unter dem Becher und tippe deine Würfel ein.": ("Roll under the cup and type in your dice.", "Tira bajo el cubilete y escribe tus dados.", "Lance sous le gobelet et saisis tes dés."),
"Würfel eintippen": ("Enter dice", "Introducir dados", "Saisir les dés"),
"Calza": ("Calza", "Calza", "Calza"),
"Du hast %@. Sage an (auch gelogen):": ("You have %@. Announce (lying is allowed):", "Tienes %@. Anuncia (también mintiendo):", "Tu as %@. Annonce (mentir est permis) :"),
"Aufgedeckt: %@ – %@ verliert ein Leben. (Ansage von %@: %@)": ("Revealed: %@ – %@ loses a life. (Announcement by %@: %@)", "Descubierto: %@ – %@ pierde una vida. (Anuncio de %@: %@)", "Dévoilé : %@ – %@ perd une vie. (Annonce de %@ : %@)"),
"Bestzeit %lld": ("Best time %lld", "Mejor tiempo %lld", "Meilleur temps %lld"),
"%lld: verdeckt": ("%lld: hidden", "%lld: oculta", "%lld : cachée"),
"%lld: Fahne": ("%lld: flag", "%lld: bandera", "%lld : drapeau"),
"%lld: Mine": ("%lld: mine", "%lld: mina", "%lld : mine"),
"%lld: leer": ("%lld: empty", "%lld: vacía", "%lld : vide"),
"%lld: %lld Minen in der Nähe": ("%lld: %lld mines nearby", "%lld: %lld minas cerca", "%lld : %lld mines à proximité"),
"Alle Minen gefunden in %lld": ("All mines found in %lld", "Todas las minas encontradas en %lld", "Toutes les mines trouvées en %lld"),
"Samen säen und erobern": ("Sow seeds and capture", "Siembra semillas y captura", "Sème des graines et capture"),
"Eroberte Samen (25 gewinnen)": ("Captured seeds (25 wins)", "Semillas capturadas (25 gana)", "Graines capturées (25 gagnent)"),
"Tippe eine deiner Mulden.": ("Tap one of your pits.", "Toca uno de tus hoyos.", "Touche l’un de tes trous."),
"Mulde %lld, %lld Samen": ("Pit %lld, %lld seeds", "Hoyo %lld, %lld semillas", "Trou %lld, %lld graines"),
"%@ erobert %lld Samen.": ("%@ captures %lld seeds.", "%@ captura %lld semillas.", "%@ capture %lld graines."),
"Bohnen werfen, Steine um den Ring führen": ("Toss beans, move pieces around the ring", "Lanza habas y mueve las fichas por el anillo", "Lance des haricots, fais avancer tes pions sur l’anneau"),
"Steine im Ziel": ("Pieces home", "Fichas en la meta", "Pions arrivés"),
"%lld Felder": ("%lld squares", "%lld casillas", "%lld cases"),
"Haus": ("Home", "Casa", "Maison"),
"Bohnen werfen": ("Toss beans", "Lanzar habas", "Lancer les haricots"),
"Tippe einen Stein, der ziehen soll.": ("Tap the piece you want to move.", "Toca la ficha que quieres mover.", "Touche le pion à déplacer."),
" – Schach!": (" – check!", " – ¡jaque!", " – échec !"),
"Schnell Karten loswerden, ohne Reihenfolge": ("Shed cards fast, no turns", "Deshazte rápido de las cartas, sin turnos", "Défausse vite tes cartes, sans tour de rôle"),
"Schnell legen!": ("Play fast!", "¡Juega rápido!", "Pose vite !"),
"Zahl: Karten übrig": ("Number: cards left", "Número: cartas restantes", "Nombre : cartes restantes"),
"Beide sitzen fest – neue Karten kommen …": ("Both stuck – new cards are coming …", "Ambos bloqueados: salen cartas nuevas …", "Les deux sont bloqués – de nouvelles cartes arrivent …"),
"Stechen, bluffen, Einsatz steigern": ("Win tricks, bluff, raise the stakes", "Gana bazas, farolea, sube la apuesta", "Fais des plis, bluffe, relève la mise"),
"Hand: %lld Punkte": ("Hand: %lld points", "Mano: %lld puntos", "Main : %lld points"),
"Dein Envido: %lld": ("Your Envido: %lld", "Tu envido: %lld", "Ton envido : %lld"),
"Annehmen": ("Accept", "Aceptar", "Accepter"),
"%@ denkt …": ("%@ is thinking …", "%@ está pensando …", "%@ réfléchit …"),
"Envido": ("Envido", "Envido", "Envido"),
"Truco": ("Truco", "Truco", "Truco"),
"Retruco": ("Retruco", "Retruco", "Retruco"),
"Vale cuatro": ("Vale cuatro", "Vale cuatro", "Vale cuatro"),
"%lld: Envido!": ("%lld: Envido!", "%lld: ¡Envido!", "%lld : Envido !"),
"%@ nimmt an.": ("%@ accepts.", "%@ acepta.", "%@ accepte."),
"%@ lehnt ab.": ("%@ declines.", "%@ rechaza.", "%@ refuse."),
}
RM = {
"Jeder hat drei Karten, die unterste Karte des Stapels zeigt das Trumpf-Atout.": (
 "Everyone has three cards; the bottom card of the deck shows the trump (atout). The starting player plays a card and the other answers with any card. The trick goes to the higher card of the same suit or to a trump. Then both draw, the trick winner first, and he or she leads the next trick. The cards have points: ace 11, three 10, king 4, knight 3, jack 2, all others 0 (120 in total). Order: ace, three, king, knight, jack, seven, six, five, four, two. Whoever has more than 60 points at the end wins.",
 "Cada jugador tiene tres cartas; la carta de abajo del mazo muestra el triunfo. El jugador que empieza juega una carta y el otro responde con cualquier carta. La baza se la lleva la carta más alta del mismo palo o un triunfo. Después ambos roban, primero quien ganó la baza, que sale en la siguiente. Las cartas tienen puntos: as 11, tres 10, rey 4, caballo 3, sota 2, las demás 0 (120 en total). Orden: as, tres, rey, caballo, sota, siete, seis, cinco, cuatro, dos. Al final gana quien tenga más de 60 puntos.",
 "Chacun a trois cartes ; la carte du dessous de la pioche indique l’atout. Le joueur qui commence pose une carte et l’autre répond avec n’importe quelle carte. Le pli revient à la carte la plus haute de la même couleur ou à un atout. Ensuite, les deux piochent, le gagnant du pli en premier, et il ouvre le pli suivant. Les cartes valent des points : as 11, trois 10, roi 4, cavalier 3, valet 2, toutes les autres 0 (120 au total). Ordre : as, trois, roi, cavalier, valet, sept, six, cinq, quatre, deux. Celui qui a plus de 60 points à la fin gagne."),
"Es gibt sechs Runden. In Runde 1 zählt die Eins": (
 "There are six rounds. In round 1 the one counts, in round 2 the two, and so on. You roll three dice: each die showing the round number gives 1 point. Three of them make a Bunco and give 21 points; three of any other matching dice make a Mini-Bunco worth 5 points. If you scored, you keep rolling, otherwise it’s the other player’s turn. Whoever reaches 21 points first wins the round. Whoever has won more rounds after six rounds wins the game.",
 "Hay seis rondas. En la ronda 1 cuenta el uno, en la ronda 2 el dos y así sucesivamente. Tiras tres dados: cada dado con el número de la ronda vale 1 punto. Tres de ellos forman un Bunco y dan 21 puntos; tres dados iguales de otro número forman un Mini-Bunco de 5 puntos. Si has puntuado, sigues tirando; si no, le toca al otro. Quien llegue primero a 21 puntos gana la ronda. Tras seis rondas gana el juego quien haya ganado más rondas.",
 "Il y a six manches. À la manche 1, le un compte, à la manche 2, le deux, et ainsi de suite. Tu lances trois dés : chaque dé montrant le numéro de la manche rapporte 1 point. Trois dés ainsi font un Bunco et rapportent 21 points ; trois dés identiques d’un autre numéro font un Mini-Bunco de 5 points. Si tu as marqué, tu continues à lancer, sinon c’est à l’autre. Le premier à 21 points gagne la manche. Après six manches, celui qui a gagné le plus de manches gagne la partie."),
"Jeder hat sieben Karten aus einem 40er-Blatt. Du ziehst eine Karte vom Stapel": (
 "Everyone has seven cards from a 40-card deck. You draw a card from the deck or the top discard and then discard a card. The aim is combinations: three or four of a kind or runs of at least three cards of one suit (7 and 10 are neighbours). You may close if, after discarding, the remaining seven cards have at most 5 points outside combinations (face cards count 10, otherwise the number). The player who closes gets their leftover points (minus 10 for 0), the opponent gets theirs. Whoever reaches 100 points is out. A run of all seven cards (Chinchón) wins immediately.",
 "Cada jugador tiene siete cartas de una baraja de 40. Robas una carta del mazo o la de arriba del descarte y luego descartas una. El objetivo son combinaciones: tres o cuatro cartas iguales o escaleras de al menos tres cartas del mismo palo (el 7 y el 10 son vecinos). Puedes cerrar si, tras descartar, las siete cartas restantes suman como mucho 5 puntos fuera de combinaciones (las figuras valen 10, el resto su número). Quien cierra recibe sus puntos sobrantes (con 0, menos 10) y el rival los suyos. Quien llega a 100 puntos queda eliminado. Una escalera con las siete cartas (Chinchón) gana al instante.",
 "Chacun a sept cartes d’un jeu de 40. Tu piches une carte dans la pioche ou prends la carte du dessus de la défausse, puis tu défausses une carte. Le but est de former des combinaisons : trois ou quatre cartes identiques ou des suites d’au moins trois cartes d’une même couleur (le 7 et le 10 sont voisins). Tu peux fermer si, après la défausse, les sept cartes restantes ont au plus 5 points hors combinaisons (les figures comptent 10, sinon le chiffre). Celui qui ferme reçoit ses points restants (moins 10 pour 0), l’adversaire les siens. Celui qui atteint 100 points est éliminé. Une suite de sept cartes (Chinchón) gagne immédiatement."),
"Jeder bekommt sieben Karten. Du legst eine Karte auf den Ablagestapel, die in Farbe oder Zahl zur obersten Karte passt.": (
 "Everyone gets seven cards. You play a card on the discard pile that matches the top card in suit or number. Eights always fit: with one you wish for a suit. If you have nothing that fits, you draw up to three cards and then have to skip if still nothing fits. Whoever has no cards first wins and gets the points of the opponent’s cards (eight 50, face card 10, ace 1, otherwise the number).",
 "Cada jugador recibe siete cartas. Juegas una carta al descarte que coincida con la de arriba en palo o número. Los ochos siempre valen: con uno pides un palo. Si no tienes nada que encaje, robas hasta tres cartas y, si sigue sin encajar nada, pierdes el turno. Gana quien se queda primero sin cartas y recibe los puntos de las cartas del rival (ocho 50, figura 10, as 1, el resto su número).",
 "Chacun reçoit sept cartes. Tu poses sur la défausse une carte qui correspond à celle du dessus par la couleur ou le chiffre. Les huit vont toujours : avec un huit, tu demandes une couleur. Si tu n’as rien qui convienne, tu piches jusqu’à trois cartes et tu passes ton tour si rien ne convient encore. Le premier qui n’a plus de cartes gagne et reçoit les points des cartes de l’adversaire (huit 50, figure 10, as 1, sinon le chiffre)."),
"Gespielt wird mit 40 Karten (Rang 1–10, Bube 8, Reiter 9, König 10).": (
 "Played with 40 cards (ranks 1–10, jack 8, knight 9, king 10). Everyone has three cards in hand, four cards lie face up. Play a hand card and collect table cards with it so that the total is exactly 15. If that is possible, you must collect; otherwise you discard the card. If you sweep the table clear, you get an escoba (1 point, not on the last move). At the end the following count: escobas, seven of coins, most cards, most coins and most sevens (1 point each). The cards left on the table go to whoever collected last.",
 "Se juega con 40 cartas (valores 1–10, sota 8, caballo 9, rey 10). Cada jugador tiene tres cartas en la mano y cuatro están boca arriba en la mesa. Juega una carta de la mano y recoge con ella cartas de la mesa de modo que la suma sea exactamente 15. Si se puede, tienes que recoger; si no, descartas la carta. Si dejas la mesa limpia, consigues una escoba (1 punto, no en la última jugada). Al final cuentan: escobas, siete de oros, más cartas, más oros y más sietes (1 punto cada uno). Las cartas que quedan en la mesa son para quien recogió en último lugar.",
 "On joue avec 40 cartes (valeurs 1 à 10, valet 8, cavalier 9, roi 10). Chacun a trois cartes en main, quatre cartes sont visibles sur la table. Joue une carte de ta main et ramasse avec elle des cartes de la table de façon que la somme soit exactement 15. Si c’est possible, tu dois ramasser ; sinon tu défausses la carte. Si tu balaies la table, tu obtiens une escoba (1 point, pas au dernier coup). À la fin comptent : escobas, sept de deniers, le plus de cartes, le plus de deniers et le plus de sept (1 point chacun). Les cartes restant sur la table vont à celui qui a ramassé en dernier."),
"Jeder hat fünf verdeckte Würfel und sieht nur seine eigenen.": (
 "Everyone has five hidden dice and only sees their own. In turn you make a bid: how many dice of all players together show a certain number. Each bid must be higher than the previous one (more dice, or the same number of dice with a higher face). Instead of bidding you can challenge the last bid: it is revealed and counted. If the bid is right, the challenger loses a die, otherwise the bidder does. Whoever has no dice left is out; whoever remains wins. Perudo rules: ones are wild and count towards every other face. The first bid may not be on ones. If you switch to ones, half the number is enough (rounded up); if you switch back from ones, you need double plus one. If someone has only one die left, they play one “Palifico” round: everyone must stay with the face of their first bid and only raise the count, and ones are not wild. “Calza” (exactly right): if you claim the bid is exactly right, you win a die if you are right (five at most), otherwise you lose one.",
 "Cada jugador tiene cinco dados ocultos y solo ve los suyos. Por turnos haces una apuesta: cuántos dados de todos los jugadores juntos muestran un número determinado. Cada apuesta debe superar a la anterior (más dados, o los mismos con un número más alto). En lugar de apostar puedes dudar de la última apuesta: se descubre y se cuenta. Si la apuesta es correcta, el que dudó pierde un dado; si no, lo pierde el que apostó. Quien se queda sin dados queda eliminado; el que queda gana. Reglas de Perudo: los unos son comodines y cuentan para cualquier otro número. La primera apuesta no puede ser de unos. Si cambias a unos, basta la mitad (redondeando hacia arriba); si vuelves de unos, necesitas el doble más uno. Si a alguien solo le queda un dado, juega una vez «Palifico»: todos deben mantener el número de su primera apuesta y solo subir la cantidad, y los unos no son comodines. «Calza» (exacto): si afirmas que la apuesta es exacta, ganas un dado si aciertas (máximo cinco); si no, pierdes uno.",
 "Chacun a cinq dés cachés et ne voit que les siens. À tour de rôle, tu fais une enchère : combien de dés de tous les joueurs ensemble montrent un certain chiffre. Chaque enchère doit être supérieure à la précédente (plus de dés, ou autant de dés avec un chiffre plus haut). Au lieu d’enchérir, tu peux contester la dernière enchère : les dés sont dévoilés et comptés. Si l’enchère est juste, celui qui conteste perd un dé, sinon c’est l’enchérisseur. Celui qui n’a plus de dés est éliminé ; le dernier restant gagne. Règles du Perudo : les as sont des jokers et comptent pour tous les autres chiffres. La première enchère ne peut pas porter sur les as. Si tu passes aux as, la moitié suffit (arrondie au supérieur) ; si tu reviens des as, il te faut le double plus un. Si quelqu’un n’a plus qu’un dé, il joue une fois « Palifico » : tout le monde doit rester sur le chiffre de sa première enchère et seulement augmenter la quantité, et les as ne sont pas des jokers. « Calza » (exactement juste) : si tu affirmes que l’enchère est exacte, tu gagnes un dé si tu as raison (cinq au maximum), sinon tu en perds un."),
"Zwölf Mulden, je vier Samen.": (
 "Twelve pits, four seeds each. Everyone owns the six pits on their side. You take all the seeds from one of your pits and sow them one by one, counter-clockwise, into the following pits; with twelve or more seeds the starting pit is skipped. If your last seed lands in an opponent’s pit that then holds two or three seeds, you capture those and the opponent’s pits before it that hold two or three seeds. If that would take all of the opponent’s seeds, nothing happens. If the opponent has no seeds, you must give them some if you can. Whoever has captured 25 seeds wins.",
 "Doce hoyos, cuatro semillas en cada uno. Cada jugador posee los seis hoyos de su lado. Coges todas las semillas de uno de tus hoyos y las siembras una a una, en sentido contrario a las agujas del reloj, en los hoyos siguientes; con doce o más semillas se salta el hoyo de salida. Si tu última semilla cae en un hoyo rival que así queda con dos o tres semillas, capturas esas y las de los hoyos rivales anteriores con dos o tres semillas. Si con ello le quitaras todas las semillas al rival, no pasa nada. Si el rival no tiene semillas, debes darle alguna si puedes. Gana quien capture 25 semillas.",
 "Douze trous, quatre graines chacun. Chacun possède les six trous de son côté. Tu prends toutes les graines d’un de tes trous et tu les sèmes une à une, dans le sens inverse des aiguilles d’une montre, dans les trous suivants ; à douze graines ou plus, le trou de départ est sauté. Si ta dernière graine tombe dans un trou adverse qui contient alors deux ou trois graines, tu les captures ainsi que les trous adverses précédents contenant deux ou trois graines. Si tu prenais ainsi toutes les graines de l’adversaire, il ne se passe rien. Si l’adversaire n’a plus de graines, tu dois lui en donner si possible. Celui qui capture 25 graines gagne."),
"Patolli ist ein uraltes Brettspiel aus Mexiko.": (
 "Patolli is an ancient board game from Mexico. Everyone has four pieces and tosses five beans, each with one marked side. As many beans as show marked, that many squares you may move. Five marked beans are ten squares and an extra toss; no marked bean means you miss a turn. A piece enters from the home onto the start square of your colour and runs once around the ring to the goal. If you land on an opponent’s piece, it has to go back home. On the safe squares (start squares and the squares with a diamond) nobody can be captured and the opponent may not land there. A sun square gives you an extra toss. Whoever first has all four pieces home in the goal wins.",
 "El Patolli es un antiguo juego de mesa de México. Cada jugador tiene cuatro fichas y lanza cinco habas, cada una con una cara marcada. Tantas habas como muestren la cara marcada, tantas casillas puedes avanzar. Cinco habas marcadas son diez casillas y un lanzamiento extra; ninguna haba marcada significa perder el turno. Una ficha sale de la casa a la casilla de salida de tu color y recorre el anillo una vez hasta la meta. Si caes sobre una ficha rival, esta debe volver a casa. En las casillas seguras (las de salida y las del rombo) nadie puede ser capturado y el rival no puede caer allí. Una casilla de sol te da un lanzamiento extra. Gana quien primero tenga las cuatro fichas en la meta.",
 "Le Patolli est un très ancien jeu de plateau du Mexique. Chacun a quatre pions et lance cinq haricots, chacun avec une face marquée. Autant de haricots montrent la face marquée, autant de cases tu peux avancer. Cinq haricots marqués donnent dix cases et un lancer de plus ; aucun haricot marqué veut dire passer son tour. Un pion sort de la maison sur la case de départ de ta couleur et fait une fois le tour de l’anneau jusqu’à l’arrivée. Si tu tombes sur un pion adverse, il doit retourner à la maison. Sur les cases sûres (cases de départ et cases à losange), personne ne peut être pris et l’adversaire ne peut pas y atterrir. Une case soleil te donne un lancer de plus. Le premier qui a ses quatre pions à l’arrivée gagne."),
"Beide spielen gleichzeitig, es gibt keine Reihenfolge.": (
 "Both play at the same time; there is no turn order. Everyone has five cards in hand and a draw pile. Two piles lie in the middle. You may play a card from your hand onto a middle pile if it is exactly one higher or lower (the ace lies between king and two, it wraps around). After every card you play, your hand is refilled to five. Whoever has no cards first wins. If nobody can play any more, two new cards are turned up in the middle automatically.",
 "Los dos juegan a la vez; no hay orden de turnos. Cada uno tiene cinco cartas en la mano y un mazo para robar. En el centro hay dos pilas. Puedes jugar una carta de tu mano sobre una pila central si es exactamente un valor más alta o más baja (el as está entre el rey y el dos, se da la vuelta). Tras cada carta jugada, tu mano vuelve a tener cinco. Gana quien se quede primero sin cartas. Si nadie puede jugar más, en el centro se descubren automáticamente dos cartas nuevas.",
 "Les deux jouent en même temps, il n’y a pas d’ordre de tour. Chacun a cinq cartes en main et une pioche. Deux piles se trouvent au milieu. Tu peux poser une carte de ta main sur une pile du milieu si elle est exactement d’une valeur plus haute ou plus basse (l’as est entre le roi et le deux, on tourne en rond). Après chaque carte posée, ta main est complétée à cinq. Le premier qui n’a plus de cartes gagne. Si plus personne ne peut jouer, deux nouvelles cartes sont retournées automatiquement au milieu."),
"Jeder bekommt drei Karten aus einem 40er-Blatt ohne 8 und 9.": (
 "Everyone gets three cards from a 40-card deck without 8s and 9s. There are up to three tricks; whoever wins two wins the hand. The strongest cards are the ace of swords, ace of clubs, seven of swords and seven of coins, then all threes, twos, the remaining aces, twelves, elevens, tens, the other sevens, sixes, fives, fours. If a trick is tied (parda), the first trick decides. Before the first trick you can call Envido: two cards of the same suit count 20 plus their values (face cards 0), otherwise the highest card counts; the higher value gets 2 points, in a tie the starting player. With Truco you raise the hand value to 2; the opponent can answer with Retruco (3) and Vale cuatro (4) or give up. Whoever reaches 15 points wins.",
 "Cada jugador recibe tres cartas de una baraja de 40 sin 8 ni 9. Hay hasta tres bazas; quien gana dos gana la mano. Las cartas más fuertes son el as de espadas, el as de bastos, el siete de espadas y el siete de oros; después todos los tres, los dos, los demás ases, doces, onces, dieces, los demás sietes, seises, cincos y cuatros. Si hay empate en una baza (parda), decide la primera baza. Antes de la primera baza puedes cantar Envido: dos cartas del mismo palo valen 20 más sus valores (las figuras 0); si no, cuenta la carta más alta; el valor más alto se lleva 2 puntos, y en caso de empate el jugador que empieza. Con Truco subes el valor de la mano a 2; el rival puede responder con Retruco (3) y Vale cuatro (4) o rendirse. Gana quien llegue a 15 puntos.",
 "Chacun reçoit trois cartes d’un jeu de 40 sans 8 ni 9. Il y a jusqu’à trois plis ; celui qui en gagne deux gagne la main. Les cartes les plus fortes sont l’as d’épées, l’as de bâtons, le sept d’épées et le sept de deniers, puis tous les trois, les deux, les autres as, les douze, onze, dix, les autres sept, six, cinq, quatre. En cas d’égalité dans un pli (parda), le premier pli décide. Avant le premier pli, tu peux annoncer Envido : deux cartes de la même couleur valent 20 plus leurs valeurs (figures 0), sinon la plus haute carte compte ; la valeur la plus haute obtient 2 points, en cas d’égalité le joueur qui commence. Avec Truco, tu relèves la valeur de la main à 2 ; l’adversaire peut répondre par Retruco (3) et Vale cuatro (4) ou abandonner. Le premier à 15 points gagne."),
}
cat = json.load(open(KAT)); s = cat['strings']
def eintragen(k, t):
    loc = s.setdefault(k, {}).setdefault('localizations', {})
    if 'en' in loc: return 0
    for sp, v in zip(('en', 'es', 'fr'), t):
        loc[sp] = {"stringUnit": {"state": "translated", "value": v}}
    return 1
n = 0
for k, t in U.items(): n += eintragen(k, t)
for f in glob.glob('Pakete/Spiel*/Sources/Spiel*/*.swift'):
    for m in re.finditer(r'"((?:[^"\\]|\\.)*)"', open(f).read()):
        de = m.group(1)
        if len(de) < 80: continue
        for anfang, t in RM.items():
            if de.startswith(anfang): n += eintragen(de, t)
text = json.dumps(cat, ensure_ascii=False, indent=2, separators=(',', ': '))
orig = open(KAT).read()
open(KAT, 'w').write(text + ('\n' if orig.endswith('\n') else ''))
print('eingetragen:', n)
