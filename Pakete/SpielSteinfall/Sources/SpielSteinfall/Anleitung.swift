// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas

/// Anleitung zum Durchwischen (KlarGlas `AnleitungBlatt`); der Rahmen hängt die Regelseite als „Alle Regeln lesen“ an.
extension SteinfallModul {
    static var anleitung: [AnleitungSchritt] { [
        AnleitungSchritt(symbol: "square.grid.3x3.fill", titel: "Reihe auflösen", text: "Fünferteile fallen in ein Feld. Ist eine Reihe lückenlos gefüllt, löst sie sich auf und bringt Punkte – mehrere Reihen zugleich bringen deutlich mehr.", geste: .keine) { p, _ in
            GeometryReader { g in
                let w = g.size.width, h = g.size.height
                let z: CGFloat = 26
                let fall = anleitungAbschnitt(p, von: 0.1, bis: 0.6)
                ZStack(alignment: .topLeading) {
                    Color.clear
                    ForEach(0..<5, id: \.self) { c in RoundedRectangle(cornerRadius: 5).fill(Color.appFlaeche.opacity(p > 0.7 ? 0 : 0.6)).frame(width: z, height: z).offset(x: CGFloat(c) * (z + 2), y: 5 * (z + 2)) }
                    ForEach(0..<5, id: \.self) { c in RoundedRectangle(cornerRadius: 5).fill(Color.appFlaeche.opacity(c == 2 && p < 0.6 ? 0 : 0.35)).frame(width: z, height: z).offset(x: CGFloat(c) * (z + 2), y: 6 * (z + 2)) }
                    ForEach(0..<2, id: \.self) { k in RoundedRectangle(cornerRadius: 5).fill(Color.appFlaeche).frame(width: z, height: z).offset(x: 2 * (z + 2), y: (CGFloat(fall) * 5 + CGFloat(k) * 0 - 5) * (z + 2) + (z + 2) * CGFloat(k) + 0) }
                }
                .frame(width: 5 * (z + 2), height: 7 * (z + 2)).position(x: w / 2, y: h / 2)
            }
        },
        AnleitungSchritt(symbol: "arrow.left.and.right", titel: "Schieben und drehen", text: "Verschiebe die Teile, drehe sie und lass sie landen. Ein gelandetes Teil lässt sich noch kurz verschieben.", geste: .keine) { p, _ in
            HStack(spacing: 28) {
                Image(systemName: "arrow.left.and.right").font(.largeTitle).foregroundStyle(Color.appFlaeche).offset(x: CGFloat(sin(p * .pi * 2)) * 8)
                Image(systemName: "arrow.clockwise").font(.largeTitle).foregroundStyle(Color.appFlaeche).rotationEffect(.degrees(p * 360))
                Image(systemName: "arrow.down.to.line").font(.largeTitle).foregroundStyle(Color.appFlaeche).offset(y: CGFloat(abs(sin(p * .pi * 2))) * 8)
            }
        },
    ] }
}
#endif
