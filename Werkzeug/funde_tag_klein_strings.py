#!/usr/bin/env python3
"""funde_tag_klein_strings.py: kleine Text-Korrekturen der Tagesfunde (Zweig funde-tag-klein). Aufruf aus dem Projektordner."""
import json
KAT = 'App/Ressourcen/Localizable.xcstrings'
cat = json.load(open(KAT)); s = cat['strings']
def setze(k, en, es, fr):
    loc = s.setdefault(k, {}).setdefault('localizations', {})
    loc.setdefault('de', {"stringUnit": {"state": "translated", "value": k}})
    for sp, v in zip(('en', 'es', 'fr'), (en, es, fr)): loc[sp] = {"stringUnit": {"state": "translated", "value": v}}
# Einzahl bei „1 Spieler“ (en/es/fr; Fund 113/116/158)
loc = s["%lld Spieler"]['localizations']
for sp, (one, other) in {"en": ("%lld player", "%lld players"), "es": ("%lld jugador", "%lld jugadores"), "fr": ("%lld joueur", "%lld joueurs")}.items():
    loc[sp] = {"variations": {"plural": {"one": {"stringUnit": {"state": "translated", "value": one}}, "other": {"stringUnit": {"state": "translated", "value": other}}}}}
setze("Spielarten", "Game types", "Tipos de juego", "Types de jeux")           # Fund 115/158: nicht „Variantes“/„Game Options“
setze("Gleich hier", "Quick settings", "A mano", "À portée de main")            # Fund 161
alt = "Nur Spiele mit Haken sind im Kinder-Modus zu sehen. Suche, Zufall und „Was spielen wir?“ halten sich daran."
neu = "Nur Spiele, deren Schalter an ist, sind im Kinder-Modus zu sehen. Suche, Zufall und „Was spielen wir?“ halten sich daran."
s.pop(alt, None)
setze(neu, "Only games whose switch is on are visible in kids mode. Search, random and “What shall we play?” follow this.",
      "Solo los juegos con el interruptor activado se ven en el modo infantil. La búsqueda, el azar y «¿A qué jugamos?» lo respetan.",
      "Seuls les jeux dont l’interrupteur est activé sont visibles en mode enfants. La recherche, le hasard et « À quoi on joue ? » en tiennent compte.")
orig = open(KAT).read()
open(KAT, 'w').write(json.dumps(cat, ensure_ascii=False, indent=2, separators=(',', ': ')) + ('\n' if orig.endswith('\n') else ''))
