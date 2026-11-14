# SpielBackgammon: Backgammon · Nardy · Acey-Deucey

**Backgammon** (Persien): Würfle und ziehe 15 Steine um das Brett nach Hause, schlage Einzelsteine und trage zuerst alle ab.

**Acey-Deucey** (Griechenland): Backgammon-Variante: alle Steine starten auf der Bar, mit der Sonderregel für 1 und 2.

Das Paket ist ein Spielmodul der Sammlung Partie (Modul-IDs `backgammon`, `nardy`, `aceydeucey`). Die App bindet es über `SpielModul` aus SpieleKern ein.

## Aufbau

- Swift Tools 6.0, Plattformen: iOS 17, macOS 14
- Ziele: `BackgammonKern`, `SpielBackgammon`
- Testziele: `BackgammonKernTests`
- Abhängigkeiten: Baukasten (KlarGlas), SpielHilfen, SpieleKern (im öffentlichen Repo unter `Pakete/Baukasten`)

## Testen

Auf dem Mac, ohne Simulator:

```bash
cd Pakete/SpielBackgammon
swift test
```

3 Testdateien. Oberflächen-Code ist mit `#if canImport(UIKit)` geschützt und wird auf dem Mac nicht mitgebaut; geprüft wird die Logik.

Es sind keine Umgebungsvariablen nötig.

## Lizenz

Code: MIT (siehe `LICENSE` im Hauptordner).
