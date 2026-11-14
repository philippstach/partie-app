#!/usr/bin/env python3
"""c019_strings.py (C-019): repariert die durch „Schlüssel=Übersetzung“-Trennung am „=“ zerschnittenen Einträge von Yacht und 10k
und trägt den fehlenden Schlüssel „Wurf %lld von 3“ nach. Überschreibt nur die zerschnittenen Einträge. Aufruf aus Partie/Haupt (Repo-Wurzel)."""
import json
KAT = 'App/Ressourcen/Localizable.xcstrings'
KAPUTT = ['Ausgewählt: %@ ', 'Jeder weitere gleiche Würfel verdoppelt den Drilling: vier Vieren ', 'Vier gleiche Würfel ',
          'Niete ', 'Drei Paare ', 'Es zählt der Drilling, weitere Würfel nur als Einsen oder Fünfen (vier Vieren ']
NEU = {
"Ausgewählt: %@ = %@ · Zug %@": ("Selected: %@ = %@ · Turn %@", "Elegido: %@ = %@ · Turno %@", "Choisi : %@ = %@ · Tour %@"),
"Jeder weitere gleiche Würfel verdoppelt den Drilling: vier Vieren = 800, fünf Vieren = 1.600.":
 ("Each further matching die doubles the triple: four fours = 800, five fours = 1,600.", "Cada dado igual adicional duplica el trío: cuatro cuatros = 800, cinco cuatros = 1.600.", "Chaque dé identique en plus double le brelan : quatre quatre = 800, cinq quatre = 1 600."),
"Vier gleiche Würfel = 1.000, fünf = 2.000, sechs = 3.000.":
 ("Four of a kind = 1,000, five = 2,000, six = 3,000.", "Cuatro iguales = 1.000, cinco = 2.000, seis = 3.000.", "Quatre identiques = 1 000, cinq = 2 000, six = 3 000."),
"Niete = −%@": ("Bust = −%@", "Nula = −%@", "Raté = −%@"),
"Drei Paare = %@": ("Three pairs = %@", "Tres pares = %@", "Trois paires = %@"),
"Es zählt der Drilling, weitere Würfel nur als Einsen oder Fünfen (vier Vieren = 400).":
 ("The triple counts, further dice only as ones or fives (four fours = 400).", "Cuenta el trío; los demás dados solo como unos o cincos (cuatro cuatros = 400).", "Seul le brelan compte, les autres dés seulement comme as ou cinq (quatre quatre = 400)."),
"Wurf %lld von 3": ("Roll %lld of 3", "Tirada %lld de 3", "Lancer %lld sur 3"),
}
cat = json.load(open(KAT)); s = cat['strings']
for k in KAPUTT: s.pop(k, None)
n = 0
for k, t in NEU.items():
    loc = s.setdefault(k, {}).setdefault('localizations', {})
    if all(x in loc for x in ('en', 'es', 'fr')): continue
    for sp, v in zip(('en', 'es', 'fr'), t): loc[sp] = {"stringUnit": {"state": "translated", "value": v}}
    n += 1
orig = open(KAT).read()
open(KAT, 'w').write(json.dumps(cat, ensure_ascii=False, indent=2, separators=(',', ': ')) + ('\n' if orig.endswith('\n') else ''))
print('eingetragen:', n)
