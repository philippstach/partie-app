#!/usr/bin/env python3
"""designwechsel_strings.py: en/es/fr (und de) für die neuen Texte des Designwechsels (Tinte, Salon).
Trägt in drei Kataloge ein: App, Baukasten-Produkt KlarGlas, Widget. Überschreibt nie vorhandene Übersetzungen,
ein zweiter Lauf ändert nichts. Aufruf aus dem Projektordner: python3 Werkzeug/designwechsel_strings.py"""
import json, os

WURZEL = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
APP = 'App/Ressourcen/Localizable.xcstrings'
WIDGET = 'Widget/Localizable.xcstrings'
# Der Baukasten liegt neben dem Projekt (project.yml: ../_Gemeinsam/Baukasten).
BAUKASTEN = '../_Gemeinsam/Baukasten/Sources/KlarGlas/Resources/Localizable.xcstrings'

# Schlüssel (Deutsch) -> (en, es, fr)
TEXTE = {
BAUKASTEN: {
"Design": ("Design", "Diseño", "Design"),
"Klar & Glas": ("Clear & Glass", "Claro y cristal", "Clair et verre"),
"Tinte": ("Ink", "Tinta", "Encre"),
"Salon": ("Salon", "Salón", "Salon"),
"Karten, Glas und kräftige Farben": ("Cards, glass and bold colours", "Tarjetas, cristal y colores vivos", "Cartes, verre et couleurs vives"),
"Papier, feine Linien, Serifenschrift": ("Paper, fine lines, serif type", "Papel, líneas finas, letra con serifa", "Papier, lignes fines, caractères à empattements"),
"Große Farbflächen wie im Magazin": ("Large colour fields like a magazine", "Grandes campos de color como en una revista", "Grands aplats de couleur comme dans un magazine"),
"Start": ("Home", "Inicio", "Accueil"),
# Stufe C: Gewinnerseite, Spiel-Startseite
"%@\ngewinnt.": ("%@\nwins.", "%@\ngana.", "%@\ngagne."),
"Protokoll · %@": ("Record · %@", "Acta · %@", "Feuille de match · %@"),
"Regeln": ("Rules", "Reglas", "Règles"),
},
APP: {
# Stufe C: Startseiten Tinte und Salon
"%@. %lld Spiele, %lld Spieler.": ("%1$@. %2$lld games, %3$lld players.", "%1$@. %2$lld juegos, %3$lld jugadores.", "%1$@. %2$lld jeux, %3$lld joueurs."),
"Was spielen wir heute?": ("What shall we play today?", "¿A qué jugamos hoy?", "À quoi on joue aujourd’hui ?"),
"Öffnet die Suche": ("Opens search", "Abre la búsqueda", "Ouvre la recherche"),
"Zuletzt": ("Recent", "Recientes", "Récents"),
"weiter": ("continue", "continuar", "reprendre"),
"Heute": ("Today", "Hoy", "Aujourd’hui"),
"Tagesaufgabe · geschafft": ("Daily task · done", "Tarea diaria · hecha", "Défi du jour · réussi"),
"Ergebnis ansehen": ("View result", "Ver resultado", "Voir le résultat"),
"Deine Spiele": ("Your games", "Tus juegos", "Tes jeux"),
"anpassen": ("customize", "personalizar", "personnaliser"),
"fertig": ("done", "listo", "terminé"),
"Noch keine Spiele hier. Tippe auf „anpassen“ oder öffne „Neue Partie“.": ("No games here yet. Tap “customize” or open “New game”.", "Aún no hay juegos aquí. Toca «personalizar» o abre «Nueva partida».", "Pas encore de jeux ici. Touche « personnaliser » ou ouvre « Nouvelle partie »."),
"Kapitel": ("Chapters", "Capítulos", "Chapitres"),
"Außerdem": ("More", "Además", "Et aussi"),
"mehrere Spiele, eine Wertung": ("several games, one score", "varios juegos, una clasificación", "plusieurs jeux, un classement"),
"Wer ist dabei?": ("Who’s in?", "¿Quién juega?", "Qui joue ?"),
"dabei": ("in", "juega", "joue"),
"nicht dabei": ("not in", "no juega", "ne joue pas"),
"Für dich": ("For you", "Para ti", "Pour toi"),
"Für euch zwei": ("For the two of you", "Para vosotros dos", "Pour vous deux"),
"Für euch drei": ("For the three of you", "Para vosotros tres", "Pour vous trois"),
"Für euch vier": ("For the four of you", "Para vosotros cuatro", "Pour vous quatre"),
"Für euch fünf": ("For the five of you", "Para vosotros cinco", "Pour vous cinq"),
"Für euch alle": ("For all of you", "Para todos vosotros", "Pour vous tous"),
"Noch keine Spiele hier. Tippe auf „Anpassen“ oder öffne „Neue Partie“.": ("No games here yet. Tap “Customize” or open “New game”.", "Aún no hay juegos aquí. Toca «Personalizar» o abre «Nueva partida».", "Pas encore de jeux ici. Touche « Personnaliser » ou ouvre « Nouvelle partie »."),
"Für diese Runde liegt noch kein Spiel auf deiner Startseite. „Neue Partie“ zeigt alle passenden.": ("None of your home games fits this group yet. “New game” shows all that fit.", "Ningún juego de tu inicio encaja aún con este grupo. «Nueva partida» muestra todos los que encajan.", "Aucun jeu de ton accueil ne convient encore à ce groupe. « Nouvelle partie » montre tous ceux qui conviennent."),
"Alle %lld Spiele": ("All %lld games", "Los %lld juegos", "Les %lld jeux"),
"drei Fragen": ("three questions", "tres preguntas", "trois questions"),
"Tagesaufgabe\ngeschafft": ("Daily task\ndone", "Tarea diaria\nhecha", "Défi du jour\nréussi"),
"Tagesaufgabe\nheute": ("Daily task\ntoday", "Tarea diaria\nhoy", "Défi du jour\naujourd’hui"),
"Ergebnis\nansehen": ("View\nresult", "Ver\nresultado", "Voir\nle résultat"),
"Runde %lld\nvon %lld": ("Round %1$lld\nof %2$lld", "Ronda %1$lld\nde %2$lld", "Manche %1$lld\nsur %2$lld"),
"%lld Min": ("%lld min", "%lld min", "%lld min"),
"Anpassen": ("Customize", "Personalizar", "Personnaliser"),
"Zufall": ("Random", "Azar", "Hasard"),
"%lld Personen, %lld Partien zusammen.": ("%1$lld people, %2$lld games together.", "%1$lld personas, %2$lld partidas en total.", "%1$lld personnes, %2$lld parties au total."),
},
WIDGET: {
},
}

gesamt = 0
for rel, texte in TEXTE.items():
    if not texte:
        continue
    pfad = os.path.normpath(os.path.join(WURZEL, rel))
    orig = open(pfad, encoding='utf-8').read()
    kat = json.loads(orig); s = kat['strings']
    n = 0
    for k, t in texte.items():
        loc = s.setdefault(k, {}).setdefault('localizations', {})
        vorher = len(loc)
        for sp, v in zip(('de', 'en', 'es', 'fr'), (k,) + tuple(t)):
            loc.setdefault(sp, {"stringUnit": {"state": "translated", "value": v}})
        n += len(loc) != vorher
    neu = json.dumps(kat, ensure_ascii=False, indent=2, separators=(',', ': ')) + ('\n' if orig.endswith('\n') else '')
    if neu != orig:
        open(pfad, 'w', encoding='utf-8').write(neu)
    print(f'{rel}: eingetragen {n}')
    gesamt += n
print('eingetragen gesamt:', gesamt)
