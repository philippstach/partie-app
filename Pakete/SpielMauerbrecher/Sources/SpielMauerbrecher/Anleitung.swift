// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas

/// Anleitung zum Durchwischen (KlarGlas `AnleitungBlatt`); der Rahmen hängt die Regelseite als „Alle Regeln lesen“ an.
extension MauerbrecherModul {
    static var anleitung: [AnleitungSchritt] { [
        AnleitungSchritt(symbol: "hand.draw", titel: "Schläger lenken", text: "Lenke den Schläger mit dem Finger und lass den Ball nicht fallen. Tippe, um den Ball abzuschießen. Jeder Treffer bricht einen Stein.", geste: .wischen(von: UnitPoint(x: 0.35, y: 0.88), nach: UnitPoint(x: 0.65, y: 0.88))) { p, _ in
            GeometryReader { g in
                let w = g.size.width, h = g.size.height
                let bx = w * (0.5 + 0.2 * sin(p * .pi * 2)), by = h * (0.62 - 0.4 * abs(sin(p * .pi * 2)))
                VStack(spacing: Design.Abstand.xs) { ForEach(0..<3, id: \.self) { r in HStack(spacing: Design.Abstand.xs) { ForEach(0..<6, id: \.self) { c in
                    RoundedRectangle(cornerRadius: 4).fill(Color.appFlaeche.opacity(r == 2 && c == 2 && p > 0.25 ? 0.05 : 0.35 + Double(r) * 0.2)).frame(width: 40, height: 16) } } } }
                    .position(x: w / 2, y: h * 0.2)
                Capsule().fill(Color.appFlaeche).frame(width: 80, height: 12).position(x: w * (0.5 + 0.2 * sin(p * .pi * 2)), y: h * 0.88)
                Circle().fill(Color(.systemBackground)).shadow(radius: 2, y: 1).frame(width: 14, height: 14).position(x: bx, y: by)
            }
        },
        AnleitungSchritt(symbol: "gift", titel: "Gaben fangen", text: "Aus Steinen fallen manchmal Gaben: breiter Schläger, drei Bälle oder ein Extraleben. Fange sie mit dem Schläger.", geste: .keine) { p, _ in
            HStack(spacing: 18) {
                ForEach(Array(["arrow.left.and.right", "circle.grid.3x3.fill", "heart.fill"].enumerated()), id: \.offset) { i, name in
                    let t = anleitungAbschnitt(p, von: 0.1 + Double(i) * 0.1, bis: 0.8)
                    Image(systemName: name).font(.title).foregroundStyle(.white)
                        .frame(width: 56, height: 56).background(Color.appFlaeche, in: .circle).offset(y: CGFloat(t) * 50 - 25)
                }
            }
        },
        .bild(symbol: "arrow.down.to.line", titel: "Die Mauer rückt vor", text: "Die Mauer rückt langsam nach unten; erreicht sie den Schläger, ist das Spiel aus. Du hast drei Leben.", bild: "arrow.down.to.line", geste: .keine),
    ] }
}
#endif
