#!/usr/bin/env python3
"""design_runde5_eb_raetsel_strings.py: Runde 5, Blatt 22, Paket EB-3 (Ergebnisseite Rätsel und Brett), de/en/es/fr.
Trägt nur ein, was es noch nicht gibt (en und fr vorhanden = nichts zu tun). Aufruf aus dem Projektordner."""
import json
KAT = 'App/Ressourcen/Localizable.xcstrings'
U = {
"Gelöst in %@.": ("Solved in %@.", "Resuelto en %@.", "Résolu en %@."),
"Stufe %lld geschafft.": ("Level %lld completed.", "Nivel %lld superado.", "Niveau %lld réussi."),
"Team %@ gewinnt": ("Team %@ wins", "El equipo %@ gana", "L’équipe %@ gagne"),
"Zeit": ("Time", "Tiempo", "Temps"),
"Stufe": ("Level", "Nivel", "Niveau"),
"Züge": ("Moves", "Movimientos", "Coups"),
"Punkte": ("Points", "Puntos", "Points"),
"Runden": ("Rounds", "Rondas", "Manches"),
"Fehler": ("Mistakes", "Errores", "Erreurs"),
"Tipps": ("Hints", "Pistas", "Indices"),
"Hinweise": ("Clues", "Ayudas", "Aides"),
"Größe": ("Size", "Tamaño", "Taille"),
"Bestwert": ("Best score", "Mejor marca", "Meilleur score"),
"%lld von %lld": ("%lld of %lld", "%lld de %lld", "%lld sur %lld"),
"Spielzüge": ("Turns", "Jugadas", "Tours joués"),
"Geschlagen": ("Captured", "Capturadas", "Prises"),
# Beschreibungen der Bilder für VoiceOver
"Gelöstes Gitter": ("Solved grid", "Cuadrícula resuelta", "Grille résolue"),
"Steine in der richtigen Reihenfolge": ("Tiles in the right order", "Fichas en el orden correcto", "Tuiles dans le bon ordre"),
"Das letzte Labyrinth": ("The last maze", "El último laberinto", "Le dernier labyrinthe"),
"Das Wort und die Figur am Ende": ("The word and the figure at the end", "La palabra y la figura al final", "Le mot et la figure à la fin"),
"Brett am Ende": ("Board at the end", "Tablero al final", "Plateau à la fin"),
}
cat = json.load(open(KAT)); s = cat['strings']; n = 0
for k, t in U.items():
    loc = s.setdefault(k, {}).setdefault('localizations', {})
    if all(sp in loc for sp in ('en', 'es', 'fr')): continue
    loc.setdefault('de', {"stringUnit": {"state": "translated", "value": k}})
    for sp, v in zip(('en', 'es', 'fr'), t): loc.setdefault(sp, {"stringUnit": {"state": "translated", "value": v}})
    n += 1
orig = open(KAT).read()
open(KAT, 'w').write(json.dumps(cat, ensure_ascii=False, indent=2, separators=(',', ': ')) + ('\n' if orig.endswith('\n') else ''))
print('eingetragen:', n)
