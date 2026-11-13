# Bei Partie mitmachen

[English](CONTRIBUTING.md)

Danke fürs Mithelfen! Neue Spiele, Fehlerkorrekturen, Übersetzungen und bessere Rätsel sind willkommen.

## Grundregeln

- **Keine fremden Bibliotheken.** Partie nutzt nur Apples Bausteine (Swift, SwiftUI, Swift Charts, WidgetKit).
- **Keine Werbung, kein Tracking, keine Netzwerkzugriffe** fürs Spielen. Alles läuft offline.
- **Design:** die gemeinsamen „Klar & Glas“-Bausteine aus `Pakete/Baukasten` (Produkt `KlarGlas`) verwenden. Kein eigenes Theme, keine kopierten Bausteine.
- **Sprache:** Code, Bezeichner und Kommentare sind deutsch. Issues und Pull Requests dürfen deutsch oder englisch sein.
- **Namen:** neutrale Spielnamen, keine Marken (z. B. „Yacht“ statt eines Markennamens).

## Bauen

```bash
cp Lokal.xcconfig.beispiel Lokal.xcconfig   # eigene Team-ID eintragen
xcodegen
open Partie.xcodeproj
```

Jedes Paket lässt sich allein auf dem Mac testen, ohne Simulator:

```bash
cd Pakete/SpielYacht && swift test
```

Jedes Paket hat eine `README.md` mit Testaufbau und Umgebungsvariablen.

## Ein neues Spiel bauen

1. **Gerüst:** `python3 Werkzeug/geruest.py <Name>` legt `Pakete/Spiel<Name>` an, mit Logik-Ziel (`<Name>Kern`, nur Foundation), Oberflächen-Ziel (`Spiel<Name>`) und Tests.
2. **Erst die Logik:** Regeln, Computergegner und Wertung gehören in `<Name>Kern` und werden mit `swift test` geprüft. Oberflächen-Code steht in `#if canImport(UIKit)`.
3. **Modul:** `SpielModul` aus `SpieleKern` umsetzen (`id`, `name`, `gattung`, `farbe`, `symbol`, `spielerzahl`, `start`). Für Start, Regeln und Ende `SpielRahmen` nutzen.
4. **Einhängen:** `python3 Werkzeug/einhaengen.py <Name> <ModulTyp>` trägt das Paket in `project.yml` und die Spieleliste in `App/PartieApp.swift` ein. Dazu eine Zeile in `App/SpielMetadaten.swift` (Herkunft, Kurzbeschreibung, Stichworte).
5. **Texte:** alle sichtbaren Texte in `App/Ressourcen/Localizable.xcstrings`, auf Deutsch, Englisch, Spanisch und Französisch.
6. **Symbol:** `App/Assets.xcassets/Symbol-<id>.appiconset` anlegen.

Wer ein Spiel beisteuert, wird in der App genannt.

## Inhalte

Rätsel, Wortlisten, Töne und Bilder müssen selbst gemacht oder von eigenem Code erzeugt sein. Nichts aus Rätselheften, Webseiten oder Wörterbüchern übernehmen. Die Herkunft kommt in `HERKUNFT.md`. Töne bitte per Erzeugungsskript (siehe `Werkzeug/Toene/`).

## Pull Requests

- Ein Thema pro Pull Request. Beschreiben, was sich ändert und wie es getestet wurde.
- Alle Pakettests müssen grün sein (`swift test`), und die App muss bauen.
- **Jeden Commit unterschreiben** ([Developer Certificate of Origin](https://developercertificate.org)):
  ```bash
  git commit -s -m "Mühle: Computer erkennt Zwickmühlen"
  ```
  Das fügt `Signed-off-by: Name <mail>` hinzu und bestätigt, dass du den Beitrag einreichen darfst.

## Lizenz

Mit einem Beitrag stimmst du zu, dass dein Code unter der [MIT-Lizenz](LICENSE) und deine Inhalte unter [CC BY 4.0](LICENSE-INHALTE.md) stehen. Der Name „Partie“, das Logo und das App-Symbol sind davon ausgenommen.

## Umgang

Freundlich und sachlich bleiben. Belästigung jeder Art wird nicht geduldet.
