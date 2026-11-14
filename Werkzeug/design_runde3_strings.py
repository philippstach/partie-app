#!/usr/bin/env python3
"""design_runde3_strings.py: de/en/es/fr für die neuen Texte der Design-Runde 3 (Startseite und Spielseite in Tinte). Idempotent, überschreibt nichts. Aufruf aus dem Projektordner."""
import json
KAT = 'App/Ressourcen/Localizable.xcstrings'
U = {
"Weiterspielen": ("Continue playing", "Seguir jugando", "Continuer à jouer"),
"Neue Runde": ("New round", "Nueva ronda", "Nouvelle partie"),
"Spielarten": ("Game types", "Tipos de juego", "Types de jeux"),
"Alle ansehen": ("See all", "Ver todos", "Tout voir"),
"aufgeklappt": ("expanded", "desplegado", "déplié"),
"zugeklappt": ("collapsed", "plegado", "replié"),
"Regeln ansehen": ("View rules", "Ver las reglas", "Voir les règles"),
"Letzte Runde wieder": ("Last round again", "Otra vez la última ronda", "Rejouer la dernière partie"),
"Spielen": ("Play", "Jugar", "Jouer"),
"Fortsetzen": ("Continue", "Continuar", "Continuer"),
"Wer spielt?": ("Who is playing?", "¿Quién juega?", "Qui joue ?"),
"Weiterspielen · Tagesaufgabe": ("Continue playing · Daily challenge", "Seguir jugando · Reto del día", "Continuer à jouer · Défi du jour"),
"Tagesaufgabe · weiter": ("Daily challenge · continue", "Reto del día · continuar", "Défi du jour · continuer"),
"%@. %lld Spiele.": ("%1$@. %2$lld games.", "%1$@. %2$lld juegos.", "%1$@. %2$lld jeux."),
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
