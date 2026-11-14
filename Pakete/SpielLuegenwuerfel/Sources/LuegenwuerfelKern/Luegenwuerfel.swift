// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

public struct Gebot: Equatable, Sendable, Codable {
    public let anzahl: Int
    public let augen: Int
    public init(_ anzahl: Int, _ augen: Int) { self.anzahl = anzahl; self.augen = augen }
    /// Ein Gebot ist höher bei mehr Würfeln oder gleicher Anzahl mit mehr Augen.
    public func hoeherAls(_ o: Gebot) -> Bool { anzahl > o.anzahl || (anzahl == o.anzahl && augen > o.augen) }
}

/// Regelvariante: `.standard` (Lügenwürfel) oder `.perudo` (Einser-Joker, Einser-Steigerung, Palifico, Calza).
public struct LuegenRegeln: Equatable, Sendable, Codable {
    public var einserJoker = false      // Einser zählen bei jeder Augenzahl mit (außer bei Gebot auf Einser); erstes Gebot nicht auf Einser
    public var palifico = false         // Spieler mit nur noch einem Würfel: einmal Runde mit fester Augenzahl, Einser ohne Joker
    public var calza = false            // „Genau richtig“: Würfel gewinnen oder verlieren
    public static let standard = LuegenRegeln()
    public static let perudo = LuegenRegeln(einserJoker: true, palifico: true, calza: true)
    public init(einserJoker: Bool = false, palifico: Bool = false, calza: Bool = false) {
        self.einserJoker = einserJoker; self.palifico = palifico; self.calza = calza
    }
}

/// Lügenwürfel (Liar's Dice): Jeder hat verdeckt fünf Würfel (je Verlust einen weniger). Gebote über alle Würfel am Tisch; anzweifeln.
public struct Luegenwuerfel: Sendable, Codable {
    /// Die letzte Auflösung ist nur Anzeige und wird nicht gespeichert.
    private enum CodingKeys: String, CodingKey { case wuerfel, anzahlen, dran, gebot, bieter, regeln, startWuerfel, palificoRunde, palificoGenutzt }
    public private(set) var wuerfel: [[Int]]
    public private(set) var anzahlen: [Int]
    public private(set) var dran = 0
    public private(set) var gebot: Gebot?
    public private(set) var bieter: Int?
    public private(set) var letzteAuflösung: (verlierer: Int, gezaehlt: Int, gebot: Gebot)?
    public let regeln: LuegenRegeln
    public let startWuerfel: Int
    public private(set) var palificoRunde = false
    private var palificoGenutzt: [Bool]

    public init(spieler: Int, wuerfelJeSpieler: Int = 5, regeln: LuegenRegeln = .standard) {
        self.regeln = regeln; startWuerfel = wuerfelJeSpieler
        palificoGenutzt = Array(repeating: false, count: spieler)
        anzahlen = Array(repeating: wuerfelJeSpieler, count: spieler)
        wuerfel = Array(repeating: [], count: spieler)
    }

    public var aktive: [Int] { anzahlen.indices.filter { anzahlen[$0] > 0 } }
    public var sieger: Int? { aktive.count == 1 ? aktive[0] : nil }
    public var gesamt: Int { anzahlen.reduce(0, +) }

    public mutating func neueRunde<G: RandomNumberGenerator>(beginnt: Int? = nil, mit g: inout G) {
        wuerfel = anzahlen.map { n in (0..<n).map { _ in Int.random(in: 1...6, using: &g) } }
        gebot = nil; bieter = nil; palificoRunde = false
        if let b = beginnt, anzahlen[b] > 0 { dran = b } else { dran = aktive.first ?? 0 }
        if regeln.palifico, anzahlen[dran] == 1, !palificoGenutzt[dran], aktive.count > 2 { palificoRunde = true; palificoGenutzt[dran] = true }
    }

    /// Echte Würfel: die Augen, die ein Spieler unter dem Becher gewürfelt hat (Anzahl muss zu seinen Würfeln passen).
    @discardableResult
    public mutating func setzeWuerfel(_ augen: [Int], fuer spieler: Int) -> Bool {
        guard anzahlen.indices.contains(spieler), augen.count == anzahlen[spieler], augen.allSatisfy({ (1...6).contains($0) }) else { return false }
        wuerfel[spieler] = augen
        return true
    }

    #if DEBUG
    /// Nur für Tests: feste Würfel/Anzahlen setzen.
    public mutating func testWuerfel(_ w: [[Int]]) { wuerfel = w }
    public mutating func testAnzahlen(_ a: [Int]) { anzahlen = a }
    #endif

    /// Zählt die Würfel für eine Augenzahl; Einser sind Joker (nicht bei Palifico, nicht beim Zählen von Einsern).
    public func zaehle(_ augen: Int) -> Int {
        let alle = wuerfel.flatMap { $0 }
        let joker = regeln.einserJoker && !palificoRunde && augen != 1
        return alle.filter { $0 == augen || (joker && $0 == 1) }.count
    }

    /// Ist `neu` nach den Regeln als Folgegebot (oder Eröffnung) erlaubt?
    public func erlaubt(_ neu: Gebot, nach alt: Gebot?) -> Bool {
        guard (1...6).contains(neu.augen), neu.anzahl >= 1, neu.anzahl <= gesamt else { return false }
        guard let alt else { return !(regeln.einserJoker && !palificoRunde && neu.augen == 1) }
        if palificoRunde { return neu.augen == alt.augen && neu.anzahl > alt.anzahl }
        guard regeln.einserJoker else { return neu.hoeherAls(alt) }
        switch (alt.augen == 1, neu.augen == 1) {
        case (false, true): return neu.anzahl >= (alt.anzahl + 1) / 2
        case (true, false): return neu.anzahl >= alt.anzahl * 2 + 1
        case (true, true): return neu.anzahl > alt.anzahl
        default: return neu.hoeherAls(alt)
        }
    }

    private func naechster(_ i: Int) -> Int { var n = (i + 1) % anzahlen.count; while anzahlen[n] == 0 { n = (n + 1) % anzahlen.count }; return n }

    @discardableResult
    public mutating func biete(_ g: Gebot) -> Bool {
        guard sieger == nil, erlaubt(g, nach: gebot) else { return false }
        gebot = g; bieter = dran; dran = naechster(dran); letzteAuflösung = nil
        return true
    }

    /// Zweifelt das letzte Gebot an. Wer sich irrt, verliert einen Würfel; der Verlierer beginnt die nächste Runde.
    public mutating func zweifeln() -> (verlierer: Int, gezaehlt: Int)? {
        guard let g = gebot, let b = bieter else { return nil }
        let gez = zaehle(g.augen)
        let verlierer = gez >= g.anzahl ? dran : b
        anzahlen[verlierer] -= 1
        letzteAuflösung = (verlierer, gez, g)
        return (verlierer, gez)
    }

    /// Calza (nur Perudo): Der Spieler am Zug behauptet, das Gebot stimme genau. Stimmt es, bekommt er einen Würfel (höchstens Startzahl),
    /// sonst verliert er einen. Gibt (Spieler, gezählt, richtig) zurück.
    public mutating func calzaRufen() -> (spieler: Int, gezaehlt: Int, richtig: Bool)? {
        guard regeln.calza, let g = gebot, sieger == nil else { return nil }
        let gez = zaehle(g.augen), rufer = dran
        let richtig = gez == g.anzahl
        if richtig { anzahlen[rufer] = min(startWuerfel, anzahlen[rufer] + 1) } else { anzahlen[rufer] -= 1 }
        letzteAuflösung = (richtig ? -1 : rufer, gez, g)
        return (rufer, gez, richtig)
    }
}

public enum LuegenwuerfelComputer {
    /// Wie viel über der Erwartung ein Gebot liegen muss, bevor die Stufe zweifelt (Stufe „schwer“ per Simulation ermittelt: 1,6 schlägt „mittel“ in rund 80 % der Partien).
    static let schwerRand = 1.6

    /// Wahrscheinlichkeitsschätzung: erwartete Anzahl der gesuchten Augen = eigene + Rest/6.
    /// `stufe` 1 leicht (zweifelt oft nach Gefühl), 2 mittel, 3 schwer.
    public static func zweifelt(_ s: Luegenwuerfel, spieler: Int, stufe: Int = 2) -> Bool {
        guard let g = s.gebot else { return false }
        let ueber = Double(g.anzahl) - erwartet(s, spieler: spieler, augen: g.augen)
        switch stufe {
        case ...1: return Double.random(in: 0..<1) < 0.5 ? Bool.random() : ueber > 1.0
        case 2: return ueber > 1.0
        default: return ueber > schwerRand
        }
    }

    /// Wahrscheinlichkeit (0…1), dass das letzte Gebot stimmt, aus Sicht von `spieler`: eigene Würfel bekannt, fremde zufällig (1/6, mit Joker 1/3).
    public static func wahrheitsChance(_ s: Luegenwuerfel, spieler: Int) -> Double {
        guard let g = s.gebot else { return 1 }
        let joker = s.regeln.einserJoker && !s.palificoRunde && g.augen != 1
        let eigene = s.wuerfel[spieler].filter { $0 == g.augen || (joker && $0 == 1) }.count
        let noetig = g.anzahl - eigene
        if noetig <= 0 { return 1 }
        let fremde = s.gesamt - s.anzahlen[spieler]
        if noetig > fremde { return 0 }
        let p = joker ? 1.0 / 3 : 1.0 / 6
        // P(mindestens `noetig` Treffer bei `fremde` Würfeln) = 1 − P(höchstens noetig−1)
        var unter = 0.0
        for k in 0..<noetig {
            var c = 1.0
            for i in 0..<k { c *= Double(fremde - i) / Double(i + 1) }
            unter += c * pow(p, Double(k)) * pow(1 - p, Double(fremde - k))
        }
        return min(1, max(0, 1 - unter))
    }

    /// Erwartete Zahl gesuchter Würfel (eigene bekannt, fremde mit Wahrscheinlichkeit 1/6 bzw. 1/3 bei Joker).
    static func erwartet(_ s: Luegenwuerfel, spieler: Int, augen: Int) -> Double {
        let joker = s.regeln.einserJoker && !s.palificoRunde && augen != 1
        let eigene = s.wuerfel[spieler].filter { $0 == augen || (joker && $0 == 1) }.count
        return Double(eigene) + Double(s.gesamt - s.anzahlen[spieler]) * (joker ? 1.0 / 3 : 1.0 / 6)
    }

    /// Calza nur, wenn das Gebot der Erwartung fast genau entspricht und wenige Würfel im Spiel sind.
    public static func ruftCalza(_ s: Luegenwuerfel, spieler: Int) -> Bool {
        guard s.regeln.calza, let g = s.gebot, s.gesamt <= 6 else { return false }
        return abs(Double(g.anzahl) - erwartet(s, spieler: spieler, augen: g.augen)) < 0.25
    }

    public static func gebot(_ s: Luegenwuerfel, spieler: Int) -> Gebot {
        var best: (Gebot, Double)?
        for augen in 1...6 {
            let erwartet = erwartet(s, spieler: spieler, augen: augen)
            let moegliche = (1...max(1, s.gesamt)).map { Gebot($0, augen) }.filter { s.erlaubt($0, nach: s.gebot) }
            guard let g = moegliche.first else { continue }
            let abstand = Double(g.anzahl) - erwartet
            if best == nil || abstand < best!.1 { best = (g, abstand) }
        }
        return best?.0 ?? (s.gebot.flatMap { b in (1...max(1, s.gesamt)).flatMap { n in (1...6).map { Gebot(n, $0) } }.first { s.erlaubt($0, nach: b) } } ?? Gebot(1, 6))
    }
}
