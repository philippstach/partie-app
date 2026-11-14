#!/usr/bin/env python3
"""design_runde5_eb_karten_strings.py: Blatt 22, Paket EB-1 (Ergebnisseite Karten), de/en/es/fr. Trägt einen Text nur ein, wenn es ihn noch nicht
in en und fr gibt. Aufruf aus dem Projektordner. Übersetzungen sind Vorschläge, nicht von Muttersprachlern geprüft."""
import json
KAT = 'App/Ressourcen/Localizable.xcstrings'
U = {
"Zeit": ("Time", "Tiempo", "Temps"),
"Züge": ("Moves", "Movimientos", "Coups"),
"Punkte": ("Points", "Puntos", "Points"),
"Runden": ("Rounds", "Rondas", "Manches"),
"Gelegte Karten": ("Cards played", "Cartas jugadas", "Cartes jouées"),
"Letzte Karte": ("Last card", "Última carta", "Dernière carte"),
"%@ hatte noch": ("%@ still held", "%@ aún tenía", "%@ avait encore"),
"+%lld weitere": ("+%lld more", "+%lld más", "+%lld de plus"),
"Bank": ("Bank", "Banca", "Banque"),
# Beschreibungen der Bilder für VoiceOver
"Ablagestapel am Ende": ("Foundation piles at the end", "Pilas de salida al final", "Piles de fondation à la fin"),
"Letzte Karte und restliche Karten": ("Last card and remaining cards", "Última carta y cartas restantes", "Dernière carte et cartes restantes"),
"Blatt des Siegers": ("Winner's hand", "Mano del ganador", "Main du gagnant"),
"Die vier Reihen am Ende": ("The four rows at the end", "Las cuatro filas al final", "Les quatre rangées à la fin"),
"Auslagen auf dem Tisch": ("Melds on the table", "Combinaciones en la mesa", "Combinaisons sur la table"),
"Restliche Karten der anderen": ("Remaining cards of the others", "Cartas restantes de los demás", "Cartes restantes des autres"),
"Die letzte Hand": ("The last hand", "La última mano", "La dernière main"),
"Auf dem Tisch": ("On the table", "En la mesa", "Sur la table"),
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
