#!/usr/bin/env python3
"""uebersetzungen_w11.py: Texte der Eingabe echter Münzen (Königsweg) und Bohnen (Patolli). Überschreibt nie vorhandene Übersetzungen."""
import json
KAT = 'App/Ressourcen/Localizable.xcstrings'
U = {
"Wie viele Münzen zeigen den Punkt?": ("How many coins show the dot?", "¿Cuántas monedas muestran el punto?", "Combien de pièces montrent le point ?"),
"Wie liegen deine Bohnen? Tippe die markierten an.": ("How did your beans land? Tap the marked ones.", "¿Cómo cayeron tus habas? Toca las marcadas.", "Comment tes haricots sont-ils tombés ? Touche les marqués."),
"Bohne %lld von 5": ("Bean %lld of 5", "Haba %lld de 5", "Haricot %lld sur 5"),
"Münzen": ("Coins", "Monedas", "Pièces"),
"Bohnen": ("Beans", "Habas", "Haricots"),
"Die App wirft die Münzen für dich.": ("The app tosses the coins for you.", "La app lanza las monedas por ti.", "L’app lance les pièces pour toi."),
"Die App wirft die Bohnen für dich.": ("The app tosses the beans for you.", "La app lanza las habas por ti.", "L’app lance les haricots pour toi."),
"Du wirfst am Tisch und tippst das Ergebnis ein.": ("You toss at the table and type in the result.", "Lanzas en la mesa y escribes el resultado.", "Tu lances à table et tu saisis le résultat."),
"nicht markiert": ("not marked", "sin marcar", "non marqué"),
}
cat = json.load(open(KAT)); s = cat['strings']; n = 0
for k, t in U.items():
    loc = s.setdefault(k, {}).setdefault('localizations', {})
    if 'en' in loc: continue
    for sp, v in zip(('en', 'es', 'fr'), t):
        loc[sp] = {"stringUnit": {"state": "translated", "value": v}}
    n += 1
orig = open(KAT).read()
open(KAT, 'w').write(json.dumps(cat, ensure_ascii=False, indent=2, separators=(',', ': ')) + ('\n' if orig.endswith('\n') else ''))
print('eingetragen:', n)
