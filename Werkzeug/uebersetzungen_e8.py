#!/usr/bin/env python3
"""E8 iPad-Tischmodus: Texte der App (App/Ressourcen/Localizable.xcstrings). Aufruf im Repo-Wurzelordner."""
import json
P = "App/Ressourcen/Localizable.xcstrings"
T = {
"Tisch-Modus": ("Tisch-Modus", "Table mode", "Modo mesa", "Mode table"),
"iPad flach auf den Tisch legen: Jede Person bekommt am Rand ein Namensschild zu sich hin.":
 ("iPad flach auf den Tisch legen: Jede Person bekommt am Rand ein Namensschild zu sich hin.",
  "Lay the iPad flat on the table: each person gets a name tag at the edge, facing them.",
  "Coloca el iPad plano sobre la mesa: cada persona tiene en el borde una etiqueta con su nombre orientada hacia ella.",
  "Pose l’iPad à plat sur la table : chaque personne a sur le bord une étiquette à son nom, tournée vers elle."),
"%@, ist dran": ("%@, ist dran", "%@, your turn", "%@, es tu turno", "%@, à toi de jouer"),
}
d = json.load(open(P))
for k, v in T.items():
    if k in d["strings"] and "localizations" in d["strings"][k]: continue
    d["strings"][k] = {"localizations": {l: {"stringUnit": {"state": "translated", "value": x}} for l, x in zip(["de", "en", "es", "fr"], v)}}
open(P, "w").write(json.dumps(d, ensure_ascii=False, indent=2) + "\n")
print("ok", len(T))
