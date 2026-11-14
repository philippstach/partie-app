#!/usr/bin/env python3
"""uebersetzungen_spieler_b6.py: Texte für Foto-Zuschnitt und die Spielerseite „Ich“ / „Andere Spieler“ (de/en/es/fr).
Überschreibt nie Vorhandenes. Aufruf aus dem Projektordner."""
import json
KAT = 'App/Ressourcen/Localizable.xcstrings'
U = {
"Ich": ("Me", "Yo", "Moi"),
"Andere Spieler": ("Other players", "Otros jugadores", "Autres joueurs"),
"Mich anlegen": ("Add myself", "Añadirme", "Me ajouter"),
"Lege dich selbst an, am besten mit Foto – du stehst dann in jedem Spiel bereit.": ("Add yourself, ideally with a photo – you will then be ready in every game.", "Añádete, mejor con foto: así estarás listo en cada juego.", "Ajoute-toi, de préférence avec une photo – tu seras alors prêt dans chaque jeu."),
"Noch niemand. Lege Mitspielerinnen und Mitspieler von Hand an, sie stehen dann in jedem Spiel bereit.": ("Nobody yet. Add the people you play with by hand; they will then be ready in every game.", "Todavía nadie. Añade a tus compañeros de juego a mano; estarán listos en cada juego.", "Personne pour l’instant. Ajoute à la main les personnes avec qui tu joues ; elles seront prêtes dans chaque jeu."),
"Zeichen": ("Symbol", "Símbolo", "Symbole"),
"Rahmenfarbe": ("Frame color", "Color del marco", "Couleur du cadre"),
"Mit Foto wird kein Zeichen angezeigt. Entferne das Foto, um ein Zeichen zu wählen.": ("A symbol is not shown while a photo is set. Remove the photo to choose a symbol.", "Con foto no se muestra ningún símbolo. Quita la foto para elegir un símbolo.", "Avec une photo, aucun symbole n’est affiché. Retire la photo pour choisir un symbole."),
"Ausschnitt ändern": ("Adjust crop", "Cambiar recorte", "Modifier le cadrage"),
"Foto anpassen": ("Adjust photo", "Ajustar foto", "Ajuster la photo"),
"Foto-Ausschnitt": ("Photo crop", "Recorte de la foto", "Cadrage de la photo"),
"Mit dem Regler vergrößern, mit Ziehen verschieben": ("Zoom with the slider, move by dragging", "Amplía con el control deslizante, mueve arrastrando", "Zoome avec le curseur, déplace en faisant glisser"),
"Zum Anpassen ziehen und zoomen.": ("Drag and zoom to adjust.", "Arrastra y haz zoom para ajustar.", "Fais glisser et zoome pour ajuster."),
"Zoom": ("Zoom", "Zoom", "Zoom"),
"Übernehmen": ("Apply", "Aplicar", "Appliquer"),
"Abbrechen": ("Cancel", "Cancelar", "Annuler"),
"Dieses Bild kann nicht verwendet werden.": ("This image cannot be used.", "Esta imagen no se puede usar.", "Cette image ne peut pas être utilisée."),
}
cat = json.load(open(KAT)); s = cat['strings']
n = 0
for k, t in U.items():
    loc = s.setdefault(k, {}).setdefault('localizations', {})
    for sp, v in zip(('de', 'en', 'es', 'fr'), (k,) + t):
        if sp not in loc:
            loc[sp] = {"stringUnit": {"state": "translated", "value": v}}; n += 1
orig = open(KAT).read()
open(KAT, 'w').write(json.dumps(cat, ensure_ascii=False, indent=2, separators=(',', ': ')) + ('\n' if orig.endswith('\n') else ''))
print('eingetragen:', n)
