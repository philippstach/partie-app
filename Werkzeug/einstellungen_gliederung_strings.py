#!/usr/bin/env python3
"""einstellungen_gliederung_strings.py: en/es/fr-Texte für die neue Gliederung der Einstellungen (Unterseiten).
Überschreibt nie Vorhandenes; beliebig oft wiederholbar. Aufruf im Projektordner: python3 Werkzeug/einstellungen_gliederung_strings.py"""
import json
KAT = 'App/Ressourcen/Localizable.xcstrings'
U = {
"Spielen": ("Play", "Jugar", "Jouer"),
"Töne, Haptik, Würfel, Game Center": ("Sounds, haptics, dice, Game Center", "Sonidos, háptica, dados, Game Center", "Sons, haptique, dés, Game Center"),
"Start und Aussehen": ("Start and appearance", "Inicio y aspecto", "Démarrage et apparence"),
"Beim Öffnen, Darstellung, Sprache, App-Symbol": ("On launch, appearance, language, app icon", "Al abrir, apariencia, idioma, icono de la app", "À l’ouverture, apparence, langue, icône de l’app"),
"Familie und Ruhe": ("Family and quiet", "Familia y calma", "Famille et calme"),
"Kinder-Modus ist an": ("Kids mode is on", "El modo infantil está activado", "Le mode enfants est activé"),
"Ruhe-Modus ist an": ("Quiet mode is on", "El modo tranquilo está activado", "Le mode calme est activé"),
"Kinder-Modus, Ruhe-Modus, Mitteilungen": ("Kids mode, Quiet mode, notifications", "Modo infantil, modo tranquilo, notificaciones", "Mode enfants, mode calme, notifications"),
"Daten und Sicherung": ("Data and backup", "Datos y copia de seguridad", "Données et sauvegarde"),
"Gespeicherte Daten, iCloud, Sicherung, Statistik": ("Saved data, iCloud, backup, statistics", "Datos guardados, iCloud, copia, estadísticas", "Données enregistrées, iCloud, sauvegarde, statistiques"),
"Hilfe und Über": ("Help and about", "Ayuda y acerca de", "Aide et à propos"),
"Einführung, Glossar, Open Source, Version": ("Introduction, glossary, open source, version", "Introducción, glosario, código abierto, versión", "Introduction, glossaire, open source, version"),
"Würfel": ("Dice", "Dados", "Dés"),
"Weitere Optionen": ("More options", "Más opciones", "Autres options"),
"Start": ("Start", "Inicio", "Démarrage"),
"„Partie abbrechen“ legt fest, ob „Beenden“ mitten in einer Partie als Niederlage zählt. Eine Partie gilt als begonnen, sobald ein Zug gemacht wurde, sie fortgesetzt wurde oder länger als 20 Sekunden läuft. Im Kinder-Modus und in Arcade-Spielen zählt ein Abbruch nie.": (
    "“Abandon game” decides whether “End” in the middle of a game counts as a loss. A game counts as started once a move was made, it was resumed or it has run for more than 20 seconds. In Kids mode and in arcade games quitting never counts.",
    "«Abandonar la partida» decide si «Terminar» en mitad de una partida cuenta como derrota. Una partida cuenta como empezada en cuanto se hace una jugada, se reanuda o dura más de 20 segundos. En el modo infantil y en los juegos arcade abandonar nunca cuenta.",
    "« Abandonner la partie » décide si « Terminer » en pleine partie compte comme une défaite. Une partie compte comme commencée dès qu’un coup est joué, qu’elle est reprise ou qu’elle dure plus de 20 secondes. En mode enfants et dans les jeux d’arcade, abandonner ne compte jamais."),
"Mit „Echt“ würfelst du auf dem Tisch und tippst das Ergebnis ein.": ("With “Real” you roll on the table and type in the result.", "Con «Real» tiras en la mesa y escribes el resultado.", "Avec « Réel », tu lances sur la table et tu saisis le résultat."),
}
d = json.load(open(KAT)); st = d["strings"]; neu = 0
for k, (en, es, fr) in U.items():
    e = st.setdefault(k, {"extractionState": "manual", "localizations": {}})
    loc = e.setdefault("localizations", {})
    for l, v in (("de", k), ("en", en), ("es", es), ("fr", fr)):
        if l not in loc: loc[l] = {"stringUnit": {"state": "translated", "value": v}}; neu += 1
json.dump(d, open(KAT, "w"), ensure_ascii=False, indent=2); open(KAT, "a").write("\n")
print("ergänzt:", neu)
