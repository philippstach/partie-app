# Partie

**77 classic games in one iOS app.** Board, card, dice, puzzle and arcade games, from Backgammon and Mahjong pairs to Sudoku, Solitaire and a daily word puzzle. No ads, no tracking, no account.

[Deutsch](README.de.md) · [App Store](#) · [Contributing](CONTRIBUTING.md)

<!-- Screenshots: start screen, one board game, one puzzle -->

## Features

- 72 games plus 5 arcade games, all playable offline
- Play against the computer or pass the phone around
- Daily puzzles, statistics per player, widgets
- German, English, Spanish and French
- Built entirely with Apple frameworks: Swift, SwiftUI, Swift Charts, WidgetKit. No third-party libraries.

## Building

Requirements: Xcode 26 or newer, iOS 17 deployment target, [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
cp Lokal.xcconfig.beispiel Lokal.xcconfig   # add your own Team ID and bundle prefix
xcodegen
open Partie.xcodeproj
```

Each game is its own Swift package in `Pakete/` and can be tested on its own with `swift test`.

## Project structure

| Folder | Content |
|---|---|
| `App/` | The app shell: start screen, settings, players, statistics |
| `Pakete/SpieleKern`, `ArcadeKern` | Shared game logic and UI frame |
| `Pakete/Baukasten` | The "Klar & Glas" design system |
| `Pakete/Spiel*` | One package per game |
| `Widget/` | Home screen widgets |
| `Werkzeug/` | Generators and translation scripts |

**A note on language:** the code, comments and commit messages are in German. Issues and pull requests are welcome in English or German.

## Contributing

New games, bug fixes and translations are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for how to build a new game package. Every commit needs a `Signed-off-by` line ([DCO](https://developercertificate.org)). Contributors of a game are credited in the app.

## License

- **Code:** [MIT](LICENSE)
- **Content** (puzzles, word lists, sounds, game icons, texts): [CC BY 4.0](LICENSE-INHALTE.md)
- The name "Partie", the logo and the app icon are not covered by these licenses.

Where the content comes from is documented in [HERKUNFT.md](HERKUNFT.md). Partie was developed with the help of AI tools.

© 2026 Philipp Stach and contributors
