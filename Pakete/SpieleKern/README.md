# SpieleKern

Gemeinsamer Kern der Sammlung: Spielmodul-Protokoll (`SpielModul`), Spieler, Statistik, Würfel, Spielrahmen (Start, Regeln, Ende-Bildschirm) und Arcade-Hülle. Jedes Spielpaket hängt davon ab.

## Aufbau

- Swift Tools 5.10, Plattformen: iOS 17, macOS 14
- Ziele: `SpieleKern`
- Testziele: `SpieleKernTests`
- Abhängigkeiten: ArcadeKern, Baukasten (KlarGlas) (im öffentlichen Repo unter `Pakete/Baukasten`)

## Testen

Auf dem Mac, ohne Simulator:

```bash
cd Pakete/SpieleKern
swift test
```

2 Testdateien. Oberflächen-Code ist mit `#if canImport(UIKit)` geschützt und wird auf dem Mac nicht mitgebaut; geprüft wird die Logik.

Es sind keine Umgebungsvariablen nötig.

## Lizenz

Code: MIT (siehe `LICENSE` im Hauptordner).
