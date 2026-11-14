#!/usr/bin/env python3
"""einfuehrung_suche_strings.py: de/en/es/fr für Einführung (Suche, Versprechen, Game-Center-Hinweis). Überschreibt nichts. Aufruf aus dem Projektordner."""
import json
KAT = 'App/Ressourcen/Localizable.xcstrings'
U = {
"Keine Werbung": ("No ads", "Sin anuncios", "Pas de publicité"),
"Kein Bezahlen": ("Nothing to pay", "Sin pagos", "Rien à payer"),
"Kein Tracking": ("No tracking", "Sin rastreo", "Pas de suivi"),
"Spiel suchen": ("Search games", "Buscar juegos", "Chercher un jeu"),
"Suche löschen": ("Clear search", "Borrar búsqueda", "Effacer la recherche"),
"Partie kann dich an die Tagesaufgabe, angefangene Partien und Game-Center-Anfragen von Freunden erinnern. Das ist freiwillig.": (
 "Partie can remind you about the daily task, games in progress and Game Center requests from friends. This is optional.",
 "Partie puede recordarte la tarea del día, las partidas empezadas y las solicitudes de amigos de Game Center. Es opcional.",
 "Partie peut te rappeler la tâche du jour, les parties en cours et les demandes d’amis Game Center. C’est facultatif."),
"Game Center?": ("Game Center?", "¿Game Center?", "Game Center ?"),
"Mit Game Center kannst du deine besten Zeiten und Punkte mit Freunden vergleichen und Erfolge sammeln. Das ist freiwillig und standardmäßig aus. Du kannst es jederzeit in den Einstellungen ändern.": ("With Game Center you can compare your best times and scores with friends and collect achievements. It is optional and off by default. You can change it any time in Settings.", "Con Game Center puedes comparar tus mejores tiempos y puntos con tus amigos y conseguir logros. Es opcional y está desactivado por defecto. Puedes cambiarlo en cualquier momento en Ajustes.", "Avec Game Center, compare tes meilleurs temps et scores avec tes amis et débloque des succès. C’est facultatif et désactivé par défaut. Tu peux le modifier à tout moment dans les Réglages."),
"Im Kinder-Modus ist Game Center aus.": ("Game Center is off in Kids mode.", "Game Center está desactivado en el modo infantil.", "Game Center est désactivé en mode enfant."),
"Game Center eingeschaltet": ("Game Center is on", "Game Center activado", "Game Center activé"),
"Game Center einschalten": ("Turn on Game Center", "Activar Game Center", "Activer Game Center"),
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
