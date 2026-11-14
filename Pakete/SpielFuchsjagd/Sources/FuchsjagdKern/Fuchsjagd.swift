// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

public struct Pos: Hashable, Sendable, Codable { public var x: Int; public var y: Int; public init(_ x: Int, _ y: Int) { self.x = x; self.y = y } }

public struct FuchsZug: Equatable, Sendable, Codable { public var von: Pos; public var nach: Pos; public var schlag: Pos? }

/// Startaufstellung: 13 Gänse (klassisch), 17 Gänse (englische Form, Fuchs darf auch schräg) oder zwei Füchse gegen 20 Gänse.
public enum FuchsVariante: String, Sendable, Codable, CaseIterable {
    case dreizehn, siebzehn, zweiFuechse
    public var gaenseZahl: Int { switch self { case .dreizehn: 13; case .siebzehn: 17; case .zweiFuechse: 20 } }
    public var fuchsZahl: Int { self == .zweiFuechse ? 2 : 1 }
    /// Der Fuchs gewinnt, sobald weniger Gänse übrig sind.
    public var gaenseMinimum: Int { switch self { case .dreizehn: 4; case .siebzehn: 6; case .zweiFuechse: 8 } }
    /// Englische Form: Der Fuchs zieht und springt auch schräg.
    public var fuchsSchraeg: Bool { self == .siebzehn }
}

/// Regelvarianten der Fuchsjagd. Standard: Fuchs darf frei wählen, Gänse gehen nur gerade.
public struct FuchsRegeln: Equatable, Sendable, Codable {
    /// Kann der Fuchs springen, muss er es (klassisch „Huffen“ entfällt, der Fuchs wird nicht bestraft).
    public var fuchsMussSchlagen = false
    /// Gänse dürfen auch schräg nach vorn ziehen.
    public var gaenseDiagonal = false
    /// Startaufstellung (alte Spielstände: 13 Gänse).
    public var variante = FuchsVariante.dreizehn
    /// Nach dem Zuglimit: `true` = Unentschieden, `false` = Fuchs gewinnt (bisheriges Verhalten).
    public var remisBeiLimit = false
    public init(fuchsMussSchlagen: Bool = false, gaenseDiagonal: Bool = false, variante: FuchsVariante = .dreizehn, remisBeiLimit: Bool = false) {
        self.fuchsMussSchlagen = fuchsMussSchlagen; self.gaenseDiagonal = gaenseDiagonal; self.variante = variante; self.remisBeiLimit = remisBeiLimit
    }
    private enum CodingKeys: String, CodingKey { case fuchsMussSchlagen, gaenseDiagonal, variante, remisBeiLimit }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        fuchsMussSchlagen = try c.decodeIfPresent(Bool.self, forKey: .fuchsMussSchlagen) ?? false
        gaenseDiagonal = try c.decodeIfPresent(Bool.self, forKey: .gaenseDiagonal) ?? false
        variante = try c.decodeIfPresent(FuchsVariante.self, forKey: .variante) ?? .dreizehn
        remisBeiLimit = try c.decodeIfPresent(Bool.self, forKey: .remisBeiLimit) ?? false
    }
    public static let standard = FuchsRegeln()
    public static let zwang = FuchsRegeln(fuchsMussSchlagen: true)
    public static let leichtGaense = FuchsRegeln(gaenseDiagonal: true)
}

/// Fuchsjagd (Fuchs und Gänse): Ein Fuchs gegen 13 Gänse auf einem Kreuzbrett. Die Gänse rücken vor und versuchen, den Fuchs einzusperren;
/// der Fuchs springt über Gänse und frisst sie. Gänse gehen einen Schritt nach vorn (nach oben) oder zur Seite; der Fuchs geht in alle vier Richtungen
/// oder springt (ein Sprung pro Zug) über eine Gans auf das freie Feld dahinter.
public struct Fuchsjagd: Equatable, Sendable, Codable {
    public enum Seite: Int, Sendable, Codable { case fuchs, gaense }
    public static let feldBreite = 7
    public static let maxZuege = 160
    public static let gaensePleite = 4

    public enum Ausgang: Equatable, Sendable { case sieg(Seite), remis }

    /// Alle Füchse (einer, in der Variante „zwei Füchse“ zwei).
    public private(set) var fuechse = [Pos(3, 3)]
    /// Der (erste) Fuchs; Ansichten mit einem Fuchs benutzen nur diesen.
    public var fuchs: Pos { fuechse[0] }
    public private(set) var gaense: Set<Pos>
    public private(set) var amZug = Seite.gaense
    public private(set) var zuege = 0
    public private(set) var geschlagen = 0
    public private(set) var letzterZug: FuchsZug?
    public private(set) var regeln = FuchsRegeln.standard
    /// Alle bisherigen Züge (Gänse beginnen, danach im Wechsel); Grundlage für den Verlauf.
    public private(set) var historie: [FuchsZug] = []

    private enum CodingKeys: String, CodingKey { case fuchs, fuechse, gaense, amZug, zuege, geschlagen, letzterZug, regeln, historie }
    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(fuchs, forKey: .fuchs)          // alte Ansicht liest nur diesen Schlüssel
        try c.encode(fuechse, forKey: .fuechse)
        try c.encode(gaense, forKey: .gaense); try c.encode(amZug, forKey: .amZug); try c.encode(zuege, forKey: .zuege)
        try c.encode(geschlagen, forKey: .geschlagen); try c.encodeIfPresent(letzterZug, forKey: .letzterZug)
        try c.encode(regeln, forKey: .regeln); try c.encode(historie, forKey: .historie)
    }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let f = try c.decodeIfPresent([Pos].self, forKey: .fuechse), !f.isEmpty { fuechse = f } else { fuechse = [try c.decode(Pos.self, forKey: .fuchs)] }
        gaense = try c.decode(Set<Pos>.self, forKey: .gaense)
        amZug = try c.decode(Seite.self, forKey: .amZug)
        zuege = try c.decode(Int.self, forKey: .zuege)
        geschlagen = try c.decode(Int.self, forKey: .geschlagen)
        letzterZug = try c.decodeIfPresent(FuchsZug.self, forKey: .letzterZug)
        regeln = try c.decodeIfPresent(FuchsRegeln.self, forKey: .regeln) ?? .standard   // alte Spielstände
        historie = try c.decodeIfPresent([FuchsZug].self, forKey: .historie) ?? []
    }

    public static func gueltig(_ p: Pos) -> Bool {
        (0..<7).contains(p.x) && (0..<7).contains(p.y) && ((2...4).contains(p.x) || (2...4).contains(p.y))
    }

    public init(regeln: FuchsRegeln = .standard) {
        self.regeln = regeln
        var g = Set<Pos>()
        switch regeln.variante {
        case .dreizehn, .siebzehn:
            for y in 4...6 { for x in 0..<7 { let p = Pos(x, y); if Fuchsjagd.gueltig(p), y == 4 || (2...4).contains(x) { g.insert(p) } } }
            if regeln.variante == .siebzehn { for x in [0, 1, 5, 6] { g.insert(Pos(x, 3)) } }
        case .zweiFuechse:
            for y in 3...6 { for x in 0..<7 where Fuchsjagd.gueltig(Pos(x, y)) { g.insert(Pos(x, y)) } }
            fuechse = [Pos(2, 1), Pos(4, 1)]
        }
        gaense = g
    }

    /// Anzahl Gänse zu Beginn (für die Ablage).
    public var startGaense: Int { regeln.variante.gaenseZahl }
    public var zuglimit: Int { Fuchsjagd.maxZuege }

    /// Wertung der Partie je Seite: gefressene Gänse (Fuchs) bzw. übrige Gänse; der Sieger erhält zusätzlich die Zahl der Start-Gänse,
    /// damit er nie hinter dem Verlierer liegt.
    public func punkte(_ s: Seite) -> Int {
        let material = s == .fuchs ? geschlagen : gaense.count
        if case .sieg(let w)? = ausgang, w == s { return material + startGaense }
        return material
    }

    public var ausgang: Ausgang? {
        if gaense.count < regeln.variante.gaenseMinimum { return .sieg(.fuchs) }
        if zuege >= zuglimit { return regeln.remisBeiLimit ? .remis : .sieg(.fuchs) }
        if amZug == .fuchs, zuegeDes(.fuchs).isEmpty { return .sieg(.gaense) }
        if amZug == .gaense, zuegeDes(.gaense).isEmpty { return .sieg(.fuchs) }
        return nil
    }

    public var sieger: Seite? { if case .sieg(let s)? = ausgang { return s } else { return nil } }

    /// Kurzschreibweise eines Feldes: Spalte a–g, Zeile 1–7 von unten (Gänse starten unten).
    public static func notation(_ p: Pos) -> String { "\(Array("abcdefg")[p.x])\(7 - p.y)" }
    public static func notation(_ z: FuchsZug) -> String { notation(z.von) + (z.schlag == nil ? "–" : "×") + notation(z.nach) }

    private var fuchsRichtungen: [(Int, Int)] {
        regeln.variante.fuchsSchraeg ? [(1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (1, -1), (-1, 1), (-1, -1)] : [(1, 0), (-1, 0), (0, 1), (0, -1)]
    }

    private func frei(_ p: Pos) -> Bool { Fuchsjagd.gueltig(p) && !fuechse.contains(p) && !gaense.contains(p) }

    public func zuegeDes(_ s: Seite) -> [FuchsZug] {
        var z: [FuchsZug] = []
        if s == .fuchs {
            for f in fuechse { for (dx, dy) in fuchsRichtungen {
                let n = Pos(f.x + dx, f.y + dy)
                if frei(n) { z.append(FuchsZug(von: f, nach: n, schlag: nil)) }
                else if gaense.contains(n) {
                    let d = Pos(f.x + 2 * dx, f.y + 2 * dy)
                    if frei(d) { z.append(FuchsZug(von: f, nach: d, schlag: n)) }
                }
            } }
            if regeln.fuchsMussSchlagen, z.contains(where: { $0.schlag != nil }) { z = z.filter { $0.schlag != nil } }
        } else {
            let richtungen = regeln.gaenseDiagonal ? [(-1, 0), (1, 0), (0, -1), (-1, -1), (1, -1)] : [(-1, 0), (1, 0), (0, -1)]
            for g in gaense { for (dx, dy) in richtungen {
                let n = Pos(g.x + dx, g.y + dy)
                if frei(n) { z.append(FuchsZug(von: g, nach: n, schlag: nil)) }
            } }
        }
        return z
    }

    /// Mögliche Ziele für die Figur auf `p` (für die Oberfläche).
    public func ziele(von p: Pos) -> [FuchsZug] { zuegeDes(amZug).filter { $0.von == p } }

    @discardableResult
    public mutating func ziehe(_ z: FuchsZug) -> Bool {
        guard ausgang == nil, zuegeDes(amZug).contains(z) else { return false }
        if amZug == .fuchs {
            if let i = fuechse.firstIndex(of: z.von) { fuechse[i] = z.nach }
            if let s = z.schlag { gaense.remove(s); geschlagen += 1 }
            amZug = .gaense
        } else {
            gaense.remove(z.von); gaense.insert(z.nach)
            amZug = .fuchs
        }
        zuege += 1; letzterZug = z; historie.append(z)
        return true
    }

    // MARK: Computer

    private func bewertung() -> Double {
        // aus Sicht der Gänse: viele Gänse, Fuchs eingeengt, Gänse weit vorn und geschlossen
        let fz = zuegeDes(.fuchs)
        let n = Double(fuechse.count)
        var w = Double(gaense.count) * 10
        w -= Double(fz.count) * 1.5 / n
        w -= Double(fz.filter { $0.schlag != nil }.count) * 12 / n
        w += gaense.reduce(0.0) { $0 + Double(6 - $1.y) * 1.0 }
        for f in fuechse {
            w -= Double(gaense.filter { $0.y < f.y }.count) * 8 / n      // Gänse hinter dem Fuchs können ihn nicht mehr einsperren
            w -= Double(max(0, f.y - 3)) * 4 / n
            w -= Double(abs(f.y - 3)) * -0.2 / n
        }
        // ungeschützte Gänse (Fuchs könnte sie schlagen) kosten
        for g in gaense {
            for (dx, dy) in fuchsRichtungen where fuechse.contains(Pos(g.x - dx, g.y - dy)) {
                let d = Pos(g.x + dx, g.y + dy); if frei(d) { w -= 5 }
            }
        }
        return w
    }

    private func endWert() -> Double? {
        switch ausgang { case .sieg(.gaense)?: 10_000; case .sieg(.fuchs)?: -10_000; case .remis?: 0; case nil: nil }
    }

    private func minimax(_ tiefe: Int, _ alpha: Double, _ beta: Double) -> Double {
        if let e = endWert() { return e }
        if tiefe == 0 { return bewertung() }
        var a = alpha, b = beta
        if amZug == .gaense {
            var best = -Double.infinity
            for z in zuegeDes(.gaense) { var k = self; k.ziehe(z); best = max(best, k.minimax(tiefe - 1, a, b)); a = max(a, best); if a >= b { break } }
            return best
        } else {
            var best = Double.infinity
            for z in zuegeDes(.fuchs) { var k = self; k.ziehe(z); best = min(best, k.minimax(tiefe - 1, a, b)); b = min(b, best); if a >= b { break } }
            return best
        }
    }

    /// Computerzug für die Seite am Zug. `tiefe` 0 = zufällig, 1 = gierig, 2–4 = Vorausberechnung.
    public func computerZug<G: RandomNumberGenerator>(tiefe: Int, mit g: inout G) -> FuchsZug? {
        let z = zuegeDes(amZug)
        guard !z.isEmpty else { return nil }
        if tiefe == 0 { return z.randomElement(using: &g) }
        let gaenseSicht = amZug == .gaense
        var besten: [FuchsZug] = []; var bestWert = -Double.infinity
        for m in z {
            var k = self; k.ziehe(m)
            let w = (tiefe == 1 ? (k.endWert() ?? k.bewertung()) : k.minimax(tiefe - 1, -Double.infinity, Double.infinity)) * (gaenseSicht ? 1 : -1)
            if w > bestWert + 1e-9 { bestWert = w; besten = [m] } else if abs(w - bestWert) <= 1e-9 { besten.append(m) }
        }
        return besten.randomElement(using: &g)
    }
}

/// Zwei-Partien-Match mit Seitentausch (zwei Menschen): jeder spielt einmal Fuchs, gewertet wird die Summe der Partiepunkte.
public struct FuchsMatch: Equatable, Sendable, Codable {
    /// Seite des ersten Teilnehmers in der laufenden Partie.
    public var seiteErster: Fuchsjagd.Seite
    public private(set) var partie = 1
    public private(set) var summe = [0, 0]
    public init(seiteErster: Fuchsjagd.Seite) { self.seiteErster = seiteErster }
    public var vorbei: Bool { partie > 2 }
    /// Bucht eine beendete Partie und tauscht die Seiten; `true`, wenn noch eine Partie folgt.
    @discardableResult
    public mutating func buche(_ spiel: Fuchsjagd) -> Bool {
        summe[0] += spiel.punkte(seiteErster); summe[1] += spiel.punkte(seiteErster == .fuchs ? .gaense : .fuchs)
        partie += 1
        seiteErster = seiteErster == .fuchs ? .gaense : .fuchs
        return partie <= 2
    }
}
