# SpielHalma: Halma

**Halma** (USA): Bringe alle Steine hüpfend und in Sprungketten in die gegenüberliegende Ecke.

Das Paket ist ein Spielmodul der Sammlung Partie (Modul-ID `halma`). Die App bindet es über `SpielModul` aus SpieleKern ein.

## Aufbau

- Swift Tools 6.0, Plattformen: iOS 17, macOS 14
- Ziele: `HalmaKern`, `SpielHalma`
- Testziele: `HalmaKernTests`
- Abhängigkeiten: Baukasten (KlarGlas), SpielHilfen, SpieleKern (im öffentlichen Repo unter `Pakete/Baukasten`)

## Testen

Auf dem Mac, ohne Simulator:

```bash
cd Pakete/SpielHalma
swift test
```

3 Testdateien. Oberflächen-Code ist mit `#if canImport(UIKit)` geschützt und wird auf dem Mac nicht mitgebaut; geprüft wird die Logik.

Es sind keine Umgebungsvariablen nötig.

## Lizenz

Code: MIT (siehe `LICENSE` im Hauptordner).
