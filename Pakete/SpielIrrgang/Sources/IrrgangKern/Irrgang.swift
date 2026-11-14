// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

public enum Richtung: Int, CaseIterable, Sendable {
    case nord, ost, sued, west
    public var dx: Int { self == .ost ? 1 : (self == .west ? -1 : 0) }
    public var dy: Int { self == .sued ? 1 : (self == .nord ? -1 : 0) }
    public var gegenueber: Richtung { Richtung(rawValue: (rawValue + 2) % 4)! }
}

/// Irrgang: Ein Irrgarten, der von Stufe zu Stufe größer wird. Von der Startecke zum Ausgang laufen, unterwegs Funken sammeln.
/// Ab Stufe 4 ist es dunkel: Man sieht nur den Bereich um die eigene Laterne.
public struct Irrgang: Equatable, Sendable, Codable {
    public let breite: Int
    public let hoehe: Int
    public let stufe: Int
    /// `offen[y][x]` hat vier Wahrheitswerte (Nord, Ost, Süd, West): ob der Durchgang offen ist.
    public private(set) var offen: [[[Bool]]]
    public private(set) var x = 0
    public private(set) var y = 0
    /// Das Ziel liegt immer unten rechts.
    public var ziel: (x: Int, y: Int) { (breite - 1, hoehe - 1) }
    public private(set) var funken: Set<Int>          // Zellennummern y * breite + x
    public private(set) var gesammelt = 0
    public private(set) var schritte = 0
    public private(set) var besucht: Set<Int> = [0]
    private struct Stand: Codable, Equatable, Sendable { var x: Int, y: Int, funken: Set<Int>, gesammelt: Int, besucht: Set<Int> }
    private var verlauf: [Stand] = []

    public static func groesse(stufe: Int) -> (b: Int, h: Int) {
        let s = min(stufe, 14)
        return (5 + s, 7 + s)
    }
    public static func sichtweite(stufe: Int) -> Int? { stufe >= 4 ? max(2, 5 - (stufe - 4) / 3) : nil }

    public static func == (a: Irrgang, b: Irrgang) -> Bool {
        a.breite == b.breite && a.hoehe == b.hoehe && a.stufe == b.stufe && a.offen == b.offen && a.x == b.x && a.y == b.y && a.funken == b.funken
    }

    public init<G: RandomNumberGenerator>(stufe: Int, mit g: inout G) {
        let (b, h) = Irrgang.groesse(stufe: stufe)
        breite = b; hoehe = h; self.stufe = stufe
        var o = Array(repeating: Array(repeating: Array(repeating: false, count: 4), count: b), count: h)
        // Tiefensuche mit Rückweg: ergibt einen Irrgarten ohne Schleifen, jede Zelle ist erreichbar.
        var besuchtZ = Set<Int>([0]); var stapel = [(0, 0)]
        while let (cx, cy) = stapel.last {
            let nachbarn = Richtung.allCases.filter { r in
                let nx = cx + r.dx, ny = cy + r.dy
                return nx >= 0 && nx < b && ny >= 0 && ny < h && !besuchtZ.contains(ny * b + nx)
            }
            if let r = nachbarn.randomElement(using: &g) {
                let nx = cx + r.dx, ny = cy + r.dy
                o[cy][cx][r.rawValue] = true; o[ny][nx][r.gegenueber.rawValue] = true
                besuchtZ.insert(ny * b + nx); stapel.append((nx, ny))
            } else { stapel.removeLast() }
        }
        offen = o
        funken = []
        // Funken in Sackgassen (nicht Start/Ziel); je Stufe etwas mehr
        var sackgassen: [Int] = []
        for yy in 0..<h { for xx in 0..<b where (xx, yy) != (0, 0) && (xx, yy) != (b - 1, h - 1) && o[yy][xx].filter({ $0 }).count == 1 { sackgassen.append(yy * b + xx) } }
        sackgassen.shuffle(using: &g)
        funken = Set(sackgassen.prefix(min(3 + stufe, 10)))
    }

    public func anzahlOeffnungen(_ cx: Int, _ cy: Int) -> Int { offen[cy][cx].filter { $0 }.count }
    public var imZiel: Bool { x == ziel.x && y == ziel.y }

    /// Es gibt etwas zum Zurücknehmen (ein Wisch oder Schritt je Eintrag).
    public var kannZurueck: Bool { !verlauf.isEmpty }
    /// Nimmt den letzten Wisch zurück. Die Schrittzahl bleibt (der Umweg zählt für die Punkte).
    @discardableResult
    public mutating func zurueck() -> Bool {
        guard let a = verlauf.popLast() else { return false }
        x = a.x; y = a.y; funken = a.funken; gesammelt = a.gesammelt; besucht = a.besucht
        return true
    }

    @discardableResult
    public mutating func bewege(_ r: Richtung) -> Bool {
        guard offen[y][x][r.rawValue] else { return false }
        verlauf.append(Stand(x: x, y: y, funken: funken, gesammelt: gesammelt, besucht: besucht))
        schritt(r)
        return true
    }

    private mutating func schritt(_ r: Richtung) {
        x += r.dx; y += r.dy; schritte += 1
        besucht.insert(y * breite + x)
        if funken.remove(y * breite + x) != nil { gesammelt += 1 }
    }

    /// Läuft geradeaus in eine Richtung, bis vor einer Wand, an einer Abzweigung, bei einem Funken oder im Ziel Schluss ist.
    /// Es gibt keine automatischen Kurven: Die Figur bleibt immer genau auf der gewischten Linie.
    @discardableResult
    public mutating func gleite(_ r: Richtung) -> Int {
        var n = 0
        guard offen[y][x][r.rawValue] else { return 0 }
        verlauf.append(Stand(x: x, y: y, funken: funken, gesammelt: gesammelt, besucht: besucht))     // ein Wisch = ein Eintrag
        while true {
            let funkenVorher = gesammelt
            guard offen[y][x][r.rawValue] else { break }
            schritt(r)
            n += 1
            if imZiel || gesammelt > funkenVorher { break }
            // Abzweigung: außer zurück und geradeaus gibt es einen weiteren offenen Durchgang
            let seitlich = Richtung.allCases.contains { $0 != r && $0 != r.gegenueber && offen[y][x][$0.rawValue] }
            if seitlich { break }
        }
        return n
    }

    /// Kürzeste Weglänge von (x, y) zum Ziel (Breitensuche); für Tests und Punkte.
    public func kuerzesterWeg() -> Int? {
        var dist: [Int: Int] = [y * breite + x: 0]; var schlange = [(x, y)]; var i = 0
        while i < schlange.count {
            let (cx, cy) = schlange[i]; i += 1
            if (cx, cy) == (ziel.x, ziel.y) { return dist[cy * breite + cx] }
            for r in Richtung.allCases where offen[cy][cx][r.rawValue] {
                let k = (cy + r.dy) * breite + cx + r.dx
                if dist[k] == nil { dist[k] = dist[cy * breite + cx]! + 1; schlange.append((cx + r.dx, cy + r.dy)) }
            }
        }
        return nil
    }

    /// Tipp: Richtung des ersten Schritts auf dem kürzesten Weg zum Ausgang.
    public func hinweisRichtung() -> Richtung? {
        guard !imZiel else { return nil }
        var vorher: [Int: (Int, Richtung)] = [:]; var gesehen: Set<Int> = [y * breite + x]; var queue = [(x, y)]; var i = 0
        let zielIndex = ziel.y * breite + ziel.x
        while i < queue.count {
            let (cx, cy) = queue[i]; i += 1
            if cy * breite + cx == zielIndex { break }
            for r in Richtung.allCases where offen[cy][cx][r.rawValue] {
                let k = (cy + r.dy) * breite + cx + r.dx
                if gesehen.insert(k).inserted { vorher[k] = (cy * breite + cx, r); queue.append((cx + r.dx, cy + r.dy)) }
            }
        }
        var cur = zielIndex; var erste: Richtung?
        while let (vor, r) = vorher[cur] { erste = r; cur = vor }
        return erste
    }

    /// Punkte der Stufe: Grundwert, Funken, Bonus für einen Weg nahe am kürzesten.
    public func stufenPunkte() -> Int {
        guard let kurz = Irrgang.kuerzesterWegVomStart(self) else { return 0 }
        let effizienz = max(0, 1 - Double(schritte - kurz) / Double(max(1, kurz * 2)))
        return 100 * stufe + gesammelt * 50 + Int(effizienz * 100 * Double(stufe))
    }

    private static func kuerzesterWegVomStart(_ i: Irrgang) -> Int? {
        var k = i; k.x = 0; k.y = 0; return k.kuerzesterWeg()
    }
}
