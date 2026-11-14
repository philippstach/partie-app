// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas

/// Anleitung zum Durchwischen (KlarGlas `AnleitungBlatt`); der Rahmen hängt die Regelseite als „Alle Regeln lesen“ an.
extension HanoiModul {
    static var anleitung: [AnleitungSchritt] { [
        AnleitungSchritt(symbol: "line.3.horizontal.decrease", titel: "Scheibe versetzen", text: "Tippe erst den Stab, von dem du nimmst, dann den Zielstab. Du darfst immer nur die oberste Scheibe nehmen.", geste: .tippen(UnitPoint(x: 0.2, y: 0.5))) { p, _ in
            GeometryReader { g in
                let s = anleitungAbschnitt(p, von: 0.25, bis: 0.75)
                let x0 = g.size.width * 0.2, x2 = g.size.width * 0.8
                ForEach(0..<3, id: \.self) { i in
                    Capsule().fill(Color.appFlaeche.opacity(0.3)).frame(width: 8, height: 130).position(x: g.size.width * (0.2 + 0.3 * Double(i)), y: g.size.height * 0.58)
                }
                ForEach(0..<3, id: \.self) { k in
                    let breite = CGFloat(110 - k * 30), fest = k > 0
                    Capsule().fill(Color.appFlaeche.opacity(1 - Double(k) * 0.2)).frame(width: breite, height: 22)
                        .position(x: fest ? x0 : x0 + (x2 - x0) * s, y: fest ? g.size.height * (0.78 - Double(k - 1) * 0.1) + 0 : g.size.height * 0.6 - 60 * sin(s * .pi) + 38 * s)
                }
            }
        },
        AnleitungSchritt(symbol: "xmark.octagon", titel: "Nie groß auf klein", text: "Eine größere Scheibe darf nie auf einer kleineren liegen.", geste: .keine) { p, _ in
            GeometryReader { g in
                Capsule().fill(Color.appFlaeche).frame(width: 50, height: 22).position(x: g.size.width * 0.5, y: g.size.height * 0.62)
                Capsule().fill(Color.appFlaeche.opacity(0.5)).frame(width: 110, height: 22)
                    .position(x: g.size.width * 0.5, y: g.size.height * (0.62 - 0.2 * anleitungAbschnitt(p, von: 0.1, bis: 0.4)))
                Image(systemName: "xmark.circle.fill").font(.title).foregroundStyle(.red)
                    .position(x: g.size.width * 0.5, y: g.size.height * 0.2).opacity(p > 0.4 ? 1 : 0)
            }
        },
        AnleitungSchritt(symbol: "number", titel: "Wenige Züge", text: "Mit n Scheiben schaffst du es in mindestens 2ⁿ − 1 Zügen.", geste: .keine) { p, _ in
            Text("2ⁿ − 1").font(.system(.largeTitle, design: Design.zahlDesign, weight: .bold).monospacedDigit()).foregroundStyle(Color.accentText).scaleEffect(1 + 0.05 * sin(p * .pi * 2))
        },
    ] }
}
#endif
