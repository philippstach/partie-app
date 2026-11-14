# Gemeinsame Regeltests (Swift ↔ Kotlin)

Erzeugt von `python3 Tools/kniffel_referenz.py` (nur der Architekt). **Nie von Hand bearbeiten.** Regeln: `Doku/REGELN.md`.
Beide Apps lesen dieselben Dateien; eine Regeländerung ist erst fertig, wenn Swift und Kotlin grün sind.

## `wertung.json`
Liste `wertung`: `dice` (5 Zahlen), `category`, `joker` (Bool: Joker-Wertung), `expectedScore`.
Aufruf: `score(dice, category, joker)`.

## `partien/*.json`
```json
{ "name": "…", "beschreibung": "…",
  "rules": {"joker": true},            // Teilobjekt, fehlende Schlüssel = Standard
  "players": ["Anna", "Ben"],
  "dice": [3,1,4,…],                    // Würfelquelle, der Reihe nach
  "steps": [ {"action": {"type":"roll","keep":[]}, "expect": {"current":0,"dice":[…],"rollsUsed":1}},
             {"action": {"type":"score","category":"chance"}, "error": true} ],
  "expected": {"finished": true, "scores": [{"ones":3,…}], "totals": [{"upper":…,"bonus":…,"lower":…,"kniffelBonus":…,"total":…}]} }
```
- Würfelquelle: bei jedem neu gewürfelten Würfel das nächste Element (erster Wurf: Positionen 0–4, später nur die nicht gehaltenen, aufsteigend). Am Ende müssen **alle** Würfel verbraucht sein.
- `"error": true`: Aktion muss abgelehnt werden; Zustand danach gleich wie davor, Würfelquelle unberührt.
- `expect` nach einem Schritt und `expected` am Ende vergleichen nur die angegebenen Schlüssel. `scores`: nur belegte Felder (fehlend = frei).
- Test-Schleife: `players` anlegen, Würfelquelle als Roller einsetzen, Schritte abspielen, am Ende `consumed == dice.count`.
