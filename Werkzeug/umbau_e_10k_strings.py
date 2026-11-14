#!/usr/bin/env python3
"""umbau_e_10k_strings.py: de/en/es/fr für die neuen Texte der Zehntausend-Spielseite (Umbau E). Idempotent, überschreibt nichts. Aufruf aus dem Projektordner."""
import json
KAT = 'App/Ressourcen/Localizable.xcstrings'
U = {
"Regeln der Partie": ("Rules of this game", "Reglas de la partida", "Règles de la partie"),
"Eigene Regeln …": ("Custom rules …", "Reglas propias …", "Règles personnalisées …"),
"Bestenliste": ("Leaderboard", "Clasificación", "Classement"),
"Rekorde": ("Records", "Récords", "Records"),
"Siege": ("Wins", "Victorias", "Victoires"),
"Bester Zug": ("Best turn", "Mejor turno", "Meilleur tour"),
"Höchster Endstand": ("Highest final score", "Puntuación final más alta", "Score final le plus élevé"),
"Längste Siegesserie": ("Longest winning streak", "Racha de victorias más larga", "Plus longue série de victoires"),
"%lld von %lld": ("%1$lld of %2$lld", "%1$lld de %2$lld", "%1$lld sur %2$lld"),
"Noch keine beendete Partie. Nach dem ersten Spiel stehen hier Rekorde und Siege.": ("No finished game yet. Records and wins appear here after your first game.", "Aún no hay partidas terminadas. Tras la primera aparecerán aquí récords y victorias.", "Aucune partie terminée. Après la première, les records et victoires apparaissent ici."),
"Würfeln und rauslegen": ("Roll and set aside", "Tirar y apartar", "Lancer et mettre de côté"),
"Wirf alle Würfel und lege mindestens einen mit Punkten raus: Eine 1 zählt 100, eine 5 zählt 50.": ("Roll all dice and set aside at least one that scores: a 1 is worth 100, a 5 is worth 50.", "Tira todos los dados y aparta al menos uno que puntúe: un 1 vale 100, un 5 vale 50.", "Lancez tous les dés et mettez de côté au moins un dé qui marque : un 1 vaut 100, un 5 vaut 50."),
"Drilling und Straße": ("Triples and straight", "Tríos y escalera", "Brelans et suite"),
"Drei gleiche zählen Augenzahl mal 100, drei Einsen 1.000. Eine Straße bringt 1.000.": ("Three of a kind score the number times 100, three 1s score 1,000. A straight scores 1,000.", "Tres iguales valen el número por 100, tres unos 1.000. Una escalera vale 1.000.", "Trois dés identiques valent le chiffre fois 100, trois 1 valent 1 000. Une suite vaut 1 000."),
"Aufhören oder weiter": ("Stop or go on", "Parar o seguir", "S'arrêter ou continuer"),
"Schreibe die Punkte an oder würfle weiter. Eine Niete löscht den Zug. Wer zuerst das Ziel erreicht, gewinnt.": ("Bank your points or keep rolling. A bust wipes the turn. First to the target wins.", "Anota los puntos o sigue tirando. Un fallo borra el turno. Gana quien llegue primero al objetivo.", "Marquez vos points ou continuez à lancer. Un raté annule le tour. Le premier à atteindre l'objectif gagne."),
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
