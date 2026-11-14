// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Regelvarianten des Kalaha. Standard = 4 Steine, Fangen und Extrazug.
public struct KalahaRegeln: Equatable, Sendable, Codable {
    public var steine = 4
    /// Landet der letzte Stein in einer leeren eigenen Mulde, gehören die gegenüberliegenden Steine dir.
    public var fangen = true
    /// Landet der letzte Stein im eigenen Haus, bist du noch einmal dran.
    public var extrazug = true
    public init(steine: Int = 4, fangen: Bool = true, extrazug: Bool = true) { self.steine = steine; self.fangen = fangen; self.extrazug = extrazug }
    public static let standard = KalahaRegeln()
    public static let sechs = KalahaRegeln(steine: 6)
    public static let drei = KalahaRegeln(steine: 3)
    public static let schlicht = KalahaRegeln(fangen: false, extrazug: false)
}

/// Kalaha: je sechs Mulden und ein Haus (Kalaha). Felder 0–5 und Haus 6 gehören Spieler 0, 7–12 und Haus 13 Spieler 1.
public struct Kalaha: Equatable, Sendable, Codable {
    public private(set) var felder: [Int]
    public private(set) var dran = 0
    public private(set) var beendet = false
    public private(set) var regeln = KalahaRegeln.standard

    public init(steine: Int = 4) { self.init(regeln: KalahaRegeln(steine: steine)) }
    public init(regeln: KalahaRegeln) {
        self.regeln = regeln
        felder = (0..<14).map { ($0 == 6 || $0 == 13) ? 0 : regeln.steine }
    }

    private enum CodingKeys: String, CodingKey { case felder, dran, beendet, regeln }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        felder = try c.decode([Int].self, forKey: .felder)
        dran = try c.decode(Int.self, forKey: .dran)
        beendet = try c.decode(Bool.self, forKey: .beendet)
        regeln = try c.decodeIfPresent(KalahaRegeln.self, forKey: .regeln) ?? .standard   // alte Spielstände
    }

    public static func haus(_ s: Int) -> Int { s == 0 ? 6 : 13 }
    public static func mulden(_ s: Int) -> [Int] { s == 0 ? Array(0...5) : Array(7...12) }

    public var zuege: [Int] { beendet ? [] : Kalaha.mulden(dran).filter { felder[$0] > 0 } }
    public func punkte(_ s: Int) -> Int { felder[Kalaha.haus(s)] }
    public var sieger: Int? {
        guard beendet else { return nil }
        let a = punkte(0), b = punkte(1)
        return a == b ? nil : (a > b ? 0 : 1)
    }

    /// Spielt eine Mulde. Gibt zurück, ob der Zug gültig war.
    @discardableResult
    public mutating func spiele(_ m: Int) -> Bool {
        guard zuege.contains(m) else { return false }
        var n = felder[m]; felder[m] = 0
        var i = m
        let gegnerHaus = Kalaha.haus(1 - dran)
        while n > 0 {
            i = (i + 1) % 14
            if i == gegnerHaus { continue }
            felder[i] += 1; n -= 1
        }
        if i == Kalaha.haus(dran) {
            if !regeln.extrazug { dran = 1 - dran }
        } else {
            if regeln.fangen, Kalaha.mulden(dran).contains(i), felder[i] == 1 {
                let gegenueber = 12 - i
                if felder[gegenueber] > 0 {
                    felder[Kalaha.haus(dran)] += felder[gegenueber] + 1
                    felder[gegenueber] = 0; felder[i] = 0
                }
            }
            dran = 1 - dran
        }
        pruefeEnde()
        return true
    }

    private mutating func pruefeEnde() {
        let leer0 = Kalaha.mulden(0).allSatisfy { felder[$0] == 0 }
        let leer1 = Kalaha.mulden(1).allSatisfy { felder[$0] == 0 }
        guard leer0 || leer1 else { return }
        for s in 0...1 { for m in Kalaha.mulden(s) { felder[Kalaha.haus(s)] += felder[m]; felder[m] = 0 } }
        beendet = true
    }
}

public enum KalahaComputer {
    /// Beste Mulde. Züge, die im eigenen Haus enden (Extrazug), werden zuerst geprüft; das beschleunigt den Alpha-Beta-Schnitt.
    public static func wahl(_ k: Kalaha, tiefe: Int = 6) -> Int? {
        let z = geordnet(k)
        guard !z.isEmpty else { return nil }
        let ich = k.dran
        var best = z[0], bw = Int.min
        for m in z {
            var n = k; n.spiele(m)
            let w = suche(n, tiefe - 1, bw == Int.min ? Int.min : bw - 1, Int.max, ich)
            if w > bw { bw = w; best = m }
        }
        return best
    }

    /// Mulden nach Aussicht sortiert: Extrazug zuerst, dann nach Nähe zum Haus.
    static func geordnet(_ k: Kalaha) -> [Int] {
        let haus = Kalaha.haus(k.dran)
        return k.zuege.sorted { a, b in
            let ea = (a + k.felder[a]) == haus, eb = (b + k.felder[b]) == haus
            if ea != eb { return ea }
            return k.dran == 0 ? a > b : a < b
        }
    }

    /// Bewertung aus Sicht von `ich`: Hausdifferenz zählt am meisten, Steine auf der eigenen Seite gelten als halber Gewinn (sie fallen bei Spielende ins eigene Haus).
    static func bewerte(_ k: Kalaha, _ ich: Int) -> Int {
        let eigene = Kalaha.mulden(ich).reduce(0) { $0 + k.felder[$1] }
        let fremde = Kalaha.mulden(1 - ich).reduce(0) { $0 + k.felder[$1] }
        return 4 * (k.punkte(ich) - k.punkte(1 - ich)) + (eigene - fremde)
    }

    private static func suche(_ k: Kalaha, _ t: Int, _ alpha: Int, _ beta: Int, _ ich: Int) -> Int {
        if k.beendet { return 4 * (k.punkte(ich) - k.punkte(1 - ich)) * 4 }
        if t == 0 { return bewerte(k, ich) }
        var a = alpha, b = beta
        let max_ = k.dran == ich
        var w = max_ ? Int.min : Int.max
        for m in geordnet(k) {
            var n = k; n.spiele(m)
            let v = suche(n, t - 1, a, b, ich)
            if max_ { w = max(w, v); a = max(a, v) } else { w = min(w, v); b = min(b, v) }
            if b <= a { break }
        }
        return w
    }
}
