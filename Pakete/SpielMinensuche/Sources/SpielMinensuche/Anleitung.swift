// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas

/// Anleitung zum Durchwischen für den `SpielRahmen` (Regeln als Text stehen im Modul).
@MainActor
enum MinensucheAnleitung {
    private static func feld(_ zeilen: [[String]], p: Double = 1, flagge: Int? = nil) -> some View {
        VStack(spacing: 5) {
            ForEach(0..<zeilen.count, id: \.self) { r in
                HStack(spacing: 5) {
                    ForEach(0..<zeilen[r].count, id: \.self) { c in
                        let k = r * zeilen[r].count + c
                        if flagge == k {
                            AnleitungKachel("", groesse: 46, aufgedeckt: false).overlay(Image(systemName: "flag.fill").foregroundStyle(.white))
                        } else {
                            AnleitungKachel(zeilen[r][c] == "·" ? "" : zeilen[r][c], groesse: 46, aufgedeckt: zeilen[r][c] != "?")
                        }
                    }
                }
            }
        }
    }

    static let schritte: [AnleitungSchritt] = [
        AnleitungSchritt.ziel("Decke alle Felder ohne Mine auf, ohne auf eine Mine zu tippen."),
        AnleitungSchritt(symbol: "hand.tap.fill", titel: "Aufdecken",
                         text: "Tippen deckt ein Feld auf. Eine Zahl sagt, wie viele der acht Nachbarfelder eine Mine enthalten.",
                         geste: .tippen(UnitPoint(x: 0.5, y: 0.5))) { p, _ in
            feld(p > 0.5 ? [["?", "?", "?"], ["?", "2", "?"], ["?", "?", "?"]] : [["?", "?", "?"], ["?", "?", "?"], ["?", "?", "?"]])
        },
        AnleitungSchritt(symbol: "flag.fill", titel: "Fahne setzen",
                         text: "Drücke lange auf ein vermutetes Minenfeld, um eine Fahne zu setzen. Mit dem Fahnen-Knopf vertauschst du beides.",
                         geste: .halten(UnitPoint(x: 0.5, y: 0.5))) { p, _ in
            feld([["?", "?", "?"], ["?", "?", "?"], ["?", "?", "?"]], flagge: p > 0.8 ? 4 : nil)
        },
        AnleitungSchritt(symbol: "checkmark.shield.fill", titel: "Ohne Raten",
                         text: "Jedes Brett lässt sich durch Nachdenken lösen, und der erste Zug ist immer sicher.",
                         geste: .keine) { p, _ in
            feld([["1", "1", "?"], ["·", "1", "?"], ["·", "1", "1"]], p: p)
        },
    ]
}
