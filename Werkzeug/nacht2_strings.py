#!/usr/bin/env python3
"""nacht2_strings.py: Plural-Einträge für Nachtchat 2 (Mogeln, Viererreihe). Überschreibt vorhandene Pluralvarianten nicht.
Aufruf aus dem Projektordner."""
import json
KAT = 'App/Ressourcen/Localizable.xcstrings'
P = {
"%lld Steine": {"de": ("%lld Stein", "%lld Steine"), "en": ("%lld disc", "%lld discs"), "es": ("%lld ficha", "%lld fichas"), "fr": ("%lld jeton", "%lld jetons")},
"%lld Karte(n) als %@ ablegen": {"de": ("%lld Karte als %@ ablegen", "%lld Karten als %@ ablegen"),
    "en": ("Play %lld card as %@", "Play %lld cards as %@"), "es": ("Jugar %lld carta como %@", "Jugar %lld cartas como %@"),
    "fr": ("Jouer %lld carte comme %@", "Jouer %lld cartes comme %@")},
}
cat = json.load(open(KAT)); s = cat['strings']; n = 0
U = {
"Bitte zuerst alle Namen eintragen.": ("Please enter all names first.", "Primero escribe todos los nombres.", "Saisis d’abord tous les noms."),
"Jeder Mensch braucht einen Namen.": ("Everyone needs a name.", "Cada persona necesita un nombre.", "Chaque personne doit avoir un nom."),
}
for k, t in U.items():
    loc = s.setdefault(k, {}).setdefault('localizations', {})
    if 'en' in loc: continue
    loc.setdefault('de', {"stringUnit": {"state": "translated", "value": k}})
    for l, v in zip(('en', 'es', 'fr'), t): loc[l] = {"stringUnit": {"state": "translated", "value": v}}
    n += 1
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
