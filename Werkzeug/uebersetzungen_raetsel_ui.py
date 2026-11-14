#!/usr/bin/env python3
"""uebersetzungen_raetsel_ui.py: es/fr für Farbrätsel und Minensuche (Oberfläche und Regeln) in App/Ressourcen/Localizable.xcstrings.
Überschreibt nie Vorhandenes. Aufruf aus dem Projektordner."""
import json
KAT = 'App/Ressourcen/Localizable.xcstrings'
U = {
# ---- Farbrätsel
"Farbrätsel": ("Puzzle de colores", "Puzzle de couleurs"),
"Nur Ecken und Randmitten stehen fest.": ("Solo las esquinas y los centros de los bordes están fijos.", "Seuls les coins et les milieux des bords sont fixes."),
"Bring die Farben in Ordnung.": ("Pon los colores en orden.", "Remets les couleurs en ordre."),
"Laufendes Rätsel verwerfen?": ("¿Descartar el puzle actual?", "Abandonner la grille en cours ?"),
"Verwerfen und neu starten": ("Descartar y empezar de nuevo", "Abandonner et recommencer"),
"Heute noch offen · Serie %lld": ("Aún pendiente hoy · racha %lld", "Encore à faire aujourd’hui · série %lld"),
"Heute geschafft · Serie %lld": ("Hecho hoy · racha %lld", "Fait aujourd’hui · série %lld"),
"Bestwert: %lld Züge · %lld× gelöst": ("Mejor: %lld movimientos · resuelto %lld×", "Meilleur : %lld coups · résolu %lld×"),
"Der Rand steht schon. Gut zum Einstieg.": ("El borde ya está puesto. Bueno para empezar.", "Le bord est déjà en place. Idéal pour débuter."),
"Nur die vier Ecken sind vorgegeben.": ("Solo se dan las cuatro esquinas.", "Seuls les quatre coins sont donnés."),
"Neuer Bestwert auf „%@“": ("Nuevo récord en «%@»", "Nouveau record sur « %@ »"),
"Noch eins": ("Otro más", "Encore une"),
"Tagesrätsel erledigt. Morgen gibt es ein neues.": ("Puzle diario resuelto. Mañana habrá uno nuevo.", "Grille du jour terminée. Une nouvelle demain."),
"Tippe eine Kachel an und dann eine zweite. Beide tauschen die Plätze. Kacheln mit weißem Punkt sind fest.": ("Toca una ficha y luego otra. Intercambian sus sitios. Las fichas con un punto blanco están fijas.", "Touche une tuile, puis une deuxième. Elles échangent leurs places. Les tuiles avec un point blanc sont fixes."),
"Richtige Kacheln markieren": ("Marcar las fichas correctas", "Marquer les tuiles justes"),
"Jeden Tag gibt es ein Rätsel für alle. Löse es an mehreren Tagen hintereinander für eine Serie.": ("Cada día hay un puzle para todos. Resuélvelo varios días seguidos para lograr una racha.", "Chaque jour, il y a une grille pour tout le monde. Résous-la plusieurs jours de suite pour une série."),
"Je weniger Züge, desto besser. Der Tipp bringt eine Kachel an ihren Platz und zählt als Zug; mit Tipp gelöste Rätsel zählen aber nicht für den Bestwert.": ("Cuantos menos movimientos, mejor. La pista coloca una ficha en su sitio y cuenta como movimiento; los puzles resueltos con pista no cuentan para tu mejor marca.", "Moins il y a de coups, mieux c’est. L’indice place une tuile à sa place et compte comme un coup ; les grilles résolues avec indice ne comptent pas pour le record."),
"Das Ziel": ("El objetivo", "Le but"),
"Ein kleiner Punkt zeigt, welche Kachel schon an ihrem Platz liegt.": ("Un punto pequeño muestra qué ficha ya está en su sitio.", "Un petit point montre quelle tuile est déjà à sa place."),
"Die Kacheln bilden einen sanften Farbverlauf zwischen den vier Ecken. Jemand hat sie durcheinandergebracht. Stelle den Verlauf wieder her.": ("Las fichas forman un degradado suave entre las cuatro esquinas. Alguien las ha desordenado. Restaura el degradado.", "Les tuiles forment un dégradé doux entre les quatre coins. Quelqu’un les a mélangées. Rétablis le dégradé."),
"Wenig Züge": ("Pocos movimientos", "Peu de coups"),
", fest": (", fija", ", fixe"),
"Zurück zum Start": ("Volver al inicio", "Retour au début"),
", richtig": (", correcta", ", juste"),
# ---- Minensuche
"Ein Brett für alle – jeden Tag neu": ("Un tablero para todos, nuevo cada día", "Un plateau pour tous, nouveau chaque jour"),
"Abbrechen und neu starten": ("Cancelar y empezar de nuevo", "Annuler et recommencer"),
"Finde jede Mine – ohne zu raten.": ("Encuentra todas las minas, sin adivinar.", "Trouve toutes les mines, sans deviner."),
"Serie %lld · heute noch offen": ("Racha %lld · aún pendiente hoy", "Série %lld · encore à faire aujourd’hui"),
"Die laufende Partie zählt dann als verloren.": ("La partida en curso contará entonces como perdida.", "La partie en cours comptera alors comme perdue."),
"Heute gelöst · Serie %lld": ("Resuelto hoy · racha %lld", "Résolu aujourd’hui · série %lld"),
"%lld × %lld Felder, %lld Minen": ("%1$lld × %2$lld casillas, %3$lld minas", "%1$lld × %2$lld cases, %3$lld mines"),
"%@: verdeckt": ("%@: oculta", "%@ : cachée"),
"%@: Mine": ("%@: mina", "%@ : mine"),
"%@: Fahne": ("%@: bandera", "%@ : drapeau"),
"Fahne umschalten": ("Cambiar bandera", "Basculer le drapeau"),
"%@: leer": ("%@: vacía", "%@ : vide"),
"Ohne Raten lösbar": ("Resoluble sin adivinar", "Résoluble sans deviner"),
"Alle Zeiten und Serien gehen verloren.": ("Se perderán todos los tiempos y rachas.", "Tous les temps et séries seront perdus."),
"Jedes neue Brett lässt sich allein durch Nachdenken lösen. Gilt ab dem nächsten Spiel.": ("Cada tablero nuevo se puede resolver solo con lógica. Vale desde la próxima partida.", "Chaque nouveau plateau se résout par la seule logique. Valable dès la prochaine partie."),
"Statistik wirklich zurücksetzen?": ("¿Restablecer de verdad las estadísticas?", "Vraiment réinitialiser les statistiques ?"),
"Zahl antippen": ("Toca un número", "Touche un chiffre"),
"Tippen deckt auf. Lang drücken setzt eine Fahne auf ein vermutetes Minenfeld. Mit dem Fahnen-Knopf vertauschst du beides.": ("Tocar descubre. Mantener pulsado pone una bandera en una casilla con mina supuesta. El botón de bandera intercambia ambas acciones.", "Toucher découvre. Un appui long pose un drapeau sur une case supposée minée. Le bouton drapeau échange les deux."),
"Jedes Brett lässt sich allein durch Nachdenken lösen. Der erste Zug ist immer sicher. Das kannst du in den Einstellungen ausschalten.": ("Cada tablero se resuelve solo con lógica. El primer movimiento siempre es seguro. Puedes desactivarlo en Ajustes.", "Chaque plateau se résout par la seule logique. Le premier coup est toujours sûr. Tu peux le désactiver dans les Réglages."),
"Hast du rund um eine aufgedeckte Zahl genau so viele Fahnen gesetzt, wie sie angibt, öffnet ein Tipp darauf alle übrigen Nachbarn auf einmal.": ("Si has puesto alrededor de un número descubierto tantas banderas como indica, tocarlo abre de golpe todas las demás casillas vecinas.", "Si tu as posé autour d’un chiffre découvert autant de drapeaux qu’il l’indique, le toucher ouvre d’un coup toutes les autres cases voisines."),
"Ohne Raten": ("Sin adivinar", "Sans deviner"),
"Eine Zahl sagt, wie viele der acht Nachbarfelder eine Mine enthalten. Eine leere Fläche öffnet ihre Umgebung von selbst.": ("Un número indica cuántas de las ocho casillas vecinas tienen una mina. Una zona vacía abre sus alrededores sola.", "Un chiffre indique combien des huit cases voisines contiennent une mine. Une zone vide ouvre ses environs toute seule."),
"Jeden Tag gibt es ein Brett, das für alle gleich ist. Löse es an aufeinanderfolgenden Tagen für eine Serie.": ("Cada día hay un tablero igual para todos. Resuélvelo varios días seguidos para lograr una racha.", "Chaque jour, il y a un plateau identique pour tous. Résous-le plusieurs jours de suite pour une série."),
"Der Hinweis deckt ein Feld auf, das sicher ist. Er kostet 10 Sekunden Strafzeit.": ("La pista descubre una casilla segura. Cuesta 10 segundos de penalización.", "L’indice découvre une case sûre. Il coûte 10 secondes de pénalité."),
"Decke alle Felder auf, unter denen keine Mine liegt. Eine Mine aufzudecken beendet die Partie.": ("Descubre todas las casillas que no tienen mina. Descubrir una mina termina la partida.", "Découvre toutes les cases sans mine. Découvrir une mine met fin à la partie."),
"%lld Minen übrig": ("%lld minas restantes", "%lld mines restantes"),
"Neue Bestzeit in „%@“.": ("Nuevo mejor tiempo en «%@».", "Nouveau meilleur temps sur « %@ »."),
"Brett ansehen": ("Ver tablero", "Voir le plateau"),
"Gleich noch einmal?": ("¿Otra partida enseguida?", "On refait une partie ?"),
"Alle Minen gefunden in %@": ("Todas las minas encontradas en %@", "Toutes les mines trouvées en %@"),
"Mine getroffen": ("Mina pisada", "Mine touchée"),
"Hinweise: %lld (+%lld s)": ("Pistas: %1$lld (+%2$lld s)", "Indices : %1$lld (+%2$lld s)"),
"Aktuelle Partie abbrechen?": ("¿Cancelar la partida actual?", "Annuler la partie en cours ?"),
"Spielregeln": ("Reglas del juego", "Règles du jeu"),
}
cat = json.load(open(KAT)); s = cat['strings']; n = 0
for k, (es, fr) in U.items():
    keys = [k] + ([k.replace('%lld', '%@')] if '%lld' in k else []) + ([k.replace('%@', '%lld')] if '%@' in k else [])
    for key in keys:
        if key in s:
            loc = s[key].setdefault('localizations', {})
            for sp, v in (('es', es), ('fr', fr)):
                if sp not in loc: loc[sp] = {"stringUnit": {"state": "translated", "value": v}}; n += 1
orig = open(KAT).read()
open(KAT, 'w').write(json.dumps(cat, ensure_ascii=False, indent=2, separators=(',', ': ')) + ('\n' if orig.endswith('\n') else ''))
print('eingetragen:', n)
