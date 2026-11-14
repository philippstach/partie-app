# SpielMuehle: Mühle

**Mühle** (Antike (Ägypten, Rom)): Setze neun Steine und schließe Mühlen aus drei in einer Reihe, um gegnerische Steine zu entfernen.

Das Paket ist ein Spielmodul der Sammlung Partie (Modul-ID `muehle`). Die App bindet es über `SpielModul` aus SpieleKern ein.

## Aufbau

- Swift Tools 6.0, Plattformen: iOS 17, macOS 14
- Ziele: `MuehleKern`, `SpielMuehle`
- Testziele: `MuehleKernTests`
- Abhängigkeiten: Baukasten (KlarGlas), SpielHilfen, SpieleKern (im öffentlichen Repo unter `Pakete/Baukasten`)

## Testen

Auf dem Mac, ohne Simulator:

```bash
cd Pakete/SpielMuehle
swift test
```

3 Testdateien. Oberflächen-Code ist mit `#if canImport(UIKit)` geschützt und wird auf dem Mac nicht mitgebaut; geprüft wird die Logik.

Es sind keine Umgebungsvariablen nötig.

## Lizenz

Code: MIT (siehe `LICENSE` im Hauptordner).
