// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas

/// Anleitung zum Durchwischen (KlarGlas `AnleitungBlatt`); der Rahmen hängt die Regelseite als „Alle Regeln lesen“ an.
extension StufenstapelModul {
    static var anleitung: [AnleitungSchritt] { [
        AnleitungSchritt(symbol: "1.circle", titel: "Von 1 bis 10 bauen", text: "Auf einen leeren Stapel kommt die 1, dann die 2 und so weiter bis zur 10. Der Stern ersetzt jede Zahl.", geste: .tippen(UnitPoint(x: 0.5, y: 0.5))) { p, _ in
            HStack(spacing: 14) {
                ForEach(Array(["1.circle", "2.circle", "3.circle"].enumerated()), id: \.offset) { i, name in
                    let t = anleitungAbschnitt(p, von: 0.1 + Double(i) * 0.15, bis: 0.6 + Double(i) * 0.1)
                    Image(systemName: name).font(.title).foregroundStyle(.white)
                        .frame(width: 58, height: 76).background(Color.appFlaeche.opacity(0.5 + 0.5 * t), in: .rect(cornerRadius: 10))
                        .offset(y: CGFloat(1 - t) * 24).opacity(0.3 + 0.7 * t)
                }
            }
        },
        .bild(symbol: "hand.point.up.left.fill", titel: "Karte, dann Stapel", text: "Tippe zuerst eine Karte an, dann den Stapel, auf den sie soll. Quellen: Vorrat, Hand oder Ablagen.", bild: "hand.point.up.left.fill", geste: .keine),
        .bild(symbol: "tray.full.fill", titel: "Ablage beendet den Zug", text: "Dein Zug endet, wenn du eine Handkarte auf eine deiner drei Ablagen legst. Wer seinen Vorrat zuerst leert, gewinnt.", bild: "tray.full.fill", geste: .keine),
    ] }
}
#endif
