# Partie

**77 klassische Spiele in einer iOS-App.** Brett-, Karten-, Würfel-, Rätsel- und Arcade-Spiele, von Backgammon und Mahjong-Paaren bis Sudoku, Solitär und einem täglichen Worträtsel. Ohne Werbung, ohne Tracking, ohne Konto.

[English](README.md) · [App Store](#) · [Mitmachen](CONTRIBUTING.md)

## Was Partie kann

- 72 Spiele und 5 Arcade-Spiele, alle offline spielbar
- Gegen den Computer oder reihum am selben Gerät
- Tagesrätsel, Statistik je Spieler, Widgets
- Deutsch, Englisch, Spanisch und Französisch
- Nur mit Apples Bausteinen gebaut: Swift, SwiftUI, Swift Charts, WidgetKit. Keine fremden Bibliotheken.

## Bauen

Voraussetzungen: Xcode 26 oder neuer, iOS 17, [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
cp Lokal.xcconfig.beispiel Lokal.xcconfig   # eigene Team-ID und Bundle-Präfix eintragen
xcodegen
open Partie.xcodeproj
```

Jedes Spiel ist ein eigenes Swift-Paket in `Pakete/` und lässt sich mit `swift test` allein prüfen.

## Mitmachen

Neue Spiele, Fehlerkorrekturen und Übersetzungen sind willkommen. Wie man ein neues Spielpaket baut, steht in [CONTRIBUTING.md](CONTRIBUTING.md). Jeder Commit braucht eine `Signed-off-by`-Zeile ([DCO](https://developercertificate.org)). Wer ein Spiel beisteuert, wird in der App genannt.

## Lizenz

- **Code:** [MIT](LICENSE)
- **Inhalte** (Rätsel, Wortlisten, Töne, Spielsymbole, Texte): [CC BY 4.0](LICENSE-INHALTE.md)
- Der Name „Partie“, das Logo und das App-Symbol fallen nicht unter diese Lizenzen.

Woher die Inhalte stammen, steht in [HERKUNFT.md](HERKUNFT.md). Partie wurde mit Hilfe von KI-Werkzeugen entwickelt.

© 2026 Philipp Stach und Mitwirkende
