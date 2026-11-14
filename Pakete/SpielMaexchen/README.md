# SpielMaexchen: Mäxchen

**Mäxchen** (Deutschland): Würfle verdeckt, sage einen Wert an (auch gelogen) und lass den nächsten glauben oder anzweifeln.

Das Paket ist ein Spielmodul der Sammlung Partie (Modul-ID `maexchen`). Die App bindet es über `SpielModul` aus SpieleKern ein.

## Aufbau

- Swift Tools 6.0, Plattformen: iOS 17, macOS 14
- Ziele: `MaexchenKern`, `SpielMaexchen`
- Testziele: `MaexchenKernTests`
- Abhängigkeiten: Baukasten (KlarGlas), SpieleKern (im öffentlichen Repo unter `Pakete/Baukasten`)

## Testen

Auf dem Mac, ohne Simulator:

```bash
cd Pakete/SpielMaexchen
swift test
```

1 Testdatei. Oberflächen-Code ist mit `#if canImport(UIKit)` geschützt und wird auf dem Mac nicht mitgebaut; geprüft wird die Logik.

Es sind keine Umgebungsvariablen nötig.

## Lizenz

Code: MIT (siehe `LICENSE` im Hauptordner).
