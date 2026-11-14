// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import SpieleKern

/// Crazy Eights (USA): Karten gleicher Farbe oder gleichen Werts auf die Ablage legen; Achter sind Joker mit Farbwunsch.
/// Zwei Spieler, sieben Karten je. Wer keine passende Karte hat, zieht bis zu drei Karten, dann ist der andere dran.
public struct CrazyEights: Sendable, Codable {
    public private(set) var stapel: Kartenstapel<SkatKarte>
    public private(set) var haende: [[SkatKarte]] = [[], []]
    public private(set) var amZug = 0
    public private(set) var gewuenschteFarbe: SkatKarte.Farbe       // gilt nach einem Achter
    public private(set) var gezogen = 0                              // Karten, die der Spieler in diesem Zug schon gezogen hat
    public private(set) var gewinner: Int?
    public private(set) var punkte = 0

    public static let maxZiehen = 3

    public init<G: RandomNumberGenerator>(mit g: inout G) {
        var s = Kartenstapel(SkatKarte.blatt, gemischt: &g)
        for p in 0..<2 { for _ in 0..<7 { haende[p].append(s.ziehen(mit: &g)!) } }
        // Startkarte: kein Achter
        var start = s.ziehen(mit: &g)!
        while start.wert == 8 { s.ablegen(start); start = s.ziehen(mit: &g)! }
        s.ablegen(start)
        stapel = s; gewuenschteFarbe = start.farbe
        // Die beim Suchen verworfenen Achter liegen unter der Startkarte; die Ablage gehört mit zur Ablage.
    }

    /// Für Tests: feste Lage.
    public init(haende: [[SkatKarte]], oben: SkatKarte, vorrat: [SkatKarte] = []) {
        self.haende = haende
        var s = Kartenstapel(vorrat); s.ablegen(oben)
        stapel = s; gewuenschteFarbe = oben.farbe
    }

    public var oben: SkatKarte { stapel.oben! }

    public func kannLegen(_ k: SkatKarte) -> Bool {
        k.wert == 8 || k.farbe == gewuenschteFarbe || k.wert == oben.wert
    }
    public var spielbar: [Int] { gewinner == nil ? haende[amZug].indices.filter { kannLegen(haende[amZug][$0]) } : [] }
    public var darfZiehen: Bool { gewinner == nil && spielbar.isEmpty && gezogen < Self.maxZiehen && !stapel.istLeer }
    public var mussPassen: Bool { gewinner == nil && spielbar.isEmpty && !darfZiehen }

    /// Karte legen; bei einem Achter muss eine Wunschfarbe angegeben werden.
    @discardableResult
    public mutating func lege(_ i: Int, wunsch: SkatKarte.Farbe? = nil) -> Bool {
        guard spielbar.contains(i) else { return false }
        let k = haende[amZug][i]
        if k.wert == 8 && wunsch == nil { return false }
        haende[amZug].remove(at: i); stapel.ablegen(k)
        gewuenschteFarbe = k.wert == 8 ? wunsch! : k.farbe
        gezogen = 0
        if haende[amZug].isEmpty {
            gewinner = amZug
            punkte = haende[1 - amZug].reduce(0) { $0 + Self.strafe($1) }
        } else { amZug = 1 - amZug }
        return true
    }

    @discardableResult
    public mutating func ziehe<G: RandomNumberGenerator>(mit g: inout G) -> Bool {
        guard darfZiehen, let k = stapel.ziehen(mit: &g) else { return false }
        haende[amZug].append(k); gezogen += 1; return true
    }

    @discardableResult
    public mutating func passe() -> Bool {
        guard mussPassen else { return false }
        gezogen = 0; amZug = 1 - amZug; return true
    }

    public static func strafe(_ k: SkatKarte) -> Int { k.wert == 8 ? 50 : (k.wert >= 11 && k.wert <= 13 ? 10 : (k.wert == 14 ? 1 : k.wert)) }
}

public enum CrazyEightsComputer {
    /// Spielt möglichst Karten der häufigsten Farbe, hebt Achter auf.
    /// `stufe` 1 = leicht (irgendeine passende Karte), 2/3 = Regeln (Achter aufheben, häufigste Farbe wünschen).
    public static func wahl(_ s: CrazyEights, stufe: Int = 2) -> (index: Int, wunsch: SkatKarte.Farbe?)? {
        let h = s.haende[s.amZug]
        let z = s.spielbar
        guard !z.isEmpty else { return nil }
        if stufe <= 1 { let i = z.randomElement()!; return (i, h[i].wert == 8 ? SkatKarte.Farbe.allCases.randomElement() : nil) }
        let ohneAchter = z.filter { h[$0].wert != 8 }
        if stufe >= 3 {
            // Schwer: Jede spielbare Karte bewerten. Hohe Strafpunkte zuerst loswerden, die Farbe wählen, von der man am meisten behält,
            // Achter für den Endspurt aufheben (oder wenn sonst gezogen werden müsste) und die Wunschfarbe nach dem Rest der Hand richten.
            let gegnerKarten = s.haende[1 - s.amZug].count
            func rest(_ i: Int) -> [SkatKarte] { h.enumerated().filter { $0.offset != i }.map(\.element) }
            func bewertung(_ i: Int) -> Double {
                let k = h[i], r = rest(i)
                if r.isEmpty { return 1000 }
                let neueFarbe = k.wert == 8 ? haeufigsteFarbe(r) : k.farbe
                let folgen = Double(r.filter { $0.wert == 8 || $0.farbe == neueFarbe || $0.wert == k.wert }.count)
                var w = Double(strafeWert(k)) * 0.15 + folgen * 1.0 + Double(k.wert) * 0.05
                if k.wert == 8 { w -= (gegnerKarten <= 2 || r.count <= 2) ? 2 : 8 }
                return w
            }
            let pick = z.max { bewertung($0) < bewertung($1) }!
            return (pick, h[pick].wert == 8 ? haeufigsteFarbe(h.enumerated().filter { $0.offset != pick }.map(\.element)) : nil)
        }
        let pick = ohneAchter.max { h[$0].wert < h[$1].wert } ?? z[0]
        return (pick, h[pick].wert == 8 ? haeufigsteFarbe(h.enumerated().filter { $0.offset != pick }.map(\.element)) : nil)
    }
    private static func strafeWert(_ k: SkatKarte) -> Int { k.wert == 8 ? 0 : CrazyEights.strafe(k) }
    public static func haeufigsteFarbe(_ h: [SkatKarte]) -> SkatKarte.Farbe {
        SkatKarte.Farbe.allCases.max { a, b in h.filter { $0.farbe == a }.count < h.filter { $0.farbe == b }.count } ?? .herz
    }
}
