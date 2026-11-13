# Herkunft der Inhalte

Stand der Prüfung: 08.11.2026. Alle Inhalte von Partie sind eigens für Partie oder ihre Vorgänger-Apps (Einzel-Apps von Philipp Stach, 2026) erstellt. Es wurden keine Inhalte aus fremden Quellen übernommen. Sie stehen unter CC BY 4.0 (siehe `LICENSE-INHALTE.md`).

| Inhalt | Ort | Herkunft | Beleg |
|---|---|---|---|
| Töne (64 Dateien) | `App/Ressourcen/Sounds/` | Per Skript aus Sinus- und Rauschanteilen berechnet (Python, nur `math` und `wave`), keine Aufnahmen, keine Klangbibliotheken. Keine Fremd-Metadaten in den Dateien. | `Werkzeug/Toene/make_sounds_*.py` (aus den Vorgänger-Apps 10k, Galgenmännchen, Schocken, Solitär, Sudoku, Vier gewinnt → Viererreihe, Mensch ärgere dich → Rauswurf, Kreuzworträtsel → Wortpfeil). **Offen:** Yacht, Skript fehlt im Archiv. |
| Galgenmännchen-Wörter (DE 637, EN 627) | `Pakete/SpielGalgenmaennchen/Shared/woerter/` | Eigene Liste, Entscheidung „Wortliste A (eigene)“ vom 04.10.2026. Freie Listen (Leipzig, SCOWL) wurden nicht verwendet. | Doku der Vorgänger-App |
| Wortpfeil-Rätsel (Wörter und Fragen) | `Pakete/SpielWortpfeil/Shared/raetsel/` | Wörter und Fragen mit KI geschrieben und in einem zweiten Durchgang geprüft, Gitter per eigenem Generator. Wiktionary und OpenThesaurus nur als Prüfwerkzeug, nichts übernommen. Keine Fragen aus fremden Rätselheften. | Doku Kreuzworträtsel, Entscheidung „Mischung (c)“ |
| Solitär-Partien und Lösungen | `Pakete/SpielSolitaer/Shared/partien/` | Per eigenem Löser berechnet | Code im Paket |
| Sudoku, Kakuro, Nonogramm, Brücken und weitere Rätsel | jeweiliges Paket | Per eigenem Generator erzeugt | Code im Paket |
| Länder- und Ortsdaten (Stadt Land Fluss, Ländermodi) | `App/Ressourcen/Daten/` | Allgemein bekannte Fakten (Namen, Hauptstädte), eigene Zusammenstellung | – |
| Spielsymbole `Symbol-*` | `App/Assets.xcassets/` | Für Partie und die Vorgänger-Apps erstellt | Logo- und Design-Doku; für neuere Symbole kein Skript im Repo |
| Texte, Anleitungen, Übersetzungen | `App/Ressourcen/Localizable.xcstrings` | Eigene Texte, Übersetzungen per Skript und KI | `Werkzeug/uebersetzungen_*.py` |
| Spielregeln | – | Traditionelle, gemeinfreie Spiele. Regeln sind nicht urheberrechtlich geschützt. Spielnamen bewusst neutral gewählt (keine Marken). | – |

**Nicht unter CC BY 4.0:** der Name „Partie“, das Partie-Logo und das App-Symbol (`AppIcon`).
