# SpielSudoku: Sudoku

**Sudoku** (Japan): Fülle das Neun-mal-neun-Gitter so, dass in jeder Zeile, Spalte und Box die Ziffern 1 bis 9 genau einmal stehen.

Das Paket ist ein Spielmodul der Sammlung Partie (Modul-ID `sudoku`). Die App bindet es über `SpielModul` aus SpieleKern ein.

## Aufbau

- Swift Tools 6.0, Plattformen: iOS 17, macOS 14
- Ziele: `SpielSudoku`
- Testziele: `SpielSudokuTests`
- Abhängigkeiten: Baukasten (KlarGlas), SpieleKern (im öffentlichen Repo unter `Pakete/Baukasten`)
- Inhalte in `Shared/`: `regeltests`

## Testen

Auf dem Mac, ohne Simulator:

```bash
cd Pakete/SpielSudoku
swift test
```

19 Testdateien. Oberflächen-Code ist mit `#if canImport(UIKit)` geschützt und wird auf dem Mac nicht mitgebaut; geprüft wird die Logik.

Es sind keine Umgebungsvariablen nötig.

## Lizenz

Code: MIT (siehe `LICENSE` im Hauptordner).
Inhalte (Rätsel, Wortlisten, Daten, Töne): CC BY 4.0 (siehe `LICENSE-INHALTE.md`), Herkunft in `HERKUNFT.md`.
