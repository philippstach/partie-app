# SpielSchiebepuzzle: Schiebepuzzle

**Schiebepuzzle** (USA): Schiebe nummerierte Kacheln in die Lücke, bis die Reihenfolge stimmt.

Das Paket ist ein Spielmodul der Sammlung Partie (Modul-ID `schiebepuzzle`). Die App bindet es über `SpielModul` aus SpieleKern ein.

## Aufbau

- Swift Tools 6.0, Plattformen: iOS 17, macOS 14
- Ziele: `SchiebepuzzleKern`, `SpielSchiebepuzzle`
- Testziele: `SchiebepuzzleKernTests`
- Abhängigkeiten: Baukasten (KlarGlas), SpielHilfen, SpieleKern (im öffentlichen Repo unter `Pakete/Baukasten`)

## Testen

Auf dem Mac, ohne Simulator:

```bash
cd Pakete/SpielSchiebepuzzle
swift test
```

1 Testdatei. Oberflächen-Code ist mit `#if canImport(UIKit)` geschützt und wird auf dem Mac nicht mitgebaut; geprüft wird die Logik.

Es sind keine Umgebungsvariablen nötig.

## Lizenz

Code: MIT (siehe `LICENSE` im Hauptordner).
