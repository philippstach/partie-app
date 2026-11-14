#!/usr/bin/env python3
"""leiter_strings.py: en/es/fr für die Texte von D4 (Schwierigkeitsleiter). Überschreibt nie vorhandene Übersetzungen.
Aufruf aus dem Projektordner."""
import json
KAT = 'App/Ressourcen/Localizable.xcstrings'
U = {
"Schwierigkeitsleiter": ("Difficulty ladder", "Escalera de dificultad", "Échelle de difficulté"),
"Alle Stufen offen": ("All levels unlocked", "Todos los niveles abiertos", "Tous les niveaux ouverts"),
"Dann ist keine Stufe gesperrt. Im Kinder-Modus sind ohnehin alle offen.": ("Then no level is locked. In Kids mode all levels are open anyway.", "Entonces ningún nivel está bloqueado. En el modo infantil todos están abiertos.", "Alors aucun niveau n’est verrouillé. En mode enfant, tous sont ouverts."),
"Jede Stufe öffnet sich, wenn du %lld Mal ohne Tipp auf der Stufe davor gewinnst. Tagesrätsel zählen nicht.": ("Each level opens when you win %lld times without a hint on the level before. Daily puzzles don’t count.", "Cada nivel se abre cuando ganas %lld veces sin pista en el nivel anterior. Los retos diarios no cuentan.", "Chaque niveau s’ouvre quand tu gagnes %lld fois sans indice au niveau précédent. Les défis du jour ne comptent pas."),
"offen, %lld von %lld Siegen": ("open, %lld of %lld wins", "abierto, %lld de %lld victorias", "ouvert, %lld victoires sur %lld"),
"gesperrt": ("locked", "bloqueado", "verrouillé"),
"Gesperrt. Gewinne %lld Mal ohne Tipp auf der Stufe davor.": ("Locked. Win %lld times without a hint on the level before.", "Bloqueado. Gana %lld veces sin pista en el nivel anterior.", "Verrouillé. Gagne %lld fois sans indice au niveau précédent."),
"Noch %lld Siege ohne Tipp für die nächste Stufe": ("%lld more wins without a hint for the next level", "%lld victorias más sin pista para el siguiente nivel", "Encore %lld victoires sans indice pour le niveau suivant"),
"Gesperrt. Gewinne %lld Mal ohne Hinweis auf der Stufe davor.": ("Locked. Win %lld times without a hint on the level before.", "Bloqueado. Gana %lld veces sin pista en el nivel anterior.", "Verrouillé. Gagne %lld fois sans indice au niveau précédent."),
"Mit Starthilfe": ("With head start", "Con ayuda inicial", "Avec aide au départ"),
}
cat = json.load(open(KAT)); s = cat['strings']
n = 0
for k, t in U.items():
    loc = s.setdefault(k, {}).setdefault('localizations', {})
    if 'en' in loc and 'fr' in loc: continue
    for sp, v in zip(('en', 'es', 'fr'), t): loc[sp] = {"stringUnit": {"state": "translated", "value": v}}
    n += 1
orig = open(KAT).read()
open(KAT, 'w').write(json.dumps(cat, ensure_ascii=False, indent=2, separators=(',', ': ')) + ('\n' if orig.endswith('\n') else ''))
print('eingetragen:', n)
