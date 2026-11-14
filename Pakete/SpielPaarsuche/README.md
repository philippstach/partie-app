# SpielPaarsuche: Paarsuche

**Paarsuche** (Deutschland): Decke Karten auf und finde gleiche Paare, wer sich mehr merkt, gewinnt.

Das Paket ist ein Spielmodul der Sammlung Partie (Modul-ID `paarsuche`). Die App bindet es über `SpielModul` aus SpieleKern ein.

## Aufbau

- Swift Tools 6.0, Plattformen: iOS 17, macOS 14
- Ziele: `PaarsucheKern`, `SpielPaarsuche`
- Testziele: `PaarsucheKernTests`
- Abhängigkeiten: Baukasten (KlarGlas), SpielHilfen, SpieleKern (im öffentlichen Repo unter `Pakete/Baukasten`)

## Testen

Auf dem Mac, ohne Simulator:

```bash
cd Pakete/SpielPaarsuche
swift test
```

1 Testdatei. Oberflächen-Code ist mit `#if canImport(UIKit)` geschützt und wird auf dem Mac nicht mitgebaut; geprüft wird die Logik.

Es sind keine Umgebungsvariablen nötig.

## Lizenz

Code: MIT (siehe `LICENSE` im Hauptordner).
