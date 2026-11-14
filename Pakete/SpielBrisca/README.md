# SpielBrisca: Brisca

**Brisca** (Spanien): Spanisches Stichspiel: Gewinne Stiche mit Trumpf und sammle die meisten Augen.

Das Paket ist ein Spielmodul der Sammlung Partie (Modul-ID `brisca`). Die App bindet es über `SpielModul` aus SpieleKern ein.

## Aufbau

- Swift Tools 6.0, Plattformen: iOS 17, macOS 14
- Ziele: `BriscaKern`, `SpielBrisca`
- Testziele: `BriscaKernTests`
- Abhängigkeiten: Baukasten (KlarGlas), SpieleKern (im öffentlichen Repo unter `Pakete/Baukasten`)

## Testen

Auf dem Mac, ohne Simulator:

```bash
cd Pakete/SpielBrisca
swift test
```

1 Testdatei. Oberflächen-Code ist mit `#if canImport(UIKit)` geschützt und wird auf dem Mac nicht mitgebaut; geprüft wird die Logik.

Es sind keine Umgebungsvariablen nötig.

## Lizenz

Code: MIT (siehe `LICENSE` im Hauptordner).
