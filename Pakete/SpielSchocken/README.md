# SpielSchocken: Schocken

**Schocken** (Deutschland): Kneipenwürfelspiel mit drei Würfeln unter dem Deckel: Wer den schlechtesten Wurf hat, bekommt die Deckel.

Das Paket ist ein Spielmodul der Sammlung Partie (Modul-ID `schocken`). Die App bindet es über `SpielModul` aus SpieleKern ein.

## Aufbau

- Swift Tools 5.10, Plattformen: iOS 17, macOS 14
- Ziele: `SpielSchocken`
- Testziele: `SpielSchockenTests`
- Abhängigkeiten: Baukasten (KlarGlas), SpieleKern (im öffentlichen Repo unter `Pakete/Baukasten`)
- Inhalte in `Shared/`: `regeltests`

## Testen

Auf dem Mac, ohne Simulator:

```bash
cd Pakete/SpielSchocken
swift test
```

8 Testdateien. Oberflächen-Code ist mit `#if canImport(UIKit)` geschützt und wird auf dem Mac nicht mitgebaut; geprüft wird die Logik.

Es sind keine Umgebungsvariablen nötig.

## Lizenz

Code: MIT (siehe `LICENSE` im Hauptordner).
Inhalte (Rätsel, Wortlisten, Daten, Töne): CC BY 4.0 (siehe `LICENSE-INHALTE.md`), Herkunft in `HERKUNFT.md`.
