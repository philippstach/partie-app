#!/usr/bin/env python3
"""design_runde5_eb2_karten_strings.py: Blatt 22, Paket EB2-1 (Ergebnisseite Karten, Zusatzwerte), de/en/es/fr. Trägt einen Text nur ein,
wenn es ihn noch nicht in en und fr gibt. Aufruf aus dem Projektordner. Übersetzungen sind Vorschläge, nicht von Muttersprachlern geprüft."""
import json
KAT = 'App/Ressourcen/Localizable.xcstrings'
U = {
"Mit %@ ausgemacht.": ("Went out with %@.", "Terminó con %@.", "Terminé avec %@."),
"Bestes Blatt": ("Best hand", "Mejor mano", "Meilleure main"),
"%@ hat ausgelegt": ("Laid down by %@", "Combinaciones de %@", "Combinaisons de %@"),
"Richtig gezweifelt": ("Correct challenges", "Dudas acertadas", "Doutes justifiés"),
"Falsch gezweifelt": ("Wrong challenges", "Dudas falladas", "Doutes à tort"),
"%@ hat die meisten Chips.": ("%@ has the most chips.", "%@ tiene más fichas.", "%@ a le plus de jetons."),
"Hände": ("Hands", "Manos", "Mains"),
"Größter Gewinn": ("Biggest win", "Mayor ganancia", "Plus gros gain"),
"Durchmärsche": ("Moon shots", "Capotes", "Chelems"),
"Punkte je Runde": ("Points per round", "Puntos por ronda", "Points par manche"),
"%@ gewinnt mit %lld Punkten.": ("%@ wins with %lld points.", "%@ gana con %lld puntos.", "%@ gagne avec %lld points."),
"Punkte je Runde als Tabelle": ("Points per round as a table", "Puntos por ronda en una tabla", "Points par manche sous forme de tableau"),
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
