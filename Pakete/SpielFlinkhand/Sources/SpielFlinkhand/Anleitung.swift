// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas

/// Anleitung zum Durchwischen (KlarGlas `AnleitungBlatt`); der Rahmen hängt die Regelseite als „Alle Regeln lesen“ an.
extension FlinkhandModul {
    static var anleitung: [AnleitungSchritt] { [
        .bild(symbol: "square.stack.fill", titel: "Karten aufdecken", text: "Reihum legt jeder seine oberste Karte offen in die Mitte.", bild: "square.stack.3d.up.fill", geste: .keine),
        .bild(symbol: "hand.tap.fill", titel: "Schnapp!", text: "Liegen zwei gleiche Bilder direkt übereinander, drücke so schnell du kannst auf Schnapp!", bild: "hand.tap.fill", geste: .tippen(UnitPoint(x: 0.5, y: 0.6))),
        .bild(symbol: "xmark.octagon.fill", titel: "Nicht zu früh", text: "Wer zu Unrecht drückt, muss eine Karte abgeben. Wer am Ende alle Karten hat, gewinnt.", bild: "exclamationmark.triangle.fill", geste: .keine),
    ] }
}
#endif
