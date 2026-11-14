# SpielBunco: Bunco

**Bunco** (USA): Würfelspiel in sechs Runden: Würfle die Zahl der Runde und sammle Punkte, drei Gleiche sind ein Bunco.

Das Paket ist ein Spielmodul der Sammlung Partie (Modul-ID `bunco`). Die App bindet es über `SpielModul` aus SpieleKern ein.

## Aufbau

- Swift Tools 6.0, Plattformen: iOS 17, macOS 14
- Ziele: `BuncoKern`, `SpielBunco`
- Testziele: `BuncoKernTests`
- Abhängigkeiten: Baukasten (KlarGlas), SpieleKern (im öffentlichen Repo unter `Pakete/Baukasten`)

## Testen

Auf dem Mac, ohne Simulator:

```bash
cd Pakete/SpielBunco
swift test
```

1 Testdatei. Oberflächen-Code ist mit `#if canImport(UIKit)` geschützt und wird auf dem Mac nicht mitgebaut; geprüft wird die Logik.

Es sind keine Umgebungsvariablen nötig.

## Lizenz

Code: MIT (siehe `LICENSE` im Hauptordner).
