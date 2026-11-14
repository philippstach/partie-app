// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas

/// Anleitung zum Durchwischen (KlarGlas `AnleitungBlatt`); der Rahmen hängt die Regelseite als „Alle Regeln lesen“ an.
extension DauerlaufModul {
    static var anleitung: [AnleitungSchritt] { [
        AnleitungSchritt(symbol: "arrow.up", titel: "Springen", text: "Dein Läufer rennt von allein und wird schneller. Tippe aufs Feld, um zu springen: über Hürden und über Löcher.", geste: .tippen(UnitPoint(x: 0.5, y: 0.5))) { p, _ in
            GeometryReader { g in
                let w = g.size.width, h = g.size.height
                let boden = h * 0.75
                let sprung = anleitungAbschnitt(p, von: 0.3, bis: 0.5) * (1 - anleitungAbschnitt(p, von: 0.5, bis: 0.7))
                Rectangle().fill(Color.appFlaeche.opacity(0.3)).frame(width: w, height: 4).position(x: w / 2, y: boden + 12)
                RoundedRectangle(cornerRadius: 4).fill(Color.appFlaeche).frame(width: 18, height: 34).position(x: w * (0.78 - 0.5 * p), y: boden - 6)
                Circle().fill(Color.appFlaeche).frame(width: 28, height: 28).position(x: w * 0.3, y: boden - 20 - 70 * sprung)
            }
        },
        AnleitungSchritt(symbol: "arrow.down", titel: "Ducken", text: "Wische nach unten, um dich zu ducken, wenn ein Balken in der Luft hängt.", geste: .wischen(von: UnitPoint(x: 0.5, y: 0.35), nach: UnitPoint(x: 0.5, y: 0.65))) { p, _ in
            GeometryReader { g in
                let w = g.size.width, h = g.size.height
                let boden = h * 0.75
                let duck = anleitungAbschnitt(p, von: 0.35, bis: 0.5) * (1 - anleitungAbschnitt(p, von: 0.6, bis: 0.75))
                Rectangle().fill(Color.appFlaeche.opacity(0.3)).frame(width: w, height: 4).position(x: w / 2, y: boden + 12)
                RoundedRectangle(cornerRadius: 4).fill(Color.appFlaeche).frame(width: 90, height: 14).position(x: w * (0.85 - 0.6 * p), y: boden - 34)
                Capsule().fill(Color.appFlaeche).frame(width: 28, height: 52 - 22 * duck).position(x: w * 0.3, y: boden - (52 - 22 * duck) / 2 + 10)
            }
        },
        .bild(symbol: "circle.fill", titel: "Perlen sammeln", text: "Sammle die Perlen auf dem Weg, jede bringt zehn Punkte extra. Stößt du an oder fällst du in ein Loch, ist der Lauf vorbei.", bild: "circle.hexagongrid.fill", geste: .keine),
    ] }
}
#endif
