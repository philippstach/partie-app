# SpielRauswurf: Rauswurf

**Rauswurf** (Deutschland): Brettspiel für 2–4: Mit der Würfelzahl die Figuren einmal um das Brett ins Haus bringen und Gegner hinauswerfen.

Das Paket ist ein Spielmodul der Sammlung Partie (Modul-ID `rauswurf`). Die App bindet es über `SpielModul` aus SpieleKern ein.

## Aufbau

- Swift Tools 5.10, Plattformen: iOS 17, macOS 14
- Ziele: `SpielRauswurf`
- Testziele: `SpielRauswurfTests`
- Abhängigkeiten: Baukasten (KlarGlas), SpieleKern (im öffentlichen Repo unter `Pakete/Baukasten`)
- Inhalte in `Shared/`: `demo`, `regeltests`

## Testen

Auf dem Mac, ohne Simulator:

```bash
cd Pakete/SpielRauswurf
swift test
```

18 Testdateien. Oberflächen-Code ist mit `#if canImport(UIKit)` geschützt und wird auf dem Mac nicht mitgebaut; geprüft wird die Logik.

Es sind keine Umgebungsvariablen nötig.

## Lizenz

Code: MIT (siehe `LICENSE` im Hauptordner).
Inhalte (Rätsel, Wortlisten, Daten, Töne): CC BY 4.0 (siehe `LICENSE-INHALTE.md`), Herkunft in `HERKUNFT.md`.
