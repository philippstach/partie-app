# SpielSolitaer: Solitär

**Solitär** (Frankreich): Klassisches Kartenlegen allein: Klondike, Spider, FreeCell, Pyramide, TriPeaks, Golf, Yukon.

Das Paket ist ein Spielmodul der Sammlung Partie (Modul-ID `solitaer`). Die App bindet es über `SpielModul` aus SpieleKern ein.

## Aufbau

- Swift Tools 6.0, Plattformen: iOS 17, macOS 14
- Ziele: `SpielSolitaer`
- Testziele: `SpielSolitaerTests`
- Abhängigkeiten: Baukasten (KlarGlas), SpieleKern (im öffentlichen Repo unter `Pakete/Baukasten`)
- Inhalte in `Shared/`: `partien`, `regeltests`

## Testen

Auf dem Mac, ohne Simulator:

```bash
cd Pakete/SpielSolitaer
swift test
```

38 Testdateien. Oberflächen-Code ist mit `#if canImport(UIKit)` geschützt und wird auf dem Mac nicht mitgebaut; geprüft wird die Logik.

Umgebungsvariablen:

- `PARTIE_PARTIEN`: Ordner mit den Inhaltsdateien, wenn die Tests ohne App laufen (mehrere mit `:` getrennt). Ohne die Variable sucht der Code im App-Bundle.
- `QUER_FOTOS`: Optional, nur für `xcodebuild test` auf einem Simulator: Zielordner für Querformat-Fotos (`TEST_RUNNER_QUER_FOTOS`). Ohne die Variable wird der Test übersprungen.

## Lizenz

Code: MIT (siehe `LICENSE` im Hauptordner).
Inhalte (Rätsel, Wortlisten, Daten, Töne): CC BY 4.0 (siehe `LICENSE-INHALTE.md`), Herkunft in `HERKUNFT.md`.
