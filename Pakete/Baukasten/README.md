# Baukasten – ein Paket, zwei Produkte

Swift-Paket (iOS 17+, Spielefamilie). Regeln: `~/Claude/App/BAUKASTEN-REGELN.md` (Funktionen) und
`~/Claude/App/Design-Konzept/HANDLUNGSEMPFEHLUNG.md` R4/R5 (Design). Einbindung in Xcode: lokales Paket
`../../../_Gemeinsam/Baukasten` (relativer Pfad), dann die Produkte **Baukasten** und **KlarGlas** zum App-Ziel hinzufügen.
Widget-Erweiterungen binden nur **KlarGlas** ein.

## Produkt `KlarGlas` (Optik, Design-Chat) – Version in `KlarGlas.version`

Alle Bausteine des CI-Handbuchs (`~/Claude/App/DESIGN.md`) in einer Fassung. Apps importieren `KlarGlas`, löschen ihre Kopien
`KlarGlas.swift`/`KlarGlasBausteine.swift` (und ein eigenes `Theme`) und bauen nichts nach. Was neu ist und wer nachziehen muss:
`KLARGLAS-VERSIONEN.md`. Wünsche: `_Gemeinsam/BAUSTEIN-WUENSCHE.md`.

| Datei | Bausteine |
|---|---|
| `KlarGlas.swift` | `KlarGlas.version`, `Theme`, `KlarGlasHaken`, `Color.appFlaeche/accentText/accentSoft/onAccent/hex`, `SectionLabel`, `card()`, `glasFlaeche()`, `kartenAktion()`, `formSheet()`, `BottomBar`, `AdaptiveStack`, `Darstellung`, `fensterTint()` |
| `Startseite.swift` | `Gruss` (ohne Namen, E2), `StartTitel`, `KartenKopf`, `WeiterspielenKarte` (mit Menü „Partie verwerfen“ + Rückfrage), `Fortschrittsbalken`, `TagesKarte`, `AuswahlZeile`, `StatistikZeile` |
| `Knoepfe.swift` | `hauptKnopf()`, `zweitKnopf()`, `AkzentPilleStil`, `RundKnopf`, **`RundKnopfMenue`** (2.1), `StatusPille`, **`StatusChip`** |
| `Spiel.swift` | `SpielKopf` (links Home), `AktionsEintrag`/`AktionsLeiste`, **`SpielfeldKarte`**, `SpielerAvatar`, **`SpielerLeiste`** |
| `Hinweis.swift` | `ErklaerSheet` (Titel/Hinweis auch als `Text`, 2.1), **`HinweisKarte`** |
| `Ende.swift` | `RangEintrag`, `SiegerStand`, `SiegerBildschirm` (Motiv, Stand, Teilen oben links), **`ZwischenstandBildschirm`** |
| `Einstellungen.swift` | `EinstellungsGruppe`, `EinstellungsKopf`, `DarstellungsAuswahl`, **`einstellungsSchalter()`** (Systemgrün, 2.1), **`einstellungsSchliessen()`** (Schließen-Rundknopf, 2.2) |
| `NeuesSpiel.swift` | **`NeuesSpielBlatt`**, `NeuesSpielKarte`, **`StufenWahl`**, **`SpielerListe`** (`SpielerEintrag` mit `farbe`/`symbol`, `SpielerArt`; `avatarTippen:`, `zusatz:` seit 2.7) |
| `Tagesraetsel.swift` | `Tagesschluessel`, `TagesSerie` (Länge, Widget-Regel, Wochenpunkte, Seriezeile), **`TagesKalender`** |
| `TagesWidget.swift` | **`TagesWidgetKonfiguration.widget`**, `TagesWidgetSpeicher.schreibe` (App-Seite), Provider und Ansicht |
| `Zeitformat.swift` | **`Zeitformat.text`** („0:34“, „1:02:05“), `gesprochen` |
| `SpielSpeicher.swift` | **`SpielSpeicher`** (lädt tolerant, löscht nie), `DefaultsAblage`/`DateiAblage`/`FluechtigeAblage`, `KeyedDecodingContainer.wert(_:sonst:)`, **`spielSpeicherRueckfrage()`** |

Fett = die zwölf neuen Bausteine aus dem Design-Konzept 3.5. Texte: `Resources/Localizable.xcstrings` (de, en, es, fr).
Die Ansichten gibt es nur für iOS; Theme-Werte, Gruß, Zeit, Serie und Speicher bauen auch auf dem Mac (Tests).

## Produkt `Baukasten` (Funktionen)

| Datei | Funktion |
|---|---|
| `Akzent.swift` | wählbare App-Farbe (Familienfarben, kontrastgeprüft), `AkzentSpeicher`, `AkzentAuswahl` |
| `Trinkgeld.swift` | Trinkgeld als verbrauchbarer In-App-Kauf (StoreKit 2), `TrinkgeldAbschnitt` |
| `Bewertung.swift` | Regel, wann um Bewertung gebeten wird; System-Dialog per `requestReview` |
| `MehrVonMir.swift` | Querverweise auf eigene Apps (zentraler Katalog, App-Store-Blatt) |
| `UeberMich.swift` | „Über mich“ (Inhalt zentral) |
| `SpielDienste.swift` | Game Center, standardmäßig aus |
| `Erinnerung.swift` | tägliche Tagesrätsel-Erinnerung (lokal), `ErinnerungsZeile` |
| `Links.swift` | Webseiten-Adressen, Version, Bewerten-Link |
| `Konfiguration.swift` | `BaukastenKonfiguration` + `BaukastenUeberGruppe` (die fertige „Über“-Gruppe) |
| `Demo.swift` | Vorschau der Einstellungen (hell/dunkel/große Schrift) |

Wählbare App-Farbe mit KlarGlas verbinden (einmal beim Start):
`KlarGlasHaken.flaeche = { … gewählte Farbe … }`, `KlarGlasHaken.accentText = { … }`, dazu `.baukastenAkzent(farbe)` und `.fensterTint(farbe)`.

## Prüfen ohne Simulator

- `swift test` – Logik beider Produkte auf dem Mac.
- `xcodebuild -scheme KlarGlas -destination 'generic/platform=iOS Simulator' build` – kompiliert die Ansichten für iOS, startet nichts.
- Referenz-App: `_Gemeinsam/Vorlagen/Referenz/baue.sh` baut nur gegen das Paket (ohne Kopie).
