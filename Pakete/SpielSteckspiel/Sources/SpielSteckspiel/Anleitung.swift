// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas

/// Anleitung zum Durchwischen (KlarGlas `AnleitungBlatt`); der Rahmen hängt die Regelseite als „Alle Regeln lesen“ an.
extension SteckspielModul {
    static var anleitung: [AnleitungSchritt] { [
        .raster(symbol: "arrow.up.forward", titel: "Über einen Stecker springen", text: "Du springst mit einem Stecker waagrecht oder senkrecht über einen Nachbarn in ein leeres Loch. Der übersprungene Stecker wird entfernt.", geste: .ziehen(von: UnitPoint(x: 0.34, y: 0.5), nach: UnitPoint(x: 0.66, y: 0.5)), ["**."], ["..*"], zelle: 44),
        .bild(symbol: "1.circle", titel: "Einer bleibt übrig", text: "Ziel: Am Ende soll nur ein einziger Stecker übrig sein. Gehen keine Sprünge mehr, ist das Spiel zu Ende.", bild: "1.circle.fill", geste: .keine),
        .bild(symbol: "lightbulb", titel: "Tipp und Zurück", text: "Der Tipp zeigt einen guten Sprung, „Zurück“ nimmt Sprünge zurück. Du wählst zwischen den Brettern Kreuz (33 Löcher) und Europa (37 Löcher).", bild: "lightbulb", geste: .keine),
    ] }
}
#endif
