# SpielKlappbrett: Klappbrett

**Klappbrett** (Frankreich): Klappe die Zahlen 1 bis 9 passend zur Würfelsumme zu; wer am Ende die wenigsten offenen Zahlen hat, gewinnt.

Das Paket ist ein Spielmodul der Sammlung Partie (Modul-ID `klappbrett`). Die App bindet es über `SpielModul` aus SpieleKern ein.

## Aufbau

- Swift Tools 6.0, Plattformen: iOS 17, macOS 14
- Ziele: `KlappbrettKern`, `SpielKlappbrett`
- Testziele: `KlappbrettKernTests`
- Abhängigkeiten: Baukasten (KlarGlas), SpieleKern (im öffentlichen Repo unter `Pakete/Baukasten`)

## Testen

Auf dem Mac, ohne Simulator:

```bash
cd Pakete/SpielKlappbrett
swift test
```

1 Testdatei. Oberflächen-Code ist mit `#if canImport(UIKit)` geschützt und wird auf dem Mac nicht mitgebaut; geprüft wird die Logik.

Es sind keine Umgebungsvariablen nötig.

## Lizenz

Code: MIT (siehe `LICENSE` im Hauptordner).
