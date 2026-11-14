// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

public struct WKarte: Equatable, Sendable, Hashable, Codable {
    public enum Art: Equatable, Sendable, Hashable, Codable { case zahl(Int), sprung, wende, zwei, joker, jokerDrei }
    public var farbe: Int          // 0…3; bei Jokern 4
    public var art: Art
    public var istJoker: Bool { art == .joker || art == .jokerDrei }
    public var zahl: Int? { if case .zahl(let n) = art { return n }; return nil }
}

/// Farbwechsel: Ablegen nach Farbe oder Zahl, Aktionskarten (Sprung, Wende, Zwei ziehen, Joker). Wer zuerst keine Karten mehr hat, gewinnt.
/// Eigene Kartenzusammenstellung (4 Farben × [1–9 doppelt, 2 Sprung, 2 Wende, 2 Zwei] + 4 Joker + 4 Joker „drei ziehen“ = 104).
public struct Farbwechsel: Equatable, Sendable, Codable {
    public static let farbNamen = ["Rubin", "Saphir", "Smaragd", "Bernstein"]
    public private(set) var haende: [[WKarte]]
    public private(set) var zieh: [WKarte]
    public private(set) var ablage: [WKarte]
    public private(set) var farbe: Int
    public private(set) var amZug = 0
    public private(set) var richtung = 1
    public private(set) var gewinner: Int?
    /// Gerade gezogene Karte (Index in der Hand), falls sie legbar ist: der Spieler darf sie legen oder passen.
    public private(set) var gezogen: Int?
    public private(set) var meldung: String = ""
    public let spieler: Int

    public static func satz() -> [WKarte] {
        var k: [WKarte] = []
        for f in 0..<4 {
            for n in 1...9 { k.append(WKarte(farbe: f, art: .zahl(n))); k.append(WKarte(farbe: f, art: .zahl(n))) }
            for a in [WKarte.Art.sprung, .wende, .zwei] { k.append(WKarte(farbe: f, art: a)); k.append(WKarte(farbe: f, art: a)) }
            k.append(WKarte(farbe: 4, art: .joker)); k.append(WKarte(farbe: 4, art: .jokerDrei))
        }
        return k
    }

    public init<G: RandomNumberGenerator>(spieler: Int, mit g: inout G) {
        self.spieler = max(2, min(4, spieler))
        var d = Farbwechsel.satz(); d.shuffle(using: &g)
        haende = (0..<self.spieler).map { _ in [] }
        for _ in 0..<7 { for i in 0..<self.spieler { haende[i].append(d.removeLast()) } }
        // Startkarte: eine Zahlenkarte
        var start = d.removeLast()
        while start.zahl == nil { d.insert(start, at: 0); start = d.removeLast() }
        ablage = [start]; zieh = d; farbe = start.farbe
    }

    /// Feste Stellung (Tests, Wiederaufnahme).
    public init(haende: [[WKarte]], ablage: [WKarte], zieh: [WKarte] = [], farbe: Int? = nil, amZug: Int = 0) {
        self.haende = haende; self.ablage = ablage; self.zieh = zieh; self.amZug = amZug
        spieler = haende.count; self.farbe = farbe ?? ablage.last!.farbe
    }

    public var oben: WKarte { ablage.last! }

    public func darfLegen(_ k: WKarte) -> Bool {
        k.istJoker || k.farbe == farbe || (k.zahl != nil && k.zahl == oben.zahl) || (k.art == oben.art && k.zahl == nil && !oben.istJoker)
    }

    public func legbar(spieler s: Int) -> [Int] { haende[s].indices.filter { darfLegen(haende[s][$0]) } }

    private mutating func naechster(_ schritte: Int = 1) { amZug = ((amZug + richtung * schritte) % spieler + spieler) % spieler }

    private mutating func nachziehen<G: RandomNumberGenerator>(_ s: Int, _ n: Int, mit g: inout G) {
        for _ in 0..<n {
            if zieh.isEmpty {
                guard ablage.count > 1 else { return }
                let letzte = ablage.removeLast(); zieh = ablage; zieh.shuffle(using: &g); ablage = [letzte]
            }
            haende[s].append(zieh.removeLast())
        }
    }

    /// Legt die Karte `i` der Hand des Spielers am Zug. Bei Jokern gibt `wunsch` die neue Farbe an.
    @discardableResult
    public mutating func lege<G: RandomNumberGenerator>(_ i: Int, wunsch: Int? = nil, mit g: inout G) -> Bool {
        guard gewinner == nil, haende[amZug].indices.contains(i), darfLegen(haende[amZug][i]) else { return false }
        if let gz = gezogen, gz != i { return false }
        let k = haende[amZug].remove(at: i)
        ablage.append(k); gezogen = nil
        farbe = k.istJoker ? (wunsch ?? 0) : k.farbe
        if haende[amZug].isEmpty { gewinner = amZug; return true }
        switch k.art {
        case .sprung: naechster(2); meldung = "Sprung"
        case .wende:
            richtung = -richtung
            if spieler == 2 { naechster(2) } else { naechster() }
            meldung = "Wende"
        case .zwei: naechster(); nachziehen(amZug, 2, mit: &g); naechster(); meldung = "Zwei ziehen"
        case .jokerDrei: naechster(); nachziehen(amZug, 3, mit: &g); naechster(); meldung = "Drei ziehen"
        default: naechster(); meldung = ""
        }
        return true
    }

    /// Zieht eine Karte. Passt sie, darf der Spieler sie noch legen (`gezogen`), sonst ist der nächste dran.
    public mutating func ziehe<G: RandomNumberGenerator>(mit g: inout G) {
        guard gewinner == nil, gezogen == nil else { return }
        let vorher = haende[amZug].count
        nachziehen(amZug, 1, mit: &g)
        if haende[amZug].count > vorher, darfLegen(haende[amZug].last!) { gezogen = haende[amZug].count - 1 }
        else { naechster() }
        meldung = ""
    }

    public mutating func passe() {
        guard gewinner == nil, gezogen != nil else { return }
        gezogen = nil; naechster()
    }

    /// Wie `computerZug`; mit Wahrscheinlichkeit `fehler` legt er irgendeine passende Karte (Joker: beliebige Wunschfarbe).
    public mutating func computerZug<G: RandomNumberGenerator>(fehler: Double, mit g: inout G) {
        if gewinner == nil, gezogen == nil, fehler > 0, Double.random(in: 0..<1, using: &g) < fehler,
           let i = legbar(spieler: amZug).randomElement(using: &g) {
            lege(i, wunsch: Int.random(in: 0..<4, using: &g), mit: &g); return
        }
        computerZug(mit: &g)
    }

    /// Ein vollständiger Zug des Computers.
    public mutating func computerZug<G: RandomNumberGenerator>(mit g: inout G) {
        guard gewinner == nil else { return }
        func waehle(_ s: Farbwechsel) -> Int? {
            let l = s.legbar(spieler: s.amZug)
            if let gz = s.gezogen { return l.contains(gz) ? gz : nil }
            let normal = l.filter { !s.haende[s.amZug][$0].istJoker }
            let gegnerWenig = (0..<s.spieler).contains { $0 != s.amZug && s.haende[$0].count <= 2 }
            if gegnerWenig, let a = normal.first(where: { s.haende[s.amZug][$0].zahl == nil }) { return a }
            if let n = normal.max(by: { (s.haende[s.amZug][$0].zahl ?? 10) < (s.haende[s.amZug][$1].zahl ?? 10) }) { return n }
            return l.first
        }
        if gezogen == nil, waehle(self) == nil { ziehe(mit: &g) }
        guard gewinner == nil else { return }
        if let i = waehle(self) {
            var zaehl = [0, 0, 0, 0]
            for k in haende[amZug] where k.farbe < 4 { zaehl[k.farbe] += 1 }
            lege(i, wunsch: zaehl.firstIndex(of: zaehl.max()!) ?? 0, mit: &g)
        } else if gezogen != nil { passe() }
    }

    public var kartenGesamt: Int { haende.reduce(0) { $0 + $1.count } + zieh.count + ablage.count }
}
