# SpielOware: Oware

**Oware** (Ghana): Afrikanisches Säespiel: Verteile Samen in Mulden und erobere sie vom Gegner.

Das Paket ist ein Spielmodul der Sammlung Partie (Modul-ID `oware`). Die App bindet es über `SpielModul` aus SpieleKern ein.

## Aufbau

- Swift Tools 6.0, Plattformen: iOS 17, macOS 14
- Ziele: `OwareKern`, `SpielOware`
- Testziele: `OwareKernTests`
- Abhängigkeiten: Baukasten (KlarGlas), SpielHilfen, SpieleKern (im öffentlichen Repo unter `Pakete/Baukasten`)

## Testen

Auf dem Mac, ohne Simulator:

```bash
cd Pakete/SpielOware
swift test
```

2 Testdateien. Oberflächen-Code ist mit `#if canImport(UIKit)` geschützt und wird auf dem Mac nicht mitgebaut; geprüft wird die Logik.

Es sind keine Umgebungsvariablen nötig.

## Lizenz

Code: MIT (siehe `LICENSE` im Hauptordner).
