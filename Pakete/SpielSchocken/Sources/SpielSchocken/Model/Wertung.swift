// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Art eines Wurfs, aufsteigend nach Rang (SPEZIFIKATION Abschnitt 4).
enum WertungsArt: String, Codable, CaseIterable {
    case zahl, strasse, general, schock, jule, schockAus

    var rang: Int {
        switch self {
        case .zahl: 1
        case .strasse: 2
        case .general: 3
        case .schock: 4
        case .jule: 5
        case .schockAus: 6
        }
    }
}

/// Vergleichswert einer Wertung: erst Rang der Art, dann Höhe.
struct Schluessel: Hashable, Comparable {
    let rang: Int
    let hoehe: Int

    static func < (a: Schluessel, b: Schluessel) -> Bool {
        (a.rang, a.hoehe) < (b.rang, b.hoehe)
    }
}

struct Wertung: Codable, Hashable {
    var art: WertungsArt
    /// zahl: dreistellig (653) · strasse: höchste Augenzahl · general/schock: Augenzahl · jule/schockAus: 0
    var hoehe: Int
    /// Deckel, die dieser Wurf als bester der Runde verteilt. schockAus = 0 (bedeutet „alle“).
    var deckel: Int

    var schluessel: Schluessel { Schluessel(rang: art.rang, hoehe: hoehe) }
}

/// Bewertet drei Würfel. `ausEinemWurf`: alle drei fielen im letzten Wurf gemeinsam
/// (nichts herausgelegt, nichts umgedreht). Nur dann zählen Straße und General.
func werte(_ wuerfel: [Int], ausEinemWurf: Bool, optionen: Optionen = .standard) -> Wertung {
    precondition(wuerfel.count == 3 && wuerfel.allSatisfy { (1...6).contains($0) })
    let s = wuerfel.sorted(by: >)
    let (a, b, c) = (s[0], s[1], s[2])
    if a == 1 && b == 1 && c == 1 { return Wertung(art: .schockAus, hoehe: 0, deckel: 0) }
    if optionen.jule && a == 4 && b == 2 && c == 1 { return Wertung(art: .jule, hoehe: 0, deckel: 7) }
    if b == 1 && c == 1 { return Wertung(art: .schock, hoehe: a, deckel: a) }
    if ausEinemWurf && a == b && b == c { return Wertung(art: .general, hoehe: a, deckel: 3) }
    if ausEinemWurf && a - 1 == b && b - 1 == c { return Wertung(art: .strasse, hoehe: a, deckel: 2) }
    return Wertung(art: .zahl, hoehe: 100 * a + 10 * b + c, deckel: 1)
}

/// Ergebnis eines Spielers in einer Runde.
struct Ergebnis: Codable, Hashable {
    var wertung: Wertung
    /// benutzte Würfe 1…3
    var wuerfe: Int
    /// 0 = Vorleger, 1 = zweiter Spieler der Runde, …
    var position: Int
}

/// `a` besser als `b`? Gleiche Wertung: weniger Würfe, sonst der frühere.
func istBesser(_ a: Ergebnis, _ b: Ergebnis) -> Bool {
    if a.wertung.schluessel != b.wertung.schluessel { return a.wertung.schluessel > b.wertung.schluessel }
    if a.wuerfe != b.wuerfe { return a.wuerfe < b.wuerfe }
    return a.position < b.position
}
