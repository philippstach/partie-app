#!/usr/bin/env python3
"""funde_strings.py: de/en/es/fr für die Nachttest-Funde (Branch funde-nachttest). Überschreibt nie vorhandene Übersetzungen.
Aufruf aus dem Projektordner."""
import json
KAT = 'App/Ressourcen/Localizable.xcstrings'
U = {
"Duell wirklich abbrechen?": ("Really cancel the duel?", "¿Cancelar el duelo?", "Vraiment annuler le duel ?"),
"Spieleabend wirklich abbrechen?": ("Really cancel the game night?", "¿Cancelar la noche de juegos?", "Vraiment annuler la soirée jeux ?"),
"Über 21": ("Over 21", "Más de 21", "Plus de 21"),
"Summe %lld, über 21": ("Total %lld, over 21", "Suma %lld, más de 21", "Total %lld, plus de 21"),
"Weiterspielen": ("Keep playing", "Seguir jugando", "Continuer à jouer"),
"Die bisherige Wertung geht verloren.": ("The scores so far will be lost.", "Se perderá la puntuación actual.", "Les scores actuels seront perdus."),
}
cat = json.load(open(KAT)); s = cat['strings']
n = 0
for k, t in U.items():
    loc = s.setdefault(k, {}).setdefault('localizations', {})
    if 'en' in loc and 'fr' in loc: continue
    loc.setdefault('de', {"stringUnit": {"state": "translated", "value": k}})
    for sp, v in zip(('en', 'es', 'fr'), t): loc[sp] = {"stringUnit": {"state": "translated", "value": v}}
    n += 1
# Plural-Einträge: Schlüssel -> {sprache: (eins, andere)}
P = {
"Hand: %lld Punkte": {"de": ("Hand: %lld Punkt", "Hand: %lld Punkte"), "en": ("Hand: %lld point", "Hand: %lld points"),
                      "es": ("Mano: %lld punto", "Mano: %lld puntos"), "fr": ("Main : %lld point", "Main : %lld points")},
}
for k, sp in P.items():
    loc = s.setdefault(k, {}).setdefault('localizations', {})
    for lang, (eins, andere) in sp.items():
        if 'variations' in loc.get(lang, {}): continue
        loc[lang] = {"variations": {"plural": {
            "one": {"stringUnit": {"state": "translated", "value": eins}},
            "other": {"stringUnit": {"state": "translated", "value": andere}}}}}
        n += 1
orig = open(KAT).read()
open(KAT, 'w').write(json.dumps(cat, ensure_ascii=False, indent=2, separators=(',', ': ')) + ('\n' if orig.endswith('\n') else ''))
print('eingetragen:', n)
