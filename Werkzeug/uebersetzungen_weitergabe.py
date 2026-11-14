#!/usr/bin/env python3
"""uebersetzungen_weitergabe.py: Texte der Weitergabe-Einstellung und der Namensprüfung (de/en/es/fr).
Überschreibt nie vorhandene Übersetzungen. Aufruf aus dem Projektordner."""
import json
KAT = 'App/Ressourcen/Localizable.xcstrings'
U = {
"Weitergabe-Meldung automatisch ausblenden": ("Hide the pass-the-device message automatically", "Ocultar automáticamente el aviso de pasar el dispositivo", "Masquer automatiquement le message de passage de l’appareil"),
"Gilt nur für Spiele ohne verdeckte Karten. Bei geheimen Karten bleibt immer „Bereit“.": ("Only applies to games without hidden cards. With secret cards, “Ready” always stays.", "Solo para juegos sin cartas ocultas. Con cartas secretas siempre se mantiene «Listo».", "Uniquement pour les jeux sans cartes cachées. Avec des cartes secrètes, « Prêt » reste toujours."),
"Jeder Mensch braucht einen Namen – oder wähle „Computer“.": ("Every human needs a name – or choose “Computer”.", "Cada persona necesita un nombre, o elige «Ordenador».", "Chaque humain a besoin d’un nom – ou choisis « Ordinateur »."),
}
cat = json.load(open(KAT)); s = cat['strings']; n = 0
for k, t in U.items():
    loc = s.setdefault(k, {}).setdefault('localizations', {})
    if 'en' in loc: continue
    loc['de'] = {"stringUnit": {"state": "translated", "value": k}}
    for sp, v in zip(('en', 'es', 'fr'), t):
        loc[sp] = {"stringUnit": {"state": "translated", "value": v}}
    n += 1
text = json.dumps(cat, ensure_ascii=False, indent=2, separators=(',', ': '))
orig = open(KAT).read()
open(KAT, 'w').write(text + ('\n' if orig.endswith('\n') else ''))
print('eingetragen:', n)
