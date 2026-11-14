#!/usr/bin/env python3
"""uebersetzungen_neue_spiele.py: trägt die Texte der neu gebauten Spiele (Paarsuche … Steckspiel, Tipps, Tagesrätsel) in
App/Ressourcen/Localizable.xcstrings ein (en, es, fr). Regeltexte werden per Textanfang aus den Swift-Quellen gelesen.
Aufruf aus dem Projektordner (Partie/Haupt oder ein Worktree)."""
import json, re, glob
KAT = 'App/Ressourcen/Localizable.xcstrings'
U = {
# Gemeinsam
"Tipp (−25 Punkte)": ("Hint (−25 points)", "Pista (−25 puntos)", "Indice (−25 points)"),
"Neuer Lauf": ("New run", "Nueva partida", "Nouvelle course"),
"Tageslauf": ("Daily run", "Partida del día", "Course du jour"),
"Tagesrätsel": ("Daily puzzle", "Reto del día", "Défi du jour"),
"Lauf beenden": ("End run", "Terminar partida", "Terminer la course"),
"Neue Bestleistung!": ("New best!", "¡Nuevo récord personal!", "Nouveau record personnel !"),
"Neue Bestzeit!": ("New best time!", "¡Nuevo mejor tiempo!", "Nouveau meilleur temps !"),
"Bestzeit: %lld s": ("Best time: %lld s", "Mejor tiempo: %lld s", "Meilleur temps : %lld s"),
"Bestzeit: %lld Sekunden": ("Best time: %lld seconds", "Mejor tiempo: %lld segundos", "Meilleur temps : %lld secondes"),
"Beste Punktzahl: %lld": ("Best score: %lld", "Mejor puntuación: %lld", "Meilleur score : %lld"),
"Beste Zugzahl: %lld": ("Fewest moves: %lld", "Menos movimientos: %lld", "Moins de coups : %lld"),
"Beste Stufenzahl: %lld": ("Best level: %lld", "Mejor nivel: %lld", "Meilleur niveau : %lld"),
"Bestleistung: %lld Versuche": ("Best: %lld attempts", "Mejor: %lld intentos", "Meilleur : %lld essais"),
"Bestleistung: %lld Züge": ("Best: %lld moves", "Mejor: %lld movimientos", "Meilleur : %lld coups"),
"Gelöst in %lld Sekunden": ("Solved in %lld seconds", "Resuelto en %lld segundos", "Résolu en %lld secondes"),
"Gelöst in %lld Sekunden!": ("Solved in %lld seconds!", "¡Resuelto en %lld segundos!", "Résolu en %lld secondes !"),
"%lld Tipps": ("%lld hints", "%lld pistas", "%lld indices"),
"%lld Sekunden, %lld Tipps": ("%lld seconds, %lld hints", "%lld segundos, %lld pistas", "%lld secondes, %lld indices"),
"Geschafft in %lld Sekunden": ("Done in %lld seconds", "Hecho en %lld segundos", "Terminé en %lld secondes"),
"%lld Züge in %lld Sekunden": ("%lld moves in %lld seconds", "%lld movimientos en %lld segundos", "%lld coups en %lld secondes"),
"Zug zurück (%lld)": ("Undo move (%lld)", "Deshacer jugada (%lld)", "Annuler le coup (%lld)"),
"2048 geschafft! ": ("2048 reached! ", "¡2048 conseguido! ", "2048 atteint ! "),
"Keine Züge mehr. ": ("No moves left. ", "No quedan jugadas. ", "Plus de coups possibles. "),
"Heute geschafft in %lld Zügen": ("Done today in %lld moves", "Hecho hoy en %lld movimientos", "Réussi aujourd’hui en %lld coups"),
"Heute gelöst in %lld Sekunden": ("Solved today in %lld seconds", "Resuelto hoy en %lld segundos", "Résolu aujourd’hui en %lld secondes"),
"Heute geknackt in %lld Versuchen": ("Cracked today in %lld attempts", "Descifrado hoy en %lld intentos", "Déchiffré aujourd’hui en %lld essais"),
"Tagesrätsel (%lld Scheiben)": ("Daily puzzle (%lld discs)", "Reto del día (%lld discos)", "Défi du jour (%lld disques)"),
"Tagesrätsel (für alle gleich)": ("Daily puzzle (same for everyone)", "Reto del día (igual para todos)", "Défi du jour (le même pour tous)"),
"Tagesrätsel (5 × 5, für alle gleich)": ("Daily puzzle (5 × 5, same for everyone)", "Reto del día (5 × 5, igual para todos)", "Défi du jour (5 × 5, le même pour tous)"),
"Tagesrätsel (Normal, für alle gleich)": ("Daily puzzle (normal, same for everyone)", "Reto del día (normal, igual para todos)", "Défi du jour (normal, le même pour tous)"),
"Tipp: von Stab %lld nach Stab %lld": ("Hint: from peg %lld to peg %lld", "Pista: del poste %lld al poste %lld", "Indice : de la tige %lld à la tige %lld"),
"mit Tipp": ("with hint", "con pista", "avec indice"),
# Paarsuche
"Finde alle Paare": ("Find all the pairs", "Encuentra todas las parejas", "Trouve toutes les paires"),
"Paarsuche": ("Pairs", "Parejas", "Paires"),
"Klein (12)": ("Small (12)", "Pequeño (12)", "Petit (12)"),
"Mittel (16)": ("Medium (16)", "Mediano (16)", "Moyen (16)"),
"Groß (20)": ("Large (20)", "Grande (20)", "Grand (20)"),
"Riesig (30)": ("Huge (30)", "Enorme (30)", "Géant (30)"),
"Motive": ("Themes", "Motivos", "Motifs"),
"%lld/%lld Paare": ("%lld/%lld pairs", "%lld/%lld parejas", "%lld/%lld paires"),
"Alle Paare in %lld Zügen": ("All pairs in %lld moves", "Todas las parejas en %lld jugadas", "Toutes les paires en %lld coups"),
# Irrgang
"Finde den Ausgang": ("Find the exit", "Encuentra la salida", "Trouve la sortie"),
"Stufe %lld geschafft": ("Level %lld cleared", "Nivel %lld superado", "Niveau %lld réussi"),
"nach oben ↑": ("up ↑", "hacia arriba ↑", "vers le haut ↑"),
"nach unten ↓": ("down ↓", "hacia abajo ↓", "vers le bas ↓"),
"nach links ←": ("left ←", "hacia la izquierda ←", "vers la gauche ←"),
"nach rechts →": ("right →", "hacia la derecha →", "vers la droite →"),
"%lld Schritte": ("%lld steps", "%lld pasos", "%lld pas"),
"Ausgang gefunden! +%lld": ("Exit found! +%lld", "¡Salida encontrada! +%lld", "Sortie trouvée ! +%lld"),
"Weiter zu Stufe %lld": ("On to level %lld", "Al nivel %lld", "Vers le niveau %lld"),
"Tipp: %@": ("Hint: %@", "Pista: %@", "Indice : %@"),
"Tipp: %lld": ("Hint: %lld", "Pista: %lld", "Indice : %lld"),
"Wische in eine Richtung, um loszulaufen.": ("Swipe in a direction to start running.", "Desliza en una dirección para empezar a correr.", "Glisse dans une direction pour te mettre en route."),
# Farbwechsel
"Wer wird zuerst alle Karten los?": ("Who gets rid of all their cards first?", "¿Quién se queda sin cartas primero?", "Qui se débarrasse le premier de toutes ses cartes ?"),
"Sprung": ("Skip", "Salto", "Passe"),
"Wende": ("Reverse", "Cambio de sentido", "Inversion"),
"Zwei ziehen": ("Draw two", "Roba dos", "Pioche deux"),
"Joker, drei ziehen": ("Wild, draw three", "Comodín, roba tres", "Joker, pioche trois"),
"%@ hat alle Karten abgelegt": ("%@ has played all their cards", "%@ se ha quedado sin cartas", "%@ s’est débarrassé de toutes ses cartes"),
# Stufenstapel
"Dein Vorrat muss weg": ("Empty your stock pile", "Vacía tu reserva", "Vide ta réserve"),
"Stern": ("Star", "Estrella", "Étoile"),
"Leer": ("Empty", "Vacío", "Vide"),
"Nächste Zahl: %@": ("Next number: %@", "Siguiente número: %@", "Prochain chiffre : %@"),
"Vorrat %lld": ("Stock %lld", "Reserva %lld", "Réserve %lld"),
"Vorrat: %lld": ("Stock: %lld", "Reserva: %lld", "Réserve : %lld"),
"Tippe eine Karte an.": ("Tap a card.", "Toca una carta.", "Touche une carte."),
"Dann einen Bau-Stapel – oder eine Ablage, um den Zug zu beenden.": ("Then a build pile – or a discard pile to end your turn.", "Luego una pila de construcción, o un descarte para terminar el turno.", "Puis une pile de construction – ou une défausse pour finir ton tour."),
"Dann einen Bau-Stapel.": ("Then a build pile.", "Luego una pila de construcción.", "Puis une pile de construction."),
"%@ hat den Vorrat geleert": ("%@ has emptied their stock pile", "%@ ha vaciado su reserva", "%@ a vidé sa réserve"),
# Kreuzwurf
"Würfeln, wählen, ankreuzen": ("Roll, choose, cross off", "Tira, elige, tacha", "Lance, choisis, coche"),
"Was hast du gewürfelt?": ("What did you roll?", "¿Qué has sacado?", "Qu’as-tu obtenu ?"),
"Tippe einen Würfel, um die Seite zu wechseln.": ("Tap a die to change its face.", "Toca un dado para cambiar su cara.", "Touche un dé pour changer sa face."),
"Übernehmen": ("Apply", "Aplicar", "Valider"),
"Ankreuzen": ("Cross off", "Tachar", "Cocher"),
"%@ überlegt …": ("%@ is thinking …", "%@ está pensando …", "%@ réfléchit …"),
"Wähle einen Farbwürfel.": ("Choose a colour die.", "Elige un dado de color.", "Choisis un dé de couleur."),
"Joker: Wähle eine Farbe.": ("Wild: choose a colour.", "Comodín: elige un color.", "Joker : choisis une couleur."),
"Wähle einen Zahlwürfel.": ("Choose a number die.", "Elige un dado de número.", "Choisis un dé de chiffre."),
"Alles klar – tippe auf „Ankreuzen“.": ("All set – tap “Cross off”.", "Todo listo: toca «Tachar».", "Tout est bon – touche « Cocher »."),
"In dieser Farbe geht nichts mehr – wähle andere Würfel oder passe.": ("Nothing left in this colour – choose other dice or pass.", "Ya no queda nada en este color: elige otros dados o pasa.", "Plus rien dans cette couleur – choisis d’autres dés ou passe."),
"Tippe bis zu %lld zusammenhängende %@-Felder an.": ("Tap up to %lld connected %@ squares.", "Toca hasta %lld casillas %@ conectadas.", "Touche jusqu’à %lld cases %@ reliées."),
"Die Felder müssen zusammenhängen.": ("The squares must be connected.", "Las casillas deben estar conectadas.", "Les cases doivent être reliées."),
"Mindestens ein Feld muss an ein schon angekreuztes Feld grenzen.": ("At least one square must touch a square already crossed off.", "Al menos una casilla debe tocar otra ya tachada.", "Au moins une case doit toucher une case déjà cochée."),
"Das erste Kreuz muss in der mittleren Spalte liegen (dick umrandet).": ("The first cross must be in the middle column (thick outline).", "La primera cruz debe estar en la columna central (borde grueso).", "La première croix doit être dans la colonne du milieu (contour épais)."),
# Pechvogel
"Wer bleibt auf dem Pechvogel sitzen?": ("Who is left with the unlucky bird?", "¿Quién se queda con el pájaro de la mala suerte?", "Qui reste avec l’oiseau de malheur ?"),
"%@ zieht": ("%@ draws", "%@ roba", "%@ pioche"),
"Paar abgelegt:": ("Pair discarded:", "Pareja descartada:", "Paire défaussée :"),
"Tippe eine verdeckte Karte deines Nachbarn an.": ("Tap a face-down card of your neighbour.", "Toca una carta boca abajo de tu vecino.", "Touche une carte cachée de ton voisin."),
"Du bist raus!": ("You’re out!", "¡Estás fuera!", "Tu es sorti !"),
"%@ bleibt auf dem Pechvogel sitzen": ("%@ is left with the unlucky bird", "%@ se queda con el pájaro de la mala suerte", "%@ reste avec l’oiseau de malheur"),
# Herzensjagd
"Weiche den Herzen aus": ("Dodge the hearts", "Esquiva los corazones", "Évite les cœurs"),
"Kreuz-Zwei beginnt": ("The two of clubs leads", "Empieza el dos de tréboles", "Le deux de trèfle commence"),
"%@ spielt aus": ("%@ leads", "%@ sale", "%@ ouvre"),
"Du bist dran – tippe eine Karte an.": ("Your turn – tap a card.", "Es tu turno: toca una carta.", "À toi – touche une carte."),
"Runde %lld vorbei": ("Round %lld over", "Ronda %lld terminada", "Manche %lld terminée"),
"Mondschuss von %@!": ("%@ shot the moon!", "¡%@ se ha llevado todo!", "%@ a tout ramassé !"),
# Kartenduell
"Die höhere Karte gewinnt": ("The higher card wins", "Gana la carta más alta", "La carte la plus haute gagne"),
"Streit! Gleichstand – nächste Karte entscheidet.": ("War! A tie – the next card decides.", "¡Guerra! Empate: decide la siguiente carta.", "Bataille ! Égalité – la carte suivante décide."),
"%@ nimmt die Karten": ("%@ takes the cards", "%@ se lleva las cartas", "%@ prend les cartes"),
# Flinkhand
"Wer ist am schnellsten?": ("Who is the fastest?", "¿Quién es el más rápido?", "Qui est le plus rapide ?"),
"Mitte: %lld": ("Centre: %lld", "Centro: %lld", "Centre : %lld"),
"Schnapp! (%@)": ("Snap! (%@)", "¡Chas! (%@)", "Clac ! (%@)"),
"Schnapp!": ("Snap!", "¡Chas!", "Clac !"),
"%@ war schneller!": ("%@ was faster!", "¡%@ fue más rápido!", "%@ a été plus rapide !"),
"%@: Falsch! Eine Karte Strafe.": ("%@: Wrong! One card as a penalty.", "%@: ¡Mal! Una carta de castigo.", "%@ : Faux ! Une carte de pénalité."),
# Himmelsleiter
"Rauf auf die Leitern, runter von den Wolken": ("Up the ladders, down the clouds", "Sube por las escaleras, baja de las nubes", "Monte aux échelles, glisse des nuages"),
# Hölzchen
"Nimm clever – das letzte Hölzchen entscheidet": ("Take cleverly – the last stick decides", "Toma con astucia: el último palillo decide", "Prends malin – le dernier bâtonnet décide"),
"Hölzchen": ("Sticks", "Palillos", "Bâtonnets"),
"Aufbau": ("Layout", "Disposición", "Disposition"),
"Wer das letzte nimmt, gewinnt.": ("Whoever takes the last one wins.", "Quien coge el último, gana.", "Celui qui prend le dernier gagne."),
"Wer das letzte nimmt, verliert.": ("Whoever takes the last one loses.", "Quien coge el último, pierde.", "Celui qui prend le dernier perd."),
"%lld nehmen": ("Take %lld", "Coger %lld", "Prendre %lld"),
"Hölzchen wählen": ("Choose sticks", "Elige palillos", "Choisis des bâtonnets"),
# Pokerwurf / Schiffsfracht
"Fünf Würfel, drei Würfe, beste Hand": ("Five dice, three rolls, best hand", "Cinco dados, tres tiradas, la mejor mano", "Cinq dés, trois lancers, la meilleure main"),
"%@ gewinnt die Runde": ("%@ wins the round", "%@ gana la ronda", "%@ gagne la manche"),
"Unentschieden in dieser Runde": ("A tie this round", "Empate en esta ronda", "Égalité dans cette manche"),
"Würfeln (%lld übrig)": ("Roll (%lld left)", "Tirar (quedan %lld)", "Lancer (%lld restants)"),
"Behalten": ("Keep", "Quedarse", "Garder"),
"%@ würfelt …": ("%@ is rolling …", "%@ está tirando …", "%@ lance …"),
"%@: Würfle!": ("%@: Roll!", "%@: ¡Tira!", "%@ : Lance !"),
"Tippe Würfel an, die du behalten willst.": ("Tap the dice you want to keep.", "Toca los dados que quieras conservar.", "Touche les dés que tu veux garder."),
"Letzter Wurf – behalte die Hand.": ("Last roll – keep your hand.", "Última tirada: quédate con la mano.", "Dernier lancer – garde ta main."),
"Schiff, Kapitän, Mannschaft – und Fracht": ("Ship, captain, crew – and cargo", "Barco, capitán, tripulación… y carga", "Navire, capitaine, équipage – et cargaison"),
"Schiff": ("Ship", "Barco", "Navire"),
"Kapitän": ("Captain", "Capitán", "Capitaine"),
"Mannschaft": ("Crew", "Tripulación", "Équipage"),
"Niemand hatte Fracht": ("Nobody had any cargo", "Nadie tuvo carga", "Personne n’avait de cargaison"),
"Gleichstand in dieser Runde": ("A tie this round", "Empate en esta ronda", "Égalité dans cette manche"),
"Besatzung komplett – Fracht: %lld": ("Crew complete – cargo: %lld", "Tripulación completa – carga: %lld", "Équipage au complet – cargaison : %lld"),
"Noch gesucht: %@ (%lld)": ("Still needed: %@ (%lld)", "Falta: %@ (%lld)", "Encore à trouver : %@ (%lld)"),
# Domino
"Lege Stein an Stein": ("Lay tile by tile", "Coloca ficha tras ficha", "Pose pierre après pierre"),
"Lege den ersten Stein.": ("Lay the first tile.", "Coloca la primera ficha.", "Pose la première pierre."),
"Stein ziehen": ("Draw a tile", "Robar ficha", "Piocher une pierre"),
"Summe deiner Augen: %lld": ("Total of your pips: %lld", "Suma de tus puntos: %lld", "Total de tes points : %lld"),
"%lld Augen übrig": ("%lld pips left", "%lld puntos restantes", "%lld points restants"),
"Das Spiel hat sich festgefahren": ("The game is blocked", "El juego se ha bloqueado", "La partie est bloquée"),
# Fuchsjagd
"Ein Fuchs gegen dreizehn Gänse": ("One fox against thirteen geese", "Un zorro contra trece ocas", "Un renard contre treize oies"),
"Fuchsjagd": ("Fox and Geese", "Zorro y ocas", "Renard et oies"),
"%@ spielt": ("%@ plays", "Juega %@", "%@ joue"),
"Du spielst": ("You play", "Juegas", "Tu joues"),
"Seite": ("Side", "Bando", "Camp"),
"Gänse (beginnen)": ("Geese (go first)", "Ocas (empiezan)", "Oies (commencent)"),
"Fuchs": ("Fox", "Zorro", "Renard"),
"%lld Gänse · %lld gefressen": ("%lld geese · %lld eaten", "%lld ocas · %lld comidas", "%lld oies · %lld mangées"),
"Gänse am Zug": ("Geese to move", "Mueven las ocas", "Au tour des oies"),
"Fuchs am Zug": ("Fox to move", "Mueve el zorro", "Au tour du renard"),
"Zug %lld/%lld": ("Move %lld/%lld", "Jugada %lld/%lld", "Coup %lld/%lld"),
"Der Fuchs entkommt": ("The fox escapes", "El zorro escapa", "Le renard s’échappe"),
"Der Fuchs sitzt in der Falle": ("The fox is trapped", "El zorro está atrapado", "Le renard est pris au piège"),
# Lagerplatz
"Kisten an ihren Platz schieben": ("Push the crates into place", "Empuja las cajas a su sitio", "Pousse les caisses à leur place"),
"%lld Stufen gelöst": ("%lld levels solved", "%lld niveles resueltos", "%lld niveaux résolus"),
"Stufe neu starten": ("Restart level", "Reiniciar nivel", "Recommencer le niveau"),
"Schritte: %lld": ("Steps: %lld", "Pasos: %lld", "Pas : %lld"),
"Geschafft! %lld Schritte, %lld Schübe": ("Done! %lld steps, %lld pushes", "¡Hecho! %lld pasos, %lld empujes", "Réussi ! %lld pas, %lld poussées"),
"Eine Kiste steckt in einer Ecke fest – mit „Zurück“ geht es weiter.": ("A crate is stuck in a corner – use “Undo” to carry on.", "Una caja está atascada en una esquina: usa «Deshacer» para seguir.", "Une caisse est coincée dans un coin – utilise « Annuler » pour continuer."),
# Farbcode
"Knacke den geheimen Code": ("Crack the secret code", "Descifra el código secreto", "Déchiffre le code secret"),
"Farbcode": ("Colour Code", "Código de colores", "Code couleur"),
"%lld Stellen, %lld Farben, %@": ("%lld positions, %lld colours, %@", "%lld posiciones, %lld colores, %@", "%lld positions, %lld couleurs, %@"),
"Farben mehrfach möglich": ("colours can repeat", "los colores pueden repetirse", "couleurs répétables"),
"jede Farbe nur einmal": ("each colour only once", "cada color solo una vez", "chaque couleur une seule fois"),
"Geknackt!": ("Cracked!", "¡Descifrado!", "Déchiffré !"),
"Code": ("Code", "Código", "Code"),
"In %lld Versuchen geknackt": ("Cracked in %lld attempts", "Descifrado en %lld intentos", "Déchiffré en %lld essais"),
"Leider nicht geschafft": ("Sadly not solved", "Lo siento, no lo has logrado", "Dommage, raté"),
"%lld richtig, %lld falsche Stelle": ("%lld correct, %lld in the wrong place", "%lld correctas, %lld en mal sitio", "%lld bien placés, %lld mal placés"),
"Code in %lld Versuchen geknackt": ("Code cracked in %lld attempts", "Código descifrado en %lld intentos", "Code déchiffré en %lld essais"),
"Code nicht geknackt": ("Code not cracked", "Código no descifrado", "Code non déchiffré"),
# Sechseck
"Baue die Brücke": ("Build the bridge", "Construye el puente", "Construis le pont"),
"Sechseck": ("Hex", "Hex", "Hex"),
"Feldgröße": ("Board size", "Tamaño del tablero", "Taille du plateau"),
"Deine Farbe": ("Your colour", "Tu color", "Ta couleur"),
"Blau (beginnt)": ("Blue (goes first)", "Azul (empieza)", "Bleu (commence)"),
"Rot": ("Red", "Rojo", "Rouge"),
"%@ hat die Brücke gebaut": ("%@ built the bridge", "%@ ha construido el puente", "%@ a construit le pont"),
# Kästchenjagd
"Schließe die meisten Kästchen": ("Close the most boxes", "Cierra más cuadrados", "Ferme le plus de carrés"),
"Kästchenjagd": ("Dots and Boxes", "Puntos y cajas", "Jeu des carrés"),
"Achtung: Das schenkt dem Gegner ein Kästchen.": ("Careful: that gives your opponent a box.", "Cuidado: eso regala un cuadrado al rival.", "Attention : cela offre un carré à l’adversaire."),
"Loslassen, um die Linie zu ziehen.": ("Let go to draw the line.", "Suelta para trazar la línea.", "Relâche pour tracer la ligne."),
"Ziehe den Finger zu einer Linie und lass los.": ("Drag your finger to a line and let go.", "Arrastra el dedo hasta una línea y suelta.", "Fais glisser ton doigt jusqu’à une ligne et relâche."),
# Steckspiel
"Spring und lass nur einen übrig": ("Jump and leave just one", "Salta y deja solo uno", "Saute et n’en laisse qu’un"),
"Steckspiel": ("Peg Solitaire", "Solitario de clavijas", "Solitaire à fiches"),
"Kreuz (33)": ("Cross (33)", "Cruz (33)", "Croix (33)"),
"Europa (37)": ("European (37)", "Europeo (37)", "Européen (37)"),
"Bisher am wenigsten: %lld Stecker": ("Fewest so far: %lld pegs", "Menos hasta ahora: %lld clavijas", "Le moins jusqu’ici : %lld fiches"),
"%lld Stecker": ("%lld pegs", "%lld clavijas", "%lld fiches"),
"Perfekt – nur ein Stecker übrig!": ("Perfect – just one peg left!", "¡Perfecto: solo queda una clavija!", "Parfait – il ne reste qu’une fiche !"),
"Keine Sprünge mehr – %lld Stecker übrig.": ("No more jumps – %lld pegs left.", "No quedan saltos: %lld clavijas restantes.", "Plus de sauts – %lld fiches restantes."),
"Mögliche Sprünge: %lld": ("Possible jumps: %lld", "Saltos posibles: %lld", "Sauts possibles : %lld"),
"%lld Stecker übrig (%@)": ("%lld pegs left (%@)", "%lld clavijas restantes (%@)", "%lld fiches restantes (%@)"),
"Anfänger": ("Beginner", "Principiante", "Débutant"),
"Tüftler": ("Tinkerer", "Manitas", "Bricoleur"),
"Kenner": ("Connoisseur", "Conocedor", "Connaisseur"),
"Könner": ("Expert", "Experto", "Expert"),
"Meister": ("Master", "Maestro", "Maître"),
# Esel
"Wer als Letzter die Hand auflegt, ist der Esel": ("The last to put their hand down is the donkey", "El último en poner la mano es el burro", "Le dernier à poser la main est l’âne"),
"Esel": ("Donkey", "Burro", "Âne"),
"Hand drauf!": ("Hand down!", "¡Mano arriba!", "Main sur la table !"),
"Karte weitergeben": ("Pass a card", "Pasar una carta", "Passer une carte"),
"Du bist der Esel! 🫏": ("You’re the donkey! 🫏", "¡Eres el burro! 🫏", "Tu es l’âne ! 🫏"),
"%@ ist der Esel!": ("%@ is the donkey!", "¡%@ es el burro!", "%@ est l’âne !"),
"Vier Gleiche! Schnell: Hand drauf!": ("Four of a kind! Quick: hand down!", "¡Póker! Rápido: ¡mano arriba!", "Carré ! Vite : main sur la table !"),
"Schnell, die anderen sind schon dran!": ("Quick, the others are already down!", "¡Rápido, los demás ya han puesto la mano!", "Vite, les autres ont déjà posé la main !"),
"Wähle eine Karte, die du nach links weitergibst. Sammle vier gleiche.": ("Choose a card to pass to the left. Collect four of a kind.", "Elige una carta para pasar a la izquierda. Reúne cuatro iguales.", "Choisis une carte à passer à gauche. Collecte quatre cartes identiques."),
"%@ ist der Esel": ("%@ is the donkey", "%@ es el burro", "%@ est l’âne"),
# Farbflut
"Färbe das ganze Feld ein": ("Flood the whole board", "Tiñe todo el tablero", "Colorie tout le plateau"),
"Farbflut": ("Flood", "Inundación", "Inondation"),
"8 × 8, 4 Farben, viele Reservezüge": ("8 × 8, 4 colours, plenty of spare moves", "8 × 8, 4 colores, muchos movimientos de reserva", "8 × 8, 4 couleurs, beaucoup de coups en réserve"),
"12 × 12, 6 Farben, wenige Reservezüge": ("12 × 12, 6 colours, few spare moves", "12 × 12, 6 colores, pocos movimientos de reserva", "12 × 12, 6 couleurs, peu de coups en réserve"),
"14 × 14, 6 Farben, keine Reserve": ("14 × 14, 6 colours, no spare moves", "14 × 14, 6 colores, sin reserva", "14 × 14, 6 couleurs, aucune réserve"),
"%lld Züge übrig": ("%lld moves left", "%lld movimientos restantes", "%lld coups restants"),
"Geschafft mit %lld Zügen!": ("Done in %lld moves!", "¡Hecho en %lld movimientos!", "Réussi en %lld coups !"),
"Leider keine Züge mehr.": ("Sadly no moves left.", "Lo siento, no quedan movimientos.", "Dommage, plus de coups."),
"In %lld von %lld Zügen geschafft": ("Done in %lld of %lld moves", "Hecho en %lld de %lld movimientos", "Réussi en %lld coups sur %lld"),
"Nicht geschafft": ("Not solved", "No resuelto", "Non résolu"),
# Königsweg
"Das uralte Rennspiel aus Ur": ("The ancient race game from Ur", "El antiguo juego de carreras de Ur", "L’ancien jeu de course d’Ur"),
"Königsweg": ("Royal Game of Ur", "Juego Real de Ur", "Jeu royal d’Ur"),
"Zwei Spieler an einem Gerät.": ("Two players on one device.", "Dos jugadores en un dispositivo.", "Deux joueurs sur un appareil."),
"· draußen %lld": ("· out %lld", "· fuera %lld", "· sortis %lld"),
"Münzen werfen": ("Toss the coins", "Lanzar las monedas", "Lancer les pièces"),
"Neuer Stein": ("New piece", "Nueva ficha", "Nouveau pion"),
# Ungleichung
"Kleiner oder größer?": ("Smaller or greater?", "¿Menor o mayor?", "Plus petit ou plus grand ?"),
"Ungleichung": ("Inequality", "Desigualdad", "Inégalité"),
"Mit Starthilfe": ("With a head start", "Con ayuda inicial", "Avec un coup de pouce"),
# Allgemein
"%lld/%lld": ("%lld/%lld", "%lld/%lld", "%lld/%lld"),
# Kakuro
"Hier passt keine Ziffer mehr – prüfe die anderen Felder.": ("No digit fits here any more – check the other squares.", "Aquí ya no cabe ninguna cifra: revisa las otras casillas.", "Plus aucun chiffre ne convient ici – vérifie les autres cases."),
"Möglich: %@": ("Possible: %@", "Posible: %@", "Possible : %@"),
}

RM = {
"Alle Karten liegen verdeckt. Wer an der Reihe ist, deckt zwei": (
 "All cards lie face down. When it’s your turn, you turn over two cards. If both show the same picture, you keep the pair and go again. If not, they are turned back over and the next player is up. Remember where everything is! Whoever has the most pairs at the end wins. Playing alone, you aim for few moves: the fewer attempts you need, the better. Before the start you choose the size and the pictures.",
 "Todas las cartas están boca abajo. Quien tiene el turno descubre dos cartas. Si las dos muestran la misma imagen, se queda con la pareja y vuelve a jugar. Si no, se vuelven a girar y le toca al siguiente. ¡Recuerda dónde está cada una! Al final gana quien tenga más parejas. Si juegas solo, el objetivo es hacerlo en pocas jugadas: cuantos menos intentos necesites, mejor. Antes de empezar eliges el tamaño y los motivos.",
 "Toutes les cartes sont face cachée. Celui dont c’est le tour retourne deux cartes. Si elles montrent la même image, il garde la paire et rejoue. Sinon, elles sont retournées et c’est au joueur suivant. Retiens où se trouve chaque carte ! À la fin, celui qui a le plus de paires gagne. Seul, tu joues pour faire peu de coups : moins il te faut d’essais, mieux c’est. Avant de commencer, tu choisis la taille et les motifs."),
"Du stehst in der Ecke links oben, der Ausgang ist in der Ecke rechts unten.": (
 "You start in the top-left corner; the exit is in the bottom-right corner. Swipe in a direction: your runner goes straight ahead and only stops in front of a wall, at a junction, on a spark or at the exit (it never turns by itself). Sparks lie in dead ends and give 50 extra points. The shorter your route, the bigger the bonus. With every level the maze gets bigger, and from level 4 it is dark: you only see what your lantern lights up. End the run whenever you like; your points count.",
 "Empiezas en la esquina superior izquierda; la salida está en la esquina inferior derecha. Desliza en una dirección: tu corredor avanza en línea recta y solo se detiene ante una pared, en una bifurcación, en una chispa o en la salida (nunca gira solo). Las chispas están en callejones sin salida y dan 50 puntos extra. Cuanto más corto sea tu camino, mayor será la bonificación. En cada nivel el laberinto es más grande y, a partir del nivel 4, está oscuro: solo ves lo que ilumina tu linterna. Termina la partida cuando quieras; tus puntos cuentan.",
 "Tu pars du coin en haut à gauche ; la sortie est dans le coin en bas à droite. Glisse dans une direction : ton coureur avance tout droit et ne s’arrête que devant un mur, à une bifurcation, sur une étincelle ou à la sortie (il ne tourne jamais tout seul). Les étincelles se trouvent dans les impasses et rapportent 50 points de plus. Plus ton chemin est court, plus le bonus est grand. À chaque niveau, le labyrinthe grandit, et à partir du niveau 4 il fait nuit : tu ne vois que ce qu’éclaire ta lanterne. Termine la course quand tu veux ; tes points comptent."),
"Jeder bekommt sieben Karten. Wer dran ist, legt eine Karte auf den Ablagestapel:": (
 "Everyone gets seven cards. On your turn, play a card onto the discard pile: it must have the same colour or the same number (or action) as the top card. If nothing fits, you draw a card; if it fits, you may play it straight away, otherwise it’s the next player’s turn. Actions: Skip – the next player misses a turn. Reverse – the direction changes (with two players it works like Skip). Draw two – the next player takes two cards and misses a turn. The wild card can always be played and chooses the colour; the wild “draw three” also makes the next player take three cards and miss a turn. Whoever gets rid of all their cards first wins. With several people on one device, a hand-over screen appears between turns.",
 "Cada jugador recibe siete cartas. En tu turno, juegas una carta al montón de descarte: debe tener el mismo color o el mismo número (o acción) que la carta de arriba. Si nada encaja, robas una carta; si encaja, puedes jugarla enseguida; si no, pasa el turno. Acciones: Salto: el siguiente pierde el turno. Cambio de sentido: se invierte la dirección (entre dos funciona como Salto). Roba dos: el siguiente toma dos cartas y pierde el turno. El comodín siempre se puede jugar y elige el color; el comodín «roba tres» además hace que el siguiente tome tres cartas y pierda el turno. Gana quien se quede primero sin cartas. Con varias personas en un dispositivo aparece una pantalla de relevo entre turnos.",
 "Chacun reçoit sept cartes. À ton tour, pose une carte sur la défausse : elle doit avoir la même couleur ou le même chiffre (ou la même action) que la carte du dessus. Si rien ne convient, tu piches une carte ; si elle convient, tu peux la poser tout de suite, sinon c’est au suivant. Actions : Passe – le suivant passe son tour. Inversion – le sens change (à deux, comme Passe). Pioche deux – le suivant prend deux cartes et passe son tour. Le joker peut toujours être posé et choisit la couleur ; le joker « pioche trois » fait en plus prendre trois cartes au suivant, qui passe son tour. Le premier qui n’a plus de cartes gagne. À plusieurs sur un même appareil, un écran de passage apparaît entre les tours."),
"Jeder hat einen Vorrat von 15 Karten, von dem nur die oberste": (
 "Everyone has a stock pile of 15 cards, of which only the top card is visible, plus five hand cards and three discard piles of their own. Whoever empties their stock pile first wins. Four build piles lie in the middle. A 1 goes on an empty pile, then the 2, then the 3 and so on up to the 10; a pile that reaches 10 is cleared away. The star replaces any number. You may build as many cards as you can: from your stock pile, from your hand or from the top of your discard piles. If you have no hand cards left, you get five new ones. Your turn ends when you place a hand card on one of your three discard piles. First tap a card, then the pile it should go on.",
 "Cada jugador tiene una reserva de 15 cartas, de la que solo se ve la de arriba, además de cinco cartas en la mano y tres descartes propios. Gana quien vacíe primero su reserva. En el centro hay cuatro pilas de construcción. En una pila vacía va el 1, encima el 2, luego el 3 y así hasta el 10; una pila que llega al 10 se retira. La estrella sustituye cualquier número. Puedes construir tantas cartas como puedas: de la reserva, de la mano o de lo alto de tus descartes. Si te quedas sin cartas en la mano, recibes cinco nuevas. Tu turno termina cuando pones una carta de la mano en uno de tus tres descartes. Toca primero una carta y luego la pila donde quieres ponerla.",
 "Chacun a une réserve de 15 cartes dont seule la carte du dessus est visible, plus cinq cartes en main et trois défausses personnelles. Le premier qui vide sa réserve gagne. Quatre piles de construction se trouvent au milieu. Sur une pile vide va le 1, puis le 2, puis le 3, et ainsi de suite jusqu’au 10 ; une pile arrivée à 10 est retirée. L’étoile remplace n’importe quel chiffre. Tu peux construire autant de cartes que possible : depuis ta réserve, ta main ou le haut de tes défausses. Si tu n’as plus de carte en main, tu en reçois cinq nouvelles. Ton tour se termine quand tu poses une carte de ta main sur l’une de tes trois défausses. Touche d’abord une carte, puis la pile où elle doit aller."),
"Alle spielen auf demselben Farbfeld mit 7 × 7 Feldern": (
 "Everyone plays on the same colour grid of 7 × 7 squares, each on their own sheet. Each round, three colour dice and three number dice are rolled. On your turn you take one colour die and one number die and cross off up to as many squares of that colour as the number die shows. The squares must be connected. The very first cross must be in the middle column; every further cross must touch a square that is already crossed off. The star on the colour die is a wild for any colour, on the number die for any number up to five. Dice that have been taken are gone for the others. Points: one point per cross, plus a bonus for full columns (first 5, later 3) and for colours you have crossed off completely (first 6, later 3). Playing alone, you get two choices per round.",
 "Todos juegan en el mismo tablero de colores de 7 × 7 casillas, cada uno en su propia hoja. En cada ronda se lanzan tres dados de color y tres dados de número. En tu turno tomas un dado de color y uno de número y tachas hasta tantas casillas de ese color como indique el dado de número. Las casillas deben estar conectadas. La primera cruz debe estar en la columna central; cada cruz siguiente debe tocar una casilla ya tachada. La estrella del dado de color es un comodín para cualquier color; en el dado de número, para cualquier cifra hasta cinco. Los dados tomados ya no están para los demás. Puntos: un punto por cruz, más bonificación por columnas completas (la primera 5, después 3) y por colores que hayas tachado por completo (el primero 6, después 3). Si juegas solo, tienes dos elecciones por ronda.",
 "Tout le monde joue sur la même grille de couleurs de 7 × 7 cases, chacun sur sa propre feuille. À chaque manche, on lance trois dés de couleur et trois dés de chiffre. À ton tour, tu prends un dé de couleur et un dé de chiffre et tu coches jusqu’à autant de cases de cette couleur que le dé de chiffre l’indique. Les cases doivent être reliées. La toute première croix doit être dans la colonne du milieu ; chaque croix suivante doit toucher une case déjà cochée. L’étoile du dé de couleur est un joker pour toutes les couleurs, sur le dé de chiffre pour tous les chiffres jusqu’à cinq. Les dés pris ne sont plus disponibles pour les autres. Points : un point par croix, plus un bonus pour les colonnes complètes (la première 5, ensuite 3) et pour les couleurs entièrement cochées (la première 6, ensuite 3). Seul, tu as deux choix par manche."),
"Es gibt 13 Tierpaare und einen einzelnen Pechvogel.": (
 "There are 13 animal pairs and one single unlucky bird. All cards are dealt, and everyone immediately discards any pairs in their hand. Then, in turn, everyone draws a face-down card from their neighbour’s hand. If it matches one of your own cards, the pair is discarded at once. Whoever has no cards left is out and safe. Whoever is left with the unlucky bird alone in their hand at the end loses. Tip: don’t give away where the unlucky bird is hiding!",
 "Hay 13 parejas de animales y un único pájaro de la mala suerte. Se reparten todas las cartas y cada uno descarta enseguida las parejas que tenga en la mano. Después, por turnos, cada uno roba sin ver una carta de la mano de su vecino. Si coincide con una carta propia, la pareja se descarta al instante. Quien se queda sin cartas queda fuera y a salvo. Al final pierde quien se quede con el pájaro de la mala suerte solo en la mano. Consejo: ¡que no se note dónde se esconde el pájaro!",
 "Il y a 13 paires d’animaux et un seul oiseau de malheur. Toutes les cartes sont distribuées et chacun défausse tout de suite les paires de sa main. Ensuite, chacun à son tour pioche une carte cachée dans la main de son voisin. Si elle va avec une de tes cartes, la paire est défaussée aussitôt. Celui qui n’a plus de cartes est sorti et en sécurité. À la fin, celui qui reste seul avec l’oiseau de malheur dans la main perd. Astuce : ne laisse pas deviner où se cache l’oiseau de malheur !"),
"Vier Spieler, jeder bekommt 13 Karten. Gespielt werden 13 Stiche.": (
 "Four players, each gets 13 cards. Thirteen tricks are played. When it’s your turn, you must follow the suit led; if you have none, you discard any card. The highest card of the suit led wins the trick, and the winner leads next. You collect penalty points: each heart counts 1, the queen of spades 13. The round starts with the two of clubs. In the first trick, point cards are avoided if possible. Hearts may only be led once a heart or the queen of spades has already been played. If a player takes all 26 points (shooting the moon), the others get 26 points each and that player gets none. As soon as someone reaches 50 points, the game ends: whoever then has the fewest points wins.",
 "Cuatro jugadores, cada uno recibe 13 cartas. Se juegan 13 bazas. En tu turno debes seguir el palo que se ha jugado; si no lo tienes, descartas cualquier carta. La baza la gana la carta más alta del palo jugado, y quien la gana sale en la siguiente. Se acumulan puntos negativos: cada corazón vale 1 y la dama de picas 13. La ronda empieza con el dos de tréboles. En la primera baza no se echan cartas con puntos, si es posible. Los corazones solo pueden jugarse como salida cuando ya ha caído un corazón o la dama de picas. Si un jugador se lleva los 26 puntos (shooting the moon), los demás reciben 26 puntos cada uno y él ninguno. En cuanto alguien llega a 50 puntos, el juego termina: gana quien entonces tenga menos puntos.",
 "Quatre joueurs, chacun reçoit 13 cartes. On joue 13 plis. À ton tour, tu dois fournir la couleur demandée ; si tu n’en as pas, tu te défausses de n’importe quelle carte. Le pli est remporté par la plus haute carte de la couleur demandée, et le gagnant ouvre le pli suivant. On ramasse des points de pénalité : chaque cœur compte 1, la dame de pique 13. La manche commence par le deux de trèfle. Au premier pli, on évite si possible les cartes à points. Les cœurs ne peuvent être ouverts que lorsqu’un cœur ou la dame de pique est déjà tombé. Si un joueur ramasse les 26 points (grand chelem), les autres reçoivent 26 points chacun et lui aucun. Dès que quelqu’un atteint 50 points, la partie s’arrête : celui qui a alors le moins de points gagne."),
"Die Karten werden gleichmäßig verteilt. Beide Spieler decken gleichzeitig": (
 "The cards are dealt out evenly. Both players turn over their top card at the same time. Whoever has the higher card (ace is highest) puts both cards under their pile. If two cards are equal, there is a war: each puts three more cards face down and then turns over one more; the higher card takes the whole heap. Whoever has all the cards wins. If it takes too long, whoever has more cards after 400 rounds wins. Tap the cards to turn them over, or switch on “Automatic”.",
 "Las cartas se reparten por igual. Los dos jugadores descubren a la vez su carta superior. Quien tenga la carta más alta (el as es la más alta) se lleva las dos cartas y las pone debajo de su mazo. Si las dos cartas son iguales, hay guerra: cada uno pone tres cartas más boca abajo y descubre otra; la carta más alta se lleva todo el montón. Gana quien tenga todas las cartas. Si se alarga demasiado, tras 400 rondas gana quien tenga más cartas. Toca las cartas para descubrirlas o activa «Automático».",
 "Les cartes sont distribuées à parts égales. Les deux joueurs retournent en même temps leur carte du dessus. Celui qui a la carte la plus haute (l’as est la plus haute) met les deux cartes sous son paquet. Si les deux cartes sont égales, c’est la bataille : chacun pose trois cartes de plus face cachée, puis en retourne une autre ; la carte la plus haute remporte tout le tas. Celui qui a toutes les cartes gagne. Si cela dure trop longtemps, après 400 manches, celui qui a le plus de cartes gagne. Touche les cartes pour les retourner, ou active « Automatique »."),
"Alle Karten werden verteilt. Reihum legt jeder seine oberste Karte offen in die Mitte.": (
 "All cards are dealt. In turn, everyone places their top card face up in the middle. When two identical pictures lie directly on top of each other, everyone presses “Snap!” as fast as they can. Whoever presses first gets the whole pile in the middle. Whoever presses wrongly must put a card under the middle pile. Whoever has no cards left drops out; whoever has all the cards at the end wins. With several people on one device, everyone has their own button.",
 "Se reparten todas las cartas. Por turnos, cada uno pone su carta superior boca arriba en el centro. Cuando dos imágenes iguales quedan una encima de la otra, todos pulsan «¡Chas!» lo más rápido que pueden. Quien pulse primero se lleva todo el montón del centro. Quien pulse sin motivo debe poner una carta debajo del montón central. Quien se queda sin cartas queda eliminado; gana quien al final tenga todas las cartas. Con varias personas en un dispositivo, cada una tiene su propio botón.",
 "Toutes les cartes sont distribuées. Chacun à son tour pose sa carte du dessus face visible au milieu. Quand deux images identiques sont l’une sur l’autre, chacun appuie le plus vite possible sur « Clac ! ». Le premier à appuyer ramasse tout le tas du milieu. Celui qui appuie à tort doit glisser une carte sous le tas du milieu. Celui qui n’a plus de cartes est éliminé ; celui qui a toutes les cartes à la fin gagne. À plusieurs sur un même appareil, chacun a son propre bouton."),
"Alle starten vor dem Feld 1 und würfeln reihum.": (
 "Everyone starts in front of square 1 and rolls in turn. You move as many squares as the die shows. If your move ends at the bottom of a ladder, you climb up. If it ends at the top of a cloud slide, you slide down. On a 6 you roll again; if you roll three 6s in a row, you must miss a turn. Whoever first reaches or passes square 100 wins.",
 "Todos empiezan antes de la casilla 1 y tiran por turnos. Avanzas tantas casillas como indique el dado. Si tu movimiento termina al pie de una escalera, subes. Si termina en lo alto de un tobogán de nubes, resbalas hacia abajo. Con un 6 vuelves a tirar; si sacas tres 6 seguidos, pierdes el turno. Gana quien primero llegue a la casilla 100 o la sobrepase.",
 "Tout le monde commence devant la case 1 et lance le dé à tour de rôle. Tu avances d’autant de cases que le dé l’indique. Si ton déplacement s’arrête en bas d’une échelle, tu grimpes. S’il s’arrête en haut d’un toboggan de nuages, tu glisses vers le bas. Avec un 6, tu rejoues ; si tu obtiens trois 6 de suite, tu passes ton tour. Le premier qui atteint ou dépasse la case 100 gagne."),
"Mehrere Reihen liegen vor euch, in jeder einige Hölzchen.": (
 "Several rows lie in front of you, each with a few sticks. On your turn you take as many sticks as you like from exactly one row, at least one. In “Classic” mode, whoever takes the last stick wins. In “Unlucky” mode, whoever has to take the last stick loses. Tap a stick: it is marked together with all sticks to its right in the same row and then taken. Against the computer you choose the strength: on “Hard” it makes no mistakes – then only the one who knows the position wins.",
 "Ante vosotros hay varias filas con algunos palillos cada una. En tu turno coges tantos palillos como quieras de exactamente una fila, al menos uno. En el modo «Clásico» gana quien coge el último palillo. En el modo «Mala suerte» pierde quien tiene que coger el último. Toca un palillo: se marca junto con todos los palillos que hay a su derecha en la misma fila y luego se cogen. Contra el ordenador eliges la fuerza: en «Difícil» no comete errores; entonces solo gana quien conoce la posición.",
 "Plusieurs rangées sont devant vous, chacune avec quelques bâtonnets. À ton tour, tu prends autant de bâtonnets que tu veux dans une seule rangée, au moins un. En mode « Classique », celui qui prend le dernier bâtonnet gagne. En mode « Malchance », celui qui doit prendre le dernier perd. Touche un bâtonnet : il est marqué avec tous les bâtonnets à sa droite dans la même rangée, puis pris. Contre l’ordinateur, tu choisis la force : en « Difficile », il ne fait aucune erreur – alors seul gagne celui qui connaît la position."),
"Fünf Runden lang würfelt jeder reihum mit fünf Würfeln bis zu dreimal.": (
 "For five rounds, everyone rolls five dice in turn, up to three times. After the first and second roll you tap the dice you want to keep. The hands, from weak to strong, are: nothing, one pair, two pairs, three of a kind, small straight (1–5), large straight (2–6), full house, four of a kind, five of a kind. With equal hands the higher dice count. Whoever has the best hand in a round gets one point; in case of a tie, all the best get one. After five rounds, whoever has the most points wins.",
 "Durante cinco rondas, cada uno tira por turnos cinco dados hasta tres veces. Tras la primera y la segunda tirada tocas los dados que quieres conservar. Las manos, de menos a más: nada, una pareja, dos parejas, trío, escalera pequeña (1–5), escalera grande (2–6), full, póker, repóker. Con manos iguales cuentan los dados más altos. Quien tenga la mejor mano en una ronda recibe un punto; en caso de empate, todos los mejores reciben uno. Tras cinco rondas gana quien tenga más puntos.",
 "Pendant cinq manches, chacun lance à tour de rôle cinq dés, jusqu’à trois fois. Après le premier et le deuxième lancer, tu touches les dés que tu veux garder. Les mains, de la plus faible à la plus forte : rien, une paire, deux paires, brelan, petite suite (1–5), grande suite (2–6), full, carré, quinte. À mains égales, les dés les plus hauts comptent. Celui qui a la meilleure main dans une manche reçoit un point ; en cas d’égalité, tous les meilleurs en reçoivent un. Après cinq manches, celui qui a le plus de points gagne."),
"Es gibt 55 Steine mit Augen von 0 bis 9.": (
 "There are 55 tiles with pips from 0 to 9. Everyone gets ten tiles, the rest is the stock. Play is like classic dominoes: place tiles matching one of the two ends of the chain; if you have no matching tile you draw, and if the stock is empty you pass. Whoever has no tiles left first wins; if nobody can go on, the lowest pip total wins.",
 "Hay 55 fichas con puntos del 0 al 9. Cada jugador recibe diez fichas, el resto es el pozo. Se juega como el dominó clásico: coloca fichas que encajen en uno de los dos extremos de la cadena; si no tienes ninguna que encaje, robas, y si el pozo está vacío, pasas. Gana quien se quede primero sin fichas; si nadie puede seguir, gana la menor suma de puntos.",
 "Il y a 55 dominos avec des points de 0 à 9. Chacun reçoit dix dominos, le reste forme la pioche. On joue comme au domino classique : pose des dominos qui correspondent à l’un des deux bouts de la chaîne ; sans domino qui convient, tu piches, et si la pioche est vide, tu passes. Le premier qui n’a plus de dominos gagne ; si plus personne ne peut jouer, le total de points le plus bas gagne."),
"Es gibt 28 Steine mit Augen von 0 bis 6.": (
 "There are 28 tiles with pips from 0 to 6. Everyone gets seven tiles (five with three or four players), the rest is the stock. The player with the highest double (a tile with two equal halves) starts, otherwise the tile with the most pips. On your turn, place a tile at one end of the chain so that the pips match. If you have no matching tile, you draw from the stock until one fits; if the stock is empty, you must pass. Whoever has no tiles left first wins. If nobody can go on, whoever has the fewest pips in their hand wins. Tap a tile, then the end of the chain where it should go (if it only fits one side, it goes there straight away).",
 "Hay 28 fichas con puntos del 0 al 6. Cada jugador recibe siete fichas (cinco si son tres o cuatro), el resto es el pozo. Empieza quien tenga el doble más alto (ficha con dos mitades iguales); si no, la ficha con más puntos. En tu turno colocas una ficha en un extremo de la cadena de modo que los puntos coincidan. Si no tienes ninguna ficha que encaje, robas del pozo hasta que una encaje; si el pozo está vacío, tienes que pasar. Gana quien se quede primero sin fichas. Si nadie puede seguir, gana quien tenga menos puntos en la mano. Toca una ficha y después el extremo de la cadena donde debe ir (si solo encaja en un lado, va directamente allí).",
 "Il y a 28 dominos avec des points de 0 à 6. Chacun reçoit sept dominos (cinq à trois ou quatre joueurs), le reste forme la pioche. Celui qui a le plus grand double (un domino avec deux moitiés identiques) commence, sinon le domino avec le plus de points. À ton tour, pose un domino à un bout de la chaîne de façon que les points correspondent. Si tu n’as aucun domino qui convient, tu piches jusqu’à en avoir un qui convient ; si la pioche est vide, tu dois passer. Le premier qui n’a plus de dominos gagne. Si plus personne ne peut jouer, celui qui a le moins de points en main gagne. Touche un domino, puis le bout de la chaîne où il doit aller (s’il ne convient que d’un côté, il y va directement)."),
"Auf dem Kreuzbrett steht ein Fuchs gegen 13 Gänse.": (
 "On the cross-shaped board, one fox faces 13 geese. The geese go first and always move one square forward (up) or sideways, never backward and never diagonally. The fox moves one square in any of the four directions or jumps over a goose onto the empty square behind it and eats it (one jump per turn). The geese win if they surround the fox so that it can no longer move. The fox wins when only three geese are left or when, after 80 moves for each side, nobody has been trapped. Tip for the geese: advance in a closed line so the fox can’t get behind. Tap a piece, then a marked target square.",
 "En el tablero en cruz, un zorro se enfrenta a 13 ocas. Las ocas empiezan y siempre avanzan una casilla hacia delante (arriba) o de lado, nunca hacia atrás ni en diagonal. El zorro se mueve una casilla en las cuatro direcciones o salta sobre una oca a la casilla libre de detrás y se la come (un salto por turno). Las ocas ganan si rodean al zorro de modo que no pueda moverse. El zorro gana cuando quedan solo tres ocas o cuando, tras 80 jugadas de cada bando, nadie ha quedado atrapado. Consejo para las ocas: avanzad en una fila cerrada para que el zorro no se cuele por detrás. Toca una pieza y luego una casilla de destino marcada.",
 "Sur le plateau en croix, un renard affronte 13 oies. Les oies commencent et avancent toujours d’une case vers l’avant (vers le haut) ou sur le côté, jamais en arrière ni en diagonale. Le renard se déplace d’une case dans les quatre directions ou saute par-dessus une oie sur la case libre derrière elle et la mange (un saut par tour). Les oies gagnent si elles encerclent le renard de sorte qu’il ne puisse plus bouger. Le renard gagne quand il ne reste que trois oies ou quand, après 80 coups de chaque côté, personne n’est piégé. Conseil pour les oies : avancez en ligne serrée pour que le renard ne passe pas derrière. Touche une pièce, puis une case d’arrivée marquée."),
"Du bist der Lagerarbeiter und musst alle Kisten": (
 "You are the warehouse worker and must push all the crates onto the marked spots. Drag your finger across the field to move: you take one step for each square-width. If you walk into a crate, you push it one square further, but only if there is room behind it. You can’t pull crates and can only push one at a time; walls are in the way. If a crate gets stuck, the Undo button helps (as often as you like). Every level is freshly shuffled and guaranteed to be solvable. Each level brings more crates and walls. End the run whenever you like; every level you have solved counts.",
 "Eres el trabajador del almacén y debes empujar todas las cajas a los sitios marcados. Arrastra el dedo por el tablero para moverte: das un paso por cada ancho de casilla. Si chocas contra una caja, la empujas una casilla más, pero solo si hay sitio detrás. No puedes tirar de las cajas y solo puedes empujar una cada vez; las paredes estorban. Si una caja se atasca, ayuda el botón Deshacer (tantas veces como quieras). Cada nivel se genera de nuevo y tiene solución garantizada. En cada nivel hay más cajas y paredes. Termina la partida cuando quieras; cada nivel resuelto cuenta.",
 "Tu es le manutentionnaire et tu dois pousser toutes les caisses sur les emplacements marqués. Fais glisser ton doigt sur le plateau pour avancer : tu fais un pas par largeur de case. Si tu te heurtes à une caisse, tu la pousses d’une case, mais seulement s’il y a de la place derrière. Tu ne peux pas tirer les caisses et tu ne peux en pousser qu’une à la fois ; les murs gênent. Si une caisse est coincée, le bouton Annuler t’aide (autant de fois que tu veux). Chaque niveau est généré de nouveau et garanti résoluble. À chaque niveau, il y a plus de caisses et de murs. Termine la course quand tu veux ; chaque niveau résolu compte."),
"Der Computer denkt sich einen Code aus Farbpunkten aus.": (
 "The computer thinks up a code made of coloured dots. You have ten attempts. Use the colours below to make a guess and tap “Check”. To the right of the guess, small dots show: a dark dot means “right colour in the right place”, a light dot means “right colour, but in the wrong place”. The dots are not tied to particular positions. In “Easy” mode every colour appears at most once; otherwise colours can repeat. The hint button suggests a code that fits everything you have learned so far and costs a point.",
 "El ordenador piensa un código de puntos de colores. Tienes diez intentos. Haz una propuesta con los colores de abajo y toca «Comprobar». A la derecha de la propuesta, unos puntos pequeños indican: un punto oscuro significa «color correcto en el sitio correcto»; un punto claro, «color correcto, pero en el sitio equivocado». Los puntos no están asignados a posiciones concretas. En el modo «Fácil» cada color aparece como mucho una vez; en los demás, los colores pueden repetirse. El botón de pista te propone un código que encaja con todo lo que sabes hasta ahora y cuesta un punto.",
 "L’ordinateur invente un code fait de points de couleur. Tu as dix essais. Fais une proposition avec les couleurs du bas et touche « Vérifier ». À droite de la proposition, de petits points indiquent : un point foncé signifie « bonne couleur au bon endroit », un point clair « bonne couleur, mais au mauvais endroit ». Les points ne sont pas attribués à des positions précises. En mode « Facile », chaque couleur apparaît au plus une fois ; sinon, les couleurs peuvent se répéter. Le bouton d’indice te propose un code qui correspond à tout ce que tu as appris jusqu’ici et coûte un point."),
"Auf dem Feld aus Sechsecken setzen zwei Spieler abwechselnd": (
 "On the board of hexagons, two players take turns placing a stone on an empty cell. Blue must connect the top edge with the bottom edge, Red the left edge with the right edge. The stones must touch along their sides. Whoever first has an unbroken chain wins. There are no draws. Tip: the centre is a strong place to be. Blue goes first. Playing alone, you play against the computer and choose the board size and strength.",
 "En el tablero de hexágonos, dos jugadores colocan por turnos una piedra en una casilla libre. El azul debe unir el borde superior con el inferior; el rojo, el izquierdo con el derecho. Las piedras deben tocarse por los lados. Gana quien primero tenga una cadena continua. No hay empates. Consejo: el centro es un buen lugar. Empieza el azul. Si juegas solo, juegas contra el ordenador y eliges el tamaño del tablero y la fuerza.",
 "Sur le plateau d’hexagones, deux joueurs posent à tour de rôle un pion sur une case libre. Le bleu doit relier le bord du haut à celui du bas, le rouge le bord gauche au bord droit. Les pions doivent se toucher par les côtés. Le premier qui a une chaîne ininterrompue gagne. Il n’y a pas de match nul. Conseil : le centre est un bon endroit. Le bleu commence. Seul, tu joues contre l’ordinateur et tu choisis la taille du plateau et la force."),
"Auf dem Punktegitter zieht jeder abwechselnd eine Linie": (
 "On the grid of dots, everyone takes turns drawing a line between two neighbouring dots. Whoever closes the fourth side of a box with their line gets that box and draws another line straight away. When all lines are drawn, whoever has more boxes wins. Tip: don’t draw the third side of a box, or you give it to your opponent. In the end, whoever gets the longest chains last often wins. Tap near a line to draw it.",
 "En la cuadrícula de puntos, cada uno traza por turnos una línea entre dos puntos vecinos. Quien cierra con su línea el cuarto lado de un cuadrado se lo queda y traza otra línea enseguida. Cuando están trazadas todas las líneas, gana quien tenga más cuadrados. Consejo: no traces el tercer lado de un cuadrado, o se lo regalas al rival. Al final suele ganar quien consigue las cadenas más largas en último lugar. Toca cerca de una línea para trazarla.",
 "Sur la grille de points, chacun trace à tour de rôle une ligne entre deux points voisins. Celui qui ferme avec sa ligne le quatrième côté d’un carré gagne ce carré et trace aussitôt une autre ligne. Quand toutes les lignes sont tracées, celui qui a le plus de carrés gagne. Conseil : ne trace pas le troisième côté d’un carré, sinon tu l’offres à l’adversaire. À la fin, gagne souvent celui qui obtient les plus longues chaînes en dernier. Touche près d’une ligne pour la tracer."),
"Auf dem Brett stecken Stecker in allen Löchern bis auf das mittlere.": (
 "On the board, pegs sit in all the holes except the middle one. You jump a peg horizontally or vertically over a direct neighbour into an empty hole behind it. The jumped peg is removed. Goal: only a single peg should be left at the end. When no more jumps are possible, the game is over; the fewer pegs are left, the better you are. Tap a peg, then the empty hole it should jump into. “Undo” takes moves back. There are two boards: the classic cross and the larger European board.",
 "En el tablero hay clavijas en todos los agujeros salvo el central. Saltas con una clavija en horizontal o vertical sobre una vecina directa hasta un agujero vacío detrás. La clavija saltada se retira. Objetivo: que al final quede una sola clavija. Cuando ya no hay más saltos, el juego termina; cuantas menos clavijas queden, mejor lo haces. Toca una clavija y luego el agujero vacío al que debe saltar. Con «Deshacer» retrocedes jugadas. Hay dos tableros: la cruz clásica y el tablero europeo, más grande.",
 "Sur le plateau, des fiches occupent tous les trous sauf celui du milieu. Tu sautes avec une fiche, à l’horizontale ou à la verticale, par-dessus une voisine directe dans un trou vide juste derrière. La fiche sautée est retirée. But : à la fin, il ne doit rester qu’une seule fiche. Quand plus aucun saut n’est possible, la partie est finie ; moins il reste de fiches, meilleur tu es. Touche une fiche, puis le trou vide où elle doit sauter. « Annuler » reprend des coups. Il y a deux plateaux : la croix classique et le plateau européen, plus grand."),
"Jeder hat vier Karten. Im Spiel sind so viele Ränge wie Spieler": (
 "Everyone has four cards. There are as many ranks in the game as there are players (for example aces, kings and queens), each in all four suits. Everyone passes a card to their neighbour at the same time and receives one from the other neighbour. Goal: collect four of a kind. Whoever has them immediately puts their hand on the table. As soon as someone has put their hand down, everyone else must follow as fast as they can by pressing the “Hand down!” button. The last one who hasn’t put their hand down is the donkey. Only one human plays here; the computer takes all the other seats.",
 "Cada jugador tiene cuatro cartas. En el juego hay tantos valores como jugadores (por ejemplo ases, reyes y reinas), cada uno en los cuatro palos. Todos pasan a la vez una carta a su vecino y reciben una del otro vecino. Objetivo: reunir cuatro cartas iguales. Quien las tiene pone enseguida la mano sobre la mesa. En cuanto alguien ha puesto la mano, todos los demás deben seguirle lo más rápido posible pulsando el botón «¡Mano arriba!». El último que no ha puesto la mano es el burro. Aquí juega siempre solo una persona; el ordenador ocupa todos los demás asientos.",
 "Chacun a quatre cartes. Il y a autant de rangs en jeu que de joueurs (par exemple as, rois et dames), chacun dans les quatre couleurs. Tout le monde passe en même temps une carte à son voisin et en reçoit une de l’autre voisin. But : réunir quatre cartes identiques. Celui qui les a pose aussitôt la main sur la table. Dès que quelqu’un a posé sa main, tous les autres doivent suivre le plus vite possible en appuyant sur le bouton « Main sur la table ! ». Le dernier qui n’a pas posé la main est l’âne. Ici, un seul humain joue ; l’ordinateur prend toutes les autres places."),
"Das Feld besteht aus bunten Quadraten. Die Flut beginnt oben links.": (
 "The board is made of coloured squares. The flood starts at the top left. Tap a colour at the bottom: the whole area that now belongs to the flood takes on that colour and swallows all neighbouring squares of that colour. Colour the whole board in a single colour before your moves run out. You only have a limited number of moves; every board is guaranteed to be solvable. The more moves you have left, the more points you get. “Undo” takes back a move.",
 "El tablero está formado por cuadrados de colores. La inundación empieza arriba a la izquierda. Toca un color abajo: toda la zona que ahora pertenece a la inundación toma ese color y se traga todas las casillas vecinas de ese color. Tiñe todo el tablero de un solo color antes de que se acaben tus movimientos. Solo tienes un número limitado de movimientos; todos los tableros tienen solución garantizada. Cuantos más movimientos te queden, más puntos obtienes. «Deshacer» retrocede una jugada.",
 "Le plateau est fait de carrés colorés. L’inondation commence en haut à gauche. Touche une couleur en bas : toute la zone qui fait maintenant partie de l’inondation prend cette couleur et avale toutes les cases voisines de cette couleur. Colorie tout le plateau d’une seule couleur avant d’avoir épuisé tes coups. Tu n’as qu’un nombre limité de coups ; chaque plateau est garanti résoluble. Plus il te reste de coups, plus tu as de points. « Annuler » reprend un coup."),
"Jeder würfelt mit fünf Würfeln, bis zu dreimal. Zuerst brauchst du eine 6": (
 "Everyone rolls five dice, up to three times. First you need a 6 (the ship), then a 5 (the captain), then a 4 (the crew). These dice are set aside automatically as soon as they fall in the right order; you may re-roll the other dice. Once you have all three, the remaining two dice together count as your cargo (12 at most). Without a complete crew, the cargo is zero. Whoever has the most cargo in a round gets a point. After five rounds, whoever has the most points wins. You can stop after any roll (“Done”).",
 "Cada uno tira cinco dados, hasta tres veces. Primero necesitas un 6 (el barco), luego un 5 (el capitán) y después un 4 (la tripulación). Estos dados se apartan automáticamente en cuanto salen en el orden correcto; los demás dados puedes volver a tirarlos. Cuando tienes los tres, los dos dados restantes suman tu carga (como máximo 12). Sin tripulación completa, la carga es cero. Quien tenga más carga en una ronda recibe un punto. Tras cinco rondas gana quien tenga más puntos. Puedes parar después de cualquier tirada («Listo»).",
 "Chacun lance cinq dés, jusqu’à trois fois. Il te faut d’abord un 6 (le navire), puis un 5 (le capitaine), puis un 4 (l’équipage). Ces dés sont mis de côté automatiquement dès qu’ils tombent dans le bon ordre ; tu peux relancer les autres dés. Quand tu as les trois, les deux dés restants forment ensemble ta cargaison (12 au maximum). Sans équipage complet, la cargaison est nulle. Celui qui a la plus grosse cargaison dans une manche reçoit un point. Après cinq manches, celui qui a le plus de points gagne. Tu peux t’arrêter après n’importe quel lancer (« Terminé »)."),
"Jeder hat sieben Steine und bringt sie über den Weg von 14 Feldern": (
 "Everyone has seven pieces and brings them along the path of 14 squares and off the board. You toss four coins: each side with a dot counts as one step, so 0 to 4. With that number you either enter a piece from the stock onto the board or move a piece on – tap it. You may not land on a square where you already have a piece. The middle strip is shared: if you land there on an opponent’s piece, it is captured and must go back to the stock. Rosette squares (flower) give an extra turn; the rosette in the middle protects the piece on it from capture. You can only bear off with an exact number. Whoever first brings all seven pieces off wins.",
 "Cada jugador tiene siete fichas y las lleva por el camino de 14 casillas hasta sacarlas del tablero. Lanzas cuatro monedas: cada lado con punto cuenta un paso, es decir, de 0 a 4. Con ese número pones una ficha de la reserva en el tablero o avanzas una ficha: tócala. No puedes caer en una casilla donde ya tienes una ficha. La franja central es común: si caes ahí sobre una ficha rival, esta es capturada y vuelve a la reserva. Las casillas con rosetón (flor) dan un turno extra; el rosetón del centro protege la ficha que está en él. Solo se sale con el número exacto. Gana quien primero saque las siete fichas.",
 "Chacun a sept pions et les fait avancer sur le chemin de 14 cases jusqu’à la sortie. Tu lances quatre pièces : chaque face avec un point compte un pas, donc de 0 à 4. Avec ce nombre, tu mets un pion de la réserve sur le plateau ou tu avances un pion – touche-le. Tu ne peux pas aller sur une case où tu as déjà un pion. La bande du milieu est commune : si tu y tombes sur un pion adverse, il est pris et retourne dans la réserve. Les cases rosaces (fleur) donnent un tour de plus ; la rosace du milieu protège le pion qui s’y trouve. On ne sort qu’avec le nombre exact. Le premier qui a sorti ses sept pions gagne."),
"Fülle das Quadrat mit den Zahlen von 1 bis zur Kantenlänge": (
 "Fill the square with the numbers from 1 up to the side length so that every number appears exactly once in each row and each column. Between some squares there is a sign: the point shows towards the smaller number, so “<” means the left (upper) number is smaller than the right (lower) one. Some numbers are given. Every puzzle has exactly one solution, so you never have to guess. Choose a square and tap the number below. Squares marked in red break a rule. The hint button fills in a number for you.",
 "Rellena el cuadrado con los números del 1 a la longitud del lado, de modo que cada número aparezca exactamente una vez en cada fila y en cada columna. Entre algunas casillas hay un signo: la punta señala el número menor, así que «<» significa que el número de la izquierda (de arriba) es menor que el de la derecha (de abajo). Algunos números ya vienen dados. Cada puzle tiene exactamente una solución, así que nunca hace falta adivinar. Elige una casilla y toca abajo el número. Las casillas marcadas en rojo incumplen una regla. El botón de pista coloca un número por ti.",
 "Remplis le carré avec les nombres de 1 à la longueur du côté, de sorte que chaque nombre apparaisse exactement une fois dans chaque ligne et chaque colonne. Entre certaines cases se trouve un signe : la pointe désigne le plus petit nombre, donc « < » signifie que le nombre de gauche (du haut) est plus petit que celui de droite (du bas). Certains nombres sont donnés. Chaque grille a exactement une solution, tu n’as donc jamais à deviner. Choisis une case et touche le nombre en bas. Les cases marquées en rouge enfreignent une règle. Le bouton d’indice place un nombre à ta place."),
}

cat = json.load(open(KAT)); s = cat['strings']
def eintragen(k, t, ueberschreiben=False):
    eintrag = s.setdefault(k, {})
    loc = eintrag.setdefault('localizations', {})
    if not ueberschreiben and 'en' in loc: return False
    for sp, v in zip(('en', 'es', 'fr'), t):
        loc[sp] = {"stringUnit": {"state": "translated", "value": v}}
    return True
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
