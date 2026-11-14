// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas

/// Anleitung (Klondike, das bekannteste Solitär) zum Durchwischen; die Regeln aller sieben Spiele stehen dahinter (`RulesDetailView`).
struct RulesView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        AnleitungBlatt(titel: "Solitär", schritte: Self.schritte, fertig: { dismiss() }) { NavigationStack { RulesDetailView() }.presentationDetents([.large]) }
    }

    static let schritte: [AnleitungSchritt] = [
        AnleitungSchritt(symbol: "target", titel: "Ziel",
                         text: "Lege alle Karten nach Farben sortiert von Ass bis König auf die vier Zielstapel.",
                         geste: .keine) { p, _ in
            HStack(spacing: 10) {
                ForEach(0..<4, id: \.self) { i in
                    ZStack {
                        RoundedRectangle(cornerRadius: Design.Ecke.klein).stroke(Color.appFlaeche.opacity(0.5), style: .init(lineWidth: 2, dash: [5])).frame(width: 54, height: 76)
                        if i == 0 {
                            let n = min(3, Int(p * 4))
                            ForEach(0..<n, id: \.self) { k in
                                AnleitungKarte(["A", "2", "3"][k], "♥", breite: 54).offset(y: CGFloat(k) * -3)
                            }
                        }
                    }
                }
            }
        },
        AnleitungSchritt(symbol: "hand.draw", titel: "Karten anlegen",
                         text: "Lege absteigend und abwechselnd rot und schwarz an, zum Beispiel die Herz-9 auf die Pik-10. Ganze passende Reihen darfst du gemeinsam verschieben.",
                         geste: .ziehen(von: UnitPoint(x: 0.7, y: 0.5), nach: UnitPoint(x: 0.34, y: 0.58))) { p, _ in
            GeometryReader { g in
                let s = anleitungAbschnitt(p, von: 0.2, bis: 0.8)
                AnleitungKarte("10", "♠", rot: false, breite: 60).position(x: g.size.width * 0.34, y: g.size.height * 0.45)
                AnleitungKarte("9", "♥", breite: 60)
                    .position(x: g.size.width * (0.7 - 0.36 * s), y: g.size.height * (0.4 + 0.18 * s))
            }
        },
        AnleitungSchritt(symbol: "rectangle.stack", titel: "Stapel ziehen",
                         text: "Geht nichts mehr, tippe auf den Stapel und decke eine neue Karte auf.",
                         geste: .tippen(UnitPoint(x: 0.36, y: 0.5))) { p, _ in
            HStack(spacing: Design.Abstand.xl) {
                AnleitungKarte("", breite: 60, verdeckt: true)
                if p > 0.5 { AnleitungKarte("Q", "♣", rot: false, breite: 60) } else { Color.clear.frame(width: 60, height: 84) }
            }
        },
    ]
}
