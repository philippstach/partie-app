# F6 (Würfel per Kamera): trägt die neuen Strings in App/Ressourcen/Localizable.xcstrings ein. Bestehende Schlüssel bleiben unberührt.
import json, pathlib
P = pathlib.Path(__file__).resolve().parent.parent / "App/Ressourcen/Localizable.xcstrings"
T = {
"Mit Kamera lesen": ("Read with camera", "Leer con la cámara", "Lire avec l’appareil photo"),
"Fotografiere die Würfel von oben. Du kannst jeden Wert danach noch ändern.": ("Take a photo of the dice from above. You can still change every value afterwards.", "Haz una foto de los dados desde arriba. Después puedes cambiar cada valor.", "Photographie les dés d’en haut. Tu peux ensuite modifier chaque valeur."),
"Keine Würfel erkannt. Lege sie einzeln auf eine einfarbige Fläche, fotografiere von oben und versuche es noch einmal, oder tippe die Augen ein.": ("No dice recognised. Place them apart on a plain surface, photograph from above and try again, or type in the pips.", "No se reconocieron dados. Colócalos separados sobre una superficie lisa, haz la foto desde arriba e inténtalo de nuevo, o escribe los puntos.", "Aucun dé reconnu. Pose-les séparément sur une surface unie, photographie d’en haut et réessaie, ou saisis les points."),
"Nicht alle Würfel erkannt. Ergänze die fehlenden mit den Zifferntasten.": ("Not all dice recognised. Fill in the missing ones with the number keys.", "No se reconocieron todos los dados. Completa los que faltan con las teclas numéricas.", "Tous les dés n’ont pas été reconnus. Complète les manquants avec les touches numériques."),
"Bitte prüfe die Augen, bevor du den Wurf übernimmst.": ("Please check the pips before you confirm the roll.", "Comprueba los puntos antes de confirmar la tirada.", "Vérifie les points avant de valider le lancer."),
}
d = json.loads(P.read_text(encoding="utf-8"))
neu = 0
for k, (en, es, fr) in T.items():
    if k in d["strings"]: continue
    d["strings"][k] = {"localizations": {l: {"stringUnit": {"state": "translated", "value": v}} for l, v in (("de", k), ("en", en), ("es", es), ("fr", fr))}}
    neu += 1
P.write_text(json.dumps(d, ensure_ascii=False, indent=2, separators=(",", ": ")) + "\n", encoding="utf-8")
print("neu:", neu)
