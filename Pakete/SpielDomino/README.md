# SpielDomino: Domino · Dominó Cubano

**Domino** (China): Lege Steine mit passenden Augen aneinander und werde zuerst deine los.

**Dominó Cubano** (Kuba): Domino mit Doppel-Neun-Satz (55 Steine), zehn Steine je Spieler.

Das Paket ist ein Spielmodul der Sammlung Partie (Modul-IDs `domino`, `dominocubano`). Die App bindet es über `SpielModul` aus SpieleKern ein.

## Aufbau

- Swift Tools 6.0, Plattformen: iOS 17, macOS 14
- Ziele: `DominoKern`, `SpielDomino`
- Testziele: `DominoKernTests`
- Abhängigkeiten: Baukasten (KlarGlas), SpielHilfen, SpieleKern (im öffentlichen Repo unter `Pakete/Baukasten`)

## Testen

Auf dem Mac, ohne Simulator:

```bash
cd Pakete/SpielDomino
swift test
```

1 Testdatei. Oberflächen-Code ist mit `#if canImport(UIKit)` geschützt und wird auf dem Mac nicht mitgebaut; geprüft wird die Logik.

Es sind keine Umgebungsvariablen nötig.

## Lizenz

Code: MIT (siehe `LICENSE` im Hauptordner).
