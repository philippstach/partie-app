// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

public struct Zelle: Hashable, Sendable { public var x: Int; public var y: Int; public init(_ x: Int, _ y: Int) { self.x = x; self.y = y } }

/// Kreuzwurf: Ein 7×7-Feld in fünf Farben. Pro Runde werden drei Farbwürfel und drei Zahlwürfel geworfen. Wer an der Reihe ist,
/// nimmt einen Farb- und einen Zahlwürfel und kreuzt bis zu so viele zusammenhängende Felder dieser Farbe an. Das erste Kreuz
/// beginnt in der Mittelspalte, jedes weitere muss an bereits Angekreuztes grenzen. Bonus für volle Spalten und volle Farben.
public struct Kreuzwurf: Equatable, Sendable, Codable {
    public static let groesse = 7
    public static let farben = 5
    public static let farbNamen = ["Rot", "Blau", "Grün", "Gelb", "Lila"]
    public static let spaltenBonus = (erste: 5, spaetere: 3)
    public static let farbBonus = (erste: 6, spaetere: 3)

    public let feld: [[Int]]                    // [y][x] → Farbe 0…4
    public private(set) var markiert: [[[Bool]]]   // [Spieler][y][x]
    public private(set) var bonus: [Int]
    public private(set) var farbenFertig: [Set<Int>]
    public private(set) var spaltenFertig: [Set<Int>]
    private var farbeVon = Set<Int>()           // Farben, die schon jemand vollendet hat
    private var spalteVon = Set<Int>()
    public let spieler: Int
    public let runden: Int
    public private(set) var runde = 0
    public private(set) var pick = 0            // wie vielvieltes Nehmen in dieser Runde
    public private(set) var farbwuerfel: [Int] = [0, 0, 0]      // 0…4 Farbe, 5 = Joker
    public private(set) var zahlwuerfel: [Int] = [1, 1, 1]      // 1…5, 0 = Joker
    public private(set) var farbGenommen = [false, false, false]
    public private(set) var zahlGenommen = [false, false, false]

    public var picksProRunde: Int { spieler == 1 ? 2 : 3 }
    public var vorbei: Bool { runde >= runden }
    /// Wer gerade wählt.
    public var amZug: Int { spieler == 1 ? 0 : (runde + pick) % spieler }

    public init<G: RandomNumberGenerator>(spieler: Int, mit g: inout G) {
        let n = Kreuzwurf.groesse
        self.spieler = max(1, min(4, spieler))
        runden = self.spieler == 1 ? 8 : 5 * self.spieler
        // Farbblöcke: Samenpunkte mit Farben, jedes Feld nimmt die Farbe des nächsten Samens
        var samen: [(Int, Int, Int)] = []
        for f in 0..<Kreuzwurf.farben { for _ in 0..<3 { samen.append((Int.random(in: 0..<n, using: &g), Int.random(in: 0..<n, using: &g), f)) } }
        var fe = Array(repeating: Array(repeating: 0, count: n), count: n)
        for y in 0..<n { for x in 0..<n {
            fe[y][x] = samen.min { abs($0.0 - x) + abs($0.1 - y) < abs($1.0 - x) + abs($1.1 - y) }!.2
        } }
        feld = fe
        markiert = Array(repeating: Array(repeating: Array(repeating: false, count: n), count: n), count: self.spieler)
        bonus = Array(repeating: 0, count: self.spieler)
        farbenFertig = Array(repeating: [], count: self.spieler)
        spaltenFertig = Array(repeating: [], count: self.spieler)
        wirf(mit: &g)
    }

    /// Echte Würfel: die Seiten der sechs Würfel für die laufende Runde setzen (Farbe 0…4, 5 = Joker; Zahl 1…5, 0 = Joker).
    @discardableResult
    public mutating func setzeWurf(farbwuerfel fw: [Int], zahlwuerfel zw: [Int]) -> Bool {
        guard fw.count == 3, zw.count == 3, fw.allSatisfy({ (0...5).contains($0) }), zw.allSatisfy({ (0...5).contains($0) }), !vorbei else { return false }
        farbwuerfel = fw; zahlwuerfel = zw
        farbGenommen = [false, false, false]; zahlGenommen = [false, false, false]
        return true
    }

    private mutating func wirf<G: RandomNumberGenerator>(mit g: inout G) {
        farbwuerfel = (0..<3).map { _ in Int.random(in: 0...5, using: &g) }
        zahlwuerfel = (0..<3).map { _ in Int.random(in: 0...5, using: &g) }
        farbGenommen = [false, false, false]; zahlGenommen = [false, false, false]; pick = 0
    }

    public func farbeAnzahl(_ f: Int) -> Int { feld.joined().filter { $0 == f }.count }

    public func punkte(_ s: Int) -> Int { bonus[s] + markiert[s].joined().filter { $0 }.count }

    private func nachbarn(_ z: Zelle) -> [Zelle] {
        [Zelle(z.x + 1, z.y), Zelle(z.x - 1, z.y), Zelle(z.x, z.y + 1), Zelle(z.x, z.y - 1)].filter { (0..<Kreuzwurf.groesse).contains($0.x) && (0..<Kreuzwurf.groesse).contains($0.y) }
    }

    private func hatKreuze(_ s: Int) -> Bool { markiert[s].joined().contains(true) }

    /// Ob ein Feld als erstes Kreuz oder als Anschluss an Angekreuztes erlaubt ist.
    public func anschluss(_ s: Int, _ z: Zelle) -> Bool {
        hatKreuze(s) ? nachbarn(z).contains { markiert[s][$0.y][$0.x] } : z.x == Kreuzwurf.groesse / 2
    }

    /// Ob die Zellen eine zusammenhängende Gruppe bilden.
    public static func zusammenhaengend(_ zellen: [Zelle]) -> Bool {
        guard let erste = zellen.first else { return false }
        var gesehen: Set<Zelle> = [erste]; var rest = [erste]
        while let c = rest.popLast() {
            for n in [Zelle(c.x + 1, c.y), Zelle(c.x - 1, c.y), Zelle(c.x, c.y + 1), Zelle(c.x, c.y - 1)] where zellen.contains(n) && !gesehen.contains(n) { gesehen.insert(n); rest.append(n) }
        }
        return gesehen.count == zellen.count
    }

    /// Prüft eine Auswahl: richtige Farbe, noch frei, höchstens `maximal`, zusammenhängend, mindestens eines schließt an.
    public func gueltig(spieler s: Int, farbe: Int, maximal: Int, zellen: [Zelle]) -> Bool {
        guard !zellen.isEmpty, zellen.count <= maximal, Set(zellen).count == zellen.count else { return false }
        for z in zellen { guard (0..<Kreuzwurf.groesse).contains(z.x), (0..<Kreuzwurf.groesse).contains(z.y), feld[z.y][z.x] == farbe, !markiert[s][z.y][z.x] else { return false } }
        // zusammenhängend
        var gesehen: Set<Zelle> = [zellen[0]]; var rest = [zellen[0]]
        while let c = rest.popLast() { for n in nachbarn(c) where zellen.contains(n) && !gesehen.contains(n) { gesehen.insert(n); rest.append(n) } }
        guard gesehen.count == zellen.count else { return false }
        return zellen.contains { anschluss(s, $0) }
    }

    /// Nimmt Würfel `fw` und `zw` für den Spieler am Zug und kreuzt `zellen` an.
    @discardableResult
    public mutating func setze<G: RandomNumberGenerator>(farbwuerfel fw: Int, zahlwuerfel zw: Int, farbe: Int, zellen: [Zelle], mit g: inout G) -> Bool {
        guard !vorbei, !farbGenommen[fw], !zahlGenommen[zw] else { return false }
        let w = farbwuerfel[fw]; let zahl = zahlwuerfel[zw]
        guard w == 5 || w == farbe else { return false }
        let maximal = zahl == 0 ? 5 : zahl
        let s = amZug
        guard gueltig(spieler: s, farbe: farbe, maximal: maximal, zellen: zellen) else { return false }
        for z in zellen { markiert[s][z.y][z.x] = true }
        // Boni
        for x in Set(zellen.map(\.x)) where !spaltenFertig[s].contains(x) && (0..<Kreuzwurf.groesse).allSatisfy({ markiert[s][$0][x] }) {
            spaltenFertig[s].insert(x)
            bonus[s] += spalteVon.contains(x) ? Kreuzwurf.spaltenBonus.spaetere : Kreuzwurf.spaltenBonus.erste; spalteVon.insert(x)
        }
        if !farbenFertig[s].contains(farbe), feld.indices.allSatisfy({ y in feld[y].indices.allSatisfy { x in feld[y][x] != farbe || markiert[s][y][x] } }) {
            farbenFertig[s].insert(farbe)
            bonus[s] += farbeVon.contains(farbe) ? Kreuzwurf.farbBonus.spaetere : Kreuzwurf.farbBonus.erste; farbeVon.insert(farbe)
        }
        nimm(fw, zw, mit: &g)
        return true
    }

    /// Verzichtet auf das Nehmen (Würfel bleiben liegen, nächster ist dran).
    public mutating func passe<G: RandomNumberGenerator>(mit g: inout G) { guard !vorbei else { return }; weiter(mit: &g) }

    private mutating func nimm<G: RandomNumberGenerator>(_ fw: Int, _ zw: Int, mit g: inout G) {
        farbGenommen[fw] = true; zahlGenommen[zw] = true
        weiter(mit: &g)
    }

    private mutating func weiter<G: RandomNumberGenerator>(mit g: inout G) {
        pick += 1
        if pick >= picksProRunde { runde += 1; if !vorbei { wirf(mit: &g) } }
    }

    /// Alle Zellen, die der Spieler mit dieser Farbe jetzt anschließend ankreuzen könnte.
    public func startZellen(spieler s: Int, farbe: Int) -> [Zelle] {
        var r: [Zelle] = []
        for y in 0..<Kreuzwurf.groesse { for x in 0..<Kreuzwurf.groesse where feld[y][x] == farbe && !markiert[s][y][x] && anschluss(s, Zelle(x, y)) { r.append(Zelle(x, y)) } }
        return r
    }

    // MARK: Computer

    /// Wählt für den Computer die beste Wahl (Farbwürfel, Zahlwürfel, Farbe, Zellen) oder nil zum Passen.
    /// `fehler`: Wahrscheinlichkeit, statt der besten irgendeine gültige Wahl zu nehmen.
    public func computerWahl<G: RandomNumberGenerator>(fehler: Double = 0, mit g: inout G) -> (fw: Int, zw: Int, farbe: Int, zellen: [Zelle])? {
        let s = amZug
        var beste: (Double, Int, Int, Int, [Zelle])?
        var alle: [(Double, Int, Int, Int, [Zelle])] = []
        for fw in 0..<3 where !farbGenommen[fw] {
            let farben = farbwuerfel[fw] == 5 ? Array(0..<Kreuzwurf.farben) : [farbwuerfel[fw]]
            for zw in 0..<3 where !zahlGenommen[zw] {
                let maximal = zahlwuerfel[zw] == 0 ? 5 : zahlwuerfel[zw]
                for f in farben {
                    let z = wachse(spieler: s, farbe: f, maximal: maximal, mit: &g)
                    guard !z.isEmpty, gueltig(spieler: s, farbe: f, maximal: maximal, zellen: z) else { continue }
                    let wert = Double(z.count) + bewerte(s, f, z) - (farbwuerfel[fw] == 5 ? 0.6 : 0) - (zahlwuerfel[zw] == 0 ? 0.4 : 0)
                    alle.append((wert, fw, zw, f, z))
                    if beste == nil || wert > beste!.0 { beste = (wert, fw, zw, f, z) }
                }
            }
        }
        if fehler > 0, Double.random(in: 0..<1, using: &g) < fehler, let z = alle.randomElement(using: &g) { beste = z }
        return beste.map { ($0.1, $0.2, $0.3, $0.4) }
    }

    /// Bonuswert einer Auswahl für die Computerwahl (Spalten und Farbe fast voll).
    private func bewerte(_ s: Int, _ f: Int, _ z: [Zelle]) -> Double {
        var w = 0.0
        for x in Set(z.map(\.x)) {
            let fehlt = (0..<Kreuzwurf.groesse).filter { !markiert[s][$0][x] && !z.contains(Zelle(x, $0)) }.count
            w += fehlt == 0 ? 4 : 1.0 / Double(fehlt + 1)
        }
        let rest = feld.indices.reduce(0) { a, y in a + feld[y].indices.filter { feld[y][$0] == f && !markiert[s][y][$0] }.count } - z.count
        if rest == 0 { w += 5 } else if rest <= 3 { w += 1 }
        return w
    }

    /// Greedy: von jedem möglichen Startfeld aus wachsen; bester Start nach Spaltenfortschritt.
    private func wachse<G: RandomNumberGenerator>(spieler s: Int, farbe: Int, maximal: Int, mit g: inout G) -> [Zelle] {
        var beste: [Zelle] = []; var besteWert = -1.0
        for start in startZellen(spieler: s, farbe: farbe) {
            var sel = [start]
            while sel.count < maximal {
                var kandidaten: [Zelle] = []
                for c in sel { for n in nachbarn(c) where feld[n.y][n.x] == farbe && !markiert[s][n.y][n.x] && !sel.contains(n) { kandidaten.append(n) } }
                guard let n = kandidaten.max(by: { spaltenDruck(s, $0.x) < spaltenDruck(s, $1.x) }) else { break }
                sel.append(n)
            }
            let wert = Double(sel.count) * 10 + sel.reduce(0.0) { $0 + spaltenDruck(s, $1.x) }
            if wert > besteWert { besteWert = wert; beste = sel }
        }
        return beste
    }

    private func spaltenDruck(_ s: Int, _ x: Int) -> Double { Double((0..<Kreuzwurf.groesse).filter { markiert[s][$0][x] }.count) / Double(Kreuzwurf.groesse) }
}
