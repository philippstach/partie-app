#!/usr/bin/env python3
"""uebersetzungen_brettspiele.py: en/es/fr für die neuen Brettspiel-Texte (Remis-Gründe, Zeitlimit, Schachmatt …). Überschreibt nichts Vorhandenes."""
import json
KAT = 'App/Ressourcen/Localizable.xcstrings'
U = {
"Patt": ("Stalemate", "Tablas por ahogado", "Pat"),
"Zu wenig Material": ("Insufficient material", "Material insuficiente", "Matériel insuffisant"),
"Dreifache Stellungswiederholung": ("Threefold repetition", "Triple repetición de posición", "Triple répétition de position"),
"50-Züge-Regel": ("Fifty-move rule", "Regla de los cincuenta movimientos", "Règle des cinquante coups"),
"Remis – 40 Züge ohne Schlag oder Männerzug": ("Draw – 40 moves without a capture or a man move", "Tablas: 40 jugadas sin captura ni movimiento de peón", "Nulle – 40 coups sans prise ni coup de pion"),
"Remis – 60 Züge ohne Mühle": ("Draw – 60 moves without a mill", "Tablas: 60 jugadas sin molino", "Nulle – 60 coups sans moulin"),
"Zug %lld von %lld – dann zählt der Fortschritt": ("Move %lld of %lld – then progress decides", "Jugada %lld de %lld: después decide el avance", "Coup %lld sur %lld – ensuite c’est la progression qui compte"),
"Zeit um – %@ ist weiter": ("Time’s up – %@ is further ahead", "Se acabó el tiempo: %@ va por delante", "Temps écoulé – %@ est plus avancé"),
"Zeit um – Gleichstand": ("Time’s up – a tie", "Se acabó el tiempo: empate", "Temps écoulé – égalité"),
"Schachmatt – %@ gewinnt": ("Checkmate – %@ wins", "Jaque mate: gana %@", "Échec et mat – %@ gagne"),
}
cat = json.load(open(KAT)); s = cat['strings']; n = 0
for k, t in U.items():
    loc = s.setdefault(k, {}).setdefault('localizations', {})
    if 'en' in loc: continue
    for sp, v in zip(('en', 'es', 'fr'), t): loc[sp] = {"stringUnit": {"state": "translated", "value": v}}
    n += 1
text = json.dumps(cat, ensure_ascii=False, indent=2, separators=(',', ': '))
orig = open(KAT).read()
open(KAT, 'w').write(text + ('\n' if orig.endswith('\n') else ''))
print('eingetragen:', n)
