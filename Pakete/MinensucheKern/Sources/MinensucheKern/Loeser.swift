// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Logik-Löser: findet Felder, die sich ohne Raten sicher bestimmen lassen.
/// Regeln: (1) Einzelzahl: alle Minen gefunden → Rest sicher; so viele Minen wie offene Felder → alles Minen.
/// (2) Teilmenge: umfasst die offene Nachbarschaft von A die von B, folgt aus der Differenz der Minenzahlen mehr.
public enum Loeser {
    public struct Ergebnis: Sendable {
        public var sicher: Set<Int> = []
        public var minen: Set<Int> = []
    }

    /// `zahl[i]` gilt nur, wo `aufgedeckt[i]` wahr ist. Es werden nur aufgedeckte Informationen benutzt.
    public static func ableiten(mass: Brettmass, zahl: [Int], aufgedeckt: [Bool]) -> Ergebnis {
        var erg = Ergebnis()
        var fortschritt = true
        while fortschritt {
            fortschritt = false
            struct Regel { var offen: Set<Int>; var rest: Int }
            var regeln: [Regel] = []
            for i in 0..<mass.felder where aufgedeckt[i] && zahl[i] > 0 {
                var offen = Set<Int>()
                var bekannt = 0
                for n in mass.nachbarn(i) where !aufgedeckt[n] {
                    if erg.minen.contains(n) { bekannt += 1 } else if !erg.sicher.contains(n) { offen.insert(n) }
                }
                let rest = zahl[i] - bekannt
                if offen.isEmpty { continue }
                regeln.append(Regel(offen: offen, rest: rest))
            }
            func anwenden(_ offen: Set<Int>, rest: Int) {
                if rest == 0 {
                    for f in offen where erg.sicher.insert(f).inserted { fortschritt = true }
                } else if rest == offen.count {
                    for f in offen where erg.minen.insert(f).inserted { fortschritt = true }
                }
            }
            for r in regeln { anwenden(r.offen, rest: r.rest) }
            if fortschritt { continue }
            // Teilmengen-Regel, nur für Regeln, die sich überlappen
            for a in regeln {
                for b in regeln where b.offen.count > a.offen.count && a.offen.isSubset(of: b.offen) {
                    anwenden(b.offen.subtracting(a.offen), rest: b.rest - a.rest)
                }
            }
        }
        return erg
    }

    /// Spielt das Brett nur mit Logik durch, beginnend bei `start`. Wahr, wenn alle sicheren Felder aufgedeckt werden.
    public static func istOhneRatenLoesbar(mass: Brettmass, minen: [Bool], start: Int) -> Bool {
        let zahl = zahlen(mass: mass, minen: minen)
        var offen = [Bool](repeating: false, count: mass.felder)
        aufdecken(start, mass: mass, minen: minen, zahl: zahl, offen: &offen)
        while true {
            let erg = ableiten(mass: mass, zahl: zahl, aufgedeckt: offen)
            let neu = erg.sicher.filter { !offen[$0] }
            if neu.isEmpty { break }
            for f in neu { aufdecken(f, mass: mass, minen: minen, zahl: zahl, offen: &offen) }
        }
        for i in 0..<mass.felder where !minen[i] && !offen[i] { return false }
        return true
    }

    public static func zahlen(mass: Brettmass, minen: [Bool]) -> [Int] {
        (0..<mass.felder).map { i in mass.nachbarn(i).reduce(0) { $0 + (minen[$1] ? 1 : 0) } }
    }

    /// Deckt `start` auf; bei Zahl 0 fließt es über alle Nullfelder und ihren Rand.
    static func aufdecken(_ start: Int, mass: Brettmass, minen: [Bool], zahl: [Int], offen: inout [Bool]) {
        var stapel = [start]
        while let i = stapel.popLast() {
            if offen[i] || minen[i] { continue }
            offen[i] = true
            if zahl[i] == 0 { stapel.append(contentsOf: mass.nachbarn(i).filter { !offen[$0] }) }
        }
    }
}
