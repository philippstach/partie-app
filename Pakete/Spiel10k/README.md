# Spiel10k: 10k

**10k** (USA): Würfle mit fünf oder sechs Würfeln Punkte zusammen und sei als Erster bei 10 000, ohne eine Niete zu würfeln.

Das Paket ist ein Spielmodul der Sammlung Partie (Modul-ID `10k`). Die App bindet es über `SpielModul` aus SpieleKern ein.

## Aufbau

- Swift Tools 5.10, Plattformen: iOS 17, macOS 14
- Ziele: `Spiel10k`, `Spiel10kModul`
- Testziele: `Spiel10kTests`
- Abhängigkeiten: Baukasten (KlarGlas), SpieleKern (im öffentlichen Repo unter `Pakete/Baukasten`)
- Inhalte in `Shared/`: `regelchat`, `regeltests`, `spieler`

## Testen

Auf dem Mac, ohne Simulator:

```bash
cd Pakete/Spiel10k
swift test
```

18 Testdateien. Oberflächen-Code ist mit `#if canImport(UIKit)` geschützt und wird auf dem Mac nicht mitgebaut; geprüft wird die Logik.

Umgebungsvariablen:

- `REGELCHAT_RUNS`: Optional: Anzahl zusätzlicher Durchläufe für den Regel-Chat-Test (nur iOS 26 mit Apple Intelligence). Standard 0.

## Lizenz

Code: MIT (siehe `LICENSE` im Hauptordner).
Inhalte (Rätsel, Wortlisten, Daten, Töne): CC BY 4.0 (siehe `LICENSE-INHALTE.md`), Herkunft in `HERKUNFT.md`.
