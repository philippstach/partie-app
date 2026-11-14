#!/usr/bin/env python3
"""uebersetzungen_arcade.py: trägt die Texte der Arcade-Spiele (en, es, fr) in App/Ressourcen/Localizable.xcstrings ein.
Regeltexte werden aus den Swift-Quellen gelesen (Schlüssel = deutscher Text). Aufruf aus Partie/Haupt (oder Arcade-Worktree)."""
import json, re, glob
KAT = 'App/Ressourcen/Localizable.xcstrings'
U = {
"Tippe zum Starten": ("Tap to start", "Toca para empezar", "Touche pour commencer"),
"Rekord: %lld": ("Best: %lld", "Récord: %lld", "Record : %lld"),
"Rekord": ("Best", "Récord", "Record"),
"Pause – tippen zum Weiterspielen": ("Paused – tap to resume", "En pausa – toca para continuar", "En pause – touche pour reprendre"),
"Aus!": ("Game over!", "¡Fin del juego!", "Perdu !"),
"Neuer Rekord!": ("New record!", "¡Nuevo récord!", "Nouveau record !"),
"Noch einmal": ("Again", "Otra vez", "Rejouer"),
"Nächster": ("Next", "Siguiente", "Suivant"),
"Reihen: %lld": ("Rows: %lld", "Filas: %lld", "Lignes : %lld"),
"Stufe %lld": ("Level %lld", "Nivel %lld", "Niveau %lld"),
"%lld Reihen": ("%lld rows", "%lld filas", "%lld lignes"),
"%lld Sprünge": ("%lld jumps", "%lld saltos", "%lld sauts"),
"Längster Ballwechsel: %lld": ("Longest rally: %lld", "Intercambio más largo: %lld", "Plus long échange : %lld"),
"Links": ("Left", "Izquierda", "Gauche"),
"Rechts": ("Right", "Derecha", "Droite"),
"Drehen": ("Rotate", "Girar", "Tourner"),
"Fallen lassen": ("Drop", "Soltar", "Lâcher"),
"Steine stapeln, Reihen auflösen": ("Stack pieces, clear rows", "Apila piezas, borra filas", "Empiler les pièces, effacer les lignes"),
"Immer höher hüpfen": ("Hop ever higher", "Salta cada vez más alto", "Sauter toujours plus haut"),
"Mauer knacken, Serie halten": ("Crack the wall, keep the streak", "Rompe el muro, mantén la racha", "Briser le mur, garder la série"),
"Das Schläger-Duell": ("The paddle duel", "El duelo de palas", "Le duel de raquettes"),
"Tippe zum Hüpfen": ("Tap to hop", "Toca para saltar", "Touche pour sauter"),
"Tippe, um loszulaufen": ("Tap to start running", "Toca para empezar a correr", "Touche pour partir"),
"Tippe, um den Ball abzuschießen": ("Tap to launch the ball", "Toca para lanzar la bola", "Touche pour lancer la balle"),
"Finger ziehen lenkt den Schläger": ("Drag your finger to move the paddle", "Arrastra el dedo para mover la pala", "Fais glisser le doigt pour bouger la raquette"),
"Mit dem Finger nach links und rechts lenken": ("Steer left and right with your finger", "Dirige a izquierda y derecha con el dedo", "Dirige à gauche et à droite avec le doigt"),
"Ein Spieler: Wie viele Punkte schaffst du?": ("One player: how many points can you get?", "Un jugador: ¿cuántos puntos consigues?", "Un joueur : combien de points peux-tu faire ?"),
"Ein Spieler: Wie hoch kommst du?": ("One player: how high can you get?", "Un jugador: ¿hasta dónde subes?", "Un joueur : jusqu’où peux-tu monter ?"),
"Ein Spieler: Du gegen die Schwerkraft.": ("One player: you against gravity.", "Un jugador: tú contra la gravedad.", "Un joueur : toi contre la gravité."),
"Ziehen: verschieben · Tippen: drehen · Nach unten ziehen: schneller": ("Drag: move · Tap: rotate · Drag down: faster", "Arrastrar: mover · Tocar: girar · Arrastrar abajo: más rápido", "Glisser : déplacer · Toucher : tourner · Glisser vers le bas : plus vite"),
"Tippen = springen · nach unten wischen = ducken": ("Tap = jump · swipe down = duck", "Tocar = saltar · deslizar abajo = agacharse", "Toucher = sauter · glisser vers le bas = se baisser"),
"Finger ziehen bewegt deinen Schläger – Kante lenkt steiler": ("Drag to move your paddle – the edge angles the ball more", "Arrastra para mover tu pala: el borde desvía más la bola", "Glisse pour bouger ta raquette – le bord dévie davantage la balle"),
"Jeder Spieler zieht in seiner Hälfte": ("Each player drags in their own half", "Cada jugador arrastra en su mitad", "Chaque joueur glisse dans sa moitié"),
# Gründe fürs Spielende (werden zur Laufzeit nachgeschlagen)
"Die Steine stoßen oben an": ("The pieces reached the top", "Las piezas llegaron arriba", "Les pièces ont atteint le haut"),
"Du bist unten aus dem Bild gefallen": ("You fell off the bottom of the screen", "Te caíste por abajo de la pantalla", "Tu es tombé en bas de l’écran"),
"Ins Loch gefallen": ("Fell into a hole", "Caíste en un agujero", "Tombé dans un trou"),
"Gegen eine Hürde gelaufen": ("Ran into a hurdle", "Chocaste con una valla", "Tu as heurté une haie"),
"Gegen einen Balken gelaufen": ("Ran into a beam", "Chocaste con una viga", "Tu as heurté une poutre"),
"Alle Bälle verloren": ("All balls lost", "Perdiste todas las bolas", "Toutes les balles perdues"),
"Die Mauer hat dich erreicht": ("The wall reached you", "El muro te alcanzó", "Le mur t’a atteint"),
"Spielende": ("Game over", "Fin de la partida", "Fin de la partie"),
}
RM = {  # Regeltexte nach Anfang des deutschen Textes
"Fünferteile fallen": ("Five-block pieces fall into a field. Move them, rotate them and let them land. A row filled without gaps dissolves and scores points – several rows at once score much more. Every six rows cleared, it gets faster. A landed piece can still be shifted briefly. The game is over when a new piece no longer fits at the top. Controls: drag left or right to move, tap to rotate, drag down to speed up, swipe down to drop the piece at once – or use the buttons below.",
 "Piezas de cinco bloques caen en un campo. Muévelas, gíralas y déjalas aterrizar. Una fila llena sin huecos se disuelve y da puntos; varias filas a la vez dan mucho más. Cada seis filas borradas va más rápido. Una pieza aterrizada aún se puede mover un momento. El juego termina cuando una pieza nueva ya no cabe arriba. Control: arrastra a izquierda o derecha para mover, toca para girar, arrastra hacia abajo para acelerar, desliza hacia abajo para soltar la pieza de golpe, o usa los botones de abajo.",
 "Des pièces de cinq blocs tombent dans un champ. Déplace-les, fais-les pivoter et laisse-les se poser. Une ligne remplie sans trou disparaît et rapporte des points – plusieurs lignes à la fois en rapportent beaucoup plus. Toutes les six lignes effacées, ça va plus vite. Une pièce posée peut encore être décalée un court instant. La partie est finie quand une nouvelle pièce ne tient plus en haut. Commandes : glisse à gauche ou à droite pour déplacer, touche pour tourner, glisse vers le bas pour accélérer, balaie vers le bas pour lâcher la pièce aussitôt – ou utilise les boutons en dessous."),
"Dein Hüpfer springt": ("Your hopper jumps by itself. Drag your finger left and right to steer – at the edge you reappear on the other side. You only land while falling. White clouds always hold, blue ones drift back and forth, grey clouds break away after the jump, and the yellow spring flings you extra high. The higher you get, the smaller the clouds and the further apart they are. If you fall out of the bottom of the screen, the game is over. The height you reach is your score.",
 "Tu saltarín salta solo. Arrastra el dedo a izquierda y derecha para dirigirlo; por el borde reapareces al otro lado. Solo aterrizas al caer. Las nubes blancas siempre sostienen, las azules van de un lado a otro, las grises se rompen tras el salto y el muelle amarillo te lanza extra alto. Cuanto más subes, más pequeñas y separadas están las nubes. Si caes por la parte de abajo de la pantalla, termina el juego. La altura que alcanzas es tu puntuación.",
 "Ton sauteur saute tout seul. Fais glisser le doigt à gauche et à droite pour le diriger ; au bord, tu réapparais de l’autre côté. Tu n’atterris qu’en tombant. Les nuages blancs portent toujours, les bleus vont et viennent, les gris se brisent après le saut, et le ressort jaune te projette très haut. Plus tu montes, plus les nuages sont petits et espacés. Si tu tombes en bas de l’écran, c’est fini. La hauteur atteinte est ton score."),
"Dein Läufer rennt": ("Your runner runs by itself and keeps getting faster. Tap the field to jump: over hurdles and over holes in the ground. If you tap just before landing, you jump again right away. Swipe down to duck when a beam hangs in the air. Collect the pearls along the way – each is worth ten extra points. If you hit something or fall into a hole, the run is over. The metres run plus the pearls are your score.",
 "Tu corredor corre solo y cada vez más rápido. Toca el campo para saltar: sobre vallas y sobre agujeros en el suelo. Si tocas justo antes de aterrizar, saltas de nuevo enseguida. Desliza hacia abajo para agacharte cuando cuelga una viga en el aire. Recoge las perlas del camino: cada una vale diez puntos extra. Si chocas o caes en un agujero, la carrera termina. Los metros recorridos más las perlas son tu puntuación.",
 "Ton coureur court tout seul et va de plus en plus vite. Touche le champ pour sauter : par-dessus les haies et les trous dans le sol. Si tu touches juste avant l’atterrissage, tu sautes aussitôt de nouveau. Glisse vers le bas pour te baisser quand une poutre est suspendue. Ramasse les perles en chemin : chacune vaut dix points de plus. Si tu heurtes quelque chose ou tombes dans un trou, la course est finie. Les mètres parcourus plus les perles font ton score."),
"Lenke den Schläger": ("Move the paddle with your finger and don’t let the ball fall. Tap to launch the ball. Every hit breaks a brick; hard bricks need several hits. If you land several hits in a row without the ball touching the paddle, your multiplier rises up to ×4. Bricks sometimes drop gifts: a wider paddle, three balls or an extra life – catch them with the paddle. The wall slowly moves down; if it reaches the paddle, the game is over. You have three lives. When the wall is gone, a new one appears and the ball gets faster.",
 "Mueve la pala con el dedo y no dejes caer la bola. Toca para lanzar la bola. Cada golpe rompe un ladrillo; los duros necesitan varios golpes. Si consigues varios golpes seguidos sin que la bola toque la pala, tu multiplicador sube hasta ×4. De los ladrillos caen a veces regalos: pala más ancha, tres bolas o una vida extra; atrápalos con la pala. El muro baja despacio; si llega a la pala, termina el juego. Tienes tres vidas. Cuando no queda muro, aparece uno nuevo y la bola va más rápido.",
 "Bouge la raquette avec le doigt et ne laisse pas tomber la balle. Touche pour lancer la balle. Chaque coup casse une brique ; les briques dures en demandent plusieurs. Si tu enchaînes plusieurs coups sans que la balle touche la raquette, ton multiplicateur monte jusqu’à ×4. Les briques lâchent parfois des cadeaux : raquette plus large, trois balles ou une vie en plus – attrape-les avec la raquette. Le mur descend lentement ; s’il atteint la raquette, c’est fini. Tu as trois vies. Quand le mur a disparu, un nouveau apparaît et la balle va plus vite."),
"Schlage den Ball": ("Hit the ball back with your paddle and get it past your opponent. Drag your finger to move the paddle – it follows you as fast as it can. If the ball hits the edge of the paddle, it flies off at a sharper angle and faster; every hit speeds the ball up, and after every point it starts slowly again. Whoever loses a point gets the next ball. The first to seven points wins. Alone you play against the computer, which makes mistakes over time; with two players, the second player drags in the upper half.",
 "Devuelve la bola con tu pala y haz que pase a tu rival. Arrastra el dedo para mover la pala: te sigue lo más rápido que puede. Si la bola golpea el borde de la pala, sale más inclinada y más rápida; cada golpe acelera la bola y tras cada punto vuelve a empezar despacio. Quien pierde un punto recibe la siguiente bola. Gana quien llegue primero a siete puntos. Solo juegas contra el ordenador, que con el tiempo comete errores; con dos jugadores, el segundo arrastra en la mitad de arriba.",
 "Renvoie la balle avec ta raquette et fais-la passer chez l’adversaire. Fais glisser le doigt pour bouger la raquette – elle te suit aussi vite qu’elle peut. Si la balle touche le bord de la raquette, elle repart plus en biais et plus vite ; chaque coup accélère la balle, et après chaque point elle repart lentement. Celui qui perd un point reçoit la balle suivante. Le premier à sept points gagne. Seul, tu joues contre l’ordinateur, qui finit par faire des fautes ; à deux, le second joueur glisse dans la moitié du haut."),
}
cat = json.load(open(KAT)); s = cat['strings']
def eintragen(k, t):
    loc = s.setdefault(k, {}).setdefault('localizations', {})
    for sp, v in zip(('en', 'es', 'fr'), t):
        loc[sp] = {"stringUnit": {"state": "translated", "value": v}}
for k, t in U.items(): eintragen(k, t)
n = len(U)
for f in glob.glob('Pakete/Spiel*/Sources/Spiel*/*.swift'):
    for m in re.finditer(r'regeln: "((?:[^"\\]|\\.)*)"', open(f).read()):
        de = m.group(1)
        for anfang, t in RM.items():
            if de.startswith(anfang): eintragen(de, t); n += 1
text = json.dumps(cat, ensure_ascii=False, indent=2, separators=(',', ': '))
orig = open(KAT).read()
open(KAT, 'w').write(text + ('\n' if orig.endswith('\n') else ''))
print('eingetragen:', n)
