// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas

/// Anleitung zum Durchwischen (KlarGlas `AnleitungBlatt`); der Rahmen hängt die Regelseite als „Alle Regeln lesen“ an.
extension BrueckenModul {
    static var anleitung: [AnleitungSchritt] { [
        .raster(symbol: "link", titel: "Inseln verbinden", text: "Tippe nacheinander zwei benachbarte Inseln an: einmal ergibt eine Brücke, zweimal eine doppelte, dreimal löscht sie.", geste: .tippen(.zelle(0, 0, zeilen: 1, spalten: 3)), ["1 2"], ["1~2"], zelle: 44),
        .bild(symbol: "number.circle", titel: "Die Zahl zählt", text: "Die Zahl auf einer Insel sagt, wie viele Brücken von ihr ausgehen. Am Ende müssen alle Inseln zusammenhängen.", bild: "point.3.connected.trianglepath.dotted", geste: .keine),
        .bild(symbol: "slider.horizontal.3", titel: "Schwierigkeit", text: "Im Menü wählst du Leicht bis Experte: mehr Inseln auf größerem Feld. Der Tipp setzt eine richtige Brücke, Rückgängig nimmt Züge zurück.", bild: "slider.horizontal.3", geste: .keine),
    ] }
}
#endif
