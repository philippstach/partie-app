# Würfel-Kameraseite (Hinweise, Ansage): trägt die neuen Strings in App/Ressourcen/Localizable.xcstrings ein. Bestehende Schlüssel bleiben unberührt.
import json, pathlib
W = pathlib.Path(__file__).resolve().parent.parent / "App/Ressourcen"
def trage(datei, T):
    P = W / datei
    d = json.loads(P.read_text(encoding="utf-8")); neu = 0
    for k, (de, en, es, fr) in T.items():
        if k in d["strings"]: continue
        d["strings"][k] = {"localizations": {l: {"stringUnit": {"state": "translated", "value": v}} for l, v in (("de", de or k), ("en", en), ("es", es), ("fr", fr))}}
        neu += 1
    P.write_text(json.dumps(d, ensure_ascii=False, indent=2, separators=(",", ": ")) + "\n", encoding="utf-8")
    print(datei, "neu:", neu)
trage("Localizable.xcstrings", {
"Näher ran. Die Würfel sind noch sehr klein.": (None, "Move closer. The dice are still very small.", "Acércate. Los dados aún se ven muy pequeños.", "Rapproche-toi. Les dés sont encore très petits."),
"Etwas weiter weg. Die Würfel sind zu groß oder angeschnitten.": (None, "Move back a little. The dice are too large or cut off.", "Aléjate un poco. Los dados son demasiado grandes o están cortados.", "Éloigne-toi un peu. Les dés sont trop grands ou coupés."),
"Noch kein Würfel gefunden. Geh näher ran oder sorge für mehr Licht.": (None, "No die found yet. Move closer or add more light.", "Aún no se encuentra ningún dado. Acércate o busca más luz.", "Aucun dé trouvé pour l’instant. Rapproche-toi ou ajoute de la lumière."),
"Zu dunkel. Schalte die Taschenlampe ein oder sorge für mehr Licht.": (None, "Too dark. Turn on the flashlight or add more light.", "Demasiado oscuro. Enciende la linterna o busca más luz.", "Trop sombre. Allume la lampe torche ou ajoute de la lumière."),
"Zu dunkel. Sorge für mehr Licht, dann wird das Lesen sicherer.": (None, "Too dark. Add more light to make reading more reliable.", "Demasiado oscuro. Con más luz la lectura es más fiable.", "Trop sombre. Plus de lumière rend la lecture plus fiable."),
"Taschenlampe": (None, "Flashlight", "Linterna", "Lampe torche"),
"Selbst eintippen": (None, "Enter manually", "Introducir a mano", "Saisir à la main"),
"%lld Würfel: %@": (None, "%lld dice: %@", "%lld dados: %@", "%lld dés : %@"),
})
