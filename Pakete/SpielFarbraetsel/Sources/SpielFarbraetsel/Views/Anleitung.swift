// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas

/// Anleitung zum Durchwischen für den `SpielRahmen` (Regeln als Text stehen im Modul).
@MainActor
enum FarbraetselAnleitung {
    static let schritte: [AnleitungSchritt] = [
        AnleitungSchritt.ziel("Tausche die Kacheln, bis sie wieder den sanften Farbverlauf bilden, mit möglichst wenigen Zügen."),
        .raster(symbol: "paintpalette", titel: "Verlauf wiederherstellen", text: "Die Kacheln bilden einen sanften Farbverlauf zwischen den vier Ecken. Jemand hat sie durcheinandergebracht – stelle den Verlauf wieder her.", geste: .keine,
                ["ryg", "ygr"], ["rgy", "ygr"], zelle: 50),
        .raster(symbol: "arrow.left.arrow.right", titel: "Tauschen", text: "Tippe eine Kachel an und dann eine zweite. Beide tauschen die Plätze. Kacheln mit weißem Punkt sind fest.", geste: .tippen(.zelle(0, 1, zeilen: 2, spalten: 3, zelle: 50)),
                ["ryg", "ygr"], ["rgy", "ygr"], zelle: 50),
        .bild(symbol: "number", titel: "Wenig Züge", text: "Je weniger Züge, desto besser. Mit Tipp gelöste Rätsel zählen nicht für den Bestwert.", bild: "figure.walk"),
    ]
}
#endif
