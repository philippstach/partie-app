# SpielSteckspiel: Steckspiel

**Steckspiel** (Deutschland): Lege Steine in die Reihe und erkenne die Muster, bevor der Gegner sie schließt.

Das Paket ist ein Spielmodul der Sammlung Partie (Modul-ID `steckspiel`). Die App bindet es über `SpielModul` aus SpieleKern ein.

## Aufbau

- Swift Tools 6.0, Plattformen: iOS 17, macOS 14
- Ziele: `SteckspielKern`, `SpielSteckspiel`
- Testziele: `SteckspielKernTests`
- Abhängigkeiten: Baukasten (KlarGlas), SpielHilfen, SpieleKern (im öffentlichen Repo unter `Pakete/Baukasten`)

## Testen

Auf dem Mac, ohne Simulator:

```bash
cd Pakete/SpielSteckspiel
swift test
```

1 Testdatei. Oberflächen-Code ist mit `#if canImport(UIKit)` geschützt und wird auf dem Mac nicht mitgebaut; geprüft wird die Logik.

Es sind keine Umgebungsvariablen nötig.

## Lizenz

Code: MIT (siehe `LICENSE` im Hauptordner).
