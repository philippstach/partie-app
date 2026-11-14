# MinensucheKern

Reine Spiellogik von Minensuche (Feld, Aufdecken, Flaggen, Tagesrätsel), ohne Oberfläche.

## Aufbau

- Swift Tools 5.9, Plattformen: iOS 17, macOS 14
- Ziele: `MinensucheKern`
- Testziele: `MinensucheKernTests`

## Testen

Auf dem Mac, ohne Simulator:

```bash
cd Pakete/MinensucheKern
swift test
```

1 Testdatei. Oberflächen-Code ist mit `#if canImport(UIKit)` geschützt und wird auf dem Mac nicht mitgebaut; geprüft wird die Logik.

Es sind keine Umgebungsvariablen nötig.

## Lizenz

Code: MIT (siehe `LICENSE` im Hauptordner).
