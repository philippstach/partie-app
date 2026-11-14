# Live-Würfelerkennung 3 (Ruhe-Logik, Build-10-Feedback): trägt die neuen Strings in App/Ressourcen/Localizable.xcstrings ein. Bestehende Schlüssel bleiben unberührt.
import json, pathlib
P = pathlib.Path(__file__).resolve().parent.parent / "App/Ressourcen/Localizable.xcstrings"
T = {
"Ruhig halten …": ("Hold still …", "Mantén quieto …", "Ne bougez pas …"),
"Kamera wackelt: ruhig halten": ("Camera is shaking: hold still", "La cámara se mueve: mantenla quieta", "L’appareil bouge : tenez-le stable"),
}
d = json.loads(P.read_text(encoding="utf-8")); neu = 0
for k, (en, es, fr) in T.items():
    if k in d["strings"]: continue
    d["strings"][k] = {"localizations": {l: {"stringUnit": {"state": "translated", "value": v}} for l, v in (("de", k), ("en", en), ("es", es), ("fr", fr))}}
    neu += 1
P.write_text(json.dumps(d, ensure_ascii=False, indent=2, separators=(",", ": ")) + "\n", encoding="utf-8")
print("neu:", neu)
