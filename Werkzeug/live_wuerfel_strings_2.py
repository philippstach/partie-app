# Live-Würfelerkennung 2 (Auslöser, Zoom, Festhalten): trägt die neuen Strings in App/Ressourcen/Localizable.xcstrings ein. Bestehende Schlüssel bleiben unberührt.
import json, pathlib
P = pathlib.Path(__file__).resolve().parent.parent / "App/Ressourcen/Localizable.xcstrings"
T = {
"Wert festhalten": ("Lock value", "Fijar valor", "Verrouiller la valeur"),
"Auto": ("Auto", "Auto", "Auto"),
"Neu aufnehmen": ("Retake", "Volver a capturar", "Reprendre"),
"Foto aufnehmen": ("Take photo", "Hacer foto", "Prendre une photo"),
"Standbild": ("Still image", "Imagen fija", "Image figée"),
}
d = json.loads(P.read_text(encoding="utf-8")); neu = 0
for k, (en, es, fr) in T.items():
    if k in d["strings"]: continue
    d["strings"][k] = {"localizations": {l: {"stringUnit": {"state": "translated", "value": v}} for l, v in (("de", k), ("en", en), ("es", es), ("fr", fr))}}
    neu += 1
P.write_text(json.dumps(d, ensure_ascii=False, indent=2, separators=(",", ": ")) + "\n", encoding="utf-8")
print("neu:", neu)
