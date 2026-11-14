// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

extension Maexchen {
    /// Stimmigkeit eines geladenen Stands: Zeiger im Bereich, Würfe vollständig, und in der Phase „entscheiden“ sind Ansage,
    /// Ansager und der verdeckte Wurf bekannt. Ein unstimmiger Stand wird verworfen statt geladen.
    public var istKonsistent: Bool {
        let n = leben.count
        guard n >= 2, leben.allSatisfy({ $0 >= 0 }), !aktive.isEmpty, leben.indices.contains(dran) else { return false }
        guard aufgedeckteAnsagen.count == n, aufgedeckteLuegen.count == n else { return false }
        func wurfGut(_ w: [Int]?) -> Bool { w.map { $0.count == 2 && $0.allSatisfy((1...6).contains) } ?? true }
        guard wurfGut(wurfAugen), wurfGut(aufgedecktAugen) else { return false }
        if let a = ansage, !MaexchenWert.alle.contains(a) { return false }
        if let a = ansager, !leben.indices.contains(a) { return false }
        if let v = verlierer, !leben.indices.contains(v) { return false }
        if sieger != nil { return true }
        guard leben[dran] > 0 else { return false }
        switch phase {
        case .wuerfeln: return true
        case .ansagen: return wurfAugen != nil
        case .entscheiden: return wurfAugen != nil && ansage != nil && ansager != nil && ansager != dran
        }
    }

    /// Schlussstand: Der Sieger steht vorn, alle anderen teilen sich Platz 2 (in Sitzreihenfolge aufgeführt).
    /// Ohne das bekämen die Verlierer Plätze nach Sitzreihenfolge, was die Rivalen-Bilanz verfälscht.
    public static func schlussstand(sieger: Int, spieler: Int) -> (reihenfolge: [Int], plaetze: [Int]) {
        let rest = (0..<spieler).filter { $0 != sieger }
        return ([sieger] + rest, [1] + rest.map { _ in 2 })
    }
}
