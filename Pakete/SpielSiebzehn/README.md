# SpielSiebzehn: Siebzehn und Vier

**Siebzehn und Vier** (Spanien): Komme mit Karten möglichst nah an 21, ohne darüber zu geraten, und schlage die Bank.

Das Paket ist ein Spielmodul der Sammlung Partie (Modul-ID `siebzehnundvier`). Die App bindet es über `SpielModul` aus SpieleKern ein.

## Aufbau

- Swift Tools 6.0, Plattformen: iOS 17, macOS 14
- Ziele: `SiebzehnKern`, `SpielSiebzehn`
- Testziele: `SiebzehnKernTests`
- Abhängigkeiten: Baukasten (KlarGlas), SpieleKern (im öffentlichen Repo unter `Pakete/Baukasten`)

## Testen

Auf dem Mac, ohne Simulator:

```bash
cd Pakete/SpielSiebzehn
swift test
```

1 Testdatei. Oberflächen-Code ist mit `#if canImport(UIKit)` geschützt und wird auf dem Mac nicht mitgebaut; geprüft wird die Logik.

Es sind keine Umgebungsvariablen nötig.

## Lizenz

Code: MIT (siehe `LICENSE` im Hauptordner).
