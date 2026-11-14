// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Ereignis, bei dem die geführte Partie einen Hinweis zeigen könnte (SPEZIFIKATION 13.5).
struct HinweisEreignis: Codable, Equatable {
    var typ: String
    var mensch: Bool
    var vorleger: Bool
    var wuerfe: Int
    var maxWuerfe: Int
    var umdrehenErlaubt: Bool
    var einsenHerauslegbar: Bool
    var darfWeiter: Bool
    var stock: Int
}

/// Welcher Hinweis erscheint wann? Referenz: `Referenz/erweiterungen.py` (HINWEISE).
enum Hinweise {
    /// Feste Reihenfolge = Vorrang; pro Ereignis höchstens ein Hinweis.
    static let eintraege: [(id: String, typ: String, bedingung: (HinweisEreignis) -> Bool)] = [
        ("ersterWurf", "zugStart", { $0.mensch && $0.wuerfe == 0 }),
        ("vorgabe", "zugStart", { $0.mensch && !$0.vorleger && $0.maxWuerfe < 3 }),
        ("zuSchlagen", "zugStart", { $0.mensch && !$0.vorleger }),
        ("sechsen", "nachWurf", { $0.mensch && $0.umdrehenErlaubt }),
        ("einsen", "nachWurf", { $0.mensch && $0.einsenHerauslegbar }),
        ("stehen", "nachWurf", { $0.mensch && $0.wuerfe >= 1 && $0.darfWeiter }),
        ("rundenwertung", "rundenwertung", { _ in true }),
        ("stockLeer", "rundenwertung", { $0.stock == 0 }),
    ]

    static var ids: [String] { eintraege.map(\.id) }

    /// Die ersten drei Würfel der geführten Partie: Sechsen umdrehen und Einsen herauslegen kommen sofort vor.
    static let gefuehrtStart = [6, 6, 1]

    /// Erster noch nicht gezeigter Hinweis, der zum Ereignis passt.
    static func naechster(_ e: HinweisEreignis, gezeigt: Set<String>, an: Bool = true) -> String? {
        guard an else { return nil }
        for h in eintraege where !gezeigt.contains(h.id) && h.typ == e.typ && h.bedingung(e) { return h.id }
        return nil
    }
}
