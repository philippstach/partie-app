// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

public struct SchachZug: Equatable, Hashable, Sendable {
    public let von: Int
    public let nach: Int
    public let umwandlung: Int?      // Figur (2–5) bei Bauernumwandlung
    public init(_ von: Int, _ nach: Int, umwandlung: Int? = nil) { self.von = von; self.nach = nach; self.umwandlung = umwandlung }
}

/// Schach mit allen Regeln außer Dreifachwiederholung und 50-Züge-Regel. Weiß = +, Schwarz = −.
/// Figuren: 1 Bauer, 2 Springer, 3 Läufer, 4 Turm, 5 Dame, 6 König. Feld = Zeile·8 + Spalte, Zeile 0 oben (Schwarz).
public struct Schach: Equatable, Sendable, Codable {
    public private(set) var brett = [Int](repeating: 0, count: 64)
    public private(set) var dran = 1
    public private(set) var rochade = [true, true, true, true]       // Weiß kurz, Weiß lang, Schwarz kurz, Schwarz lang
    public private(set) var enPassant: Int?
    public private(set) var halbzuege = 0
    /// Stellungsabdrücke der gespielten Züge (für die dreifache Wiederholung).
    public private(set) var historie: [Int] = []

    public init() {
        let hinten = [4, 2, 3, 5, 6, 3, 2, 4]
        for c in 0..<8 {
            brett[c] = -hinten[c]; brett[8 + c] = -1
            brett[48 + c] = 1; brett[56 + c] = hinten[c]
        }
    }

    public init(brett: [Int], dran: Int, rochade: [Bool] = [false, false, false, false], enPassant: Int? = nil) {
        self.brett = brett; self.dran = dran; self.rochade = rochade; self.enPassant = enPassant
    }

    static let springer = [(-2, -1), (-2, 1), (-1, -2), (-1, 2), (1, -2), (1, 2), (2, -1), (2, 1)]
    static let diag = [(-1, -1), (-1, 1), (1, -1), (1, 1)]
    static let gerade = [(-1, 0), (1, 0), (0, -1), (0, 1)]

    static func im(_ r: Int, _ c: Int) -> Bool { (0..<8).contains(r) && (0..<8).contains(c) }

    public func koenig(_ s: Int) -> Int? { brett.firstIndex(of: 6 * s) }

    /// Wird Feld `f` von Farbe `s` angegriffen?
    public func angegriffen(_ f: Int, von s: Int) -> Bool {
        let r = f / 8, c = f % 8
        let bauernR = r - (s == 1 ? -1 : 1)          // Bauern von s stehen eine Zeile „hinter“ dem Ziel
        for dc in [-1, 1] where Schach.im(bauernR, c + dc) && brett[bauernR * 8 + c + dc] == s { return true }
        for (dr, dc) in Schach.springer where Schach.im(r + dr, c + dc) && brett[(r + dr) * 8 + c + dc] == 2 * s { return true }
        for dr in -1...1 { for dc in -1...1 where !(dr == 0 && dc == 0) {
            if Schach.im(r + dr, c + dc), brett[(r + dr) * 8 + c + dc] == 6 * s { return true }
        } }
        for (dr, dc) in Schach.diag {
            var rr = r + dr, cc = c + dc
            while Schach.im(rr, cc) {
                let p = brett[rr * 8 + cc]
                if p != 0 { if p == 3 * s || p == 5 * s { return true }; break }
                rr += dr; cc += dc
            }
        }
        for (dr, dc) in Schach.gerade {
            var rr = r + dr, cc = c + dc
            while Schach.im(rr, cc) {
                let p = brett[rr * 8 + cc]
                if p != 0 { if p == 4 * s || p == 5 * s { return true }; break }
                rr += dr; cc += dc
            }
        }
        return false
    }

    public var imSchach: Bool { koenig(dran).map { angegriffen($0, von: -dran) } ?? false }

    /// Pseudolegale Züge (König darf noch im Schach stehen); die Suche prüft die Legalität mit `nachZug`.
    func pseudo() -> [SchachZug] { pseudoZuege() }

    /// Stellung nach dem Zug oder `nil`, wenn der eigene König danach im Schach stünde (schnelle Legalitätsprüfung für die Suche).
    func nachZug(_ z: SchachZug) -> Schach? {
        let s = dran
        var k = self; k.ausfuehren(z)
        guard let kp = k.koenig(s) else { return nil }
        return k.angegriffen(kp, von: -s) ? nil : k
    }

    private func pseudoZuege() -> [SchachZug] {
        var z: [SchachZug] = []
        let s = dran
        for i in 0..<64 where brett[i] * s > 0 {
            let p = abs(brett[i]), r = i / 8, c = i % 8
            switch p {
            case 1:
                let vor = -s, start = s == 1 ? 6 : 1, letzte = s == 1 ? 0 : 7
                if Schach.im(r + vor, c), brett[(r + vor) * 8 + c] == 0 {
                    let nach = (r + vor) * 8 + c
                    if r + vor == letzte { for u in [5, 4, 3, 2] { z.append(SchachZug(i, nach, umwandlung: u)) } } else { z.append(SchachZug(i, nach)) }
                    if r == start, brett[(r + 2 * vor) * 8 + c] == 0 { z.append(SchachZug(i, (r + 2 * vor) * 8 + c)) }
                }
                for dc in [-1, 1] where Schach.im(r + vor, c + dc) {
                    let nach = (r + vor) * 8 + c + dc
                    if brett[nach] * s < 0 || nach == enPassant {
                        if r + vor == letzte { for u in [5, 4, 3, 2] { z.append(SchachZug(i, nach, umwandlung: u)) } } else { z.append(SchachZug(i, nach)) }
                    }
                }
            case 2:
                for (dr, dc) in Schach.springer where Schach.im(r + dr, c + dc) && brett[(r + dr) * 8 + c + dc] * s <= 0 { z.append(SchachZug(i, (r + dr) * 8 + c + dc)) }
            case 3, 4, 5:
                var richt: [(Int, Int)] = []
                if p != 4 { richt += Schach.diag }; if p != 3 { richt += Schach.gerade }
                for (dr, dc) in richt {
                    var rr = r + dr, cc = c + dc
                    while Schach.im(rr, cc) {
                        let q = brett[rr * 8 + cc]
                        if q * s > 0 { break }
                        z.append(SchachZug(i, rr * 8 + cc))
                        if q != 0 { break }
                        rr += dr; cc += dc
                    }
                }
            default:
                for dr in -1...1 { for dc in -1...1 where !(dr == 0 && dc == 0) {
                    if Schach.im(r + dr, c + dc), brett[(r + dr) * 8 + c + dc] * s <= 0 { z.append(SchachZug(i, (r + dr) * 8 + c + dc)) }
                } }
                // Rochade
                let reihe = s == 1 ? 7 : 0, k = s == 1 ? 0 : 2
                if i == reihe * 8 + 4, !angegriffen(i, von: -s) {
                    if rochade[k], brett[reihe * 8 + 5] == 0, brett[reihe * 8 + 6] == 0, brett[reihe * 8 + 7] == 4 * s,
                       !angegriffen(reihe * 8 + 5, von: -s), !angegriffen(reihe * 8 + 6, von: -s) { z.append(SchachZug(i, reihe * 8 + 6)) }
                    if rochade[k + 1], brett[reihe * 8 + 3] == 0, brett[reihe * 8 + 2] == 0, brett[reihe * 8 + 1] == 0, brett[reihe * 8] == 4 * s,
                       !angegriffen(reihe * 8 + 3, von: -s), !angegriffen(reihe * 8 + 2, von: -s) { z.append(SchachZug(i, reihe * 8 + 2)) }
                }
            }
        }
        return z
    }

    public var zuege: [SchachZug] {
        pseudoZuege().filter { z in
            var k = self; k.ausfuehren(z)
            guard let kp = k.koenig(dran) else { return false }
            return !k.angegriffen(kp, von: -dran)
        }
    }

    public func zuege(von f: Int) -> [SchachZug] { zuege.filter { $0.von == f } }

    private mutating func ausfuehren(_ z: SchachZug) {
        let p = brett[z.von], s = dran
        if abs(p) == 1, z.nach == enPassant { brett[z.nach + (s == 1 ? 8 : -8)] = 0 }
        if abs(p) == 6, abs(z.nach - z.von) == 2 {
            let reihe = z.von / 8
            if z.nach % 8 == 6 { brett[reihe * 8 + 5] = brett[reihe * 8 + 7]; brett[reihe * 8 + 7] = 0 }
            else { brett[reihe * 8 + 3] = brett[reihe * 8]; brett[reihe * 8] = 0 }
        }
        halbzuege = (abs(p) == 1 || brett[z.nach] != 0) ? 0 : halbzuege + 1
        brett[z.nach] = z.umwandlung.map { $0 * s } ?? p
        brett[z.von] = 0
        enPassant = (abs(p) == 1 && abs(z.nach - z.von) == 16) ? (z.von + z.nach) / 2 : nil
        if z.von == 60 || z.nach == 60 { rochade[0] = false; rochade[1] = false }
        if z.von == 4 || z.nach == 4 { rochade[2] = false; rochade[3] = false }
        if z.von == 63 || z.nach == 63 { rochade[0] = false }
        if z.von == 56 || z.nach == 56 { rochade[1] = false }
        if z.von == 7 || z.nach == 7 { rochade[2] = false }
        if z.von == 0 || z.nach == 0 { rochade[3] = false }
        dran = -s
    }

    @discardableResult
    public mutating func ziehe(_ z: SchachZug) -> Bool {
        guard zuege.contains(z) else { return false }
        if historie.isEmpty { historie = [abdruck] }
        ausfuehren(z); historie.append(abdruck); return true
    }

    /// Hash der Stellung (Figuren, Seite am Zug, Rochaderechte, En-passant-Feld).
    public var abdruck: Int {
        var h = Hasher()
        h.combine(brett); h.combine(dran); h.combine(rochade); h.combine(enPassant)
        return h.finalize()
    }
    public var dreifach: Bool { historie.filter { $0 == abdruck }.count >= 3 }

    public var schachmatt: Bool { imSchach && zuege.isEmpty }
    public var patt: Bool { !imSchach && zuege.isEmpty }
    public var remis: Bool { patt || halbzuege >= 100 || unzureichend || dreifach }
    public var remisGrund: String? {
        if patt { return "Patt" }
        if unzureichend { return "Zu wenig Material" }
        if dreifach { return "Dreifache Stellungswiederholung" }
        if halbzuege >= 100 { return "50-Züge-Regel" }
        return nil
    }
    private var unzureichend: Bool {
        let f = brett.filter { $0 != 0 && abs($0) != 6 }
        return f.isEmpty || (f.count == 1 && [2, 3].contains(abs(f[0])))
    }
}

/// Spielstärke des Computers: Suchtiefe und Wahrscheinlichkeit eines absichtlichen Patzers.
public enum SchachStaerke: CaseIterable, Sendable {
    case leicht, mittel, schwer
    public var tiefe: Int { switch self { case .leicht: 1; case .mittel: 2; case .schwer: 4 } }
    public var fehler: Double { switch self { case .leicht: 0.35; case .mittel: 0.1; case .schwer: 0 } }
}

public enum SchachComputer {
    public static func wahl(_ s: Schach, staerke: SchachStaerke) -> SchachZug? { wahl(s, tiefe: staerke.tiefe, fehler: staerke.fehler) }
    public static func wahl(_ s: Schach, tiefe: Int = 3, fehler: Double = 0) -> SchachZug? { wahl(s, tiefe: tiefe, fehler: fehler, art: .neu) }

    static let wert = [0, 100, 320, 330, 500, 900, 0]

    enum Bewertung { case alt, neu }

    // Figurentabellen (Weiß-Sicht, Zeile 0 = Grundreihe des Gegners); für Schwarz wird die Zeile gespiegelt.
    static let tabBauer = [0,0,0,0,0,0,0,0, 50,50,50,50,50,50,50,50, 10,10,20,30,30,20,10,10, 5,5,10,25,25,10,5,5, 0,0,0,20,20,0,0,0, 5,-5,-10,0,0,-10,-5,5, 5,10,10,-20,-20,10,10,5, 0,0,0,0,0,0,0,0]
    static let tabSpringer = [-50,-40,-30,-30,-30,-30,-40,-50, -40,-20,0,0,0,0,-20,-40, -30,0,10,15,15,10,0,-30, -30,5,15,20,20,15,5,-30, -30,0,15,20,20,15,0,-30, -30,5,10,15,15,10,5,-30, -40,-20,0,5,5,0,-20,-40, -50,-40,-30,-30,-30,-30,-40,-50]
    static let tabLaeufer = [-20,-10,-10,-10,-10,-10,-10,-20, -10,0,0,0,0,0,0,-10, -10,0,5,10,10,5,0,-10, -10,5,5,10,10,5,5,-10, -10,0,10,10,10,10,0,-10, -10,10,10,10,10,10,10,-10, -10,5,0,0,0,0,5,-10, -20,-10,-10,-10,-10,-10,-10,-20]
    static let tabTurm = [0,0,0,0,0,0,0,0, 5,10,10,10,10,10,10,5, -5,0,0,0,0,0,0,-5, -5,0,0,0,0,0,0,-5, -5,0,0,0,0,0,0,-5, -5,0,0,0,0,0,0,-5, -5,0,0,0,0,0,0,-5, 0,0,0,5,5,0,0,0]
    static let tabDame = [-20,-10,-10,-5,-5,-10,-10,-20, -10,0,0,0,0,0,0,-10, -10,0,5,5,5,5,0,-10, -5,0,5,5,5,5,0,-5, 0,0,5,5,5,5,0,-5, -10,5,5,5,5,5,0,-10, -10,0,5,0,0,0,0,-10, -20,-10,-10,-5,-5,-10,-10,-20]
    static let tabKoenigMitte = [-30,-40,-40,-50,-50,-40,-40,-30, -30,-40,-40,-50,-50,-40,-40,-30, -30,-40,-40,-50,-50,-40,-40,-30, -30,-40,-40,-50,-50,-40,-40,-30, -20,-30,-30,-40,-40,-30,-30,-20, -10,-20,-20,-20,-20,-20,-20,-10, 20,20,0,0,0,0,20,20, 20,30,10,0,0,10,30,20]
    static let tabKoenigEnde = [-50,-40,-30,-20,-20,-30,-40,-50, -30,-20,-10,0,0,-10,-20,-30, -30,-10,20,30,30,20,-10,-30, -30,-10,30,40,40,30,-10,-30, -30,-10,30,40,40,30,-10,-30, -30,-10,20,30,30,20,-10,-30, -30,-30,0,0,0,0,-30,-30, -50,-30,-30,-30,-30,-30,-30,-50]

    /// Bewertung mit Figurentabellen, weich ausgeblendetem Königswechsel ins Endspiel, Läuferpaar, Bauernstruktur und Freibauern.
    static func bewerteNeu(_ s: Schach, fuer: Int) -> Int {
        var phase = 0
        for q in s.brett { switch abs(q) { case 2, 3: phase += 1; case 4: phase += 2; case 5: phase += 4; default: break } }
        phase = min(24, phase)
        var w = 0
        var bauernSpalten = [[Int]](repeating: [0, 0, 0, 0, 0, 0, 0, 0], count: 2)   // [Weiß/Schwarz][Spalte] = Anzahl
        for i in 0..<64 where abs(s.brett[i]) == 1 { bauernSpalten[s.brett[i] > 0 ? 0 : 1][i % 8] += 1 }
        for farbe in [1, -1] {
            var v = 0, laeufer = 0
            let f = farbe == 1 ? 0 : 1, g = 1 - f
            for i in 0..<64 where s.brett[i] * farbe > 0 {
                let p = abs(s.brett[i]), r = i / 8, c = i % 8
                let idx = farbe == 1 ? i : (7 - r) * 8 + c
                v += wert[p]
                switch p {
                case 1:
                    v += tabBauer[idx]
                    // Freibauer: kein gegnerischer Bauer voraus auf eigener oder Nachbarspalte
                    let frei = !(max(0, c - 1)...min(7, c + 1)).contains { sp in
                        (0..<8).contains { rr in s.brett[rr * 8 + sp] == -farbe && (farbe == 1 ? rr < r : rr > r) }
                    }
                    if frei { let weg = farbe == 1 ? 6 - r : r - 1; v += 10 + weg * weg * 3 }
                    if bauernSpalten[f][c] > 1 { v -= 12 }
                    if (c == 0 || bauernSpalten[f][c - 1] == 0) && (c == 7 || bauernSpalten[f][c + 1] == 0) { v -= 10 }   // Isolani
                case 2: v += tabSpringer[idx]
                case 3: v += tabLaeufer[idx]; laeufer += 1
                case 4:
                    v += tabTurm[idx]
                    if bauernSpalten[f][c] == 0 { v += bauernSpalten[g][c] == 0 ? 20 : 10 }   // offene / halboffene Linie
                case 5: v += tabDame[idx]
                default: v += (tabKoenigMitte[idx] * phase + tabKoenigEnde[idx] * (24 - phase)) / 24
                }
            }
            if laeufer >= 2 { v += 30 }
            w += farbe == fuer ? v : -v
        }
        return w
    }

    static func bewerte(_ s: Schach, fuer: Int, _ art: Bewertung = .neu) -> Int {
        if art == .neu { return bewerteNeu(s, fuer: fuer) }
        var w = 0
        for i in 0..<64 where s.brett[i] != 0 {
            let p = abs(s.brett[i]), farbe = s.brett[i] > 0 ? 1 : -1
            var v = wert[p]
            let r = i / 8, c = i % 8
            let zentrum = 3 - max(abs(c - 3), abs(c - 4)) + 3 - max(abs(r - 3), abs(r - 4))
            if p == 1 { v += (farbe == 1 ? 6 - r : r - 1) * 6 } else if p != 6 { v += zentrum * 4 }
            w += farbe == fuer ? v : -v
        }
        // Läuferpaar und Bauernstruktur
        for farbe in [1, -1] {
            var b = 0
            if s.brett.filter({ $0 == 3 * farbe }).count >= 2 { b += 30 }
            for c in 0..<8 { let n = (0..<8).filter { s.brett[$0 * 8 + c] == farbe }.count; if n > 1 { b -= 12 * (n - 1) } }
            w += farbe == fuer ? b : -b
        }
        return w
    }

    /// Beste Antwort. `tiefe` ist die volle Suchtiefe; danach läuft eine Ruhesuche nur mit Schlägen und Umwandlungen,
    /// damit der Computer keine Figur hängen lässt. `fehler` (0…1) ist die Wahrscheinlichkeit, einen Zug aus den besseren Hälfte zufällig zu wählen.
    /// Höchstzeit für einen Computerzug in Sekunden (grobe Grenze, gemessen am Mac; iPhones sind ähnlich schnell).
    static let zeitBudget = 0.35

    /// Bewertet alle Wurzelzüge mit fester Tiefe.
    private static func wurzel(_ s: Schach, _ zuege: [SchachZug], tiefe: Int, fehler: Double, art: Bewertung) -> [(SchachZug, Int)] {
        var bewertet: [(SchachZug, Int)] = []
        var bester = -1_000_000
        for m in zuege {
            var n = s; n.ziehe(m)
            if n.remis { bewertet.append((m, 0)); bester = max(bester, 0); continue }
            // Ohne Patzer reicht ein Fenster knapp unter dem bisher besten Wert (Züge innerhalb 3 Punkten bleiben genau)
            let untere = fehler > 0 ? -1_000_000 : bester - 4
            let w = -suche(n, tiefe - 1, -1_000_000, -untere, art)
            // Gewinnt die Stellung schon, gilt „jetzt umwandeln“ mehr als „später“ (sonst schiebt die feste Suchtiefe die Dame ewig auf)
            let bonus = (m.umwandlung == 5 && abs(w) < 90000) ? 60 : 0
            bewertet.append((m, w + bonus)); bester = max(bester, w + bonus)
        }
        return bewertet
    }

    static func wahl(_ s: Schach, tiefe: Int, fehler: Double, art: Bewertung) -> SchachZug? {
        let z = s.zuege
        guard !z.isEmpty else { return nil }
        // Iterative Vertiefung: Die nächste Tiefe wird nur begonnen, wenn die vorige schnell genug war (Zeitbudget, damit kein Zug zu lange dauert).
        let start = Date()
        var geordnet = Array(sortiert(z, s).prefix(60))
        var bewertet: [(SchachZug, Int)] = []
        for d in 1...max(1, tiefe) {
            let rundeStart = Date()
            bewertet = wurzel(s, geordnet, tiefe: d, fehler: fehler, art: art)
            if d == tiefe { break }
            let dauer = Date().timeIntervalSince(rundeStart), gesamt = Date().timeIntervalSince(start)
            if gesamt + dauer * 10 > zeitBudget { break }              // die nächste Tiefe kostet etwa das Zehnfache
            geordnet = bewertet.sorted { $0.1 > $1.1 }.map(\.0)
        }
        bewertet.sort { $0.1 > $1.1 }
        if fehler > 0, bewertet.count > 2, Double.random(in: 0..<1) < fehler {
            return bewertet[0..<max(2, bewertet.count / 2)].randomElement()!.0
        }
        let top = bewertet[0].1
        let toleranz = abs(top) > 90000 ? 0 : 3     // Matt-Abstände nie verwischen
        return bewertet.filter { $0.1 >= top - toleranz }.randomElement()!.0     // gleichwertige Züge abwechseln
    }

    /// Ruhesuche: nur Schläge und Umwandlungen, bis die Stellung ruhig ist.
    private static func ruhe(_ s: Schach, _ alpha: Int, _ beta: Int, _ t: Int, _ art: Bewertung) -> Int {
        let stand = bewerte(s, fuer: s.dran, art)
        if t == 0 { return stand }
        if stand >= beta { return beta }
        var a = max(alpha, stand)
        let laut = s.pseudo().filter { s.brett[$0.nach] != 0 || $0.umwandlung != nil }
        for m in sortiert(laut, s) {
            guard let n = s.nachZug(m) else { continue }
            let w = -ruhe(n, -beta, -a, t - 1, art)
            if w >= beta { return beta }
            if w > a { a = w }
        }
        return a
    }

    /// Negamax mit Alpha-Beta; Wert aus Sicht des Spielers am Zug.
    private static func suche(_ s: Schach, _ t: Int, _ alpha: Int, _ beta: Int, _ art: Bewertung) -> Int {
        if s.halbzuege >= 100 { return 0 }
        if t <= 0 { return ruhe(s, alpha, beta, 3, art) }
        var a = alpha, legal = 0
        for m in sortiert(s.pseudo(), s) {
            guard let n = s.nachZug(m) else { continue }
            legal += 1
            let w = -suche(n, t - 1, -beta, -a, art)
            if w >= beta { return beta }
            if w > a { a = w }
        }
        if legal == 0 { return s.imSchach ? -100_000 - t : 0 }
        return a
    }

    /// Schlagzüge zuerst (bessere Beschneidung).
    private static func sortiert(_ z: [SchachZug], _ s: Schach) -> [SchachZug] {
        z.sorted { abs(s.brett[$0.nach]) * 10 - abs(s.brett[$0.von]) > abs(s.brett[$1.nach]) * 10 - abs(s.brett[$1.von]) }
    }
}
