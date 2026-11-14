#!/usr/bin/env python3
"""uebersetzungen_b7.py (Build 7): ergänzt fehlende en/es/fr-Texte der Oberfläche (Datenseite, Statistik, „Was spielen wir?“,
Sammlungs-Start, Spielerprofil sowie Barrierefreiheits-Texte einzelner Spiele) in App/Ressourcen/Localizable.xcstrings.
Überschreibt nie vorhandene Übersetzungen; beliebig oft wiederholbar (der Integrator kann es nach einem Konflikt neu laufen lassen).
Aufruf aus dem Projektordner (Partie/Haupt): python3 Werkzeug/uebersetzungen_b7.py"""
import json

KAT = 'App/Ressourcen/Localizable.xcstrings'

U = {
# --- Datenseite ---
"Gespeicherte Daten": ("Stored data", "Datos guardados", "Données enregistrées"),
"Auf diesem Gerät gespeichert": ("Stored on this device", "Guardado en este dispositivo", "Enregistré sur cet appareil"),
"Alle Daten bleiben auf deinem Gerät. Partie hat keine Konten, keine Server und kein Tracking.": (
    "All data stays on your device. Partie has no accounts, no servers and no tracking.",
    "Todos los datos permanecen en tu dispositivo. Partie no tiene cuentas, servidores ni seguimiento.",
    "Toutes les données restent sur ton appareil. Partie n’a ni compte, ni serveur, ni suivi."),
"Statistik exportieren (CSV)": ("Export statistics (CSV)", "Exportar estadísticas (CSV)", "Exporter les statistiques (CSV)"),
"Alle Daten löschen": ("Delete all data", "Borrar todos los datos", "Supprimer toutes les données"),
"Alle Daten löschen?": ("Delete all data?", "¿Borrar todos los datos?", "Supprimer toutes les données ?"),
"Alles löschen": ("Delete everything", "Borrar todo", "Tout supprimer"),
"Partien, Spieler, Favoriten, Spielstände und Einstellungen werden unwiderruflich entfernt.": (
    "Games, players, favourites, saved games and settings will be removed permanently.",
    "Se eliminarán de forma permanente las partidas, los jugadores, los favoritos, las partidas guardadas y los ajustes.",
    "Les parties, joueurs, favoris, parties en cours et réglages seront supprimés définitivement."),
"Alles gelöscht. Beende Partie und öffne sie neu, damit alle Ansichten leer starten.": (
    "Everything deleted. Quit Partie and open it again so all views start empty.",
    "Todo borrado. Cierra Partie y ábrela de nuevo para que todas las vistas empiecen vacías.",
    "Tout est supprimé. Quitte Partie et rouvre-la pour que toutes les vues repartent à zéro."),
# --- Statistik ---
"Alle Partien": ("All games", "Todas las partidas", "Toutes les parties"),
"Je Spiel": ("By game", "Por juego", "Par jeu"),
"Partien je Woche": ("Games per week", "Partidas por semana", "Parties par semaine"),
"Partien nach Spielart": ("Games by type", "Partidas por tipo", "Parties par type"),
"letzte 12 Wochen": ("last 12 weeks", "últimas 12 semanas", "12 dernières semaines"),
"nach Spielart": ("by type", "por tipo", "par type"),
"nach Partien": ("by games", "por partidas", "par parties"),
"gegen": ("against", "contra", "contre"),
"in %lld": ("in %lld", "en %lld", "en %lld"),
"Lieblingsspiele": ("Favourite games", "Juegos favoritos", "Jeux préférés"),
"Noch keine Partien gespielt. Sobald ihr spielt, siehst du hier Diagramme und den Verlauf.": (
    "No games played yet. Once you play, you’ll see charts and your history here.",
    "Aún no hay partidas jugadas. En cuanto juguéis, verás aquí gráficos y el historial.",
    "Aucune partie jouée pour l’instant. Dès que vous jouez, tu verras ici des graphiques et l’historique."),
"Noch keine Partien mit %@. Wähle die Person beim nächsten Spiel aus, dann zählt alles hier mit.": (
    "No games with %@ yet. Pick this person in your next game and everything will count here.",
    "Aún no hay partidas con %@. Elige a esta persona en la próxima partida y todo contará aquí.",
    "Pas encore de partie avec %@. Choisis cette personne à la prochaine partie et tout sera compté ici."),
"%lld Partien": ("%lld games", "%lld partidas", "%lld parties"),
"%lld Partien in den letzten zwölf Wochen": ("%lld games in the last twelve weeks", "%lld partidas en las últimas doce semanas", "%lld parties au cours des douze dernières semaines"),
"%lld Partien · %lld Siege · %lld %%": ("%lld games · %lld wins · %lld %%", "%lld partidas · %lld victorias · %lld %%", "%lld parties · %lld victoires · %lld %%"),
"%lld : %lld": ("%lld : %lld", "%lld : %lld", "%lld : %lld"),
"%@: %lld Partien, %lld Siege": ("%@: %lld games, %lld wins", "%@: %lld partidas, %lld victorias", "%@ : %lld parties, %lld victoires"),
"%@: %lld Partien, %lld Siege, Siegquote %lld Prozent": (
    "%@: %lld games, %lld wins, win rate %lld percent", "%@: %lld partidas, %lld victorias, tasa de victorias %lld por ciento", "%@ : %lld parties, %lld victoires, taux de victoire %lld pour cent"),
"Gegen %@: %lld Siege, %lld Niederlagen in %lld Partien": (
    "Against %@: %lld wins, %lld losses in %lld games", "Contra %@: %lld victorias, %lld derrotas en %lld partidas", "Contre %@ : %lld victoires, %lld défaites en %lld parties"),
"gewonnen": ("won", "ganada", "gagnée"),
" Ich": (" Me", " Yo", " Moi"),
"Doppeltippen für die Statistik dieser Person": ("Double-tap for this person’s statistics", "Toca dos veces para ver las estadísticas de esta persona", "Appuie deux fois pour voir les statistiques de cette personne"),
# --- Was spielen wir? / Sammlung ---
"Apple Intelligence": ("Apple Intelligence", "Apple Intelligence", "Apple Intelligence"),
"Apple Intelligence ist gerade nicht verfügbar. Vorschlag nach Spielart, Spielerzahl, Zeit und Anspruch.": (
    "Apple Intelligence isn’t available right now. Suggestion by type, number of players, time and difficulty.",
    "Apple Intelligence no está disponible ahora. Sugerencia según tipo, número de jugadores, tiempo y dificultad.",
    "Apple Intelligence n’est pas disponible pour le moment. Suggestion selon le type, le nombre de joueurs, la durée et la difficulté."),
"Ohne Apple Intelligence: Vorschlag nach Spielart, Spielerzahl, Zeit und Anspruch aus deinem Text.": (
    "Without Apple Intelligence: suggestion by type, number of players, time and difficulty from your text.",
    "Sin Apple Intelligence: sugerencia según tipo, número de jugadores, tiempo y dificultad a partir de tu texto.",
    "Sans Apple Intelligence : suggestion selon le type, le nombre de joueurs, la durée et la difficulté d’après ton texte."),
"Dafür gibt es kein Spiel. Ändere Spielerzahl oder Zeit.": ("There’s no game for that. Change the number of players or the time.", "No hay ningún juego para eso. Cambia el número de jugadores o el tiempo.", "Il n’y a pas de jeu pour ça. Change le nombre de joueurs ou la durée."),
"Dazu passt kein Spiel in der Sammlung. Beschreibe es anders oder lockere Spielerzahl und Zeit.": (
    "No game in the collection fits. Describe it differently or loosen the number of players and time.",
    "Ningún juego de la colección encaja. Descríbelo de otra forma o relaja el número de jugadores y el tiempo.",
    "Aucun jeu de la collection ne correspond. Décris-le autrement ou assouplis le nombre de joueurs et la durée."),
"Mein Vorschlag": ("My suggestion", "Mi sugerencia", "Ma suggestion"),
"Passt zu eurem Wunsch": ("Matches what you asked for", "Encaja con lo que pedís", "Correspond à votre souhait"),
"Überrasch mich": ("Surprise me", "Sorpréndeme", "Surprends-moi"),
"z. B. Würfelspiel zu viert, gemütlich, nicht viel Denken": (
    "e.g. dice game for four, relaxed, not much thinking", "p. ej. juego de dados para cuatro, tranquilo, sin pensar mucho", "p. ex. jeu de dés à quatre, tranquille, sans trop réfléchir"),
"Wie viele Spieler? %lld": ("How many players? %lld", "¿Cuántos jugadores? %lld", "Combien de joueurs ? %lld"),
"ca. %lld Min.": ("approx. %lld min", "aprox. %lld min", "env. %lld min"),
"%@ · ca. %lld Min.": ("%@ · approx. %lld min", "%@ · aprox. %lld min", "%@ · env. %lld min"),
"%@ · %@ · ca. %lld Min.": ("%@ · %@ · approx. %lld min", "%@ · %@ · aprox. %lld min", "%@ · %@ · env. %lld min"),
"%lld Spieler": ("%lld players", "%lld jugadores", "%lld joueurs"),
"Allein": ("Solo", "Solo", "Seul"),
"Favoriten · %lld": ("Favourites · %lld", "Favoritos · %lld", "Favoris · %lld"),
"Neue Liste": ("New list", "Nueva lista", "Nouvelle liste"),
"Liste löschen": ("Delete list", "Borrar lista", "Supprimer la liste"),
"Spielprofil": ("Game profile", "Perfil de juego", "Profil de jeu"),
"Spielzeit": ("Play time", "Duración", "Durée de jeu"),
"Schnellstart": ("Quick start", "Inicio rápido", "Démarrage rapide"),
"Zuletzt gespieltes Spiel öffnen": ("Open last played game", "Abrir el último juego jugado", "Ouvrir le dernier jeu joué"),
"Öffnet das Spiel": ("Opens the game", "Abre el juego", "Ouvre le jeu"),
"Aktionen: nach vorn, nach hinten oder entfernen": ("Actions: move forward, move back or remove", "Acciones: mover adelante, mover atrás o quitar", "Actions : avancer, reculer ou retirer"),
"Nach vorn": ("Move forward", "Mover adelante", "Avancer"),
"Nach hinten": ("Move back", "Mover atrás", "Reculer"),
"Namensvorschläge zurücksetzen?": ("Reset name suggestions?", "¿Restablecer las sugerencias de nombres?", "Réinitialiser les suggestions de noms ?"),
# --- Einstellungen / Symbol / Glossar / Regeln ---
"App-Symbol": ("App icon", "Icono de la app", "Icône de l’app"),
"Symbol nicht geändert": ("Icon not changed", "Icono sin cambios", "Icône inchangée"),
"Farben unterscheidbar": ("Distinguishable colours", "Colores distinguibles", "Couleurs distinguables"),
"Zeigt zu jeder Spielart ein Zeichen und zu Spielerfarben Muster, für Menschen mit Farbsehschwäche.": (
    "Shows a symbol for each type of game and patterns for player colours, for people with colour vision deficiency.",
    "Muestra un símbolo para cada tipo de juego y patrones para los colores de los jugadores, para personas con daltonismo.",
    "Affiche un symbole pour chaque type de jeu et des motifs pour les couleurs des joueurs, pour les personnes daltoniennes."),
"Begriff suchen": ("Search term", "Buscar término", "Rechercher un terme"),
"Kein Begriff gefunden.": ("No term found.", "No se encontró ningún término.", "Aucun terme trouvé."),
"Einzelne Kapitel": ("Individual chapters", "Capítulos individuales", "Chapitres individuels"),
"Frage zu den Regeln": ("Question about the rules", "Pregunta sobre las reglas", "Question sur les règles"),
"Nicht verfügbar": ("Not available", "No disponible", "Indisponible"),
"%lld. %@": ("%lld. %@", "%lld. %@", "%lld. %@"),
"%lld. %@, %lld: %@": ("%lld. %@, %lld: %@", "%lld. %@, %lld: %@", "%lld. %@, %lld : %@"),
"%lld. %lld": ("%lld. %lld", "%lld. %lld", "%lld. %lld"),
"Rundenlimit": ("Round limit", "Límite de rondas", "Limite de manches"),
"Strafe": ("Penalty", "Penalización", "Pénalité"),
"Zielpunkte": ("Target points", "Puntos objetivo", "Points à atteindre"),
"DAS WÜRFELSPIEL": ("THE DICE GAME", "EL JUEGO DE DADOS", "LE JEU DE DÉS"),
# --- einzelne Spiele ---
"Welche Farbe?": ("Which colour?", "¿Qué color?", "Quelle couleur ?"),
"Welche Farbe wünschst du dir?": ("Which colour do you wish for?", "¿Qué color deseas?", "Quelle couleur veux-tu ?"),
"Farbe wünschen": ("Choose a colour", "Elegir un color", "Choisir une couleur"),
"aussetzen": ("skip", "pierde el turno", "passe son tour"),
"gewinnt": ("wins", "gana", "gagne"),
"gleichauf": ("tied", "empate", "à égalité"),
"ins Ziel": ("into the goal", "a la meta", "à l’arrivée"),
"auf Feld %lld": ("onto square %lld", "a la casilla %lld", "sur la case %lld"),
"Haus-tier": ("Pet", "Mascota", "Animal"),
"Tipp: ": ("Hint: ", "Pista: ", "Indice : "),
"%@: %@!": ("%@: %@!", "¡%@: %@!", "%@ : %@ !"),
", Sonne": (", sun", ", sol", ", soleil"),
", sicher": (", safe", ", segura", ", sûre"),
" und ": (" and ", " y ", " et "),
"Feld %lld%@%@": ("Square %lld%@%@", "Casilla %lld%@%@", "Case %lld%@%@"),
"Zeile %lld, Spalte %lld%@%@%@": ("Row %lld, column %lld%@%@%@", "Fila %lld, columna %lld%@%@%@", "Ligne %lld, colonne %lld%@%@%@"),
"Mulde %lld von %@, %lld Samen": ("Pit %lld of %@, %lld seeds", "Hoyo %lld de %@, %lld semillas", "Fosse %lld de %@, %lld graines"),
"Gänse": ("Geese", "Ocas", "Oies"),
"%lld Gänse, %lld gefressen, %@ am Zug, Zug %lld von %lld": (
    "%lld geese, %lld captured, %@ to move, move %lld of %lld", "%lld ocas, %lld capturadas, mueve %@, jugada %lld de %lld", "%lld oies, %lld capturées, %@ à jouer, coup %lld sur %lld"),
" – wirft raus!": (" – sends a piece home!", " – ¡echa una ficha!", " – renvoie un pion !"),
"Tipp: Figur %lld aus dem Haus setzen.": ("Hint: bring piece %lld out of the house.", "Pista: saca la ficha %lld de la casa.", "Indice : sors le pion %lld de la maison."),
"Tipp: Figur %lld %@ ziehen%@": ("Hint: move piece %lld %@%@", "Pista: mueve la ficha %lld %@%@", "Indice : déplace le pion %lld %@%@"),
"Tipp: Diese %lld Karten auslegen (%@).": ("Hint: lay down these %lld cards (%@).", "Pista: baja estas %lld cartas (%@).", "Indice : pose ces %lld cartes (%@)."),
"Tipp: Karte %lld von %lld, %@ %@ anlegen.": ("Hint: card %1$lld of %2$lld, play %3$@ %4$@.", "Pista: carta %1$lld de %2$lld, juega %3$@ %4$@.", "Indice : carte %1$lld sur %2$lld, joue %3$@ %4$@."),
"Handkarte %lld (%@)": ("Hand card %lld (%@)", "Carta de la mano %lld (%@)", "Carte en main %lld (%@)"),
"%@ legt 1 Karte (%@). Glaubst du das?": ("%1$@ plays 1 card (%2$@). Do you believe that?", "%1$@ juega 1 carta (%2$@). ¿Te lo crees?", "%1$@ pose 1 carte (%2$@). Tu y crois ?"),
"%@ legt %lld Karten (%@). Glaubst du das?": ("%1$@ plays %2$lld cards (%3$@). Do you believe that?", "%1$@ juega %2$lld cartas (%3$@). ¿Te lo crees?", "%1$@ pose %2$lld cartes (%3$@). Tu y crois ?"),
"1 beendetes Spiel. Mitspielende werden am Namen erkannt. Die Statistik bleibt auch, wenn beendete Spiele nicht behalten werden.": (
    "1 finished game. Fellow players are recognised by name. The statistics are kept even if finished games are not kept.",
    "1 partida terminada. Los demás jugadores se reconocen por el nombre. Las estadísticas se conservan aunque no se guarden las partidas terminadas.",
    "1 partie terminée. Les autres joueurs sont reconnus par leur nom. Les statistiques sont conservées même si les parties terminées ne le sont pas."),
"%lld beendete Spiele. Mitspielende werden am Namen erkannt. Die Statistik bleibt auch, wenn beendete Spiele nicht behalten werden.": (
    "%lld finished games. Fellow players are recognised by name. The statistics are kept even if finished games are not kept.",
    "%lld partidas terminadas. Los demás jugadores se reconocen por el nombre. Las estadísticas se conservan aunque no se guarden las partidas terminadas.",
    "%lld parties terminées. Les autres joueurs sont reconnus par leur nom. Les statistiques sont conservées même si les parties terminées ne le sont pas."),
"Wirf den offenen Würfel und tippe die an, die du rauslegst.": (
    "Roll the open die and tap the ones you set aside.", "Tira el dado libre y toca los que apartas.", "Lance le dé libre et touche ceux que tu mets de côté."),
"Wirf die %lld offenen Würfel und tippe die an, die du rauslegst.": (
    "Roll the %lld open dice and tap the ones you set aside.", "Tira los %lld dados libres y toca los que apartas.", "Lance les %lld dés libres et touche ceux que tu mets de côté."),
"Vorschlag: %@, zuletzt %@": ("Suggestion: %@, last used %@", "Sugerencia: %@, usado por última vez %@", "Suggestion : %@, utilisé la dernière fois %@"),
"%lld, %@, %@, %lld": ("%lld, %@, %@, %lld", "%lld, %@, %@, %lld", "%lld, %@, %@, %lld"),

# --- Zehntausend: Einführung (OnboardingView) ---
"Jede 1 bringt 100, jede 5 bringt 50. Drei Einsen und drei Fünfen bringen je 500, andere Drillinge zählen nicht. Eine Straße bringt 1.000.": (
    "Every 1 scores 100, every 5 scores 50. Three ones and three fives score 500 each, other triples don’t count. A straight scores 1,000.",
    "Cada 1 vale 100 y cada 5 vale 50. Tres unos y tres cincos valen 500 cada uno; otros tríos no cuentan. Una escalera vale 1.000.",
    "Chaque 1 rapporte 100, chaque 5 rapporte 50. Trois 1 et trois 5 rapportent 500 chacun, les autres brelans ne comptent pas. Une suite rapporte 1 000."),
"Jede 1 bringt 100, jede 5 bringt 50. Drei Gleiche bringen Augenzahl × 100, drei Einsen 1.000. Eine Straße aus allen Würfeln bringt 1.000.": (
    "Every 1 scores 100, every 5 scores 50. Three of a kind score the face value × 100, three ones 1,000. A straight using all the dice scores 1,000.",
    "Cada 1 vale 100 y cada 5 vale 50. Tres iguales valen el número × 100, tres unos 1.000. Una escalera con todos los dados vale 1.000.",
    "Chaque 1 rapporte 100, chaque 5 rapporte 50. Trois dés identiques rapportent la valeur × 100, trois 1 rapportent 1 000. Une suite avec tous les dés rapporte 1 000."),
"Drei Nieten in Folge kosten %@ Punkte.": ("Three busts in a row cost %@ points.", "Tres nulos seguidos cuestan %@ puntos.", "Trois ratés d’affilée coûtent %@ points."),
"Eine Strafe für Nieten gibt es bei euch nicht.": ("There is no penalty for busts in your game.", "En vuestra partida no hay penalización por nulos.", "Dans votre partie, il n’y a pas de pénalité pour les ratés."),
"Wer holt zuerst %@?": ("Who gets to %@ first?", "¿Quién llega primero a %@?", "Qui atteindra %@ le premier ?"),
"Ihr würfelt reihum und sammelt Punkte. Wer zuerst das Ziel erreicht, gewinnt. Ihr könnt mit der App würfeln oder mit echten Würfeln am Tisch.": (
    "You take turns rolling and collecting points. Whoever reaches the target first wins. You can roll with the app or with real dice at the table.",
    "Tiráis por turnos y acumuláis puntos. Gana quien llega primero al objetivo. Podéis tirar con la app o con dados reales en la mesa.",
    "Vous lancez les dés chacun votre tour et collectez des points. Le premier à atteindre l’objectif gagne. Vous pouvez lancer avec l’app ou avec de vrais dés à table."),
"%lld goldene Würfel, darüber zählt %@ hoch": ("%lld golden dice, above them a counter counting up to %@", "%lld dados dorados y encima un contador que sube hasta %@", "%lld dés dorés, au-dessus un compteur qui monte jusqu’à %@"),
"2 bis 8 Mitspielende auf einem %@": ("2 to 8 players on one %@", "De 2 a 8 jugadores en un %@", "De 2 à 8 joueurs sur un %@"),
"Was zählt?": ("What counts?", "¿Qué cuenta?", "Qu’est-ce qui compte ?"),
"Würfelbilder mit ihren Punkten": ("Dice pictures with their points", "Imágenes de dados con sus puntos", "Images de dés avec leurs points"),
"Rauslegen": ("Setting aside", "Apartar", "Mettre de côté"),
"Nach jedem Wurf legst du mindestens einen Würfel mit Punkten raus. Gezählt wird nur, was in einem Wurf fällt.": (
    "After every roll you set aside at least one scoring die. Only what falls in a single roll counts.",
    "Después de cada tirada apartas al menos un dado que puntúe. Solo cuenta lo que sale en una misma tirada.",
    "Après chaque lancer, tu mets de côté au moins un dé qui compte. Seul ce qui tombe dans un même lancer est compté."),
"Wurf 1, 3, 5, 2, 6 – die 1 und die 5 werden rausgelegt": ("Roll 1, 3, 5, 2, 6 – the 1 and the 5 are set aside", "Tirada 1, 3, 5, 2, 6: el 1 y el 5 se apartan", "Lancer 1, 3, 5, 2, 6 – le 1 et le 5 sont mis de côté"),
"1 und 5 raus: +150": ("1 and 5 set aside: +150", "1 y 5 apartados: +150", "1 et 5 mis de côté : +150"),
"Weiter oder aufhören?": ("Keep going or stop?", "¿Seguir o parar?", "Continuer ou s’arrêter ?"),
"Danach entscheidest du: aufhören und die Punkte sichern, oder mit den übrigen Würfeln weiterwürfeln und mehr riskieren.": (
    "Then you decide: stop and bank the points, or keep rolling the remaining dice and risk more.",
    "Después decides: parar y asegurar los puntos, o seguir tirando con los dados restantes y arriesgar más.",
    "Ensuite, tu décides : t’arrêter et sécuriser les points, ou continuer avec les dés restants et risquer davantage."),
"Zwei Knöpfe: Weiterwürfeln mit %lld Würfeln oder Aufhören mit 150": ("Two buttons: keep rolling with %lld dice or stop with 150", "Dos botones: seguir tirando con %lld dados o parar con 150", "Deux boutons : continuer avec %lld dés ou s’arrêter à 150"),
"150 gesichert oder weiterzocken?": ("Bank 150 or gamble on?", "¿Asegurar 150 o seguir jugándotela?", "Sécuriser 150 ou tenter sa chance ?"),
"Bringt ein Wurf keinen einzigen Punkt, ist es eine Niete. Die Punkte dieses Zugs sind weg, und die nächste Person ist dran.": (
    "If a roll scores no points at all, it’s a bust. The points of this turn are gone and the next person is up.",
    "Si una tirada no da ningún punto, es un nulo. Los puntos de este turno se pierden y le toca a la siguiente persona.",
    "Si un lancer ne rapporte aucun point, c’est un raté. Les points de ce tour sont perdus et c’est à la personne suivante."),
"Wurf ohne Punkte, die Würfel wackeln, rotes Niete": ("Roll without points, the dice shake, red “bust”", "Tirada sin puntos, los dados tiemblan, «nulo» en rojo", "Lancer sans point, les dés tremblent, « raté » en rouge"),
"Niete: Die 150 aus diesem Zug sind weg": ("Bust: the 150 from this turn are gone", "Nulo: se pierden los 150 de este turno", "Raté : les 150 de ce tour sont perdus"),
"Alle Würfel punkten": ("All dice score", "Todos los dados puntúan", "Tous les dés comptent"),
"Hast du alle Würfel rausgelegt, darfst du mit allen wieder würfeln. Die Punkte bleiben dir.": (
    "If you have set aside all the dice, you may roll them all again. You keep the points.",
    "Si has apartado todos los dados, puedes volver a tirarlos todos. Conservas los puntos.",
    "Si tu as mis tous les dés de côté, tu peux tous les relancer. Tu gardes les points."),
"Goldener Blitz, alle Würfel kommen zurück": ("Golden flash, all dice come back", "Rayo dorado, todos los dados vuelven", "Éclair doré, tous les dés reviennent"),
"Alle punkten: weiter mit allen %lld!": ("All score: carry on with all %lld!", "¡Todos puntúan: sigues con los %lld!", "Tous comptent : on continue avec les %lld !"),
"Hört jemand auf und lässt Würfel liegen, darfst du sie samt Punkten übernehmen und weiterwürfeln. Mit einer Niete ist aber alles weg.": (
    "If someone stops and leaves dice on the table, you may take them over along with the points and keep rolling. But a bust wipes it all out.",
    "Si alguien para y deja dados en la mesa, puedes quedártelos con sus puntos y seguir tirando. Pero con un nulo lo pierdes todo.",
    "Si quelqu’un s’arrête et laisse des dés, tu peux les reprendre avec leurs points et continuer. Mais un raté efface tout."),
"Karte: Übernehmen, plus 350, 3 Würfel": ("Card: Take over, plus 350, 3 dice", "Tarjeta: Quedarse, más 350, 3 dados", "Carte : Reprendre, plus 350, 3 dés"),
"+350 übernommen, du würfelst mit 3 Würfeln": ("+350 taken over, you roll with 3 dice", "+350 asumidos, tiras con 3 dados", "+350 repris, tu lances avec 3 dés"),
"Strafe und eure Regeln": ("Penalty and your rules", "Penalización y vuestras reglas", "Pénalité et vos règles"),
"%@ Fast alles ist einstellbar: Ziel, Runden, 6 Würfel, Stechen und mehr. Mit echten Würfeln tippst du einfach ein, was du rauslegst.": (
    "%@ Almost everything can be adjusted: target, rounds, 6 dice, tie-break and more. With real dice you simply type in what you set aside.",
    "%@ Casi todo se puede ajustar: objetivo, rondas, 6 dados, desempate y más. Con dados reales solo tienes que escribir lo que apartas.",
    "%@ Presque tout est réglable : objectif, manches, 6 dés, départage et plus. Avec de vrais dés, tu saisis simplement ce que tu mets de côté."),
"Drei rote Punkte, dann minus %@": ("Three red dots, then minus %@", "Tres puntos rojos, luego menos %@", "Trois points rouges, puis moins %@"),
"Drei Punkte und die Regel-Karte": ("Three dots and the rules card", "Tres puntos y la tarjeta de reglas", "Trois points et la carte des règles"),
"Viel Glück beim Würfeln!": ("Good luck rolling!", "¡Buena suerte con los dados!", "Bonne chance aux dés !"),
"1 + 5 + 1-1-1 = 650": ("1 + 5 + 1-1-1 = 650", "1 + 5 + 1-1-1 = 650", "1 + 5 + 1-1-1 = 650"),
"1 + 5 + 4-4-4 = 550": ("1 + 5 + 4-4-4 = 550", "1 + 5 + 4-4-4 = 550", "1 + 5 + 4-4-4 = 550"),
# --- Sonstiges ---
"Virtuell": ("Virtual", "Virtual", "Virtuel"),
"Echt": ("Real", "Reales", "Réels"),
"Bilanz": ("Head-to-head", "Balance", "Bilan"),
"Liste": ("List", "Lista", "Liste"),
"Zu Liste": ("Add to list", "Añadir a lista", "Ajouter à la liste"),
"Was ihr spielt": ("What you play", "A qué jugáis", "À quoi vous jouez"),
"Worauf habt ihr Lust?": ("What are you in the mood for?", "¿Qué os apetece?", "Qu’avez-vous envie de jouer ?"),
"Was liegt unter deinem Becher?": ("What’s under your cup?", "¿Qué hay bajo tu cubilete?", "Qu’y a-t-il sous ton gobelet ?"),
}

# Zusatz aus dem Bau (Skript Werkzeug/stringsdata_abgleich.py): Schlüssel mit anderem Platzhaltertyp als im Katalog
try:
    exec(open('Werkzeug/uebersetzungen_b7_zusatz.py').read())
except FileNotFoundError:
    pass

d = json.load(open(KAT))
neu = 0
for k, (en, es, fr) in U.items():
    e = d['strings'].setdefault(k, {})
    l = e.setdefault('localizations', {})
    for sprache, wert in (('en', en), ('es', es), ('fr', fr)):
        if sprache in l:
            continue
        l[sprache] = {"stringUnit": {"state": "translated", "value": wert}}
        neu += 1
open(KAT, 'w').write(json.dumps(d, ensure_ascii=False, indent=2) + "\n")
print(f"{neu} neue Übersetzungen eingetragen")
