# SpielSchach: Schach

**Schach** (Indien): Der Klassiker: Setze den gegnerischen König matt; mit Rochade, en passant und Umwandlung.

Das Paket ist ein Spielmodul der Sammlung Partie (Modul-ID `schach`). Die App bindet es über `SpielModul` aus SpieleKern ein.

## Aufbau

- Swift Tools 6.0, Plattformen: iOS 17, macOS 14
- Ziele: `SchachKern`, `SpielSchach`
- Testziele: `SchachKernTests`
- Abhängigkeiten: Baukasten (KlarGlas), SpielHilfen, SpieleKern (im öffentlichen Repo unter `Pakete/Baukasten`)

## Testen

Auf dem Mac, ohne Simulator:

```bash
cd Pakete/SpielSchach
swift test
```

3 Testdateien. Oberflächen-Code ist mit `#if canImport(UIKit)` geschützt und wird auf dem Mac nicht mitgebaut; geprüft wird die Logik.

Es sind keine Umgebungsvariablen nötig.

## Lizenz

Code: MIT (siehe `LICENSE` im Hauptordner).
