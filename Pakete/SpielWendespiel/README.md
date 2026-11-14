# SpielWendespiel: Wendespiel

**Wendespiel** (England): Schließe gegnerische Steine zwischen deinen ein und wende sie; am Ende gewinnt, wer mehr Steine hat.

Das Paket ist ein Spielmodul der Sammlung Partie (Modul-ID `wendespiel`). Die App bindet es über `SpielModul` aus SpieleKern ein.

## Aufbau

- Swift Tools 6.0, Plattformen: iOS 17, macOS 14
- Ziele: `WendespielKern`, `SpielWendespiel`
- Testziele: `WendespielKernTests`
- Abhängigkeiten: Baukasten (KlarGlas), SpielHilfen, SpieleKern (im öffentlichen Repo unter `Pakete/Baukasten`)

## Testen

Auf dem Mac, ohne Simulator:

```bash
cd Pakete/SpielWendespiel
swift test
```

3 Testdateien. Oberflächen-Code ist mit `#if canImport(UIKit)` geschützt und wird auf dem Mac nicht mitgebaut; geprüft wird die Logik.

Es sind keine Umgebungsvariablen nötig.

## Lizenz

Code: MIT (siehe `LICENSE` im Hauptordner).
