# SpielSchiffe: Schiffe versenken

**Schiffe versenken** (Russland): Verstecke Schiffe auf einem Gitter und errate die Felder der gegnerischen Flotte.

Das Paket ist ein Spielmodul der Sammlung Partie (Modul-ID `schiffeversenken`). Die App bindet es über `SpielModul` aus SpieleKern ein.

## Aufbau

- Swift Tools 6.0, Plattformen: iOS 17, macOS 14
- Ziele: `SchiffeKern`, `SpielSchiffe`
- Testziele: `SchiffeKernTests`
- Abhängigkeiten: Baukasten (KlarGlas), SpieleKern (im öffentlichen Repo unter `Pakete/Baukasten`)

## Testen

Auf dem Mac, ohne Simulator:

```bash
cd Pakete/SpielSchiffe
swift test
```

1 Testdatei. Oberflächen-Code ist mit `#if canImport(UIKit)` geschützt und wird auf dem Mac nicht mitgebaut; geprüft wird die Logik.

Es sind keine Umgebungsvariablen nötig.

## Lizenz

Code: MIT (siehe `LICENSE` im Hauptordner).
