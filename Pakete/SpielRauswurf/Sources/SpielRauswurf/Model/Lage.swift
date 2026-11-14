// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Konstanten des Bretts (SPEZIFIKATION Abschnitt 3).
enum Brettmass {
    static let haus = -1
    static let lauf = 40          // Felder der Laufbahn
    static let zielErstes = 40
    static let zielLetztes = 43
    static let figuren = 4
    static let sitze = 4
    static let abstand = 10       // Felder zwischen zwei Startfeldern
}

/// Absolutes Laufbahnfeld 0…39 für eine relative Position 0…39.
func feld(_ sitz: Int, _ rel: Int) -> Int {
    (sitz * Brettmass.abstand + rel) % Brettmass.lauf
}

/// Positionen aller Figuren. Positionen sind relativ zum Spieler (-1 Haus, 0…39 Laufbahn, 40…43 Ziel).
struct Lage: Codable, Equatable, Hashable, Sendable {
    /// Je Spieler sein Sitz 0…3, aufsteigend.
    var sitze: [Int]
    /// Je Spieler 4 relative Positionen (Reihenfolge = Figur-Index).
    var figuren: [[Int]]

    init(sitze: [Int], figuren: [[Int]]) {
        self.sitze = sitze
        self.figuren = figuren
    }

    /// Aufstellung zu Beginn: alle im Haus, mit `startMitFigur` steht Figur 0 schon auf dem Startfeld.
    static func neu(sitze: [Int], _ opt: Optionen = .standard) -> Lage {
        let start = opt.startMitFigur ? [0] : []
        return Lage(sitze: sitze, figuren: sitze.map { _ in start + Array(repeating: Brettmass.haus, count: opt.figuren - start.count) })
    }

    func fertig(_ spieler: Int) -> Bool {
        figuren[spieler].allSatisfy { $0 >= Brettmass.zielErstes }
    }

    /// (Spieler, Figur-Index) auf einem absoluten Laufbahnfeld.
    func besetzer(_ absFeld: Int) -> (spieler: Int, figur: Int)? {
        for (q, fs) in figuren.enumerated() {
            for (k, r) in fs.enumerated() where (0 ..< Brettmass.lauf).contains(r) && feld(sitze[q], r) == absFeld {
                return (q, k)
            }
        }
        return nil
    }
}
