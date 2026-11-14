// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

/// Anleitung zum Durchwischen für den `SpielRahmen` (der ausführliche Regeltext steht im Modul).
@MainActor
enum SudokuAnleitung {
    static let schritte: [AnleitungSchritt] = [
        AnleitungSchritt.ziel("Fülle das ganze Gitter mit den Zahlen 1 bis 9, sodass jede in jeder Zeile, Spalte und jedem 3×3-Kästchen einmal steht."),
        AnleitungSchritt(symbol: "square.grid.3x3", titel: "Jede Zahl nur einmal",
                         text: "Jede Zahl von 1 bis 9 darf in jeder Zeile, jeder Spalte und jedem 3×3-Kästchen nur einmal vorkommen.",
                         geste: .keine) { p, _ in
            VStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { r in
                    HStack(spacing: 5) {
                        ForEach(0..<3, id: \.self) { c in
                            let n = r * 3 + c + 1
                            AnleitungKachel(Double(n) <= p * 11 ? "\(n)" : "", groesse: 46, hervorgehoben: Double(n) > p * 11 - 1 && Double(n) <= p * 11)
                        }
                    }
                }
            }
        },
        AnleitungSchritt(symbol: "hand.tap", titel: "Zahl eintragen",
                         text: "Tippe ein Feld an, dann die Ziffer. Die fest gedruckten Zahlen bleiben, und jedes Rätsel hat genau eine Lösung.",
                         geste: .tippen(UnitPoint(x: 0.5, y: 0.4))) { p, _ in
            VStack(spacing: 14) {
                HStack(spacing: 5) {
                    AnleitungKachel("3"); AnleitungKachel(p > 0.5 ? "7" : "", hervorgehoben: p < 0.5); AnleitungKachel("5")
                }
                HStack(spacing: Design.Abstand.xs) {
                    ForEach([1, 4, 7, 9], id: \.self) { n in AnleitungKachel("\(n)", groesse: 34, hervorgehoben: n == 7 && p > 0.3 && p < 0.5) }
                }
            }
        },
        AnleitungSchritt(symbol: "pencil", titel: "Notizen",
                         text: "Schalte „Notizen“ ein, um kleine Merkzahlen in ein Feld zu schreiben. Setzt du eine Zahl, verschwindet sie aus den Notizen der Nachbarn.",
                         geste: .keine) { p, _ in
            RoundedRectangle(cornerRadius: Theme.feldRadius).fill(Tisch.aktiv ? Tisch.elfenbein : Color(.systemBackground)).frame(width: 130, height: 130)
                .overlay {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: Design.Abstand.xs) {
                        ForEach(1...9, id: \.self) { n in
                            Text(Double(n) <= p * 9 && [2, 4, 6, 9].contains(n) ? "\(n)" : "").font(.system(.subheadline, design: Design.zahlDesign).bold())
                                .foregroundStyle(Color.accentText)
                        }
                    }.padding(12)
                }
        },
    ]

    /// Neue deutsche Fassung (Regeltexte neu, Build 25) ohne die Zielseite (`mitZielSchrittNeu`): Bühnen wie heute, drei neue Seiten mit Figuren.
    static let schritteNeu: [AnleitungSchritt] = [
        AnleitungSchritt.figuren(symbol: "square.grid.3x3", titel: "Drei Spielarten",
                                 text: "Klassisch spielst du mit 9 × 9 Feldern und den Zahlen 1 bis 9. Das Kinder-Sudoku hat 6 × 6 Felder und die Zahlen 1 bis 6, gut zum Einstieg. Beim X-Sudoku müssen zusätzlich die beiden Diagonalen jede Zahl einmal enthalten. Die Stufen gehen von Leicht bis Experte.",
                                 figuren: ["9️⃣", "6️⃣", "✖️"]),
        AnleitungSchritt(symbol: "hand.tap", titel: "Zahl eintragen",
                         text: "Tippe ein leeres Feld an, dann unten die Zahl. Tippst du dieselbe Zahl noch einmal, verschwindet sie. Unten siehst du auch, wie oft jede Zahl noch fehlt. Mit „Rückgängig“ nimmst du den letzten Schritt zurück. Eine falsche Zahl wird rot.",
                         geste: .tippen(UnitPoint(x: 0.5, y: 0.4))) { p, _ in
            VStack(spacing: 14) {
                HStack(spacing: 5) {
                    AnleitungKachel("3"); AnleitungKachel(p > 0.5 ? "7" : "", hervorgehoben: p < 0.5); AnleitungKachel("5")
                }
                HStack(spacing: Design.Abstand.xs) {
                    ForEach([1, 4, 7, 9], id: \.self) { n in AnleitungKachel("\(n)", groesse: 34, hervorgehoben: n == 7 && p > 0.3 && p < 0.5) }
                }
            }
        },
        AnleitungSchritt(symbol: "pencil", titel: "Notizen",
                         text: "Schalte „Notizen“ ein, um kleine Merkzahlen in ein Feld zu schreiben: Zahlen, die dort noch passen könnten. Setzt du später eine echte Zahl, streicht die App sie aus den Notizen der Nachbarn. Unter „Mehr“ füllt „Notizen füllen“ alle leeren Felder auf einmal.",
                         geste: .keine) { p, _ in
            RoundedRectangle(cornerRadius: Theme.feldRadius).fill(Tisch.aktiv ? Tisch.elfenbein : Color(.systemBackground)).frame(width: 130, height: 130)
                .overlay {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: Design.Abstand.xs) {
                        ForEach(1...9, id: \.self) { n in
                            Text(Double(n) <= p * 9 && [2, 4, 6, 9].contains(n) ? "\(n)" : "").font(.system(.subheadline, design: Design.zahlDesign).bold())
                                .foregroundStyle(Color.accentText)
                        }
                    }.padding(12)
                }
        },
        AnleitungSchritt.figuren(symbol: "lightbulb", titel: "Fehler und Tipp",
                                 text: "Eine Zahl, die nicht zur Lösung passt, zählt als Fehler. Nach drei Fehlern kannst du zum letzten fehlerfreien Stand zurück oder einfach weiterspielen. Verlieren kannst du nicht. Der Tipp zeigt dir das nächste Feld und erklärt, warum die Zahl dorthin gehört. Mit Tipp gibt es aber keine Bestzeit.",
                                 figuren: ["❌", "❌", "❌", "→", "↩️"]),
        AnleitungSchritt.figuren(symbol: "calendar", titel: "Tagesrätsel und Lernweg",
                                 text: "Jeden Tag wartet ein Tagesrätsel, und deine Serie wächst. Im Lernweg übst du die Tricks der Profis Schritt für Schritt. Ein Rätsel aus der Zeitung tippst du als eigenes Rätsel ab, die App prüft es und hilft dir beim Lösen. Höhere Stufen öffnen sich nach drei Rätseln ohne Tipp.",
                                 figuren: ["📅", "🎓", "✏️"]),
    ]
}
