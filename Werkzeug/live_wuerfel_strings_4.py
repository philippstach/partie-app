# Live-Würfelerkennung 4 (neue Kamera-Seite mit Würfelzeile, Anhalten, Übernehmen): trägt die neuen Strings in App/Ressourcen/Localizable.xcstrings ein. Bestehende Schlüssel bleiben unberührt.
import json, pathlib
P = pathlib.Path(__file__).resolve().parent.parent / "App/Ressourcen/Localizable.xcstrings"
T = {
"Halte das iPhone über die Würfel.": ("Hold your iPhone above the dice.", "Mantén el iPhone sobre los dados.", "Tenez l’iPhone au-dessus des dés."),
"%lld von %lld Würfeln erkannt": ("%lld of %lld dice recognised", "%lld de %lld dados reconocidos", "%lld dés reconnus sur %lld"),
"Noch einen Moment ruhig halten": ("Hold still a moment longer", "Mantén quieto un momento más", "Ne bougez pas encore un instant"),
"Alle Würfel erkannt": ("All dice recognised", "Todos los dados reconocidos", "Tous les dés sont reconnus"),
"Angehalten. Tippe auf einen Würfel, um ihn zu ändern.": ("Paused. Tap a die to change it.", "En pausa. Toca un dado para cambiarlo.", "En pause. Touchez un dé pour le modifier."),
"Welche Augenzahl zeigt der Würfel?": ("Which number does the die show?", "¿Qué número muestra el dado?", "Quel nombre le dé affiche-t-il ?"),
"Kein Würfel": ("Not a die", "No es un dado", "Pas un dé"),
"Anhalten": ("Pause", "Pausar", "Mettre en pause"),
"Neu scannen": ("Scan again", "Escanear de nuevo", "Scanner à nouveau"),
"Übernehmen": ("Apply", "Aplicar", "Appliquer"),
"Schließen": ("Close", "Cerrar", "Fermer"),
}
d = json.loads(P.read_text(encoding="utf-8")); neu = 0
for k, (en, es, fr) in T.items():
    if k in d["strings"]: continue
    d["strings"][k] = {"localizations": {l: {"stringUnit": {"state": "translated", "value": v}} for l, v in (("de", k), ("en", en), ("es", es), ("fr", fr))}}
    neu += 1
P.write_text(json.dumps(d, ensure_ascii=False, indent=2, separators=(",", ": ")) + "\n", encoding="utf-8")
print("neu:", neu)
