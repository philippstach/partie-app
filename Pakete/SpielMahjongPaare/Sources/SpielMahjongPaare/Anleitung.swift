// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas

/// Anleitung zum Durchwischen (KlarGlas `AnleitungBlatt`); der Rahmen hängt die Regelseite als „Alle Regeln lesen“ an.
extension MahjongPaareModul {
    static var anleitung: [AnleitungSchritt] { [
        .raster(symbol: "square.on.square", titel: "Zwei gleiche Steine", text: "Entferne alle Steine, indem du zwei gleiche freie Steine antippst.", geste: .tippen(.zelle(0, 0, zeilen: 2, spalten: 3)), ["AB.", "CAB"], ["~B.", "CAB"], zelle: 44),
        .bild(symbol: "lock.open", titel: "Frei oder nicht?", text: "Ein Stein ist frei, wenn kein anderer auf ihm liegt und er links oder rechts nichts berührt. Der Tipp zeigt ein mögliches Paar.", bild: "lock.open.fill", geste: .keine),
    ] }
}
#endif
