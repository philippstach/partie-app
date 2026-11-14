// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Mäxchen-Rangfolge: 31 < … < 65 < Pasch 11 < … < Pasch 66 < Mäxchen (2·1).
public enum MaexchenWert {
    public static func rang(_ a: Int, _ b: Int) -> Int {
        let hi = max(a, b), lo = min(a, b)
        if hi == 2 && lo == 1 { return 200 }
        if hi == lo { return 100 + hi }
        return hi * 10 + lo
    }
    /// Alle 21 Ansagen aufsteigend.
    public static let alle: [Int] = {
        var r = Set<Int>()
        for a in 1...6 { for b in 1...6 { r.insert(rang(a, b)) } }
        return r.sorted()
    }()
    public static func text(_ rang: Int) -> String {
        if rang == 200 { return String(localized: "Mäxchen") }
        if rang >= 100 { return String(localized: "Pasch \(rang - 100)") }
        return "\(rang)"
    }
}

/// Mäxchen: Verdeckt würfeln, eine (ehrliche oder gelogene) Ansage machen; der Nächste glaubt oder zweifelt.
public struct Maexchen: Sendable, Codable {
    public enum Phase: Equatable, Sendable, Codable { case wuerfeln, ansagen, entscheiden }

    public private(set) var leben: [Int]
    public private(set) var dran = 0
    public private(set) var phase: Phase = .wuerfeln
    private(set) var wurfAugen: [Int]?               // gespeichert (Fortsetzen)
    /// Verdeckter Wurf des aktuellen Spielers.
    public private(set) var wurf: (Int, Int)? {
        get { wurfAugen.map { ($0[0], $0[1]) } }
        set { wurfAugen = newValue.map { [$0.0, $0.1] } }
    }
    public private(set) var ansage: Int?               // letzte Ansage
    public private(set) var ansager: Int?
    public private(set) var verlierer: Int?
    private(set) var aufgedecktAugen: [Int]?
    public private(set) var aufgedeckt: (Int, Int)? {
        get { aufgedecktAugen.map { ($0[0], $0[1]) } }
        set { aufgedecktAugen = newValue.map { [$0.0, $0.1] } }
    }
    public private(set) var log: [String] = []
    /// Nur aufgedeckte Ansagen zählen: wie oft jemand angesagt hat und wie oft das gelogen war.
    public private(set) var aufgedeckteAnsagen: [Int] = []
    public private(set) var aufgedeckteLuegen: [Int] = []
    /// Blatt 22 (EB2, Schritt 2): je Person sechs Zähler (Index 0 = Einsen), wie viele davon eingetippt wurden und wie oft ein Mäxchen fiel.
    /// Optional: ein Stand von vor dem Update lädt mit `nil` (dann keine Zeile „Mäxchen geworfen“ und kein Würfelbild).
    public private(set) var augen: [[Int]]?
    public private(set) var eingetippt: [Int]?
    public private(set) var maexchenWuerfe: Int?

    /// T-097: `beginner` (0-basiert) sagt in der ersten Runde zuerst an.
    public init(spieler: Int, leben: Int, beginner: Int) {
        self.init(spieler: spieler, leben: leben)
        dran = min(max(beginner, 0), spieler - 1)
    }

    public init(spieler: Int, leben: Int = 3) {
        self.leben = Array(repeating: leben, count: spieler)
        augen = Array(repeating: Array(repeating: 0, count: 6), count: spieler)
        eingetippt = Array(repeating: 0, count: spieler)
        maexchenWuerfe = 0
        aufgedeckteAnsagen = Array(repeating: 0, count: spieler); aufgedeckteLuegen = Array(repeating: 0, count: spieler)
    }

    public var aktive: [Int] { leben.indices.filter { leben[$0] > 0 } }
    public var sieger: Int? { aktive.count == 1 ? aktive[0] : nil }
    public var wurfRang: Int? { wurf.map { MaexchenWert.rang($0.0, $0.1) } }
    /// Erlaubte Ansagen: strikt höher als die letzte.
    public var moeglicheAnsagen: [Int] { MaexchenWert.alle.filter { $0 > (ansage ?? 0) } }

    private func naechster(_ i: Int) -> Int {
        var n = (i + 1) % leben.count
        while leben[n] <= 0 { n = (n + 1) % leben.count }
        return n
    }

    public mutating func wuerfeln<G: RandomNumberGenerator>(mit g: inout G) {
        guard phase == .wuerfeln else { return }
        wurf = (Int.random(in: 1...6, using: &g), Int.random(in: 1...6, using: &g))
        phase = .ansagen
        zaehleWurf(echt: false)
    }

    /// Zählt den gerade gefallenen Wurf für den, der dran ist (ein alter Stand ohne Zählung zählt nicht mit).
    private mutating func zaehleWurf(echt: Bool) {
        guard let w = wurf else { return }
        if var a = augen, a.indices.contains(dran), a[dran].count == 6 {
            a[dran][w.0 - 1] += 1; a[dran][w.1 - 1] += 1
            augen = a
            if var e = eingetippt, e.indices.contains(dran), echt { e[dran] += 2; eingetippt = e }
        }
        if let m = maexchenWuerfe, MaexchenWert.rang(w.0, w.1) == 200 { maexchenWuerfe = m + 1 }
    }

    /// Echte Würfel: Augen eintippen.
    public mutating func setzeWurf(_ a: Int, _ b: Int) {
        guard phase == .wuerfeln, (1...6).contains(a), (1...6).contains(b) else { return }
        wurf = (a, b); phase = .ansagen
        zaehleWurf(echt: true)
    }

    @discardableResult
    public mutating func ansagen(_ rang: Int) -> Bool {
        guard phase == .ansagen, moeglicheAnsagen.contains(rang) else { return false }
        ansage = rang; ansager = dran; dran = naechster(dran); phase = .entscheiden
        aufgedeckt = nil; verlierer = nil
        return true
    }

    /// Der nächste glaubt: Er würfelt selbst verdeckt und muss höher ansagen.
    public mutating func glauben() {
        guard phase == .entscheiden else { return }
        if ansage == 200 { zweifeln(); return }   // auf Mäxchen gibt es nichts Höheres: man muss aufdecken
        wurf = nil; phase = .wuerfeln
    }

    /// Der nächste zweifelt: Der Wurf des Ansagers wird aufgedeckt.
    public mutating func zweifeln() {
        guard phase == .entscheiden, let a = ansager, let w = wurf, let an = ansage else { return }
        aufgedeckt = w
        let ehrlich = MaexchenWert.rang(w.0, w.1) >= an
        let v = ehrlich ? dran : a
        aufgedeckteAnsagen[a] += 1; if !ehrlich { aufgedeckteLuegen[a] += 1 }
        let schaden = (an == 200 && ehrlich) ? 2 : 1
        leben[v] = max(0, leben[v] - schaden)
        verlierer = v
        log.append("\(MaexchenWert.text(an)) – \(ehrlich ? "stimmte" : "gelogen")")
        neueRunde(beginnt: leben[v] > 0 ? v : naechster(v))
    }

    private mutating func neueRunde(beginnt: Int) {
        dran = beginnt; ansage = nil; ansager = nil; wurf = nil; phase = .wuerfeln
    }
}

/// Einfacher Computer: ehrlich, wenn der Wurf reicht, sonst kleine Lüge; zweifelt bei hohen Ansagen.
public enum MaexchenComputer {
    /// Wahrscheinlichkeit, dass ein Wurf mindestens `rang` erreicht (36 Würfe).
    public static func wahrscheinlichkeit(mindestens rang: Int) -> Double {
        var n = 0
        for a in 1...6 { for b in 1...6 where MaexchenWert.rang(a, b) >= rang { n += 1 } }
        return Double(n) / 36
    }

    /// `stufe` 1 leicht (viel zufällig), 2 mittel, 3 schwer (kleinste glaubhafte Lüge, zweifelt nach Höhe der Ansage und der beobachteten Lügenquote des Gegners).
    public static func ansage<G: RandomNumberGenerator>(_ m: Maexchen, stufe: Int, mit g: inout G) -> Int {
        let moegl = m.moeglicheAnsagen
        let echt = m.wurfRang ?? 0
        if stufe <= 1 { return moegl.randomElement(using: &g) ?? echt }
        if stufe == 2 { return ansage(m, mit: &g) }
        // Schwer: ehrlich, wenn der Wurf reicht; sonst die kleinste glaubhafte Lüge
        if echt > (m.ansage ?? 0) { return moegl.first(where: { $0 >= echt }) ?? echt }
        let k = Double.random(in: 0..<1, using: &g) < 0.7 ? 0 : min(1, moegl.count - 1)
        return moegl[k]
    }

    public static func zweifelt<G: RandomNumberGenerator>(_ m: Maexchen, stufe: Int, mit g: inout G) -> Bool {
        guard let a = m.ansage, let ansager = m.ansager else { return false }
        if stufe <= 1 { return Bool.random(using: &g) }
        if stufe == 2 { return zweifelt(m, mit: &g) }
        if a == 200 { return Double.random(in: 0..<1, using: &g) < 0.85 }
        // Grundwert wie „mittel“ (je höher die Ansage, desto eher gelogen), nachjustiert mit der beobachteten Lügenquote des Ansagers:
        // wer oft erwischt wurde, wird eher angezweifelt, wer meist ehrlich war, eher geglaubt.
        let grund: Double = a >= 100 ? 0.65 : (a >= 61 ? 0.5 : (a >= 51 ? 0.3 : 0.12))
        let luegenQuote = Double(m.aufgedeckteLuegen[ansager] + 1) / Double(m.aufgedeckteAnsagen[ansager] + 2)    // 0,5 ohne Erfahrung
        return Double.random(in: 0..<1, using: &g) < min(0.9, max(0.03, grund * (0.4 + luegenQuote * 1.2)))
    }

    public static func ansage<G: RandomNumberGenerator>(_ m: Maexchen, mit g: inout G) -> Int {
        let moegl = m.moeglicheAnsagen
        let echt = m.wurfRang ?? 0
        if let ehrlich = moegl.first(where: { $0 == echt }), Int.random(in: 0..<5, using: &g) > 0 { return ehrlich }
        if echt > (m.ansage ?? 0) { return moegl.filter { $0 >= echt }.first ?? echt }
        // Lüge: ein bis drei Stufen über der letzten Ansage
        let k = min(Int.random(in: 0...2, using: &g), moegl.count - 1)
        return moegl[k]
    }

    public static func zweifelt<G: RandomNumberGenerator>(_ m: Maexchen, mit g: inout G) -> Bool {
        guard let a = m.ansage else { return false }
        if a == 200 { return Int.random(in: 0..<4, using: &g) > 0 }
        let wahrscheinlich: Double = a >= 100 ? 0.65 : (a >= 61 ? 0.5 : (a >= 51 ? 0.3 : 0.12))
        return Double.random(in: 0..<1, using: &g) < wahrscheinlich
    }
}
