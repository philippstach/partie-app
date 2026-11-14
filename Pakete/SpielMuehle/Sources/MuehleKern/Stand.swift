// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

extension Muehle {
    /// Stimmigkeit eines geladenen Stands: Brett, Vorrat und Zeiger im Bereich, nicht mehr Steine im Spiel als die Regel vorsieht.
    public var istKonsistent: Bool {
        guard brett.count == 24, brett.allSatisfy({ (0...2).contains($0) }), vorrat.count == 3, (1...2).contains(dran) else { return false }
        guard (3...12).contains(regeln.steine), ruhigeZuege >= 0 else { return false }
        return [1, 2].allSatisfy { vorrat[$0] >= 0 && gesamt($0) <= regeln.steine }
    }
}

/// Vollständiger gespeicherter Stand: die Stellung samt Zugverlauf, damit „Zug zurück“ auch nach dem Fortsetzen geht
/// und die Ansicht weiß, dass die Partie schon läuft (kein stiller Regelwechsel). Alte Stände (nur die Stellung) bleiben ladbar.
public struct MuehleStand: Codable, Equatable, Sendable {
    /// So viele frühere Stellungen werden höchstens mitgespeichert.
    public static let verlaufGrenze = 80
    public var spiel: Muehle
    public var verlauf: [Muehle]

    public init(spiel: Muehle, verlauf: [Muehle] = []) {
        self.spiel = spiel; self.verlauf = Array(verlauf.suffix(Self.verlaufGrenze))
    }

    private enum CodingKeys: String, CodingKey { case spiel, verlauf }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if c.contains(.spiel) {
            spiel = try c.decode(Muehle.self, forKey: .spiel)
            verlauf = try c.decodeIfPresent([Muehle].self, forKey: .verlauf) ?? []
        } else {
            spiel = try Muehle(from: decoder)   // altes Format: nur die Stellung
            verlauf = []
        }
    }

    /// Der Verlauf muss zur selben Partie gehören (gleiche Regel), sonst würde „Zug zurück“ die Regel wechseln.
    public var istKonsistent: Bool {
        spiel.istKonsistent && verlauf.allSatisfy { $0.istKonsistent && $0.regeln == spiel.regeln }
    }

    /// Die Partie hat schon begonnen: Ein Regelwechsel würde sie verwerfen und ist deshalb gesperrt.
    public var begonnen: Bool {
        // Nicht über `==` mit einer frischen Partie: Ein alter Stand hat `geschlosseneMuehlen == nil` und wäre sonst „begonnen“.
        !verlauf.isEmpty || spiel.brett.contains { $0 != 0 } || spiel.vorrat != [0, spiel.regeln.steine, spiel.regeln.steine] || spiel.mussEntfernen || spiel.ruhigeZuege != 0
    }   // 1.0 (M7): leeres Brett mit beliebigem Beginner
}
