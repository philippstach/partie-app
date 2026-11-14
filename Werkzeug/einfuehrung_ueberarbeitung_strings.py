#!/usr/bin/env python3
"""einfuehrung_ueberarbeitung_strings.py: de/en/es/fr für die überarbeitete Einführung (eine Seite für Erinnerungen und Game Center). Überschreibt nichts. Aufruf aus dem Projektordner."""
import json
KAT = 'App/Ressourcen/Localizable.xcstrings'
U = {
"Zwei Dinge, beide freiwillig": ("Two things, both optional", "Dos cosas, ambas opcionales", "Deux choses, toutes deux facultatives"),
"Du kannst beides jederzeit in den Einstellungen ändern. Partie funktioniert auch ohne.": (
 "You can change both any time in Settings. Partie works fine without them.",
 "Puedes cambiar ambas en cualquier momento en Ajustes. Partie funciona igual sin ellas.",
 "Tu peux modifier les deux à tout moment dans les Réglages. Partie fonctionne aussi sans."),
"Erinnerungen": ("Reminders", "Recordatorios", "Rappels"),
"Partie kann dich an die Tagesaufgabe und an angefangene Partien erinnern.": (
 "Partie can remind you about the daily task and games in progress.",
 "Partie puede recordarte la tarea del día y las partidas empezadas.",
 "Partie peut te rappeler la tâche du jour et les parties en cours."),
"Game Center": ("Game Center", "Game Center", "Game Center"),
"Game Center ist der Spieledienst von Apple. Wenn du ihn einschaltest, sendet Partie deine besten Zeiten und Punkte dorthin, und du kannst Erfolge sammeln. Das ist nicht nötig, um Partie zu spielen. Ohne Game Center bleiben alle Ergebnisse nur auf deinem Gerät.": (
 "Game Center is Apple’s gaming service. If you turn it on, Partie sends your best times and scores there, and you can collect achievements. You don’t need it to play Partie. Without Game Center, all results stay on your device only.",
 "Game Center es el servicio de juegos de Apple. Si lo activas, Partie envía allí tus mejores tiempos y puntos, y puedes conseguir logros. No lo necesitas para jugar a Partie. Sin Game Center, todos los resultados se quedan solo en tu dispositivo.",
 "Game Center est le service de jeux d’Apple. Si tu l’actives, Partie y envoie tes meilleurs temps et scores, et tu peux débloquer des succès. Tu n’en as pas besoin pour jouer à Partie. Sans Game Center, tous les résultats restent uniquement sur ton appareil."),
"25 Spiele für Familie, Freunde und dich allein. Karten, Würfel, Rätsel und mehr, alles in einer App. Wischen, um loszulegen.": (
 "25 games for family, friends and just you. Cards, dice, puzzles and more, all in one app. Swipe to get started.",
 "25 juegos para la familia, los amigos y para ti solo. Cartas, dados, puzles y más, todo en una app. Desliza para empezar.",
 "25 jeux pour la famille, les amis et toi tout seul. Cartes, dés, énigmes et plus encore, tout dans une seule app. Fais glisser pour commencer."),
"25 Spiele für Familie, Freunde und dich allein. Hier das Wichtigste in einer Minute.": (
 "25 games for family, friends and just you. The essentials in one minute.",
 "25 juegos para la familia, los amigos y para ti solo. Lo esencial en un minuto.",
 "25 jeux pour la famille, les amis et toi tout seul. L’essentiel en une minute."),
"Game Center verwenden": ("Use Game Center", "Usar Game Center", "Utiliser Game Center"),
}
cat = json.load(open(KAT)); s = cat['strings']; n = 0
for k, t in U.items():
    loc = s.setdefault(k, {}).setdefault('localizations', {})
    if 'en' in loc and 'fr' in loc: continue
    loc.setdefault('de', {"stringUnit": {"state": "translated", "value": k}})
    for sp, v in zip(('en', 'es', 'fr'), t): loc.setdefault(sp, {"stringUnit": {"state": "translated", "value": v}})
    n += 1
orig = open(KAT).read()
open(KAT, 'w').write(json.dumps(cat, ensure_ascii=False, indent=2, separators=(',', ': ')) + ('\n' if orig.endswith('\n') else ''))
print('eingetragen:', n)
