// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Chicago (Würfel): Elf Runden mit den Zielzahlen 2 bis 12. Jeder darf pro Runde bis zu dreimal mit zwei Würfeln werfen;
/// trifft die Augensumme die Zielzahl, gibt es so viele Punkte (ein Pasch zählt doppelt) und der Zug endet.
public struct Chicago: Sendable, Codable {
    /// Der zuletzt geworfene Wurf ist nur Anzeige und wird nicht gespeichert.
    private enum CodingKeys: String, CodingKey { case punkte, runde, dran, versuche, treffer, beendet, rundenPunkte }
    public static let wuerfe = 3
    public private(set) var punkte: [Int]
    public private(set) var runde = 0                 // 0 → Ziel 2
    public private(set) var dran = 0
    public private(set) var wurf: (Int, Int)?
    public private(set) var versuche = 0
    public private(set) var treffer: Bool?
    public private(set) var beendet = false
    /// Blatt 22 (EB2, Schritt 2): je Person die Punkte jedes beendeten Zuges (0 = verfehlt; Zug k hatte die Zielzahl k + 2).
    /// Optional: ein Stand von vor dem Update lädt mit `nil`, dann gibt es weder „Treffer“ noch das Bild.
    public private(set) var rundenPunkte: [[Int]]?

    public init(spieler: Int) {
        punkte = Array(repeating: 0, count: spieler)
        rundenPunkte = Array(repeating: [], count: spieler)
    }

    /// C-024: Prüfung eines geladenen Stands (Spielerzahl, Runde, Versuche), damit nichts außerhalb der Grenzen indiziert.
    public var istStimmig: Bool {
        !punkte.isEmpty && (0...11).contains(runde) && (0..<punkte.count).contains(dran) && (0...Chicago.wuerfe).contains(versuche)
    }

    public var ziel: Int { runde + 2 }
    public var darfWerfen: Bool { !beendet && treffer == nil && versuche < Chicago.wuerfe }

    public mutating func wuerfeln<G: RandomNumberGenerator>(mit g: inout G) {
        setzeWurf(Int.random(in: 1...6, using: &g), Int.random(in: 1...6, using: &g))
    }

    public mutating func setzeWurf(_ a: Int, _ b: Int) {
        guard darfWerfen, (1...6).contains(a), (1...6).contains(b) else { return }
        wurf = (a, b); versuche += 1
        if a + b == ziel {
            let p = ziel * (a == b ? 2 : 1)
            punkte[dran] += p; treffer = true
            merkeZug(p)
        } else if versuche >= Chicago.wuerfe { treffer = false; merkeZug(0) }
    }

    private mutating func merkeZug(_ p: Int) {
        guard var r = rundenPunkte, r.indices.contains(dran) else { return }
        r[dran].append(p)
        rundenPunkte = r
    }

    /// Treffer je Person (Züge mit Punkten); `nil` bei einem alten Stand ohne Zählung.
    public var trefferJePerson: [Int]? { rundenPunkte.map { $0.map { z in z.filter { $0 > 0 }.count } } }

    /// 1.0 (P4): Wahrscheinlichkeit, dass ein Wurf mit zwei Würfeln die Augensumme `summe` ergibt (0 bis 1; Summen außerhalb 2…12 → 0).
    public static func chance(summe: Int) -> Double {
        guard (2...12).contains(summe) else { return 0 }
        let moeglich = (1...6).reduce(0) { n, a in n + ((1...6).contains(summe - a) ? 1 : 0) }
        return Double(moeglich) / 36
    }

    /// 1.0 (P4): Chance auf die Zielzahl im nächsten Wurf (0, wenn nicht mehr geworfen werden darf).
    public var chanceNaechsterWurf: Double { darfWerfen ? Chicago.chance(summe: ziel) : 0 }

    /// 1.0 (P4): Chance, die Zielzahl in den noch übrigen Würfen dieses Zuges mindestens einmal zu treffen.
    public var chanceRestlicheWuerfe: Double {
        guard darfWerfen else { return 0 }
        return 1 - pow(1 - Chicago.chance(summe: ziel), Double(Chicago.wuerfe - versuche))
    }

    /// Nächster Spieler bzw. nächste Runde (nach Treffer oder letztem Versuch).
    public mutating func weiter() {
        guard treffer != nil, !beendet else { return }
        wurf = nil; versuche = 0; treffer = nil
        dran += 1
        if dran >= punkte.count { dran = 0; runde += 1; if runde > 10 { beendet = true } }
    }
}
