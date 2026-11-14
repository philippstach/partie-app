// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas

/// Anleitung zum Durchwischen (KlarGlas `AnleitungBlatt`); der Rahmen hängt die Regelseite als „Alle Regeln lesen“ an.
extension BallwechselModul {
    static var anleitung: [AnleitungSchritt] { [
        AnleitungSchritt(symbol: "hand.draw", titel: "Schläger bewegen", text: "Ziehe den Finger, um den Schläger zu bewegen – er folgt dir, so schnell er kann. Schlage den Ball zurück und lass ihn beim Gegner durch.", geste: .wischen(von: UnitPoint(x: 0.35, y: 0.9), nach: UnitPoint(x: 0.65, y: 0.9))) { p, _ in
            GeometryReader { g in
                let w = g.size.width, h = g.size.height
                let bx = w * (0.5 + 0.28 * sin(p * .pi * 2)), by = h * (0.5 - 0.3 * cos(p * .pi * 4))
                Capsule().fill(Color.appFlaeche.opacity(0.4)).frame(width: 70, height: 10).position(x: w * (0.5 - 0.2 * sin(p * .pi * 2 + 0.6)), y: h * 0.1)
                Capsule().fill(Color.appFlaeche).frame(width: 70, height: 12).position(x: w * (0.5 + 0.26 * sin(p * .pi * 2 + 0.3)), y: h * 0.9)
                Circle().fill(Color(.systemBackground)).shadow(radius: 2, y: 1).frame(width: 16, height: 16).position(x: bx, y: by)
            }
        },
        AnleitungSchritt(symbol: "arrow.up.right", titel: "Kante macht schräg", text: "Trifft der Ball die Kante des Schlägers, fliegt er schräger und schneller weg. Jeder Schlag macht ihn schneller.", geste: .keine) { p, _ in
            GeometryReader { g in
                let w = g.size.width, h = g.size.height
                let t = anleitungAbschnitt(p, von: 0.1, bis: 0.9)
                Capsule().fill(Color.appFlaeche).frame(width: 90, height: 12).position(x: w * 0.4, y: h * 0.85)
                Circle().fill(Color(.systemBackground)).shadow(radius: 2, y: 1).frame(width: 16, height: 16)
                    .position(x: w * (0.46 + 0.4 * max(0, t - 0.5) * 2), y: t < 0.5 ? h * (0.2 + 0.6 * t * 2) : h * (0.8 - 0.6 * (t - 0.5) * 2))
            }
        },
        .bild(symbol: "7.circle", titel: "Sieben Punkte", text: "Wer zuerst sieben Punkte hat, gewinnt. Zu zweit zieht der zweite Spieler im oberen Feld.", bild: "7.circle.fill", geste: .keine),
    ] }
}
#endif
