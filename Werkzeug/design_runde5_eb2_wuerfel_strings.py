#!/usr/bin/env python3
"""design_runde5_eb2_wuerfel_strings.py: Runde 5, Paket EB2-2 (Ergebnisseite Schritt 2, Würfel), de/en/es/fr. Überschreibt nichts. Aufruf aus dem Projektordner."""
import json
KAT = 'App/Ressourcen/Localizable.xcstrings'
U = {
"Schock aus": ("Schock out", "Schock fuera", "Schock sorti"),
"Mäxchen geworfen": ("Mäxchen rolled", "Mäxchen sacados", "Mäxchen obtenus"),
"Treffer": ("Hits", "Aciertos", "Réussites"),
"Zielzahlen und Treffer je Spieler": ("Targets and hits per player", "Objetivos y aciertos por jugador", "Cibles et réussites par joueur"),
"%@ gewinnt mit %lld Punkten.": ("%@ wins with %lld points.", "%@ gana con %lld puntos.", "%@ gagne avec %lld points."),
"Yacht geworfen": ("Yachts rolled", "Yachts conseguidos", "Yachts réussis"),
"%@ gewinnt %lld von %lld Runden.": ("%@ wins %lld of %lld rounds.", "%@ gana %lld de %lld rondas.", "%@ gagne %lld manches sur %lld."),
"Bester Wurf": ("Best roll", "Mejor tirada", "Meilleur lancer"),
"Alle sieben Steine draußen.": ("All seven pieces are off the board.", "Las siete fichas están fuera.", "Les sept pions sont sortis."),
"Geschlagen": ("Captured", "Capturadas", "Prises"),
"Runden": ("Rounds", "Rondas", "Manches"),
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
