# SpielHimmelsleiter: Himmelsleiter

**Himmelsleiter** (Indien): Würfle dich über das Brett nach oben, Leitern helfen, Schlangen werfen zurück.

Das Paket ist ein Spielmodul der Sammlung Partie (Modul-ID `himmelsleiter`). Die App bindet es über `SpielModul` aus SpieleKern ein.

## Aufbau

- Swift Tools 6.0, Plattformen: iOS 17, macOS 14
- Ziele: `HimmelsleiterKern`, `SpielHimmelsleiter`
- Testziele: `HimmelsleiterKernTests`
- Abhängigkeiten: Baukasten (KlarGlas), SpieleKern (im öffentlichen Repo unter `Pakete/Baukasten`)

## Testen

Auf dem Mac, ohne Simulator:

```bash
cd Pakete/SpielHimmelsleiter
swift test
```

2 Testdateien. Oberflächen-Code ist mit `#if canImport(UIKit)` geschützt und wird auf dem Mac nicht mitgebaut; geprüft wird die Logik.

Es sind keine Umgebungsvariablen nötig.

## Lizenz

Code: MIT (siehe `LICENSE` im Hauptordner).
