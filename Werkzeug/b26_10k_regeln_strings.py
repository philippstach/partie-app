#!/usr/bin/env python3
"""b26_wuerfel_strings.py: Zehntausend: regeln:-Text nach T-099, de/en/es/fr. Trägt einen Text nur ein, wenn es ihn noch nicht in en und fr gibt. Aufruf aus dem Projektordner. Übersetzungen sind Vorschläge."""
import json
KAT = 'App/Ressourcen/Localizable.xcstrings'
U = {
"Du würfelst mit fünf Würfeln. Nach jedem Wurf legst du mindestens einen Würfel mit Punkten raus: eine 1 zählt 100, eine 5 zählt 50, drei gleiche zählen Augenzahl mal 100 (drei Einsen 1.000), eine Straße 1.000. Dann hörst du auf und schreibst die Punkte an – oder du würfelst mit den übrigen Würfeln weiter. Bringt ein Wurf nichts, ist es eine Niete und alle Punkte dieses Zugs sind weg. Drei Nieten in Folge kosten Strafpunkte. Wer zuerst das Ziel erreicht, gewinnt. Die Regeln der Partie (Einstiegshürde, Mehrfache, drei Paare, sechs Würfel und mehr) stellst du auf der Spielseite vor dem Start ein.": ("You roll five dice. After each throw you set aside at least one scoring die: a 1 is worth 100, a 5 is worth 50, three of a kind are worth the number times 100 (three ones 1,000), a straight 1,000. Then you stop and bank the points – or keep rolling the remaining dice. If a throw scores nothing, it is a bust and all points of this turn are lost. Three busts in a row cost penalty points. The first to reach the goal wins. You set the rules of the game (entry threshold, multiples, three pairs, six dice and more) on the game page before the start.", "Lanzas cinco dados. Tras cada lanzamiento apartas al menos un dado que puntúe: un 1 vale 100, un 5 vale 50, tres iguales valen el número por 100 (tres unos 1.000), una escalera 1.000. Luego paras y anotas los puntos, o sigues lanzando con los dados restantes. Si un lanzamiento no puntúa, es una nula y se pierden todos los puntos del turno. Tres nulas seguidas cuestan puntos de penalización. Gana quien llegue primero a la meta. Las reglas de la partida (umbral de entrada, múltiples, tres pares, seis dados y más) se ajustan en la página del juego antes de empezar.", "Tu lances cinq dés. Après chaque lancer, tu mets de côté au moins un dé qui compte : un 1 vaut 100, un 5 vaut 50, trois identiques valent le chiffre fois 100 (trois as 1 000), une suite 1 000. Ensuite tu t'arrêtes et notes les points – ou tu relances les dés restants. Si un lancer ne rapporte rien, c'est un raté et tous les points du tour sont perdus. Trois ratés de suite coûtent des points de pénalité. Le premier à atteindre l'objectif gagne. Les règles de la partie (seuil d'entrée, multiples, trois paires, six dés et plus) se règlent sur la page du jeu avant le début."),
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
