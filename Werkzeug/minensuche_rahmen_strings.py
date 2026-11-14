#!/usr/bin/env python3
"""minensuche_rahmen_strings.py: de/en/es/fr für den Regeltext der Minensuche im SpielRahmen. Überschreibt nie vorhandene Übersetzungen.
Aufruf aus dem Projektordner."""
import json
KAT = 'App/Ressourcen/Localizable.xcstrings'
U = {
"Decke alle Felder auf, unter denen keine Mine liegt. Eine Mine aufzudecken beendet die Partie. Eine Zahl sagt, wie viele der acht Nachbarfelder eine Mine enthalten, eine leere Fläche öffnet ihre Umgebung von selbst. Tippen deckt auf, lang drücken setzt eine Fahne, mit dem Fahnen-Knopf vertauschst du beides. Hast du rund um eine aufgedeckte Zahl genau so viele Fahnen gesetzt, wie sie angibt, öffnet ein Tipp darauf alle übrigen Nachbarn. Jedes Brett lässt sich allein durch Nachdenken lösen, der erste Zug ist immer sicher; das kannst du vor dem Start ausschalten. Der Hinweis deckt ein sicheres Feld auf und kostet 10 Sekunden Strafzeit. Jeden Tag gibt es ein Tagesrätsel, das für alle gleich ist; an aufeinanderfolgenden Tagen gelöst ergibt es eine Serie.": (
 "Uncover every square that has no mine under it. Uncovering a mine ends the game. A number tells you how many of the eight neighbouring squares contain a mine, and an empty area opens its surroundings by itself. Tapping uncovers, a long press places a flag, and the flag button swaps the two. If you have placed exactly as many flags around an uncovered number as it shows, tapping it opens all the remaining neighbours. Every board can be solved by thinking alone and the first move is always safe; you can switch this off before you start. The hint uncovers a safe square and costs 10 seconds of penalty time. Every day there is a daily puzzle that is the same for everyone; solving it on consecutive days builds a streak.",
 "Descubre todas las casillas bajo las que no hay mina. Descubrir una mina termina la partida. Un número indica cuántas de las ocho casillas vecinas contienen una mina, y una zona vacía abre sus alrededores por sí sola. Tocar descubre, una pulsación larga coloca una bandera y el botón de bandera intercambia ambas cosas. Si has colocado alrededor de un número descubierto tantas banderas como indica, tocarlo abre todas las demás casillas vecinas. Todo tablero se puede resolver pensando, sin adivinar, y la primera jugada siempre es segura; puedes desactivarlo antes de empezar. La pista descubre una casilla segura y cuesta 10 segundos de penalización. Cada día hay un reto diario igual para todos; resolverlo en días seguidos forma una racha.",
 "Découvre toutes les cases sous lesquelles il n’y a pas de mine. Découvrir une mine met fin à la partie. Un chiffre indique combien des huit cases voisines contiennent une mine, et une zone vide ouvre d’elle-même ses environs. Toucher découvre, un appui long pose un drapeau et le bouton drapeau permute les deux. Si tu as posé autour d’un chiffre découvert autant de drapeaux qu’il l’indique, le toucher ouvre toutes les autres cases voisines. Chaque grille peut se résoudre en réfléchissant, sans deviner, et le premier coup est toujours sûr ; tu peux le désactiver avant de commencer. L’indice découvre une case sûre et coûte 10 secondes de pénalité. Chaque jour, il y a un défi du jour identique pour tous ; le réussir plusieurs jours de suite crée une série."),
}
cat = json.load(open(KAT)); s = cat['strings']
n = 0
for k, t in U.items():
    loc = s.setdefault(k, {}).setdefault('localizations', {})
    if 'en' in loc and 'fr' in loc: continue
    loc.setdefault('de', {"stringUnit": {"state": "translated", "value": k}})
    for sp, v in zip(('en', 'es', 'fr'), t): loc[sp] = {"stringUnit": {"state": "translated", "value": v}}
    n += 1
orig = open(KAT).read()
open(KAT, 'w').write(json.dumps(cat, ensure_ascii=False, indent=2, separators=(',', ': ')) + ('\n' if orig.endswith('\n') else ''))
print('eingetragen:', n)
