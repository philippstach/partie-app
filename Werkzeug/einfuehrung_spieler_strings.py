#!/usr/bin/env python3
"""einfuehrung_spieler_strings.py: de/en/es/fr für die Einführungsseite „Wer spielt?“ (fester lokaler Spieler). Überschreibt nichts. Aufruf aus dem Projektordner."""
import json
KAT = 'App/Ressourcen/Localizable.xcstrings'
U = {
"Wer spielt?": ("Who’s playing?", "¿Quién juega?", "Qui joue ?"),
"Lege dich einmal an, mit Name und auf Wunsch Foto. Du stehst dann in jedem Spiel schon bereit. Es gibt kein Konto, alles bleibt auf deinem Gerät.": (
 "Set yourself up once with a name and, if you like, a photo. You will then be ready in every game. There is no account; everything stays on your device.",
 "Créate una vez con tu nombre y, si quieres, una foto. Así estarás listo en todos los juegos. No hay cuenta; todo se queda en tu dispositivo.",
 "Crée-toi une fois, avec ton nom et, si tu veux, une photo. Tu seras alors prêt dans chaque jeu. Il n’y a pas de compte, tout reste sur ton appareil."),
"Du kannst auch später unter „Spieler“ anlegen.": ("You can also do this later under “Players”.", "También puedes hacerlo más tarde en «Jugadores».", "Tu peux aussi le faire plus tard sous « Joueurs »."),
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
