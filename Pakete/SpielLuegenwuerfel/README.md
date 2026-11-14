# SpielLuegenwuerfel: Perudo

**Perudo** (Südamerika): Würfel-Bluffspiel mit verdeckten Würfeln: Biete Mengen, zweifle an oder gib Calza.

Das Paket ist ein Spielmodul der Sammlung Partie (Modul-ID `perudo`). Die App bindet es über `SpielModul` aus SpieleKern ein.

## Aufbau

- Swift Tools 6.0, Plattformen: iOS 17, macOS 14
- Ziele: `LuegenwuerfelKern`, `SpielLuegenwuerfel`
- Testziele: `LuegenwuerfelKernTests`
- Abhängigkeiten: Baukasten (KlarGlas), SpieleKern (im öffentlichen Repo unter `Pakete/Baukasten`)

## Testen

Auf dem Mac, ohne Simulator:

```bash
cd Pakete/SpielLuegenwuerfel
swift test
```

1 Testdatei. Oberflächen-Code ist mit `#if canImport(UIKit)` geschützt und wird auf dem Mac nicht mitgebaut; geprüft wird die Logik.

Es sind keine Umgebungsvariablen nötig.

## Lizenz

Code: MIT (siehe `LICENSE` im Hauptordner).
