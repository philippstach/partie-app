# SpielDauerlauf: Dauerlauf

**Dauerlauf** (Deutschland): Ein Läufer rennt von allein; springe über Hürden, ducke dich und sammle Perlen.

Das Paket ist ein Spielmodul der Sammlung Partie (Modul-ID `dauerlauf`). Die App bindet es über `SpielModul` aus SpieleKern ein.

## Aufbau

- Swift Tools 6.0, Plattformen: iOS 17, macOS 14
- Ziele: `DauerlaufKern`, `SpielDauerlauf`
- Testziele: `DauerlaufKernTests`
- Abhängigkeiten: ArcadeKern, Baukasten (KlarGlas), SpieleKern (im öffentlichen Repo unter `Pakete/Baukasten`)

## Testen

Auf dem Mac, ohne Simulator:

```bash
cd Pakete/SpielDauerlauf
swift test
```

1 Testdatei. Oberflächen-Code ist mit `#if canImport(UIKit)` geschützt und wird auf dem Mac nicht mitgebaut; geprüft wird die Logik.

Es sind keine Umgebungsvariablen nötig.

## Lizenz

Code: MIT (siehe `LICENSE` im Hauptordner).
