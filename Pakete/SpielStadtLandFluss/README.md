# SpielStadtLandFluss: Stadt, Land, Fluss

**Stadt, Land, Fluss** (Deutschland): Finde zu einem Buchstaben Stadt, Land, Fluss, Tier und mehr; seltene Antworten zählen doppelt.

Das Paket ist ein Spielmodul der Sammlung Partie (Modul-ID `stadtlandfluss`). Die App bindet es über `SpielModul` aus SpieleKern ein.

## Aufbau

- Swift Tools 6.0, Plattformen: iOS 17, macOS 14
- Ziele: `StadtLandFlussKern`, `SpielStadtLandFluss`
- Testziele: `StadtLandFlussKernTests`
- Abhängigkeiten: Baukasten (KlarGlas), SpieleKern (im öffentlichen Repo unter `Pakete/Baukasten`)

## Testen

Auf dem Mac, ohne Simulator:

```bash
cd Pakete/SpielStadtLandFluss
swift test
```

1 Testdatei. Oberflächen-Code ist mit `#if canImport(UIKit)` geschützt und wird auf dem Mac nicht mitgebaut; geprüft wird die Logik.

Es sind keine Umgebungsvariablen nötig.

## Lizenz

Code: MIT (siehe `LICENSE` im Hauptordner).
