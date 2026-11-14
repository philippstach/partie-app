# SpielMinensuche: Minensuche

**Minensuche** (USA): Decke alle sicheren Felder auf, ohne eine Mine zu treffen; Zahlen zeigen die Minen in der Nachbarschaft.

Das Paket ist ein Spielmodul der Sammlung Partie (Modul-ID `minensuche`). Die App bindet es über `SpielModul` aus SpieleKern ein.

## Aufbau

- Swift Tools 5.10, Plattformen: iOS 17, macOS 14
- Ziele: `SpielMinensuche`
- Abhängigkeiten: Baukasten (KlarGlas), MinensucheKern, SpieleKern (im öffentlichen Repo unter `Pakete/Baukasten`)

## Testen

Dieses Paket hat keine eigenen Tests; die Logik steckt in einem eigenen Kern-Paket (siehe Abhängigkeiten) und wird dort geprüft. Bauen lässt es sich nur zusammen mit der App (iOS).

## Lizenz

Code: MIT (siehe `LICENSE` im Hauptordner).
