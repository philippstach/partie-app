#!/usr/bin/env python3
"""design_runde5_e_strings.py: Runde 5 Paket E (Einführung in Tinte), de/en/es/fr. Überschreibt nichts. Aufruf aus dem Projektordner."""
import json
KAT = 'App/Ressourcen/Localizable.xcstrings'
U = {
"26 Spiele für Familie, Freunde und dich allein. Karten, Würfel, Rätsel und mehr, alles in einer App.": ("26 games for family, friends and you alone. Cards, dice, puzzles and more, all in one app.", "26 juegos para la familia, los amigos y para ti solo. Cartas, dados, rompecabezas y más, todo en una app.", "26 jeux pour la famille, les amis et toi tout seul. Cartes, dés, énigmes et plus, dans une seule appli."),
"Anlegen und weiter": ("Create and continue", "Crear y continuar", "Créer et continuer"),
"Dein Name": ("Your name", "Tu nombre", "Ton prénom"),
"Die App startet direkt dort.": ("The app opens right there.", "La app se abre directamente ahí.", "L’appli s’ouvre directement là."),
"Nur %@ nutzen": ("Only use %@", "Usar solo %@", "Utiliser seulement %@"),
"Noch zwei Dinge": ("Two more things", "Dos cosas más", "Encore deux choses"),
"Beides ist freiwillig. Du kannst es jederzeit in den Einstellungen ändern.": ("Both are optional. You can change this any time in Settings.", "Ambas son opcionales. Puedes cambiarlo en cualquier momento en Ajustes.", "Les deux sont facultatifs. Tu peux les modifier à tout moment dans les Réglages."),
"Partie erinnert dich an die Tagesaufgabe und an angefangene Partien.": ("Partie reminds you of the daily task and of games in progress.", "Partie te recuerda la tarea del día y las partidas empezadas.", "Partie te rappelle la tâche du jour et les parties en cours."),
"Bestenlisten und Erfolge von Apple. Ohne Game Center bleiben alle Ergebnisse nur auf deinem Gerät.": ("Leaderboards and achievements from Apple. Without Game Center all results stay on your device only.", "Clasificaciones y logros de Apple. Sin Game Center, todos los resultados quedan solo en tu dispositivo.", "Classements et succès d’Apple. Sans Game Center, tous les résultats restent sur ton appareil."),
"Game Center verwenden": ("Use Game Center", "Usar Game Center", "Utiliser Game Center"),
"Nicht erlaubt. Änderbar in den iOS-Einstellungen.": ("Not allowed. Can be changed in iOS Settings.", "No permitido. Se puede cambiar en los Ajustes de iOS.", "Non autorisé. Modifiable dans les Réglages iOS."),
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
