#!/usr/bin/env python3
"""E5 Live Activity: Texte der Widget-Erweiterung (Widget/Localizable.xcstrings). Aufruf im Repo-Wurzelordner."""
import json
P = "Widget/Localizable.xcstrings"
T = {"%@ ist dran": ("%@ ist dran", "%@ is up", "Turno de %@", "%@ joue")}
d = json.load(open(P))
for k, (de, en, es, fr) in T.items():
    d["strings"][k] = {"localizations": {l: {"stringUnit": {"state": "translated", "value": v}} for l, v in zip(["de", "en", "es", "fr"], [de, en, es, fr])}}
open(P, "w").write(json.dumps(d, ensure_ascii=False, indent=2) + "\n")
print("ok", len(T))
