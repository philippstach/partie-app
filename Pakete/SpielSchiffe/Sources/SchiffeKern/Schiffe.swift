// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Regelvarianten: Feldgröße, Flotte, Berührungsverbot, Extraschuss nach Treffer.
public struct FlottenRegeln: Equatable, Sendable, Codable {
    public var groesse = 10
    public var laengen = [5, 4, 3, 3, 2]
    /// Schiffe dürfen sich seitlich oder diagonal berühren.
    public var beruehrung = false
    /// Nach einem Treffer noch einmal schießen.
    public var extraschuss = true
    public init(groesse: Int = 10, laengen: [Int] = [5, 4, 3, 3, 2], beruehrung: Bool = false, extraschuss: Bool = true) {
        self.groesse = groesse; self.laengen = laengen; self.beruehrung = beruehrung; self.extraschuss = extraschuss
    }
    public static let klassisch = FlottenRegeln()
    public static let klein = FlottenRegeln(groesse: 8, laengen: [4, 3, 3, 2])
    public static let gross = FlottenRegeln(groesse: 12, laengen: [6, 5, 4, 4, 3, 3, 2])
    public static let dicht = FlottenRegeln(beruehrung: true)
    public static let abwechselnd = FlottenRegeln(extraschuss: false)
}

/// Schiffe versenken: standardmäßig 10×10, Flotte 5-4-3-3-2.
public struct Flotte: Equatable, Sendable, Codable {
    public static let laengen = [5, 4, 3, 3, 2]
    public private(set) var regeln = FlottenRegeln.klassisch
    public var n: Int { regeln.groesse }
    public private(set) var schiffe: [[Int]] = []             // Felder je Schiff
    public private(set) var beschossen = Set<Int>()

    public init(regeln: FlottenRegeln = .klassisch) { self.regeln = regeln }

    private enum CodingKeys: String, CodingKey { case regeln, schiffe, beschossen }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        regeln = try c.decodeIfPresent(FlottenRegeln.self, forKey: .regeln) ?? .klassisch   // alte Spielstände
        schiffe = try c.decode([[Int]].self, forKey: .schiffe)
        beschossen = try c.decode(Set<Int>.self, forKey: .beschossen)
    }

    public var belegt: Set<Int> { Set(schiffe.flatMap { $0 }) }
    public var versenktAlle: Bool { !schiffe.isEmpty && belegt.isSubset(of: beschossen) }
    public func treffer(_ i: Int) -> Bool { belegt.contains(i) }
    public func versenkt(_ s: [Int]) -> Bool { Set(s).isSubset(of: beschossen) }
    public var versenkteSchiffe: [[Int]] { schiffe.filter(versenkt) }

    /// Darf ein Schiff mit diesen Feldern hier liegen (innerhalb, ohne Überlappen, ohne Berührung außer erlaubt)?
    public func passt(_ felder: [Int]) -> Bool {
        let b = belegt
        for f in felder {
            guard (0..<(n * n)).contains(f) else { return false }
            let z = f / n, s = f % n
            let weite = regeln.beruehrung ? 0 : 1
            for dz in -weite...weite { for ds in -weite...weite {
                let r = z + dz, c = s + ds
                if (0..<n).contains(r), (0..<n).contains(c), b.contains(r * n + c) { return false }
            } }
        }
        return true
    }

    public func felder(start: Int, laenge: Int, waagrecht: Bool) -> [Int]? {
        let z = start / n, s = start % n
        if waagrecht { guard s + laenge <= n else { return nil }; return (0..<laenge).map { start + $0 } }
        guard z + laenge <= n else { return nil }
        return (0..<laenge).map { start + $0 * n }
    }

    @discardableResult
    public mutating func platziere(start: Int, laenge: Int, waagrecht: Bool) -> Bool {
        guard let f = felder(start: start, laenge: laenge, waagrecht: waagrecht), passt(f) else { return false }
        schiffe.append(f); return true
    }

    public mutating func zufaellig<G: RandomNumberGenerator>(mit g: inout G) {
        while true {
            schiffe = []
            var ok = true
            for l in regeln.laengen {
                var gelegt = false
                for _ in 0..<300 {
                    if platziere(start: Int.random(in: 0..<(n * n), using: &g), laenge: l, waagrecht: Bool.random(using: &g)) { gelegt = true; break }
                }
                if !gelegt { ok = false; break }
            }
            if ok { return }
        }
    }

    /// Schuss; gibt zurück, ob getroffen. Nur neue Felder zählen.
    @discardableResult
    public mutating func schiesse(_ i: Int) -> Bool? {
        guard (0..<(n * n)).contains(i), !beschossen.contains(i) else { return nil }
        beschossen.insert(i); return treffer(i)
    }
}

/// Computer: sucht, bis er trifft, dann schießt er in der Nähe weiter (Jagd), sonst Schachbrettmuster.
public struct SchiffeComputer: Sendable, Codable {
    public var offeneTreffer: [Int] = []
    public init() {}

    /// `stufe` 1 leicht (nur zufällige Schüsse), 2 mittel (jagt nach Treffern, sucht sonst zufällig), 3 schwer (jagt und sucht im Schachbrettmuster).
    public mutating func wahl<G: RandomNumberGenerator>(gegen f: Flotte, stufe: Int = 3, mit g: inout G) -> Int {
        let n = f.n
        let frei = (0..<(n * n)).filter { !f.beschossen.contains($0) }
        if stufe <= 1 { return frei.randomElement(using: &g)! }
        if stufe >= 3 { return dichteWahl(gegen: f, frei: frei, mit: &g) }
        // Treffer an noch nicht versenkten Schiffen
        let versenktFelder = Set(f.versenkteSchiffe.flatMap { $0 })
        let nichtVersenkt = f.beschossen.filter { f.treffer($0) && !versenktFelder.contains($0) }
        if !nichtVersenkt.isEmpty {
            var kandidaten: [Int] = []
            let sortiert = nichtVersenkt.sorted()
            for t in sortiert {
                let z = t / n, s = t % n
                let nachbarn = [(z - 1, s), (z + 1, s), (z, s - 1), (z, s + 1)].filter { (0..<n).contains($0.0) && (0..<n).contains($0.1) }.map { $0.0 * n + $0.1 }
                for nb in nachbarn where !f.beschossen.contains(nb) {
                    // Bevorzuge Verlängerung einer Linie von zwei Treffern
                    let gleicheReihe = nichtVersenkt.contains { $0 != t && (($0 / f.n == z && nb / f.n == z) || ($0 % f.n == s && nb % f.n == s)) }
                    kandidaten += gleicheReihe ? [nb, nb, nb] : [nb]
                }
            }
            if let k = kandidaten.randomElement(using: &g) { return k }
        }
        if stufe == 2 { return frei.randomElement(using: &g)! }
        let schach = frei.filter { ($0 / n + $0 % n) % 2 == 0 }
        return (schach.isEmpty ? frei : schach).randomElement(using: &g)!
    }

    /// Schwere Stufe: Jede noch mögliche Lage der übrigen Schiffe zählt für ihre Felder; offene Treffer geben ein Vielfaches.
    /// Geschossen wird auf das Feld mit der höchsten Zahl (bei Gleichstand zufällig).
    func dichteWahl<G: RandomNumberGenerator>(gegen f: Flotte, frei: [Int], mit g: inout G) -> Int {
        let n = f.n
        var offen = f.regeln.laengen
        for v in f.versenkteSchiffe { if let i = offen.firstIndex(of: v.count) { offen.remove(at: i) } }
        let versenktFelder = Set(f.versenkteSchiffe.flatMap { $0 })
        let offeneTreffer = Set(f.beschossen.filter { f.treffer($0) && !versenktFelder.contains($0) })
        let daneben = f.beschossen.filter { !f.treffer($0) }
        var zahl = [Int](repeating: 0, count: n * n)
        for l in offen {
            for waagrecht in [true, false] {
                for start in 0..<(n * n) {
                    guard let fl = f.felder(start: start, laenge: l, waagrecht: waagrecht) else { continue }
                    if fl.contains(where: { daneben.contains($0) || versenktFelder.contains($0) }) { continue }
                    let treffer = fl.filter { offeneTreffer.contains($0) }.count
                    let gewicht = treffer == 0 ? 1 : 12 * treffer * treffer
                    for x in fl where !f.beschossen.contains(x) { zahl[x] += gewicht }
                }
            }
        }
        // Bei offenen Treffern nur Felder, die mindestens eine Lage mit einem Treffer verlängern
        let beste = frei.map { zahl[$0] }.max() ?? 0
        let kandidaten = frei.filter { zahl[$0] == beste }
        return (kandidaten.isEmpty ? frei : kandidaten).randomElement(using: &g)!
    }
}
