# ArcadeKern

Gemeinsamer Logik-Baustein aller Arcade-Spiele: Takt, Zufall, Kollision, Schwierigkeitskurve und Rekorde. Ohne Oberfläche, vollständig mit `swift test` auf dem Mac prüfbar.

## Aufbau

- Swift Tools 6.0, Plattformen: iOS 17, macOS 14
- Ziele: `ArcadeKern`
- Testziele: `ArcadeKernTests`

## Testen

Auf dem Mac, ohne Simulator:

```bash
cd Pakete/ArcadeKern
swift test
```

1 Testdatei. Oberflächen-Code ist mit `#if canImport(UIKit)` geschützt und wird auf dem Mac nicht mitgebaut; geprüft wird die Logik.

Es sind keine Umgebungsvariablen nötig.

## Lizenz

Code: MIT (siehe `LICENSE` im Hauptordner).
