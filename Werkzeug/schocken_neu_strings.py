#!/usr/bin/env python3
"""schocken_neu_strings.py: en/es/fr für die neuen Texte von „Schocken (neu)“. Überschreibt nie vorhandene Übersetzungen.
Aufruf aus dem Projektordner (Partie/Haupt)."""
import json
KAT = 'App/Ressourcen/Localizable.xcstrings'
U = {
"Stock %lld": ("Pot %lld", "Reserva %lld", "Réserve %lld"),
"Stock, %lld Deckel": ("Pot, %lld lids", "Reserva, %lld tapas", "Réserve, %lld couvercles"),
"%@ · Runde %lld": ("%@ · Round %lld", "%@ · Ronda %lld", "%@ · Manche %lld"),
"Runde gewertet": ("Round scored", "Ronda puntuada", "Manche comptée"),
"Der Vorleger bestimmt, wie oft gewürfelt wird": ("The leader decides how many throws everyone gets", "Quien abre decide cuántas tiradas hay", "Le premier joueur décide du nombre de lancers"),
"Noch nichts zu schlagen": ("Nothing to beat yet", "Aún nada que superar", "Rien à battre pour l’instant"),
"Die Würfe der Runde": ("The throws of this round", "Las tiradas de la ronda", "Les lancers de la manche"),
"%@: %@, %@": ("%@: %@, %@", "%@: %@, %@", "%@ : %@, %@"),
", schlechtester Wurf": (", worst throw", ", peor tirada", ", pire lancer"),
", bester Wurf": (", best throw", ", mejor tirada", ", meilleur lancer"),
"Brauchst du Hilfe?": ("Need help?", "¿Necesitas ayuda?", "Besoin d’aide ?"),
"%@, %lld Deckel": ("%@, %lld lids", "%@, %lld tapas", "%@, %lld couvercles"),
", raus": (", out", ", fuera", ", éliminé"),
", am Zug": (", their turn", ", su turno", ", à son tour"),
"Diese Runde": ("This round", "Esta ronda", "Cette manche"),
"Abend ansehen": ("View the evening", "Ver la velada", "Voir la soirée"),
"Hausregeln ändern": ("Change house rules", "Cambiar reglas de la casa", "Changer les règles maison"),
"Du verlierst die Partie": ("You lose the game", "Pierdes la partida", "Tu perds la partie"),
"%@ verliert die Partie": ("%@ loses the game", "%@ pierde la partida", "%@ perd la partie"),
"1 Hälfte verloren": ("1 half lost", "1 mitad perdida", "1 moitié perdue"),
"%lld Hälften verloren": ("%lld halves lost", "%lld mitades perdidas", "%lld moitiés perdues"),
"Kneipe": ("Pub", "Taberna", "Bistrot"),
"Streng: nur Einsen herauslegen, Jule 4-2-1 an.": ("Strict: only ones may be set aside, Jule 4-2-1 on.", "Estricto: solo se apartan unos, Jule 4-2-1 activada.", "Strict : seuls les as se mettent de côté, Jule 4-2-1 activée."),
"Familie": ("Family", "Familia", "Famille"),
"Locker: Jule aus, beliebige Würfel herauslegen.": ("Relaxed: Jule off, any dice may be set aside.", "Relajado: Jule desactivada, se puede apartar cualquier dado.", "Détendu : Jule désactivée, on peut mettre n’importe quel dé de côté."),
"Schock aus beendet die Hälfte": ("Schock out ends the half", "Schock aus termina la mitad", "Schock aus termine la moitié"),
"Aus: Schock aus gibt nur so viele Deckel wie eine Hälfte hat, das Spiel geht weiter.": ("Off: Schock out gives only as many lids as one half has, and play goes on.", "Desactivado: Schock aus reparte solo tantas tapas como tiene una mitad y el juego continúa.", "Désactivé : Schock aus ne donne que le nombre de couvercles d’une moitié et la partie continue."),
"Würfeln, Deckel verteilen, nicht verlieren": ("Throw, hand out lids, don’t lose", "Tirar, repartir tapas, no perder", "Lancer, distribuer des couvercles, ne pas perdre"),
"Verliere nicht: Wer am Ende der Partie die meisten Hälften verloren hat, verliert die Partie.": ("Don’t lose: whoever loses the most halves loses the game.", "No pierdas: quien pierde más mitades pierde la partida.", "Ne perds pas : celui qui perd le plus de moitiés perd la partie."),
"Jeder würfelt reihum mit drei Würfeln, höchstens dreimal. Nach jedem Wurf darfst du Würfel herauslegen und mit den übrigen weiterwürfeln; Einsen legst du heraus, zwei oder drei Sechsen darfst du zu Einsen umdrehen. Wer vorlegt, bestimmt, wie oft die anderen würfeln dürfen. Die Rangfolge: Zahl, Straße, General, Schock (zwei Einsen plus eine Zahl), Schock aus (drei Einsen). Der schlechteste Wurf der Runde bekommt Deckel, so viele, wie der beste Wurf wert ist, erst aus dem Stock, danach vom Gewinner. Wer alle Deckel hat, verliert die Hälfte. Nach zwei Hälften spielen die beiden Verlierer das Finale. Vor dem ersten Zug kannst du die Hausregeln der Partie ändern.":
 ("Everyone throws three dice in turn, at most three times. After each throw you may set dice aside and keep throwing the rest; you set aside ones, and two or three sixes may be turned into ones. Whoever leads decides how often the others may throw. The ranking: number, run, general, Schock (two ones plus a number), Schock out (three ones). The worst throw of the round receives lids, as many as the best throw is worth, first from the pot, then from the winner. Whoever holds all the lids loses the half. After two halves the two losers play the final. Before the first throw you can change the house rules of the game.",
  "Todos tiran por turno con tres dados, como máximo tres veces. Tras cada tirada puedes apartar dados y seguir tirando con los demás; los unos se apartan, y dos o tres seises pueden darse la vuelta y contar como unos. Quien abre decide cuántas veces pueden tirar los demás. El orden: número, escalera, general, Schock (dos unos más un número), Schock aus (tres unos). La peor tirada de la ronda recibe tapas, tantas como valga la mejor tirada, primero de la reserva y después del ganador. Quien tiene todas las tapas pierde la mitad. Tras dos mitades, los dos perdedores juegan la final. Antes de la primera tirada puedes cambiar las reglas de la casa.",
  "Chacun lance à tour de rôle trois dés, au plus trois fois. Après chaque lancer, tu peux mettre des dés de côté et relancer les autres ; les as se mettent de côté, deux ou trois six peuvent être retournés en as. Celui qui ouvre décide combien de fois les autres peuvent lancer. Le classement : nombre, suite, général, Schock (deux as plus un nombre), Schock aus (trois as). Le pire lancer de la manche reçoit des couvercles, autant que vaut le meilleur lancer, d’abord de la réserve, puis du gagnant. Celui qui a tous les couvercles perd la moitié. Après deux moitiés, les deux perdants jouent la finale. Avant le premier lancer, tu peux changer les règles maison de la partie."),
}
cat = json.load(open(KAT)); s = cat['strings']
n = 0
for k, t in U.items():
    loc = s.setdefault(k, {}).setdefault('localizations', {})
    if 'en' in loc and 'fr' in loc: continue
    for sp, v in zip(('en', 'es', 'fr'), t): loc[sp] = {"stringUnit": {"state": "translated", "value": v}}
    n += 1
orig = open(KAT).read()
open(KAT, 'w').write(json.dumps(cat, ensure_ascii=False, indent=2, separators=(',', ': ')) + ('\n' if orig.endswith('\n') else ''))
print('eingetragen:', n)
