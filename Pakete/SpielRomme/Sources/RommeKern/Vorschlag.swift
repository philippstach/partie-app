// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
/// Vorschlag für den Menschen (F4 Tipp): dieselben Regeln wie `RommeComputer.zug(stufe: 3)` (schwer), aber ohne den Zug auszuführen.
/// Änderungen an der Stufe-3-Logik in `zug` bitte hier nachziehen (Test `testVorschlagEntsprichtStufeSchwer`).
public enum RommeVorschlag: Equatable, Sendable {
    case ablageNehmen, vomStapelZiehen
    case auslegen([Int])
    case anlegen(index: Int, an: Int)
    /// 1.0 (S3 Jokertausch): Handkarte gegen den Joker in Auslage `an` tauschen.
    case jokerTauschen(index: Int, an: Int)
    case abwerfen(Int)
}

public extension RommeComputer {
    /// Was der „Computer“ jetzt täte: vor dem Ziehen Ablage/Stapel, danach Auslegen (ab 40 bzw. nach erster Auslage), Anlegen, sonst Abwerfen.
    static func vorschlag(_ r: Romme) -> RommeVorschlag? {
        guard r.gewinner == nil else { return nil }
        let h = r.haende[r.dran]
        if !r.gezogen {
            if let oben = r.ablage.last {
                for a in 0..<h.count { for b in (a + 1)..<max(a + 1, h.count) where RommeRegeln.istMeld([oben, h[a], h[b]]) { return .ablageNehmen } }
            }
            return .vomStapelZiehen
        }
        // 1.0 (S3 Jokertausch): wie `zug` (Stufe 3 tauscht vor dem Auslegen)
        if r.hatAusgelegt[r.dran] {
            for i in h.indices { for m in r.tisch.indices where r.kannJokerTauschen(i, an: m) { return .jokerTauschen(index: i, an: m) } }
        }
        // Auslegen: größte disjunkte Auslagen per Greedy (wie `zug`)
        var gruppen: [[Int]] = []
        var benutzt = Set<Int>()
        while true {
            var best: ([Int], Int)?
            let idx = h.indices.filter { !benutzt.contains($0) }
            guard idx.count >= 3, idx.count <= 15 else { break }
            for maske in 0..<(1 << idx.count) where maske.nonzeroBitCount >= 3 {
                let teil = (0..<idx.count).filter { maske & (1 << $0) != 0 }.map { idx[$0] }
                let karten = teil.map { h[$0] }
                if RommeRegeln.istMeld(karten) { let p = RommeRegeln.punkte(karten); if best == nil || p > best!.1 { best = (teil, p) } }
            }
            guard let b = best else { break }
            gruppen.append(b.0); benutzt.formUnion(b.0)
        }
        let alle = gruppen.flatMap { $0 }
        let punkte = gruppen.reduce(0) { $0 + RommeRegeln.punkte($1.map { h[$0] }) }
        if !alle.isEmpty, (r.hatAusgelegt[r.dran] || punkte >= Romme.mindestens) {
            var wahl = alle
            if wahl.count == h.count { wahl.removeLast() }
            if let teile = RommeRegeln.zerlege(wahl.map { h[$0] }), !teile.isEmpty, r.hatAusgelegt[r.dran] || teile.reduce(0, { $0 + RommeRegeln.punkte($1) }) >= Romme.mindestens { return .auslegen(wahl.sorted()) }
        }
        if r.hatAusgelegt[r.dran], h.count > 1 {
            for i in h.indices { for m in r.tisch.indices {
                for pos in 0...r.tisch[m].count { var neu = r.tisch[m]; neu.insert(h[i], at: pos); if RommeRegeln.istMeld(neu) { return .anlegen(index: i, an: m) } }
            } }
        }
        let i = h.indices.max { a, b in schlecht(h[a], h) < schlecht(h[b], h) } ?? 0
        return .abwerfen(i)
    }
}

