// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas

/// Anleitung zum Durchwischen (KlarGlas `AnleitungBlatt`); der Rahmen hängt die Regelseite als „Alle Regeln lesen“ an.
extension WolkenhuepferModul {
    static var anleitung: [AnleitungSchritt] { [
        AnleitungSchritt(symbol: "cloud", titel: "Von Wolke zu Wolke", text: "Dein Hüpfer springt von allein. Ziehe den Finger nach links und rechts, um ihn zu lenken – am Rand kommst du auf der anderen Seite wieder heraus.", geste: .wischen(von: UnitPoint(x: 0.35, y: 0.6), nach: UnitPoint(x: 0.65, y: 0.6))) { p, _ in
            GeometryReader { g in
                let w = g.size.width, h = g.size.height
                let hoch = 0.5 - 0.5 * cos(p * .pi * 2)
                ForEach(0..<3, id: \.self) { i in
                    Capsule().fill(i == 1 ? Color.blue.opacity(0.6) : (i == 2 ? Color.gray.opacity(0.5) : Color(.systemBackground))).shadow(radius: 2, y: 1)
                        .frame(width: 70, height: 16).position(x: w * [0.3, 0.65, 0.45][i], y: h * [0.85, 0.55, 0.25][i])
                }
                Circle().fill(Color.appFlaeche).frame(width: 26, height: 26).position(x: w * 0.4, y: h * (0.78 - 0.3 * hoch))
            }
        },
        .bild(symbol: "cloud.fill", titel: "Weiß, blau, grau", text: "Weiße Wolken tragen immer, blaue wandern hin und her, graue brechen nach dem Sprung weg. Die gelbe Feder schleudert dich besonders hoch.", bild: "cloud.fill", geste: .keine),
    ] }
}
#endif
