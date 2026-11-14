// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Rommé-Karte: farbe 0–3, wert 1 (Ass) bis 13 (König); wert 0 = Joker.
public struct RKarte: Hashable, Sendable, Codable {
    public let farbe: Int
    public let wert: Int
    public let nummer: Int            // zur Unterscheidung der zwei Decks
    public init(_ f: Int, _ w: Int, _ n: Int = 0) { farbe = f; wert = w; nummer = n }
    public var joker: Bool { wert == 0 }
    public var symbol: String { joker ? "★" : ["♣", "♠", "♥", "♦"][farbe] }
    public var name: String { joker ? "J" : ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "B", "D", "K"][wert - 1] }
    public var augen: Int { joker ? 0 : (wert == 1 ? 11 : min(wert, 10)) }

    public static func deck() -> [RKarte] {
        var d: [RKarte] = []
        for n in 0..<2 { for f in 0..<4 { for w in 1...13 { d.append(RKarte(f, w, n)) } } }
        d += (0..<6).map { RKarte(0, 0, $0) }   // S1-012: deutsches Rommé-Blatt, 110 Karten
        return d
    }
}

public enum RommeRegeln {
    /// Satz: 3–4 Karten gleichen Werts in verschiedenen Farben (Joker ersetzen Karten).
    public static func istSatz(_ k: [RKarte]) -> Bool {
        guard (3...4).contains(k.count) else { return false }
        let echte = k.filter { !$0.joker }
        guard let w = echte.first?.wert, echte.allSatisfy({ $0.wert == w }) else { return false }
        return Set(echte.map(\.farbe)).count == echte.count && (k.count - echte.count) <= 2
    }

    /// Folge: ab 3 Karten gleicher Farbe in aufsteigender Reihe (Ass unten oder oben), Joker füllen Lücken.
    public static func istFolge(_ k: [RKarte]) -> Bool {
        guard k.count >= 3, k.count <= 14 else { return false }
        let echte = k.filter { !$0.joker }
        guard let f = echte.first?.farbe, echte.allSatisfy({ $0.farbe == f }) else { return false }
        let jok = k.count - echte.count
        guard Set(echte.map(\.wert)).count == echte.count else { return false }
        func geht(_ ws: [Int]) -> Bool {
            guard let lo = ws.min(), let hi = ws.max() else { return jok >= 3 }
            let luecken = (hi - lo + 1) - ws.count
            return luecken <= jok && (hi - lo + 1) <= k.count && k.count <= 14 && lo >= 1 && hi <= 14
        }
        let niedrig = echte.map(\.wert)
        let hoch = echte.map { $0.wert == 1 ? 14 : $0.wert }
        return geht(niedrig) || geht(hoch)
    }

    public static func istMeld(_ k: [RKarte]) -> Bool { istSatz(k) || istFolge(k) }

    /// Augen eines Kartenwerts auf der Reihe: 1 = Ass unten (1), 14 = Ass oben (11), 11–13 = 10, sonst der Wert.
    private static func reihenAugen(_ v: Int) -> Int { v == 14 ? 11 : (v >= 10 ? 10 : v) }

    /// Punktwert einer Auslage (RT-044, übliche Wertung): Joker zählen, was sie ersetzen. In einem Satz ist das der Wert des Satzes,
    /// in einer Folge der Wert der ersetzten Stelle (Lücken zuerst, übrige Joker nach oben, dann nach unten); das Ass zählt unten (A-2-3) 1, oben (D-K-A) 11.
    public static func punkte(_ k: [RKarte]) -> Int {
        let echte = k.filter { !$0.joker }
        guard let erste = echte.first else { return k.count * 10 }
        if istSatz(k) { return k.count * erste.augen }
        guard istFolge(k) else {   // keine gültige Auslage: wie bisher (Durchschnitt), nur für Anzeigen und Vorschläge
            let schnitt = echte.reduce(0) { $0 + $1.augen } / echte.count
            return echte.reduce(0) { $0 + $1.augen } + (k.count - echte.count) * schnitt
        }
        let jok = k.count - echte.count
        var beste = Int.min
        for hochAss in [false, true] {
            let ws = echte.map { hochAss && $0.wert == 1 ? 14 : $0.wert }
            guard let lo = ws.min(), let hi = ws.max() else { continue }
            let luecken = (hi - lo + 1) - ws.count
            guard luecken >= 0, luecken <= jok, hi - lo + 1 <= k.count, lo >= 1, hi <= 14 else { continue }
            var werte = Array(lo...hi)
            var extra = jok - luecken
            var oben = hi
            while extra > 0, oben < (hochAss ? 14 : 13) { oben += 1; werte.append(oben); extra -= 1 }
            var unten = lo
            while extra > 0, unten > 1 { unten -= 1; werte.append(unten); extra -= 1 }
            // Echte Karten zählen mit ihren echten Augen, die Joker mit den Werten der freien Stellen
            let belegt = Set(ws)
            let frei = werte.filter { !belegt.contains($0) }
            let summe = ws.reduce(0) { $0 + reihenAugen($1) } + frei.reduce(0) { $0 + reihenAugen($1) }
            beste = max(beste, summe)
        }
        return beste == Int.min ? echte.reduce(0) { $0 + $1.augen } : beste
    }

    /// Ordnet eine gültige Auslage für die Anzeige: Sätze nach Farbe, Folgen aufsteigend (Joker in den Lücken, Rest hinten).
    public static func ordne(_ k: [RKarte]) -> [RKarte] {
        let echte = k.filter { !$0.joker }, jok = k.filter(\.joker)
        if istSatz(k) { return echte.sorted { $0.farbe < $1.farbe } + jok }
        guard istFolge(k) else { return k }
        for hochAss in [false, true] {
            func w(_ c: RKarte) -> Int { hochAss && c.wert == 1 ? 14 : c.wert }
            let s = echte.sorted { w($0) < w($1) }
            var r: [RKarte] = [], j = jok
            for (i, c) in s.enumerated() {
                if i > 0 { for _ in 0..<(w(c) - w(s[i - 1]) - 1) where !j.isEmpty { r.append(j.removeFirst()) } }
                r.append(c)
            }
            r += j
            if istFolge(r) { return r }
        }
        return k
    }

    /// 1.0 (S3 Augen): Augen der gewählten Karten, wenn sie sich ganz in gültige Auslagen zerlegen lassen (sonst nil).
    /// Gleiche Rechnung wie die 40-Augen-Prüfung beim Auslegen.
    public static func auslageAugen(_ k: [RKarte]) -> Int? {
        guard k.count >= 3, let teile = zerlege(k) else { return nil }
        return teile.reduce(0) { $0 + punkte($1) }
    }

    /// Zerlegt die Karten vollständig in gültige Auslagen (falls möglich).
    public static func zerlege(_ k: [RKarte]) -> [[RKarte]]? {
        if k.isEmpty { return [] }
        let erste = k[0], rest = Array(k.dropFirst())
        let n = rest.count
        guard n <= 16 else { return nil }
        for maske in 0..<(1 << n) {
            let anzahl = maske.nonzeroBitCount
            guard anzahl >= 2 else { continue }
            var gruppe = [erste], uebrig: [RKarte] = []
            for i in 0..<n { if maske & (1 << i) != 0 { gruppe.append(rest[i]) } else { uebrig.append(rest[i]) } }
            if istMeld(gruppe), let r = zerlege(uebrig) { return [gruppe] + r }
        }
        return nil
    }
}

/// 1.0 (M19): Sortierung der eigenen Hand. Wirkt nur auf die Anzeige, die Hand im Stand bleibt unverändert.
public enum RommeSortierung: String, CaseIterable, Sendable {
    case gezogen, farbe, wert

    /// Anzeige-Reihenfolge als Indizes der Hand. Joker stehen bei Farbe und Wert immer hinten.
    public func reihenfolge(_ hand: [RKarte]) -> [Int] {
        let alle = Array(hand.indices)
        switch self {
        case .gezogen: return alle
        case .farbe: return alle.sorted { a, b in Self.schluessel(hand[a], farbeZuerst: true, a).lexicographicallyPrecedes(Self.schluessel(hand[b], farbeZuerst: true, b)) }
        case .wert: return alle.sorted { a, b in Self.schluessel(hand[a], farbeZuerst: false, a).lexicographicallyPrecedes(Self.schluessel(hand[b], farbeZuerst: false, b)) }
        }
    }

    private static func schluessel(_ k: RKarte, farbeZuerst: Bool, _ i: Int) -> [Int] {
        if k.joker { return [1, 0, 0, i] }
        return farbeZuerst ? [0, k.farbe, k.wert, i] : [0, k.wert, k.farbe, i]
    }
}

/// Rommé für 2–4 Spieler: 13 Karten, Karte ziehen (Stapel oder Ablage), auslegen (erste Auslage mindestens 40 Punkte), anlegen, abwerfen.
public struct Romme: Equatable, Sendable, Codable {
    public static let mindestens = 40
    public private(set) var haende: [[RKarte]]
    public private(set) var stapel: [RKarte] = []
    public private(set) var ablage: [RKarte] = []
    public private(set) var tisch: [[RKarte]] = []
    public private(set) var hatAusgelegt: [Bool]
    public private(set) var dran = 0
    public private(set) var gezogen = false
    /// Gewinner der laufenden Runde (bei einer Runde: der Partie).
    public private(set) var gewinner: Int?
    /// 1.0 (M8): Rundenzahl der Partie (1, 3 oder 5; Standard eine Runde) und die laufende Runde ab 1.
    public private(set) var rundenZiel = 1
    public private(set) var runde = 1
    /// 1.0 (M8): Strafpunkte je Spieler über alle beendeten Runden (Augen der Resthand, Joker 20). Zählt die laufende Runde mit, sobald sie endet.
    public private(set) var gesamt: [Int]
    /// Blatt 22 (EB2): Wer die Auslage `tisch[i]` zuerst gelegt hat (gleich lang wie `tisch`). Optional: Stände von vor dem Update haben es nicht (nil),
    /// dann zeigt die Ergebnisseite alle Auslagen. Anlegen und Joker tauschen ändern den Besitzer nicht.
    public private(set) var tischVon: [Int]?

    public static let rundenWahl = [1, 3, 5]

    public init<G: RandomNumberGenerator>(spieler: Int, runden: Int = 1, mit g: inout G) {
        let (h, st, a) = Self.geben(spieler, mit: &g)
        haende = h; stapel = st; ablage = a
        hatAusgelegt = Array(repeating: false, count: spieler)
        rundenZiel = Self.rundenWahl.contains(runden) ? runden : 1
        gesamt = Array(repeating: 0, count: spieler)
        tischVon = []
    }

    /// Feste Stellung (Tests, Wiederaufnahme).
    public init(haende: [[RKarte]], stapel: [RKarte] = [], ablage: [RKarte] = [], tisch: [[RKarte]] = [], hatAusgelegt: [Bool]? = nil, dran: Int = 0, gezogen: Bool = false,
                rundenZiel: Int = 1, runde: Int = 1, gesamt: [Int]? = nil) {
        self.haende = haende; self.stapel = stapel; self.ablage = ablage; self.tisch = tisch; self.dran = dran; self.gezogen = gezogen
        self.hatAusgelegt = hatAusgelegt ?? Array(repeating: false, count: haende.count)
        self.rundenZiel = rundenZiel; self.runde = runde
        self.gesamt = gesamt ?? Array(repeating: 0, count: haende.count)
    }

    /// 13 Karten je Spieler, eine offen auf die Ablage, der Rest ist der Stapel.
    private static func geben<G: RandomNumberGenerator>(_ spieler: Int, mit g: inout G) -> ([[RKarte]], [RKarte], [RKarte]) {
        var d = RKarte.deck().shuffled(using: &g)
        let h = (0..<spieler).map { _ in let h = Array(d.suffix(13)); d.removeLast(13); return h }
        let a = [d.removeLast()]
        return (h, d, a)
    }

    // 1.0 (M8): Stände von vor den Runden haben die neuen Felder nicht; sie laden als eine Runde.
    enum CodingKeys: String, CodingKey { case haende, stapel, ablage, tisch, hatAusgelegt, dran, gezogen, gewinner, rundenZiel, runde, gesamt, tischVon }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        haende = try c.decode([[RKarte]].self, forKey: .haende)
        stapel = try c.decode([RKarte].self, forKey: .stapel)
        ablage = try c.decode([RKarte].self, forKey: .ablage)
        tisch = try c.decode([[RKarte]].self, forKey: .tisch)
        hatAusgelegt = try c.decode([Bool].self, forKey: .hatAusgelegt)
        dran = try c.decode(Int.self, forKey: .dran)
        gezogen = try c.decode(Bool.self, forKey: .gezogen)
        gewinner = try c.decodeIfPresent(Int.self, forKey: .gewinner)
        rundenZiel = try c.decodeIfPresent(Int.self, forKey: .rundenZiel) ?? 1
        runde = try c.decodeIfPresent(Int.self, forKey: .runde) ?? 1
        gesamt = try c.decodeIfPresent([Int].self, forKey: .gesamt) ?? Array(repeating: 0, count: haende.count)
        tischVon = try c.decodeIfPresent([Int].self, forKey: .tischVon)
        if let v = tischVon, v.count != tisch.count { tischVon = nil }   // unstimmig: lieber nicht verwenden
        if !c.contains(.gesamt), gewinner != nil { gesamt = haende.indices.map { strafpunkte($0) } }
    }

    /// 1.0 (M8): Runde vorbei, es folgt noch eine.
    public var hatWeitereRunde: Bool { gewinner != nil && runde < rundenZiel }
    /// 1.0 (M8): Letzte Runde vorbei.
    public var partieVorbei: Bool { gewinner != nil && runde >= rundenZiel }
    /// 1.0 (M8): Spieler nach Gesamtstrafpunkten, wenigste zuerst (Gleichstand: wer die letzte Runde gewonnen hat, sonst Sitzreihenfolge).
    public var gesamtRangfolge: [Int] {
        haende.indices.sorted { a, b in
            if gesamt[a] != gesamt[b] { return gesamt[a] < gesamt[b] }
            if a == gewinner || b == gewinner { return a == gewinner }
            return a < b
        }
    }

    /// 1.0 (M8): Neu geben für die nächste Runde. Gesamtpunkte bleiben, der Startspieler rückt eins weiter.
    public mutating func naechsteRunde<G: RandomNumberGenerator>(mit g: inout G) {
        guard hatWeitereRunde else { return }
        let (h, st, a) = Self.geben(haende.count, mit: &g)
        haende = h; stapel = st; ablage = a; tisch = []; tischVon = []; hatAusgelegt = Array(repeating: false, count: haende.count)
        runde += 1; dran = (runde - 1) % haende.count; gezogen = false; gewinner = nil
    }

    /// Runde endet: Der Spieler am Zug hat keine Karten mehr; alle anderen bekommen die Augen ihrer Resthand als Strafpunkte.
    private mutating func rundeBeenden() {
        gewinner = dran
        for s in haende.indices { gesamt[s] += strafpunkte(s) }   // 1.0 (M8)
    }

    private mutating func naechster() { dran = (dran + 1) % haende.count; gezogen = false }

    public mutating func ziehe<G: RandomNumberGenerator>(vomStapel: Bool, mit g: inout G) {
        guard gewinner == nil, !gezogen else { return }
        if vomStapel {
            if stapel.isEmpty, ablage.count > 1 { let oben = ablage.removeLast(); stapel = ablage.shuffled(using: &g); ablage = [oben] }
            guard let k = stapel.popLast() else { return }
            haende[dran].append(k)
        } else { guard let k = ablage.popLast() else { return }; haende[dran].append(k) }
        gezogen = true
    }

    /// Legt die gewählten Karten (Indizes der Hand) aus. Muss sich vollständig in Auslagen zerlegen lassen.
    @discardableResult
    public mutating func auslegen(_ indizes: [Int]) -> Bool {
        guard gewinner == nil, gezogen, Set(indizes).count == indizes.count, indizes.allSatisfy({ haende[dran].indices.contains($0) }) else { return false }
        let karten = indizes.map { haende[dran][$0] }
        guard let teile = RommeRegeln.zerlege(karten) else { return false }
        if !hatAusgelegt[dran] && teile.reduce(0, { $0 + RommeRegeln.punkte($1) }) < Romme.mindestens { return false }
        for i in indizes.sorted(by: >) { haende[dran].remove(at: i) }
        if tischVon == nil && tisch.isEmpty { tischVon = [] }
        tisch += teile.map(RommeRegeln.ordne); hatAusgelegt[dran] = true
        if tischVon != nil { tischVon! += Array(repeating: dran, count: teile.count) }
        if haende[dran].isEmpty { rundeBeenden() }
        return true
    }

    @discardableResult
    public mutating func anlegen(_ index: Int, an meld: Int) -> Bool {
        guard gewinner == nil, gezogen, hatAusgelegt[dran], haende[dran].indices.contains(index), tisch.indices.contains(meld) else { return false }
        let k = haende[dran][index]
        for pos in 0...tisch[meld].count {
            var neu = tisch[meld]; neu.insert(k, at: pos)
            if RommeRegeln.istMeld(neu) { tisch[meld] = RommeRegeln.ordne(neu); haende[dran].remove(at: index); if haende[dran].isEmpty { rundeBeenden() }; return true }
        }
        return false
    }

    /// Ob die Handkarte an diese Auslage passt (ohne etwas zu ändern).
    public func kannAnlegen(_ index: Int, an meld: Int) -> Bool { var kopie = self; return kopie.anlegen(index, an: meld) }

    /// 1.0 (S3 Jokertausch): Stelle des Jokers in der Auslage, den die Handkarte ersetzen kann (die Auslage bleibt danach gültig).
    /// Nur nach der eigenen ersten Auslage, nach dem Ziehen, nur echte Karten.
    private func jokerTauschStelle(_ index: Int, an meld: Int) -> Int? {
        guard gewinner == nil, gezogen, hatAusgelegt[dran], haende[dran].indices.contains(index), tisch.indices.contains(meld) else { return nil }
        let k = haende[dran][index]
        guard !k.joker else { return nil }
        for j in tisch[meld].indices where tisch[meld][j].joker {
            var neu = tisch[meld]; neu[j] = k
            if RommeRegeln.istMeld(neu) { return j }
        }
        return nil
    }

    /// 1.0 (S3 Jokertausch): Ob die Handkarte einen Joker in dieser Auslage ersetzen kann.
    public func kannJokerTauschen(_ index: Int, an meld: Int) -> Bool { jokerTauschStelle(index, an: meld) != nil }

    /// 1.0 (S3 Jokertausch): Ob der Spieler am Zug gerade irgendeinen Joker tauschen kann.
    public var jokerTauschMoeglich: Bool {
        haende[dran].indices.contains { i in tisch.indices.contains { kannJokerTauschen(i, an: $0) } }
    }

    /// 1.0 (S3 Jokertausch): Legt die echte Karte an die Stelle des Jokers und nimmt den Joker auf die Hand (an dieselbe Handstelle).
    /// Der Zug geht weiter: Danach darf der Spieler den Joker auslegen, anlegen oder behalten.
    @discardableResult
    public mutating func jokerTauschen(_ index: Int, an meld: Int) -> Bool {
        guard let j = jokerTauschStelle(index, an: meld) else { return false }
        let joker = tisch[meld][j]
        tisch[meld][j] = haende[dran][index]
        tisch[meld] = RommeRegeln.ordne(tisch[meld])
        haende[dran][index] = joker
        return true
    }

    @discardableResult
    public mutating func abwerfen(_ index: Int) -> Bool {
        guard gewinner == nil, gezogen, haende[dran].indices.contains(index) else { return false }
        ablage.append(haende[dran].remove(at: index))
        if haende[dran].isEmpty { rundeBeenden() } else { naechster() }
        return true
    }

    public func strafpunkte(_ s: Int) -> Int { haende[s].reduce(0) { $0 + ($1.joker ? 20 : $1.augen) } }
}

public enum RommeComputer {
    /// Spielt einen ganzen Zug: ziehen, auslegen, anlegen, abwerfen.
    /// `stufe` 1 leicht (nimmt nie die Ablagekarte, wirft Zufälliges ab), 2 mittel (nimmt die Ablagekarte nur manchmal, wirft die höchste Karte ab),
    /// 3 schwer (nimmt passende Ablagekarten, wirft die Karte ab, die zu keiner anderen passt).
    public static func zug<G: RandomNumberGenerator>(_ r: inout Romme, stufe: Int = 3, mit g: inout G) {
        // Ablagekarte nehmen, wenn sie in einen Meld passt (vereinfacht: nur wenn sie mit zwei Handkarten einen Meld bildet)
        var nahm = false
        if let oben = r.ablage.last {
            let h = r.haende[r.dran]
            outer: for a in 0..<h.count { for b in (a + 1)..<max(a + 1, h.count) where RommeRegeln.istMeld([oben, h[a], h[b]]) { nahm = true; break outer } }
        }
        if stufe <= 1 || (stufe == 2 && nahm && Bool.random(using: &g)) { nahm = false }
        r.ziehe(vomStapel: !nahm, mit: &g)
        // 1.0 (S3 Jokertausch): ab Stufe mittel tauscht der Computer Joker vom Tisch, bevor er auslegt
        if stufe >= 2 { jokerTauschen(&r) }
        // Auslegen: größte Menge disjunkter Auslagen per Greedy
        var h = r.haende[r.dran]
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
        // Immer eine Karte zum Abwerfen behalten (außer Gewinn durch alles auslegen)
        if !alle.isEmpty, (r.hatAusgelegt[r.dran] || punkte >= Romme.mindestens) {
            var wahl = alle
            if wahl.count == h.count { wahl.removeLast() }       // eine Karte zum Abwerfen aufheben
            if let teile = RommeRegeln.zerlege(wahl.map { h[$0] }), !teile.isEmpty, r.hatAusgelegt[r.dran] || teile.reduce(0, { $0 + RommeRegeln.punkte($1) }) >= Romme.mindestens { r.auslegen(wahl) }
        }
        // 1.0 (S3 Jokertausch): auch direkt nach der ersten Auslage
        if stufe >= 2 { jokerTauschen(&r) }
        // Anlegen
        if r.hatAusgelegt[r.dran] {
            var geaendert = true
            while geaendert && r.gewinner == nil && r.haende[r.dran].count > 1 {
                geaendert = false
                h = r.haende[r.dran]
                outer: for i in h.indices { for m in r.tisch.indices where r.anlegen(i, an: m) { geaendert = true; break outer } }
            }
        }
        guard r.gewinner == nil else { return }
        // Abwerfen: Karte mit höchstem Wert, die in keiner Paarung steht (vereinfacht: höchste Augen)
        h = r.haende[r.dran]
        let i: Int
        if stufe <= 1 { i = h.indices.randomElement(using: &g) ?? 0 }
        else if stufe == 2 { i = h.indices.max { a, b in (h[a].joker ? -100 : h[a].augen) < (h[b].joker ? -100 : h[b].augen) } ?? 0 }
        else { i = h.indices.max { a, b in schlecht(h[a], h) < schlecht(h[b], h) } ?? 0 }
        r.abwerfen(i)
    }

    /// 1.0 (S3 Jokertausch): Tauscht, solange eine Handkarte einen Joker auf dem Tisch ersetzen kann (endet, weil jeder Tausch einen Joker vom Tisch nimmt).
    static func jokerTauschen(_ r: inout Romme) {
        var weiter = true
        while weiter && r.gewinner == nil {
            weiter = false
            suche: for i in r.haende[r.dran].indices { for m in r.tisch.indices where r.jokerTauschen(i, an: m) { weiter = true; break suche } }
        }
    }

    static func schlecht(_ k: RKarte, _ h: [RKarte]) -> Int {   // intern, auch für Vorschlag.swift (F4)
        if k.joker { return -100 }
        let nachbarn = h.filter { $0 != k && !$0.joker && (($0.wert == k.wert && $0.farbe != k.farbe) || ($0.farbe == k.farbe && abs($0.wert - k.wert) <= 2)) }.count
        return k.augen - nachbarn * 6
    }
}
