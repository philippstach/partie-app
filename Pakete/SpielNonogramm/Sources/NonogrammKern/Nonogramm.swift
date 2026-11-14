// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

public enum NonoFeld: Int, Sendable, Codable { case leer = 0, gefuellt, markiert }

/// Nonogramm: Zahlenhinweise je Zeile und Spalte; gelöst, wenn die gefüllten Felder alle Hinweise erfüllen.
public struct Nonogramm: Equatable, Sendable, Codable {
    public let n: Int
    public let loesung: [Bool]
    public private(set) var stand: [NonoFeld]
    public let zeilenHinweise: [[Int]]
    public let spaltenHinweise: [[Int]]

    public init(loesung: [Bool], n: Int) {
        self.n = n; self.loesung = loesung; stand = Array(repeating: .leer, count: n * n)
        func hinweise(_ linie: [Bool]) -> [Int] {
            var r: [Int] = [], c = 0
            for b in linie { if b { c += 1 } else if c > 0 { r.append(c); c = 0 } }
            if c > 0 { r.append(c) }
            return r.isEmpty ? [0] : r
        }
        zeilenHinweise = (0..<n).map { z in hinweise((0..<n).map { loesung[z * n + $0] }) }
        spaltenHinweise = (0..<n).map { s in hinweise((0..<n).map { loesung[$0 * n + s] }) }
    }

    /// Zufälliges Bild. Es wird so oft neu gewürfelt (bis `versuche`), bis die Hinweise das Bild eindeutig und
    /// ohne Raten festlegen (nur mit Zeilen- und Spaltenlogik lösbar). Danach das letzte Bild.
    public static func zufaellig<G: RandomNumberGenerator>(n: Int, dichte: Double = 0.58, versuche: Int = 300, mit g: inout G) -> Nonogramm {
        var letztes: Nonogramm?
        for _ in 0..<max(1, versuche) {
            var l = (0..<(n * n)).map { _ in Double.random(in: 0..<1, using: &g) < dichte }
            if !l.contains(true) { l[0] = true }
            let p = Nonogramm(loesung: l, n: n)
            if p.logischLoesbar { return p }
            letztes = p
        }
        return letztes!
    }

    /// Lösen die Hinweise das Bild allein durch Zeilen-/Spaltenlogik (jede Linie für sich), ohne Raten?
    public var logischLoesbar: Bool {
        var w = [Int](repeating: -1, count: n * n)         // -1 unbekannt, 0 leer, 1 gefüllt
        func plaetze(_ hint: [Int], _ bekannt: [Int]) -> [[Int]] {
            let h = hint == [0] ? [] : hint
            var aus: [[Int]] = []
            var cur = [Int](repeating: 0, count: bekannt.count)
            func rec(_ b: Int, _ pos: Int) {
                if b == h.count {
                    for i in pos..<bekannt.count where bekannt[i] == 1 { return }
                    aus.append(cur); return
                }
                let rest = h[(b + 1)...].reduce(0, +) + max(0, h.count - b - 1)
                var start = pos
                while start + h[b] + rest <= bekannt.count {
                    var ok = true
                    for i in pos..<start where bekannt[i] == 1 { ok = false; break }
                    if ok { for i in start..<(start + h[b]) where bekannt[i] == 0 { ok = false; break } }
                    if ok, start + h[b] < bekannt.count, bekannt[start + h[b]] == 1 { ok = false }
                    if ok {
                        for i in start..<(start + h[b]) { cur[i] = 1 }
                        rec(b + 1, min(bekannt.count, start + h[b] + 1))
                        for i in start..<(start + h[b]) { cur[i] = 0 }
                    }
                    start += 1
                }
            }
            rec(0, 0)
            return aus
        }
        var aenderung = true
        while aenderung {
            aenderung = false
            for lin in 0..<(2 * n) {
                let idx = (0..<n).map { lin < n ? lin * n + $0 : $0 * n + (lin - n) }
                let hint = lin < n ? zeilenHinweise[lin] : spaltenHinweise[lin - n]
                let ps = plaetze(hint, idx.map { w[$0] })
                if ps.isEmpty { return false }
                for (k, i) in idx.enumerated() where w[i] == -1 {
                    let alle = ps.allSatisfy { $0[k] == 1 }, keins = ps.allSatisfy { $0[k] == 0 }
                    if alle { w[i] = 1; aenderung = true } else if keins { w[i] = 0; aenderung = true }
                }
            }
        }
        return !w.contains(-1)
    }

    public mutating func tippe(_ i: Int) {
        guard stand.indices.contains(i) else { return }
        stand[i] = stand[i] == .gefuellt ? .leer : .gefuellt
    }
    /// Tipp: korrigiert ein falsches Feld (zu Unrecht gefüllt) oder füllt ein fehlendes; gibt den Index zurück.
    @discardableResult
    public mutating func tipp<G: RandomNumberGenerator>(mit g: inout G) -> Int? {
        let falsch = stand.indices.filter { (loesung[$0] && stand[$0] != .gefuellt) || (!loesung[$0] && stand[$0] == .gefuellt) }
        guard let i = falsch.filter({ !loesung[$0] }).randomElement(using: &g) ?? falsch.randomElement(using: &g) else { return nil }
        stand[i] = loesung[i] ? .gefuellt : .leer
        return i
    }

    public mutating func markiere(_ i: Int) { guard stand.indices.contains(i) else { return }; stand[i] = stand[i] == .markiert ? .leer : .markiert }

    private func linie(_ idx: [Int]) -> [Int] {
        var r: [Int] = [], c = 0
        for i in idx { if stand[i] == .gefuellt { c += 1 } else if c > 0 { r.append(c); c = 0 } }
        if c > 0 { r.append(c) }
        return r.isEmpty ? [0] : r
    }

    public func zeileErfuellt(_ z: Int) -> Bool { linie((0..<n).map { z * n + $0 }) == zeilenHinweise[z] }
    public func spalteErfuellt(_ s: Int) -> Bool { linie((0..<n).map { $0 * n + s }) == spaltenHinweise[s] }
    public var geloest: Bool { (0..<n).allSatisfy { zeileErfuellt($0) && spalteErfuellt($0) } }
    public var fehler: Int { stand.indices.filter { stand[$0] == .gefuellt && !loesung[$0] }.count }
}
