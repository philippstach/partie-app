# Minensuche, Ergebnisseite (Blatt 8, Paket R2): trägt die neuen Texte in App/Ressourcen/Localizable.xcstrings ein. Bestehende Schlüssel bleiben unberührt.
import json, pathlib
P = pathlib.Path(__file__).resolve().parent.parent / "App/Ressourcen/Localizable.xcstrings"
T = {
"Mine getroffen nach %@.": ("Hit a mine after %@.", "Mina pisada tras %@.", "Mine touchée après %@."),
"Alle Felder aufgedeckt in %@.": ("All squares uncovered in %@.", "Todas las casillas descubiertas en %@.", "Toutes les cases découvertes en %@."),
"Stufe": ("Level", "Nivel", "Niveau"),
"Zeit": ("Time", "Tiempo", "Temps"),
"Minen": ("Mines", "Minas", "Mines"),
"Spielfeld am Ende": ("Board at the end", "Tablero al final", "Grille à la fin"),
}
d = json.loads(P.read_text(encoding="utf-8")); neu = 0
for k, (en, es, fr) in T.items():
    if k in d["strings"]: continue
    d["strings"][k] = {"localizations": {l: {"stringUnit": {"state": "translated", "value": v}} for l, v in (("de", k), ("en", en), ("es", es), ("fr", fr))}}
    neu += 1
P.write_text(json.dumps(d, ensure_ascii=False, indent=2, separators=(",", ": ")) + "\n", encoding="utf-8")
print("neu:", neu)
