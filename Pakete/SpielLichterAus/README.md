# SpielLichterAus: Lichter aus

**Lichter aus** (USA): Ein Tipp schaltet ein Licht und seine Nachbarn um; bringe alle Lichter zum Erlöschen.

Das Paket ist ein Spielmodul der Sammlung Partie (Modul-ID `lichteraus`). Die App bindet es über `SpielModul` aus SpieleKern ein.

## Aufbau

- Swift Tools 6.0, Plattformen: iOS 17, macOS 14
- Ziele: `LichterAusKern`, `SpielLichterAus`
- Testziele: `LichterAusKernTests`
- Abhängigkeiten: Baukasten (KlarGlas), SpielHilfen, SpieleKern (im öffentlichen Repo unter `Pakete/Baukasten`)

## Testen

Auf dem Mac, ohne Simulator:

```bash
cd Pakete/SpielLichterAus
swift test
```

1 Testdatei. Oberflächen-Code ist mit `#if canImport(UIKit)` geschützt und wird auf dem Mac nicht mitgebaut; geprüft wird die Logik.

Es sind keine Umgebungsvariablen nötig.

## Lizenz

Code: MIT (siehe `LICENSE` im Hauptordner).
