# SpielGalgenmaennchen: Galgenmännchen

**Galgenmännchen** (England): Errate ein gesuchtes Wort Buchstabe für Buchstabe, bevor das Männchen am Galgen vollständig ist.

Das Paket ist ein Spielmodul der Sammlung Partie (Modul-ID `galgenmaennchen`). Die App bindet es über `SpielModul` aus SpieleKern ein.

## Aufbau

- Swift Tools 6.0, Plattformen: iOS 17, macOS 14
- Ziele: `SpielGalgenmaennchen`
- Testziele: `SpielGalgenmaennchenTests`
- Abhängigkeiten: Baukasten (KlarGlas), SpieleKern (im öffentlichen Repo unter `Pakete/Baukasten`)
- Inhalte in `Shared/`: `regeltests`, `woerter`

## Testen

Auf dem Mac, ohne Simulator:

```bash
cd Pakete/SpielGalgenmaennchen
swift test
```

14 Testdateien. Oberflächen-Code ist mit `#if canImport(UIKit)` geschützt und wird auf dem Mac nicht mitgebaut; geprüft wird die Logik.

Es sind keine Umgebungsvariablen nötig.

## Lizenz

Code: MIT (siehe `LICENSE` im Hauptordner).
Inhalte (Rätsel, Wortlisten, Daten, Töne): CC BY 4.0 (siehe `LICENSE-INHALTE.md`), Herkunft in `HERKUNFT.md`.
