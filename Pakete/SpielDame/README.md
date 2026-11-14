# SpielDame: Dame

**Dame** (Frankreich): Ziehe diagonal, springe und schlage Pflicht, erreiche die letzte Reihe und werde Dame.

Das Paket ist ein Spielmodul der Sammlung Partie (Modul-ID `dame`). Die App bindet es über `SpielModul` aus SpieleKern ein.

## Aufbau

- Swift Tools 6.0, Plattformen: iOS 17, macOS 14
- Ziele: `DameKern`, `SpielDame`
- Testziele: `DameKernTests`
- Abhängigkeiten: Baukasten (KlarGlas), SpielHilfen, SpieleKern (im öffentlichen Repo unter `Pakete/Baukasten`)

## Testen

Auf dem Mac, ohne Simulator:

```bash
cd Pakete/SpielDame
swift test
```

3 Testdateien. Oberflächen-Code ist mit `#if canImport(UIKit)` geschützt und wird auf dem Mac nicht mitgebaut; geprüft wird die Logik.

Es sind keine Umgebungsvariablen nötig.

## Lizenz

Code: MIT (siehe `LICENSE` im Hauptordner).
