// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Laufende Partie: wer liegt wo, Züge, Hilfen. Reine Logik, ohne UI.
struct Partie: Equatable, Codable, Sendable {
    let raetsel: Raetsel
    /// `belegung[platz]` = Kachel, die dort liegt.
    private(set) var belegung: [Int]
    private(set) var zuege = 0
    private(set) var hilfen = 0
    /// Bisher gespielte Sekunden (wird beim Pausieren/Speichern gesammelt).
    var sekunden: Double = 0
    private var verlauf: [Tausch] = []

    struct Tausch: Equatable, Codable, Sendable { let a: Int; let b: Int; let warHilfe: Bool }

    init(raetsel: Raetsel) {
        self.raetsel = raetsel
        self.belegung = raetsel.start
    }

    var geloest: Bool { belegung.indices.allSatisfy { belegung[$0] == $0 } }
    var richtigePlaetze: Int { belegung.indices.filter { belegung[$0] == $0 }.count }
    /// Anteil der richtig liegenden *losen* Kacheln (0…1), für den Fortschrittsbalken.
    var fortschritt: Double {
        let lose = raetsel.stufe.anzahl - raetsel.fest.count
        guard lose > 0 else { return 1 }
        let richtig = belegung.indices.filter { !raetsel.fest.contains($0) && belegung[$0] == $0 }.count
        return Double(richtig) / Double(lose)
    }
    var kannZurueck: Bool { !verlauf.isEmpty }

    func istFest(_ platz: Int) -> Bool { raetsel.fest.contains(platz) }
    func istRichtig(_ platz: Int) -> Bool { belegung[platz] == platz }

    /// Tauscht zwei Plätze. `false`, wenn einer fest ist, gleich oder außerhalb.
    @discardableResult
    mutating func tauschen(_ a: Int, _ b: Int) -> Bool {
        guard a != b, belegung.indices.contains(a), belegung.indices.contains(b),
              !istFest(a), !istFest(b), !gesperrt else { return false }
        belegung.swapAt(a, b)
        zuege += 1
        verlauf.append(Tausch(a: a, b: b, warHilfe: false))
        return true
    }

    /// Nimmt den letzten Tausch zurück (zählt als Zug, damit man nicht mogelt: Zähler geht nicht zurück).
    @discardableResult
    mutating func zurueck() -> Bool {
        guard let letzter = verlauf.popLast() else { return false }
        belegung.swapAt(letzter.a, letzter.b)
        return true
    }

    /// Hilfe: bringt die Kachel eines falschen, losen Platzes an ihren Platz. Gibt die beiden Plätze zurück.
    @discardableResult
    mutating func hilfe() -> (Int, Int)? {
        guard !gesperrt, let platz = belegung.indices.first(where: { !istFest($0) && !istRichtig($0) }),
              let quelle = belegung.firstIndex(of: platz) else { return nil }
        belegung.swapAt(platz, quelle)
        hilfen += 1
        zuege += 1
        verlauf.append(Tausch(a: platz, b: quelle, warHilfe: true))
        return (platz, quelle)
    }

    private var gesperrt: Bool { geloest }
}
