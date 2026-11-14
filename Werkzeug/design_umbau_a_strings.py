#!/usr/bin/env python3
"""design_umbau_a_strings.py: de/en/es/fr für die neuen Texte des Design-Umbaus A (Startseite, Einstellungen, Profil). Idempotent. Aufruf aus dem Projektordner."""
import json
KAT = 'App/Ressourcen/Localizable.xcstrings'
U = {
"Noch keine Favoriten. Wähle die Spiele, die du oft spielst; sie liegen dann hier ganz vorn.": ("No favorites yet. Pick the games you play often; they will sit right here at the front.", "Aún no hay favoritos. Elige los juegos que juegas a menudo; estarán aquí al principio.", "Pas encore de favoris. Choisis les jeux auxquels tu joues souvent ; ils seront ici, tout devant."),
"Favoriten wählen": ("Choose favorites", "Elegir favoritos", "Choisir des favoris"),
"Gleich hier": ("Right here", "Aquí mismo", "Ici directement"),
"Vorschau": ("Preview", "Vista previa", "Aperçu"),
"Dein Profil": ("Your profile", "Tu perfil", "Ton profil"),
"Mitspieler": ("Other players", "Otros jugadores", "Autres joueurs"),
"Mein Profil anlegen": ("Create my profile", "Crear mi perfil", "Créer mon profil"),
"Als mein Profil festlegen": ("Set as my profile", "Establecer como mi perfil", "Définir comme mon profil"),
"So erscheinst du in jedem Spiel: mit Name, Foto und Farbe.": ("This is how you appear in every game: with name, photo and color.", "Así apareces en cada juego: con nombre, foto y color.", "Voilà comment tu apparais dans chaque jeu : avec nom, photo et couleur."),
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
