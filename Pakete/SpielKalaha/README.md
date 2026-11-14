# SpielKalaha: Kalaha

**Kalaha** (Afrika): Säe Steine aus Mulden reihum und fülle dein Haus; endet der letzte Stein im Haus, bist du nochmal dran.

Das Paket ist ein Spielmodul der Sammlung Partie (Modul-ID `kalaha`). Die App bindet es über `SpielModul` aus SpieleKern ein.

## Aufbau

- Swift Tools 6.0, Plattformen: iOS 17, macOS 14
- Ziele: `KalahaKern`, `SpielKalaha`
- Testziele: `KalahaKernTests`
- Abhängigkeiten: Baukasten (KlarGlas), SpielHilfen, SpieleKern (im öffentlichen Repo unter `Pakete/Baukasten`)

## Testen

Auf dem Mac, ohne Simulator:

```bash
cd Pakete/SpielKalaha
swift test
```

1 Testdatei. Oberflächen-Code ist mit `#if canImport(UIKit)` geschützt und wird auf dem Mac nicht mitgebaut; geprüft wird die Logik.

Es sind keine Umgebungsvariablen nötig.

## Lizenz

Code: MIT (siehe `LICENSE` im Hauptordner).
