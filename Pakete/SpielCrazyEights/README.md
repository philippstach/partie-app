# SpielCrazyEights: Crazy Eights

**Crazy Eights** (USA): Lege Karten gleicher Farbe oder Zahl ab, Achter sind Joker und bestimmen die Farbe.

Das Paket ist ein Spielmodul der Sammlung Partie (Modul-ID `crazyeights`). Die App bindet es über `SpielModul` aus SpieleKern ein.

## Aufbau

- Swift Tools 6.0, Plattformen: iOS 17, macOS 14
- Ziele: `CrazyEightsKern`, `SpielCrazyEights`
- Testziele: `CrazyEightsKernTests`
- Abhängigkeiten: Baukasten (KlarGlas), SpieleKern (im öffentlichen Repo unter `Pakete/Baukasten`)

## Testen

Auf dem Mac, ohne Simulator:

```bash
cd Pakete/SpielCrazyEights
swift test
```

1 Testdatei. Oberflächen-Code ist mit `#if canImport(UIKit)` geschützt und wird auf dem Mac nicht mitgebaut; geprüft wird die Logik.

Es sind keine Umgebungsvariablen nötig.

## Lizenz

Code: MIT (siehe `LICENSE` im Hauptordner).
