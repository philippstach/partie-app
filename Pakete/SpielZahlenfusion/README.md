# SpielZahlenfusion: Zahlenfusion

**Zahlenfusion** (Italien): Wische Zahlenkacheln, gleiche verschmelzen zu ihrer Summe, bis die 2048 erscheint.

Das Paket ist ein Spielmodul der Sammlung Partie (Modul-ID `zahlenfusion`). Die App bindet es über `SpielModul` aus SpieleKern ein.

## Aufbau

- Swift Tools 6.0, Plattformen: iOS 17, macOS 14
- Ziele: `ZahlenfusionKern`, `SpielZahlenfusion`
- Testziele: `ZahlenfusionKernTests`
- Abhängigkeiten: Baukasten (KlarGlas), SpielHilfen, SpieleKern (im öffentlichen Repo unter `Pakete/Baukasten`)

## Testen

Auf dem Mac, ohne Simulator:

```bash
cd Pakete/SpielZahlenfusion
swift test
```

1 Testdatei. Oberflächen-Code ist mit `#if canImport(UIKit)` geschützt und wird auf dem Mac nicht mitgebaut; geprüft wird die Logik.

Es sind keine Umgebungsvariablen nötig.

## Lizenz

Code: MIT (siehe `LICENSE` im Hauptordner).
