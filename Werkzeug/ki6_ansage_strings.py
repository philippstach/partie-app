#!/usr/bin/env python3
"""ki6_ansage_strings.py: KI-6 (Blatt 13, Variante ansagen), de/en/es/fr. Überschreibt nichts. Aufruf aus dem Projektordner."""
import json
KAT = 'App/Ressourcen/Localizable.xcstrings'
U = {
"Sag, wie ihr spielen wollt": ("Say how you want to play", "Di cómo queréis jugar", "Dites comment vous voulez jouer"),
"Ansage senden": ("Send", "Enviar", "Envoyer"),
"Das stelle ich ein": ("Here is what I will set", "Esto es lo que ajustaré", "Voici ce que je règle"),
"Das ändert sich": ("What changes", "Qué cambia", "Ce qui change"),
"Das kenne ich nicht": ("I don't know this", "Esto no lo conozco", "Je ne connais pas ça"),
"„%@“ gibt es in %@ hier nicht. Alles andere bleibt, wie es eingestellt ist.": ("“%@” does not exist in %@ here. Everything else stays as it is set.", "«%@» no existe aquí en %@. Todo lo demás se queda como está ajustado.", "« %@ » n'existe pas ici dans %@. Tout le reste reste comme réglé."),
"„%@“ gibt es hier nicht. Sag es zum Beispiel so: „Mit sieben Karten, das Ass setzt aus.“": ("“%@” does not exist here. Try saying it like this: “With seven cards, the ace skips.”", "«%@» no existe aquí. Prueba así: «Con siete cartas, el as salta».", "« %@ » n'existe pas ici. Dites par exemple : « Avec sept cartes, l'as fait passer »."),
"Das habe ich nicht verstanden. Sag es zum Beispiel so: „Mit sieben Karten, das Ass setzt aus.“": ("I didn't understand that. Try saying it like this: “With seven cards, the ace skips.”", "No lo he entendido. Prueba así: «Con siete cartas, el as salta».", "Je n'ai pas compris. Dites par exemple : « Avec sept cartes, l'as fait passer »."),
"Das ist schon so eingestellt.": ("That is already set.", "Eso ya está así ajustado.", "C'est déjà réglé ainsi."),
"Das hat gerade nicht geklappt. Versuch es noch einmal.": ("That didn't work just now. Please try again.", "Esto no ha funcionado. Inténtalo de nuevo.", "Ça n'a pas marché. Réessayez."),
"Apple Intelligence lädt noch. Dann kannst du die Regeln ansagen.": ("Apple Intelligence is still loading. Then you can say the rules.", "Apple Intelligence aún se está cargando. Después podrás decir las reglas.", "Apple Intelligence est encore en cours de chargement. Vous pourrez ensuite dire les règles."),
"Schalte Apple Intelligence in den Einstellungen ein, dann kannst du die Regeln ansagen.": ("Turn on Apple Intelligence in Settings, then you can say the rules.", "Activa Apple Intelligence en Ajustes y podrás decir las reglas.", "Activez Apple Intelligence dans les Réglages pour pouvoir dire les règles."),
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
