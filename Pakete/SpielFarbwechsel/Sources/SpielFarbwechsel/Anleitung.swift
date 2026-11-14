// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas

/// Anleitung zum Durchwischen (KlarGlas `AnleitungBlatt`); der Rahmen hängt die Regelseite als „Alle Regeln lesen“ an.
extension FarbwechselModul {
    static var anleitung: [AnleitungSchritt] { [
        AnleitungSchritt(symbol: "rectangle.on.rectangle", titel: "Passende Karte legen", text: "Lege eine Karte mit derselben Farbe oder Zahl wie die oberste. Passt nichts, ziehst du eine.", geste: .tippen(UnitPoint(x: 0.5, y: 0.5))) { p, _ in
            HStack(spacing: 14) {
                ForEach(Array(["heart.fill", "arrow.right", "heart.fill"].enumerated()), id: \.offset) { i, name in
                    let t = anleitungAbschnitt(p, von: 0.1 + Double(i) * 0.15, bis: 0.6 + Double(i) * 0.1)
                    Image(systemName: name).font(.title).foregroundStyle(.white)
                        .frame(width: 58, height: 76).background(Color.appFlaeche.opacity(0.5 + 0.5 * t), in: .rect(cornerRadius: 10))
                        .offset(y: CGFloat(1 - t) * 24).opacity(0.3 + 0.7 * t)
                }
            }
        },
        .bild(symbol: "forward.end.fill", titel: "Aktionskarten", text: "Sprung lässt den Nächsten aussetzen, Wende kehrt die Richtung um, Zwei ziehen gibt dem Nächsten zwei Karten.", bild: "arrow.triangle.2.circlepath", geste: .keine),
        .bild(symbol: "paintpalette.fill", titel: "Joker", text: "Der Joker passt immer und wählt die neue Farbe. Wer zuerst keine Karten mehr hat, gewinnt.", bild: "sparkles", geste: .keine),
    ] }
}
#endif
