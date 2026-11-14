// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

public struct KakuroLauf: Equatable, Sendable, Codable {
    public let felder: [Int]        // Zellindizes in Leserichtung
    public let summe: Int
    public let waagrecht: Bool
    public let startFeld: Int       // Hinweis-Zelle (Block vor dem Lauf)
}

/// Kakuro: Zahlen 1–9 so eintragen, dass jeder Lauf (waagrecht/senkrecht) die Hinweissumme ergibt und keine Zahl doppelt vorkommt.
public struct Kakuro: Equatable, Sendable, Codable {
    public let n: Int
    public let weiss: [Bool]
    public let laeufe: [KakuroLauf]
    public let loesung: [Int]
    public private(set) var eintrag: [Int]
    /// Felder mit fester Ziffer (damit das Rätsel genau eine Lösung hat); sie lassen sich nicht ändern.
    public let vorgaben: Set<Int>

    public init(n: Int, weiss: [Bool], laeufe: [KakuroLauf], loesung: [Int], vorgaben: Set<Int> = []) {
        self.n = n; self.weiss = weiss; self.laeufe = laeufe; self.loesung = loesung; self.vorgaben = vorgaben
        var e = Array(repeating: 0, count: n * n)
        for i in vorgaben { e[i] = loesung[i] }
        eintrag = e
    }

    /// RT-008: Erstes weißes Feld, das man ändern darf (feste Vorgaben sind nicht wählbar).
    public var ersteFreie: Int? { weiss.indices.first { weiss[$0] && !vorgaben.contains($0) } }

    public static func zufaellig<G: RandomNumberGenerator>(n: Int = 6, mit g: inout G) -> Kakuro {
        while true {
            var weiss = (0..<(n * n)).map { i in i / n > 0 && i % n > 0 && Double.random(in: 0..<1, using: &g) > 0.2 }
            // Einzelfelder (Lauf der Länge 1) zu Blöcken machen, bis alles stabil ist
            var geaendert = true
            while geaendert {
                geaendert = false
                for i in 0..<(n * n) where weiss[i] {
                    let z = i / n, s = i % n
                    let h = (s > 0 && weiss[i - 1]) || (s < n - 1 && weiss[i + 1])
                    let v = (z > 0 && weiss[i - n]) || (z < n - 1 && weiss[i + n])
                    if !h || !v { weiss[i] = false; geaendert = true }
                }
            }
            guard weiss.filter({ $0 }).count >= n * n / 2 - 2 else { continue }
            // Läufe bestimmen
            var laeufeFelder: [(felder: [Int], waag: Bool, start: Int)] = []
            for z in 0..<n { var s = 0
                while s < n { if weiss[z * n + s] { var f: [Int] = []; let st = z * n + s - 1; while s < n, weiss[z * n + s] { f.append(z * n + s); s += 1 }; if f.count >= 2 { laeufeFelder.append((f, true, st)) } } else { s += 1 } } }
            for s in 0..<n { var z = 0
                while z < n { if weiss[z * n + s] { var f: [Int] = []; let st = (z - 1) * n + s; while z < n, weiss[z * n + s] { f.append(z * n + s); z += 1 }; if f.count >= 2 { laeufeFelder.append((f, false, st)) } } else { z += 1 } } }
            guard laeufeFelder.count >= 4, laeufeFelder.allSatisfy({ $0.felder.count <= 9 }) else { continue }
            // Füllen per Rückverfolgung
            var wert = Array(repeating: 0, count: n * n)
            let reihenfolge = (0..<(n * n)).filter { weiss[$0] }
            var laeufeVon: [Int: [Int]] = [:]
            for (k, l) in laeufeFelder.enumerated() { for f in l.felder { laeufeVon[f, default: []].append(k) } }
            var schritte = 0
            func fuelle(_ idx: Int) -> Bool {
                if idx == reihenfolge.count { return true }
                schritte += 1; if schritte > 20000 { return false }
                let f = reihenfolge[idx]
                for d in (1...9).shuffled(using: &g) {
                    if (laeufeVon[f] ?? []).contains(where: { k in laeufeFelder[k].felder.contains { wert[$0] == d } }) { continue }
                    wert[f] = d
                    if fuelle(idx + 1) { return true }
                    wert[f] = 0
                }
                return false
            }
            guard fuelle(0) else { continue }
            let laeufe = laeufeFelder.map { l in KakuroLauf(felder: l.felder, summe: l.felder.reduce(0) { $0 + wert[$1] }, waagrecht: l.waag, startFeld: l.start) }
            return Kakuro.eindeutig(Kakuro(n: n, weiss: weiss, laeufe: laeufe, loesung: wert), mit: &g)
        }
    }

    /// Macht das Rätsel eindeutig: Ziffern vorgeben, bis genau eine Lösung bleibt, dann überflüssige Vorgaben wieder streichen.
    static func eindeutig<G: RandomNumberGenerator>(_ k: Kakuro, mit g: inout G) -> Kakuro {
        let weisse = k.weiss.indices.filter { k.weiss[$0] }
        var v = Set<Int>()
        func zaehle(_ v: Set<Int>) -> Int? { Kakuro(n: k.n, weiss: k.weiss, laeufe: k.laeufe, loesung: k.loesung, vorgaben: v).loesungenOderNil(grenze: 2, schrittLimit: 25_000) }   // knappes Limit: bei Zweifel bleibt die Vorgabe stehen (Rätsel bleibt eindeutig, Erzeugung bleibt schnell)
        var reihenfolge = weisse.shuffled(using: &g)
        while zaehle(v) != 1, let naechste = reihenfolge.popLast() { v.insert(naechste) }
        for i in v.sorted().shuffled(using: &g) {
            var w = v; w.remove(i)
            if zaehle(w) == 1 { v = w }
        }
        return Kakuro(n: k.n, weiss: k.weiss, laeufe: k.laeufe, loesung: k.loesung, vorgaben: v)
    }

    /// Zählt die Lösungen (bricht bei `grenze` ab). 1 = eindeutig lösbar. Bei erreichtem Suchlimit: Mindestzahl bis dahin.
    public func loesungen(grenze: Int = 2) -> Int { loesungenOderNil(grenze: grenze) ?? grenze }

    /// Wie `loesungen`, aber `nil`, wenn die Suche das Schrittlimit erreicht hat (Ergebnis unbekannt).
    func loesungenOderNil(grenze: Int, schrittLimit: Int = 300_000) -> Int? {
        let felder = weiss.indices.filter { weiss[$0] }
        var laeufeVon: [Int: [KakuroLauf]] = [:]
        for l in laeufe { for f in l.felder { laeufeVon[f, default: []].append(l) } }
        var w = Array(repeating: 0, count: n * n)
        for i in vorgaben { w[i] = loesung[i] }
        var anzahl = 0, schritte = 0, abgebrochen = false
        func ok(_ f: Int, _ d: Int) -> Bool {
            for l in laeufeVon[f] ?? [] {
                var summe = d, offen = 0, benutzt = 1 << (d - 1)
                for g in l.felder where g != f {
                    if w[g] == d { return false }
                    if w[g] == 0 { offen += 1 } else { summe += w[g]; benutzt |= 1 << (w[g] - 1) }
                }
                let rest = l.summe - summe
                if rest < 0 || (offen == 0 && rest != 0) { return false }
                if offen > 0 {
                    let frei = (1...9).filter { benutzt & (1 << ($0 - 1)) == 0 }
                    if frei.count < offen { return false }
                    if frei.prefix(offen).reduce(0, +) > rest || frei.suffix(offen).reduce(0, +) < rest { return false }
                }
            }
            return true
        }
        func rec(_ i: Int) {
            if anzahl >= grenze || abgebrochen { return }
            schritte += 1
            if schritte > schrittLimit { abgebrochen = true; return }
            if i == felder.count { anzahl += 1; return }
            let f = felder[i]
            if vorgaben.contains(f) { if ok(f, w[f]) || true { rec(i + 1) }; return }
            for d in 1...9 where ok(f, d) { w[f] = d; rec(i + 1); w[f] = 0 }
        }
        // Vorgaben prüfen: jede muss zu den Läufen passen
        for f in vorgaben { let d = w[f]; w[f] = 0; let gut = ok(f, d); w[f] = d; if !gut { return 0 } }
        rec(0)
        if abgebrochen && anzahl < grenze { return nil }
        return anzahl
    }

    public mutating func setze(_ feld: Int, _ zahl: Int) {
        guard weiss.indices.contains(feld), weiss[feld], !vorgaben.contains(feld), (0...9).contains(zahl) else { return }
        eintrag[feld] = zahl
    }

    public func laufErfuellt(_ l: KakuroLauf) -> Bool {
        let w = l.felder.map { eintrag[$0] }
        return !w.contains(0) && Set(w).count == w.count && w.reduce(0, +) == l.summe
    }

    public var geloest: Bool { !laeufe.isEmpty && laeufe.allSatisfy(laufErfuellt) }   // ohne Läufe (kaputter Stand) nie „gelöst“

    /// Felder mit doppelter Zahl in einem Lauf oder zu großer Summe.
    public func fehlerFelder() -> Set<Int> {
        var f = Set<Int>()
        for l in laeufe {
            let w = l.felder.filter { eintrag[$0] != 0 }
            let werte = w.map { eintrag[$0] }
            for a in w where werte.filter({ $0 == eintrag[a] }).count > 1 { f.insert(a) }
            if werte.reduce(0, +) > l.summe { w.forEach { f.insert($0) } }
        }
        return f
    }

    public func hinweisWaagrecht(_ feld: Int) -> Int? { laeufe.first { $0.waagrecht && $0.startFeld == feld }?.summe }
    public func hinweisSenkrecht(_ feld: Int) -> Int? { laeufe.first { !$0.waagrecht && $0.startFeld == feld }?.summe }

    public mutating func loesen() { eintrag = loesung }

    /// Ziffern, die im Feld nach den bisherigen Einträgen noch möglich sind (Summe und „keine Zahl doppelt“ in beiden Läufen).
    public func kandidaten(_ feld: Int) -> Set<Int> {
        guard weiss.indices.contains(feld), weiss[feld] else { return [] }
        var ergebnis = Set(1...9)
        for l in laeufe where l.felder.contains(feld) {
            let andere = l.felder.filter { $0 != feld }.map { eintrag[$0] }.filter { $0 != 0 }
            var moeglich = Set<Int>()
            for maske in 1..<512 where maske.nonzeroBitCount == l.felder.count {
                let ziffern = (1...9).filter { maske & (1 << ($0 - 1)) != 0 }
                guard ziffern.reduce(0, +) == l.summe, andere.allSatisfy(ziffern.contains) else { continue }
                for d in ziffern where !andere.contains(d) { moeglich.insert(d) }
            }
            ergebnis.formIntersection(moeglich)
        }
        return ergebnis
    }

    /// „Prüfen“: Felder, die ausgefüllt sind, aber nicht zur Lösung passen (Vorgaben zählen nie dazu).
    public func falscheEintraege() -> Set<Int> {
        Set(weiss.indices.filter { weiss[$0] && !vorgaben.contains($0) && eintrag[$0] != 0 && eintrag[$0] != loesung[$0] })
    }

    /// Tipp: trägt in ein leeres oder falsches Feld die Ziffer der Lösung ein und gibt das Feld zurück.
    @discardableResult
    public mutating func tipp<G: RandomNumberGenerator>(bevorzugt feld: Int?, mit g: inout G) -> Int? {
        if let f = feld, weiss[f], !vorgaben.contains(f), eintrag[f] != loesung[f] { eintrag[f] = loesung[f]; return f }
        let offen = weiss.indices.filter { weiss[$0] && !vorgaben.contains($0) && eintrag[$0] != loesung[$0] }
        guard let f = offen.randomElement(using: &g) else { return nil }
        eintrag[f] = loesung[f]; return f
    }
}
