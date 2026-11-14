// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

public struct BgZug: Equatable, Hashable, Sendable {
    public let von: Int          // 0–23, 24 = Bar
    public let nach: Int         // 0–23, -1 = hinaus (abtragen)
    public let wuerfel: Int
}

/// Regelvarianten (Tavla, Nardy, Plakoto, Fevga, Acey-Deucey …). `.standard` ist das klassische Backgammon.
public struct BgRegeln: Equatable, Sendable, Codable {
    /// 24 Punkte: + weiß (Spieler 1), − schwarz (Spieler 2).
    public var aufstellung: [Int]
    /// Startbestand auf der Bar (Index 1, 2).
    public var bar: [Int]
    public var schlagen: Bool
    /// Beide ziehen in dieselbe Richtung (Nardy, Fevga): Schwarz startet bei Punkt 11 und zieht 11→0→23→12.
    public var richtungGleich: Bool
    /// Nardy: pro Zug nur ein Stein vom Startpunkt (Ausnahme: erster Wurf mit Pasch erlaubt zwei).
    public var kopfRegel: Bool
    /// Nardy/Fevga: kein Block aus sechs Punkten, wenn dahinter kein gegnerischer Stein steht.
    public var sperre6: Bool
    /// Plakoto: ein gegnerischer Einzelstein wird festgesetzt statt geschlagen.
    public var pin: Bool
    /// Acey-Deucey: Wurf 1+2 gibt nach dem Ziehen einen frei gewählten Pasch (1–6) und einen weiteren Wurf.
    public var aceyBonus: Bool

    public init(aufstellung: [Int], bar: [Int] = [0, 0, 0], schlagen: Bool = true, richtungGleich: Bool = false,
                kopfRegel: Bool = false, sperre6: Bool = false, pin: Bool = false, aceyBonus: Bool = false) {
        self.aufstellung = aufstellung; self.bar = bar; self.schlagen = schlagen; self.richtungGleich = richtungGleich
        self.kopfRegel = kopfRegel; self.sperre6 = sperre6; self.pin = pin; self.aceyBonus = aceyBonus
    }

    private static func leer() -> [Int] { [Int](repeating: 0, count: 24) }
    public static let standard: BgRegeln = {
        var p = leer(); p[23] = 2; p[12] = 5; p[7] = 3; p[5] = 5; p[0] = -2; p[11] = -5; p[16] = -3; p[18] = -5
        return BgRegeln(aufstellung: p)
    }()
    /// Acey-Deucey (ohne die Sonderregel für 1+2): alle Steine starten auf der Bar.
    public static let aceyDeucey = BgRegeln(aufstellung: leer(), bar: [0, 15, 15], aceyBonus: true)
    public static let nardy: BgRegeln = {
        var p = leer(); p[23] = 15; p[11] = -15
        return BgRegeln(aufstellung: p, schlagen: false, richtungGleich: true, kopfRegel: true, sperre6: true)
    }()
    public static let fevga: BgRegeln = {
        var p = leer(); p[23] = 15; p[11] = -15
        return BgRegeln(aufstellung: p, schlagen: false, richtungGleich: true, sperre6: true)
    }()
    public static let plakoto: BgRegeln = {
        var p = leer(); p[23] = 15; p[0] = -15
        return BgRegeln(aufstellung: p, schlagen: false, pin: true)
    }()
}

/// Backgammon. Spieler 1 (weiß, +) zieht von Punkt 23 nach 0 (Heimfeld 0–5), Spieler 2 (schwarz, −) von 0 nach 23 (Heimfeld 18–23).
public struct Backgammon: Equatable, Sendable, Codable {
    public private(set) var punkte = [Int](repeating: 0, count: 24)   // + weiß, − schwarz
    public private(set) var bar = [0, 0, 0]                          // Index 1, 2
    public private(set) var draussen = [0, 0, 0]
    public private(set) var dran = 1
    public private(set) var wuerfel: [Int] = []                      // noch zu spielende Augen
    public private(set) var regeln: BgRegeln = .standard
    /// Plakoto: je Punkt der Spieler, dessen Einzelstein unter einem gegnerischen festsitzt (0 = keiner).
    public private(set) var festgesetzt = [Int](repeating: 0, count: 24)
    /// Acey-Deucey: Der Spieler darf nach seinem 1+2-Zug einen Pasch wählen (`waehlePasch`).
    public private(set) var paschWahl = false
    private var aceyOffen = false
    private var nochmalWurf = false
    private var kopfGezogen = 0                                       // Nardy: in diesem Zug vom Startpunkt gezogen
    private var erstesMal = [false, true, true]                       // Nardy: noch kein Zug dieses Spielers

    public init(regeln: BgRegeln = .standard) {
        self.regeln = regeln
        punkte = regeln.aufstellung
        bar = regeln.bar
    }

    public init(punkte: [Int], bar: [Int] = [0, 0, 0], draussen: [Int] = [0, 0, 0], dran: Int, wuerfel: [Int] = [], regeln: BgRegeln = .standard) {
        self.regeln = regeln
        self.punkte = punkte; self.bar = bar; self.draussen = draussen; self.dran = dran; self.wuerfel = wuerfel
    }

    /// Weg eines Spielers: `pos` 0…23 (Start → Ziel) ↔ Punkt auf dem Brett.
    private func punkt(_ s: Int, _ pos: Int) -> Int {
        if s == 1 { return 23 - pos }
        return regeln.richtungGleich ? ((11 - pos) % 24 + 24) % 24 : pos
    }
    private func pos(_ s: Int, _ p: Int) -> Int {
        if s == 1 { return 23 - p }
        return regeln.richtungGleich ? ((11 - p) % 24 + 24) % 24 : p
    }
    private func vz(_ s: Int) -> Int { s == 1 ? 1 : -1 }          // Vorzeichen der Steine von Spieler s auf `punkte`
    private func steine(_ s: Int, _ p: Int) -> Int { max(0, punkte[p] * vz(s)) }
    private func gegnerSteine(_ s: Int, _ p: Int) -> Int { steine(3 - s, p) }

    public var gewinner: Int? { draussen[1] == 15 ? 1 : (draussen[2] == 15 ? 2 : nil) }

    public mutating func wuerfeln<G: RandomNumberGenerator>(mit g: inout G) {
        let a = Int.random(in: 1...6, using: &g), b = Int.random(in: 1...6, using: &g)
        setzeWurf(a, b)
    }

    public mutating func setzeWurf(_ a: Int, _ b: Int) {
        wuerfel = a == b ? [a, a, a, a] : [a, b]
        aceyOffen = regeln.aceyBonus && Set([a, b]) == [1, 2]
    }

    /// Acey-Deucey: Pasch wählen, der anschließend gespielt wird; danach würfelt derselbe Spieler noch einmal.
    @discardableResult
    public mutating func waehlePasch(_ n: Int) -> Bool {
        guard paschWahl, (1...6).contains(n) else { return false }
        paschWahl = false; wuerfel = [n, n, n, n]; nochmalWurf = true
        if zuege.isEmpty { zugEnde() }
        return true
    }

    private func alleImHeim(_ s: Int) -> Bool {
        guard bar[s] == 0 else { return false }
        for p in 0..<24 where steine(s, p) > 0 || festgesetzt[p] == s {
            if pos(s, p) < 18 { return false }
        }
        return true
    }

    /// Darf Spieler `s` auf Punkt `p` ziehen?
    private func offen(_ s: Int, _ p: Int) -> Bool {
        let eigene = punkte[p] * vz(s)
        if eigene >= 0 { return true }
        // gegnerische Steine
        if regeln.pin { return abs(punkte[p]) == 1 && festgesetzt[p] == 0 }
        return regeln.schlagen && abs(punkte[p]) == 1
    }

    /// Nardy/Fevga: Bildet Spieler `s` nach einem Zug auf `ziel` einen Block aus sechs Punkten ohne gegnerischen Stein dahinter?
    private func sechserBlock(_ s: Int, von: Int?, nach ziel: Int) -> Bool {
        var belegt = [Bool](repeating: false, count: 24)           // nach pos
        for p in 0..<24 where steine(s, p) > 0 { belegt[pos(s, p)] = true }
        if let v = von, steine(s, v) == 1 { belegt[pos(s, v)] = false }
        belegt[pos(s, ziel)] = true
        var lauf = 0
        for q in 0..<24 {
            lauf = belegt[q] ? lauf + 1 : 0
            if lauf >= 6 {
                // Gegner mit Steinen weiter auf meinem Weg?
                let gegnerVoraus = (0..<24).contains { p in gegnerSteine(s, p) > 0 && pos(s, p) > q }
                if !gegnerVoraus { return true }
            }
        }
        return false
    }

    /// Einzelzüge mit Würfel `w` (ohne Maximalregel).
    private func einzelzuege(_ w: Int) -> [BgZug] {
        let s = dran
        var z: [BgZug] = []
        if bar[s] > 0 {
            let ziel = punkt(s, w - 1)
            if offen(s, ziel) { z.append(BgZug(von: 24, nach: ziel, wuerfel: w)) }
            return z
        }
        let heim = alleImHeim(s)
        let kopfPunkt = punkt(s, 0)
        let kopfMax = (regeln.kopfRegel && erstesMal[s] && Set(wuerfel).count == 1 && wuerfel.count == 4) ? 2 : 1
        for p in 0..<24 where steine(s, p) > 0 {
            if regeln.kopfRegel, p == kopfPunkt, kopfGezogen >= kopfMax { continue }
            let np = pos(s, p) + w
            if np < 24 {
                let ziel = punkt(s, np)
                guard offen(s, ziel) else { continue }
                if regeln.sperre6, sechserBlock(s, von: p, nach: ziel) { continue }
                z.append(BgZug(von: p, nach: ziel, wuerfel: w))
            } else if heim {
                // Abtragen: genau, oder mit größerem Wurf, wenn dahinter kein eigener Stein steht
                let abstand = 24 - pos(s, p)
                if abstand == w { z.append(BgZug(von: p, nach: -1, wuerfel: w)) }
                else if w > abstand {
                    let weiter = (0..<24).contains { q in steine(s, q) > 0 && pos(s, q) < pos(s, p) }
                    if !weiter { z.append(BgZug(von: p, nach: -1, wuerfel: w)) }
                }
            }
        }
        return z
    }

    private func anwenden(_ z: BgZug) -> Backgammon {
        var k = self
        let s = dran
        if z.von == 24 { k.bar[s] -= 1 }
        else {
            k.punkte[z.von] -= vz(s)
            if regeln.kopfRegel, z.von == punkt(s, 0) { k.kopfGezogen += 1 }
            // Plakoto: Wer festsaß, wird frei, sobald der festsetzende Stein weg ist
            if k.punkte[z.von] == 0, k.festgesetzt[z.von] != 0 { k.punkte[z.von] = k.vz(k.festgesetzt[z.von]); k.festgesetzt[z.von] = 0 }
        }
        if z.nach == -1 { k.draussen[s] += 1 }
        else {
            if k.punkte[z.nach] * vz(s) < 0 {
                if regeln.pin { k.festgesetzt[z.nach] = 3 - s; k.punkte[z.nach] = 0 }
                else { k.punkte[z.nach] = 0; k.bar[3 - s] += 1 }
            }
            k.punkte[z.nach] += vz(s)
        }
        if let i = k.wuerfel.firstIndex(of: z.wuerfel) { k.wuerfel.remove(at: i) }
        return k
    }

    /// Wie viele der übrigen Würfel lassen sich noch spielen (Maximum über alle Reihenfolgen)?
    private func maximal() -> Int {
        var best = 0
        for w in Set(wuerfel) {
            for z in einzelzuege(w) { best = max(best, 1 + anwenden(z).maximal()); if best == wuerfel.count { return best } }
        }
        return best
    }

    /// Erlaubte Züge (mit der Regel, möglichst viele Würfel zu spielen; bei nur einem spielbaren: den größeren).
    public var zuege: [BgZug] {
        guard gewinner == nil, !wuerfel.isEmpty else { return [] }
        let max = maximal()
        guard max > 0 else { return [] }
        var erlaubt: [BgZug] = []
        for w in Set(wuerfel) { for z in einzelzuege(w) where 1 + anwenden(z).maximal() == max { erlaubt.append(z) } }
        if max == 1, wuerfel.count == 2, wuerfel[0] != wuerfel[1] {
            // Nur ein Würfel spielbar: wenn beide einzeln möglich sind, muss der größere gespielt werden
            let groesser = wuerfel.max()!
            if erlaubt.contains(where: { $0.wuerfel == groesser }) { erlaubt = erlaubt.filter { $0.wuerfel == groesser } }
        }
        return erlaubt
    }

    @discardableResult
    public mutating func ziehe(_ z: BgZug) -> Bool {
        guard zuege.contains(z) else { return false }
        self = anwenden(z)
        if gewinner == nil, wuerfel.isEmpty || zuege.isEmpty { zugEnde() }
        return true
    }

    /// Kein Zug möglich: Zug verfällt.
    public mutating func aussetzen() { if zuege.isEmpty { zugEnde() } }

    private mutating func zugEnde() {
        if aceyOffen && wuerfel.isEmpty && gewinner == nil {
            aceyOffen = false; paschWahl = true; return             // erst Pasch wählen
        }
        aceyOffen = false
        let bleibt = nochmalWurf; nochmalWurf = false
        wuerfel = []; erstesMal[dran] = false; kopfGezogen = 0
        if !bleibt { dran = 3 - dran }
    }

    public func pips(_ s: Int) -> Int {
        var p = bar[s] * 25
        for i in 0..<24 where steine(s, i) > 0 { p += steine(s, i) * (s == 1 ? i + 1 : 24 - i) }
        return p
    }
}

/// Spielstärke des Computers: Wahrscheinlichkeit, mit der er statt der besten irgendeine Zugfolge spielt.
public enum BackgammonStaerke: CaseIterable, Sendable {
    case leicht, mittel, schwer
    public var fehler: Double { switch self { case .leicht: 0.6; case .mittel: 0.2; case .schwer: 0 } }
}

public enum BackgammonComputer {
    public static func zugfolge(_ b: Backgammon, staerke: BackgammonStaerke) -> [BgZug] {
        var g = SystemRandomNumberGenerator()
        return zugfolge(b, fehler: staerke.fehler, mit: &g)
    }

    /// Wie `zugfolge`; mit Wahrscheinlichkeit `fehler` wählt der Computer irgendeine vollständige Zugfolge.
    public static func zugfolge<G: RandomNumberGenerator>(_ b: Backgammon, fehler: Double, mit g: inout G) -> [BgZug] {
        guard fehler > 0, Double.random(in: 0..<1, using: &g) < fehler else { return zugfolge(b) }
        var folgen: [[BgZug]] = []
        func suche(_ s: Backgammon, _ weg: [BgZug]) {
            let z = s.zuege
            if z.isEmpty || s.dran != b.dran { folgen.append(weg); return }
            if folgen.count > 400 { return }
            for m in z { var k = s; k.ziehe(m); suche(k, weg + [m]) }
        }
        suche(b, [])
        return folgen.randomElement(using: &g) ?? []
    }

    /// Spielt alle Würfel mit dem besten Zugfolgen-Ergebnis.
    public static func zugfolge(_ b: Backgammon) -> [BgZug] { zugfolge(b, art: .neu) }

    enum Bewertung { case alt, neu }
    static func zugfolge(_ b: Backgammon, art: Bewertung) -> [BgZug] {
        var best: ([BgZug], Double) = ([], -.infinity)
        func suche(_ s: Backgammon, _ weg: [BgZug]) {
            let z = s.zuege
            if z.isEmpty || s.dran != b.dran { let w = bewerte(s, fuer: b.dran, art); if w > best.1 { best = (weg, w) }; return }
            for m in z { var k = s; k.ziehe(m); suche(k, weg + [m]) }
        }
        suche(b, [])
        return best.0
    }

    /// Stellungswert aus Sicht von `p`. Bei Varianten ohne Schlagen (Nardy, Fevga, Plakoto) zählt nur das Rennen;
    /// sonst kommen Angriffsflächen (einzelne Steine in Reichweite des Gegners), eigene Punkte, Heimfeld und Blockaden dazu.
    static func bewerte(_ s: Backgammon, fuer p: Int, _ art: Bewertung = .neu) -> Double {
        let g = 3 - p
        var w = Double(s.pips(g) - s.pips(p))
        w += Double(s.draussen[p] - s.draussen[g]) * 8
        w += Double(s.bar[g] - s.bar[p]) * 10
        guard s.regeln.schlagen, !s.regeln.pin, !s.regeln.richtungGleich else {
            for i in 0..<24 {
                let st = s.punkte[i] * (p == 1 ? 1 : -1)
                if st == 1 { w -= 1 } else if st >= 2 { w += 1 }
            }
            return w
        }
        // Kontakt: Steht noch ein Stein des Gegners hinter einem eigenen?
        func steine(_ q: Int, _ i: Int) -> Int { max(0, s.punkte[i] * (q == 1 ? 1 : -1)) }
        let weisseHoechster = (0..<24).filter { steine(1, $0) > 0 }.max() ?? -1
        let schwarzerTiefster = (0..<24).filter { steine(2, $0) > 0 }.min() ?? 24
        let kontakt = s.bar[1] > 0 || s.bar[2] > 0 || schwarzerTiefster < weisseHoechster
        if !kontakt { return w }
        func seite(_ q: Int) -> Double {
            var v = 0.0
            let heim = q == 1 ? Array(0...5) : Array(18...23)
            var reihe = 0, bestReihe = 0
            for i in (q == 1 ? Array((0..<24).reversed()) : Array(0..<24)) {
                let n = steine(q, i)
                if n >= 2 { reihe += 1; bestReihe = max(bestReihe, reihe) } else { reihe = 0 }
                if n >= 2 { v += 2.5; if heim.contains(i) { v += 2 } }
                if n == 1 {
                    // Wie viele gegnerische Steine können diesen Einzelstein direkt erreichen?
                    var schuesse = 0
                    for j in 0..<24 {
                        let d = q == 1 ? i - j : j - i          // Gegner (3-q) zieht in die andere Richtung
                        if (1...6).contains(d) { schuesse += steine(3 - q, j) > 0 ? 1 : 0 }
                    }
                    if s.bar[3 - q] > 0, (q == 1 ? i <= 5 : i >= 18) { schuesse += 1 }
                    if art == .neu {
                        // Trefferwahrscheinlichkeit aus den 36 Würfen (direkt 1–6, indirekt 7–12), Summe über die Angreifer gedeckelt
                        let kombis = [0, 11, 12, 14, 15, 15, 17, 6, 6, 5, 3, 2, 3]
                        var treffer = 0
                        for j in 0..<24 where steine(3 - q, j) > 0 {
                            let d = q == 1 ? i - j : j - i
                            if (1...12).contains(d) { treffer += kombis[d] }
                        }
                        if s.bar[3 - q] > 0, (q == 1 ? i <= 5 : i >= 18) { treffer += 11 }
                        let risiko = Double(min(treffer, 36)) / 36
                        // Verlust bei Treffer: bereits gelaufene Strecke des Steins + Bar-Strafe, nahe der Gegner-Heimat härter
                        let gelaufen = Double(q == 1 ? 24 - i : i + 1)
                        v -= 1.0 + risiko * (6.0 + gelaufen * 0.6)
                    } else {
                        v -= 2.0 + 3.0 * Double(min(schuesse, 3))
                    }
                    if heim.contains(i) { v -= 1 }
                }
            }
            if bestReihe >= 3 { v += Double(bestReihe - 2) * 3 }       // Blockade (Prime)
            return v
        }
        w += seite(p) - seite(g)
        return w
    }
}
