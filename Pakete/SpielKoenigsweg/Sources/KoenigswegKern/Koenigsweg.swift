// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Königsweg (nach dem altmesopotamischen Königsspiel von Ur): Jeder hat sieben Steine und muss sie über einen 14-Felder-Weg aus dem Spiel bringen.
/// Vier Münzwürfe ergeben 0 bis 4 Schritte. Felder 5–12 sind gemeinsam: Dort werden gegnerische Steine geschlagen und zurückgeschickt.
/// Rosettenfelder (4, 8, 14) geben einen Extrazug; auf der mittleren Rosette (8) ist man sicher. Der Ausgang muss genau getroffen werden (Feld 15).
public struct Koenigsweg: Equatable, Sendable, Codable {
    public static let steine = 7
    public static let weg = 14
    public static let rosetten: Set<Int> = [4, 8, 14]

    public struct Zug: Equatable, Sendable, Codable { public var von: Int; public var nach: Int }

    public private(set) var brett: [[Int]]          // [Spieler] Zahl der Steine pro Feld 0…15 (0 = Vorrat, 15 = draußen)
    public private(set) var amZug = 0
    public private(set) var wurf: Int?
    public private(set) var sieger: Int?
    public private(set) var meldung = ""
    /// 1.0 (P4): Zahl des zuletzt geworfenen Wurfs (0…4), auch wenn der Wurf gleich verfällt (Null, kein Zug). Für die Würfelbilanz.
    /// Optional, damit gespeicherte Stände ohne dieses Feld weiter laden.
    public private(set) var letzterWurf: Int?
    /// Blatt 22 (EB2, Schritt 2): wie viele gegnerische Steine jede Seite geschlagen hat. Optional: ein Stand von vor dem Update lädt mit `nil`,
    /// dann keine Zeile „Geschlagen“.
    public private(set) var geschlagen: [Int]?

    public init() {
        var b = Array(repeating: Array(repeating: 0, count: 16), count: 2)
        b[0][0] = Koenigsweg.steine; b[1][0] = Koenigsweg.steine
        brett = b
        geschlagen = [0, 0]
    }

    /// T-097: `beginner` (1 = erster, 2 = zweiter Eintrag) wirft zuerst; Standard wie bisher der erste.
    public init(beginner: Int) {
        self.init()
        amZug = beginner == 2 ? 1 : 0
    }

    /// Feste Stellung (Tests, Wiederaufnahme). `steine[s]` = Felder 0…15 mit der Zahl der Steine.
    public init(steine: [[Int]], amZug: Int = 0, wurf: Int? = nil) { brett = steine; self.amZug = amZug; self.wurf = wurf; geschlagen = [0, 0] }

    /// C-024: Prüfung eines geladenen Stands.
    public var istStimmig: Bool { brett.count == 2 && brett.allSatisfy { $0.count == 16 } && (0..<2).contains(amZug) && (wurf.map { (0...4).contains($0) } ?? true) }

    public static func gemeinsam(_ f: Int) -> Bool { (5...12).contains(f) }

    /// Gibt zurück, ob geworfen wurde (1.0 P4: für die Würfelbilanz).
    @discardableResult
    public mutating func wuerfeln<G: RandomNumberGenerator>(mit g: inout G) -> Bool {
        guard wurf == nil, sieger == nil else { return false }
        return setzeWurf((0..<4).reduce(0) { a, _ in a + Int.random(in: 0...1, using: &g) })
    }

    /// Echte Münzen: Zahl der Münzen mit Punkt (0…4) von Hand setzen.
    @discardableResult
    public mutating func setzeWurf(_ punkte: Int) -> Bool {
        guard wurf == nil, sieger == nil, (0...4).contains(punkte) else { return false }
        wurf = punkte; letzterWurf = punkte
        if wurf == 0 || zuege().isEmpty { meldung = wurf == 0 ? "Null – ausgesetzt" : "Kein Zug möglich"; wurf = nil; amZug = 1 - amZug }
        else { meldung = "" }
        return true
    }

    /// Mögliche Züge mit dem aktuellen Wurf.
    public func zuege() -> [Zug] {
        guard let w = wurf, w > 0 else { return [] }
        var z: [Zug] = []
        for f in 0...14 where brett[amZug][f] > 0 {
            let n = f + w
            if n > 15 { continue }
            if n < 15 {
                if brett[amZug][n] > 0 { continue }               // eigener Stein steht schon dort
                if Koenigsweg.gemeinsam(n), n == 8, brett[1 - amZug][n] > 0 { continue }   // sichere Rosette
            }
            z.append(Zug(von: f, nach: n))
        }
        return z
    }

    @discardableResult
    public mutating func ziehe(_ z: Zug) -> Bool {
        guard sieger == nil, zuege().contains(z) else { return false }
        brett[amZug][z.von] -= 1; brett[amZug][z.nach] += 1
        meldung = ""
        if z.nach < 15, Koenigsweg.gemeinsam(z.nach), brett[1 - amZug][z.nach] > 0 {
            brett[1 - amZug][z.nach] -= 1; brett[1 - amZug][0] += 1; meldung = "Stein geschlagen!"
            if var g = geschlagen, g.count == 2 { g[amZug] += 1; geschlagen = g }
        }
        wurf = nil
        if brett[amZug][15] == Koenigsweg.steine { sieger = amZug; return true }
        if z.nach < 15, Koenigsweg.rosetten.contains(z.nach) { meldung += (meldung.isEmpty ? "" : " ") + "Rosette – nochmal!" } else { amZug = 1 - amZug }
        return true
    }

    public func draussen(_ s: Int) -> Int { brett[s][15] }
    public func vorrat(_ s: Int) -> Int { brett[s][0] }

    // MARK: Computer

    public func computerZug<G: RandomNumberGenerator>(stufe: Int, mit g: inout G) -> Zug? {
        let z = zuege()
        guard !z.isEmpty else { return nil }
        if stufe == 1 { return z.randomElement(using: &g) }
        if stufe >= 3 { return z.max { vorausschau($0, tiefe: 2) < vorausschau($1, tiefe: 2) } }
        func wert(_ m: Zug) -> Double {
            var w = Double(m.nach) * 0.3
            if m.nach == 15 { w += 6 }
            if m.nach < 15, Koenigsweg.gemeinsam(m.nach), brett[1 - amZug][m.nach] > 0 { w += 8 + Double(m.nach) }     // schlagen: je weiter, desto besser
            if Koenigsweg.rosetten.contains(m.nach) { w += 7 }
            if m.nach == 8 { w += 2 }
            if m.von == 0 { w += 1 }
            // Gefahr: auf gemeinsamem Feld vor gegnerischen Steinen in Reichweite
            if m.nach < 15, Koenigsweg.gemeinsam(m.nach), !Koenigsweg.rosetten.contains(m.nach) {
                let bedroht = (1...4).filter { d in m.nach - d >= 0 && brett[1 - amZug][m.nach - d] > 0 }.count
                w -= Double(bedroht) * (stufe >= 3 ? 1.5 : 0.5)
            }
            if m.von < 15, Koenigsweg.gemeinsam(m.von), !Koenigsweg.rosetten.contains(m.von) {
                let bedroht = (1...4).filter { d in m.von - d >= 0 && brett[1 - amZug][m.von - d] > 0 }.count
                w += Double(bedroht) * (stufe >= 3 ? 1.5 : 0.5)       // aus der Gefahr herausziehen
            }
            return w
        }
        return z.max { wert($0) < wert($1) }
    }

    /// Münzwurf-Wahrscheinlichkeiten für 0…4 Punkte.
    private static let wurfChance: [Double] = [1, 4, 6, 4, 1].map { $0 / 16 }

    /// Stellungswert aus Sicht von `ich`: Vorsprung im Weg, sichere Mittelrosette zählt extra.
    private static func stellung(_ k: Koenigsweg, ich: Int) -> Double {
        func fortschritt(_ s: Int) -> Double {
            var w = 0.0
            for f in 1...15 where k.brett[s][f] > 0 {
                w += Double(f * k.brett[s][f])
                if f == 8 { w += 3 } else if f == 15 { w += 4 * Double(k.brett[s][f]) }
            }
            return w
        }
        return fortschritt(ich) - fortschritt(1 - ich)
    }

    /// Erwartungswert (Expectimax) eines Zugs: nach dem Zug folgen Münzwurf und beste Antwort des Gegners, `tiefe` Halbzüge weit.
    func vorausschau(_ z: Zug, tiefe: Int) -> Double {
        let ich = amZug
        var k = self
        k.ziehe(z)
        return Koenigsweg.erwartung(k, ich: ich, tiefe: tiefe - 1)
    }

    private static func erwartung(_ k: Koenigsweg, ich: Int, tiefe: Int) -> Double {
        if let s = k.sieger { return s == ich ? 10_000 : -10_000 }
        if tiefe <= 0 { return stellung(k, ich: ich) }
        var summe = 0.0
        for (r, p) in wurfChance.enumerated() {
            var t = Koenigsweg(steine: k.brett, amZug: k.amZug, wurf: nil)
            if r == 0 { t.amZug = 1 - t.amZug; summe += p * erwartung(t, ich: ich, tiefe: tiefe - 1); continue }
            t = Koenigsweg(steine: k.brett, amZug: k.amZug, wurf: r)
            let zuege = t.zuege()
            if zuege.isEmpty { t = Koenigsweg(steine: k.brett, amZug: 1 - k.amZug); summe += p * erwartung(t, ich: ich, tiefe: tiefe - 1); continue }
            var werte: [Double] = []
            for m in zuege { var n = t; n.ziehe(m); werte.append(erwartung(n, ich: ich, tiefe: tiefe - 1)) }
            summe += p * (t.amZug == ich ? werte.max()! : werte.min()!)
        }
        return summe
    }
}
