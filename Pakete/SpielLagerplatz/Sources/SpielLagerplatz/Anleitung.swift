// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas

/// Anleitung zum Durchwischen (KlarGlas `AnleitungBlatt`); der Rahmen hängt die Regelseite als „Alle Regeln lesen“ an.
extension LagerplatzModul {
    static var anleitung: [AnleitungSchritt] { [
        .raster(symbol: "shippingbox", titel: "Kisten schieben", text: "Ziehe den Finger über das Feld, um dich zu bewegen. Läufst du gegen eine Kiste, schiebst du sie ein Feld weiter.", geste: .ziehen(von: UnitPoint(x: 0.3, y: 0.5), nach: UnitPoint(x: 0.55, y: 0.5)), ["*B~"], [".*B"], zelle: 44),
        .bild(symbol: "exclamationmark.triangle", titel: "Nur schieben, nicht ziehen", text: "Kisten kannst du nicht ziehen und nur einzeln schieben. Steckt eine Kiste fest, hilft der Neustart.", bild: "arrow.uturn.backward.circle", geste: .keine),
        .bild(symbol: "lightbulb", titel: "Tipp", text: "Der Tipp-Knopf zeigt dir die nächste Richtung. Wer ihn nicht braucht, schafft die Stufe ohne Hilfe.", bild: "lightbulb", geste: .keine),
    ] }
}
#endif
