# SpielKoenigsweg: Königsweg

**Königsweg** (nach dem Königsspiel von Ur): Bringe als Erster alle sieben Steine über den Weg von 14 Feldern aus dem Spiel. Vier Münzwürfe ergeben 0 bis 4 Schritte, im mittleren Streifen werden gegnerische Steine geschlagen.

Das Paket ist ein Spielmodul der Sammlung Partie (Modul-ID `koenigsweg`). Die App bindet es über `SpielModul` aus SpieleKern ein.

## Aufbau

- Swift Tools 6.0, Plattformen: iOS 17, macOS 14
- Ziele: `KoenigswegKern`, `SpielKoenigsweg`
- Testziele: `KoenigswegKernTests`
- Abhängigkeiten: Baukasten (KlarGlas), SpielHilfen, SpieleKern (im öffentlichen Repo unter `Pakete/Baukasten`)

## Testen

Auf dem Mac, ohne Simulator:

```bash
cd Pakete/SpielKoenigsweg
swift test
```

1 Testdatei. Oberflächen-Code ist mit `#if canImport(UIKit)` geschützt und wird auf dem Mac nicht mitgebaut; geprüft wird die Logik.

Es sind keine Umgebungsvariablen nötig.

## Lizenz

Code: MIT (siehe `LICENSE` im Hauptordner).
