# Design der Sammlung („Spieleabend“)

Partie nutzt das Designsystem **Klar & Glas** aus `Pakete/Baukasten` (Produkt `KlarGlas`). Hier steht, was die Sammlung darüber hinaus festlegt.
Neue Bildschirme und Spiele verwenden die vorhandenen Bausteine; eigene Themes oder kopierte Bausteine gibt es nicht.

## Fünf Regeln

1. **Die Hülle ist Nachtblau** (`AkzentFarbeWert.nachtblau`, `#1F3A5F`): Titel, Hauptknopf, Tischgrund, Tint.
2. **Farbe = Spielart.** Sechs feste Farben (`Gattung.farbe`): Karten Rot, Würfel Indigo, Brett Türkis, Rätsel Blau, Wort Pink, Arcade Orange.
   Im Spiel gelten Kopf, Knöpfe und Ende in der Spielart-Farbe (`Spielfarbe.geteilt.aktuell = modul.gattung.farbe`).
   Die eigene `farbe` eines Moduls wird nur noch für das App-Symbol einiger älterer Spiele genutzt.
3. **Spielmaterial statt Symbol.** Jedes Spiel zeigt eine gezeichnete Miniatur (`Miniatur`, `MiniaturAnsicht` in KlarGlas), etwa Kartenfächer,
   Würfel, Brett, Zahlengitter oder Buchstaben. Zuordnung in `App/SpielMiniaturen.swift`; fehlt ein Eintrag, gilt `Gattung.miniatur`.
4. **Ein Knopf unten.** Der Start hat genau einen Hauptknopf „Neues Spiel“ (`hauptKnopf(hell: true)`). Zufall, „Was spielen wir?“ und Glossar
   liegen im Würfel-Menü, die Suche hinter der Lupe.
5. **Dunkel ist der Start, hell sind die Blätter.** Nur der Sammlungs-Start liegt auf dem dunklen Tisch (`spieleabendGrund`); alle Blätter sind
   normale helle Klar-&-Glas-Blätter mit `SpielZeile(hell:)`.

## Bildschirme

| Bildschirm | Aufbau |
|---|---|
| Start (`SammlungStart`) | Rundknöpfe (Einstellungen, Suche, Spieler, Würfel-Menü) · `StartTitel` · `WeiterspielenKarte` · `FilterChip`-Reihe (Alle, Favoriten, Spielarten, eigene Listen, Spieler, Zeit, Sortierung) · `SpielZeile` je Spiel, neue Spiele mit „Neu“-Marke (`SammlungStart.neueSpiele`) · `StatistikZeile` · Hauptknopf |
| Neues Spiel (`SpielWahlBlatt`) | Favoriten zuerst, dann Gruppen je Spielart (`SpielartLabel`) |
| Suche (`SpielSucheBlatt`) | Suchfeld, Apple-Intelligence-Suche ab 8 Zeichen, Herkunft, Sortierung |
| Was spielen wir (`WasSpielenWirBlatt`) | Freitext „Worauf habt ihr Lust?“ (Apple Intelligence, Rückfall `WunschDeuter`), Spielerzahl, Zeit, Vorschläge |
| Spielprofil (`SpielProfilBlatt`) | `SpielBild` · Name · `SpielartLabel` · Kurzregel · Werte · Spielen · Favorit |
| Spieler (`SpielerSeite`) | Karten je Person, Tippen öffnet `SpielerStatistikBlatt` |
| Statistik (`StatistikSeite`) | Kennzahlen, Partien je Woche, nach Spielart, Verlauf, Siegquote je Spiel |
| Glossar (`GlossarBlatt`) | Spielbegriffe nach Spielart, mit Suche |
| Spielstart (`SpielRahmen`) | `StartTitel` in Spielart-Farbe · `SpielBild` · Würfelwahl · Statistik · Hauptknopf |
| Ende (`SpielRahmen`) | `SiegerBildschirm` mit `SpielBild` und Pokal; Spiele mit eigenem Material (Solitär, Rauswurf, Viererreihe) zeigen dieses |

## Haken der Hülle (in `PartieApp.init`)

- `KlarGlasHaken.flaeche` / `.accentText`: Spielart-Farbe im Spiel, Nachtblau in der Sammlung.
- `SpielRahmenHaken.bild`: liefert zu einer Spiel-ID Spielart-Farbe und Miniatur (Spielstart, Neues-Spiel-Blatt, Ende).
- `\.farbenUnterscheidbar` (Einstellungen › Aussehen): zeigt Spielart-Zeichen (`Gattung.zeichen`) zusätzlich zur Farbe; Spiele dürfen den Wert lesen und Muster statt Farben zeigen.

## App-Symbole

Jedes Spiel hat ein Wechsel-Symbol `Symbol-<id>` (1024 px, Spielart-Fläche mit Miniatur) und eine Vorschau `Vorschau-<id>` (180 px).
Ein neues Spiel braucht beides und einen Eintrag in `project.yml` (`ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES`).
