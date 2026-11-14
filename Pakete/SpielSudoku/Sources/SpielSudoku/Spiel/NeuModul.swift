// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

/// Sudoku : die eine Fassung des Spiels in der Sammlung. Spielbildschirm ohne Scrollen, Anbindung an den `SpielRahmen`,
/// Spielarten Klassisch 9×9, Kinder 6×6 und X-Sudoku, eigenes Rätsel eingeben.
@MainActor
public struct SudokuModul: SpielModul {
    public init() {}
    public let id = "sudoku-neu"
    public let name = "Sudoku"
    public let gattung = Gattung.raetsel
    public let farbe = AkzentFarbeWert.blau
    public let symbol = "square.grid.3x3.fill"
    public let spielerzahl = 1...1
    /// Stufen für die Statistik je Stufe (klassisches 9×9); die Kennung „sudoku-neu“ steht nicht in `Leiter.spiele`
    public let stufenNamen = ["Leicht", "Mittel", "Schwer", "Experte"]
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(
            SpielRahmen(id: id, name: name, untertitel: "Zahlenrätsel in drei Spielarten", farbe: farbe, spieler: 1...1,
                        regeln: "Fülle das Gitter so, dass jede Zahl in jeder Zeile, jeder Spalte und jedem Kästchen genau einmal steht. Beim klassischen Sudoku (9 × 9) sind es die Zahlen 1 bis 9 in 3 × 3-Kästchen, beim Kinder-Sudoku (6 × 6) die Zahlen 1 bis 6 in Kästchen aus 3 × 2 Feldern. Beim X-Sudoku enthalten zusätzlich die beiden Diagonalen jede Zahl von 1 bis 9 genau einmal. Tippe ein Feld an und dann die Zahl. Mit dem Stift merkst du dir Möglichkeiten, der Tipp erklärt den nächsten Schritt. Nach drei falschen Zahlen kannst du zum letzten fehlerfreien Stand zurück. Beim neuen Rätsel findest du das Tagesrätsel, den Lernweg und die Eingabe eigener Rätsel.",
                        umgebung: umgebung) { teilnehmer, ende, abbrechen in
                NeuSpiel(name: teilnehmer.first?.name ?? "", ende: ende, abbrechen: abbrechen)
            }
            .mitStartOptionen { _ in NeuStartWahl() }   // Design-Runde 3: Wahl auf der Spielseite (nur Tinte, sonst leer)
            .mitZiel("Fülle das ganze Gitter, sodass jede Zahl in jeder Zeile, Spalte und jedem Kästchen einmal steht.")
            .mitZielSchrittNeu(.ziel("Fülle das ganze Gitter, sodass jede Zahl in jeder Zeile, jeder Spalte und jedem Kästchen genau einmal steht. Rechnen musst du nicht, nur genau hinschauen. Jedes Rätsel hat genau eine Lösung. Die Zahlen, die schon dastehen, sind fest. Du spielst allein und ganz in Ruhe."))
            .mitAnleitung(RegelTexteNeu.anleitung(neu: SudokuAnleitung.schritteNeu, alt: Array(SudokuAnleitung.schritte.dropFirst())))
        )
    }
}
