# Bei Partie mitmachen

[English](CONTRIBUTING.en.md)

Danke fürs Mithelfen! Fehlerkorrekturen und Verbesserungen am gemeinsamen Baukasten, Übersetzungen und Ideen sind willkommen. **Vor Version 1.0 nehmen wir keine neuen Spiele und keine Änderungen an einzelnen Spielen an.**

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

## Wo Code-Beiträge hingehören

Am besten in den gemeinsamen Baukasten `Pakete/Baukasten` (Produkt `KlarGlas`): Farben, Blätter, Knöpfe, Miniaturen und das Design „Tinte“. Dort ändert sich etwas einmal, und die App übernimmt es für alle Spiele. Bitte vorher ein Issue anlegen und kurz beschreiben, was besser werden soll. Änderungen an einzelnen Spielen und neue Spiele kommen frühestens nach 1.0 in Frage, dann steht hier die Anleitung dazu.

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
