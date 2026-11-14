#!/usr/bin/env python3
"""Fund 177: neuer Text für die gesperrte Tageswahl, vier Sprachen."""
import json, pathlib
p = pathlib.Path(__file__).resolve().parent.parent / "App/Ressourcen/Localizable.xcstrings"
d = json.loads(p.read_text(encoding="utf-8"))
k = "Gilt erst, wenn die laufende Partie zu Ende ist."
t = {"de": k, "en": "Applies once the current game is over.", "es": "Vale cuando termine la partida en curso.", "fr": "Valable une fois la partie en cours terminée."}
d["strings"][k] = {"localizations": {l: {"stringUnit": {"state": "translated", "value": v}} for l, v in t.items()}}
p.write_text(json.dumps(d, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
