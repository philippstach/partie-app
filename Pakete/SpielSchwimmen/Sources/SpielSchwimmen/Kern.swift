// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

// Regelkern von Schwimmen. Reine Logik ohne Oberfläche. Hausregeln stehen in `SchwimmenRegeln`.

struct SwKarte: Hashable, Codable, Sendable {
    var farbe: Int   // 0 Kreuz, 1 Pik, 2 Herz, 3 Karo
    var wert: Int    // 7…10, 11 Bube, 12 Dame, 13 König, 14 Ass
    init(_ farbe: Int, _ wert: Int) { self.farbe = farbe; self.wert = wert }
    static let alle: [SwKarte] = (0..<4).flatMap { f in (7...14).map { SwKarte(f, $0) } }
    var augen: Double { wert == 14 ? 11 : (wert >= 11 ? 10 : Double(wert)) }
    var symbol: String { ["♣", "♠", "♥", "♦"][farbe] }
    var name: String { ["7", "8", "9", "10", "B", "D", "K", "A"][wert - 7] }
}

enum SwModus: String, Codable, CaseIterable, Sendable { case leben, punkte }

struct SchwimmenRegeln: Codable, Equatable, Sendable {
    /// Leben zu Beginn (3 oder 4). Nur im Modus „Leben“.
    var leben = 3
    /// 31 bzw. 33 beendet die Runde sofort (sonst zählt sie wie jede andere Hand).
    var feuerSofort = true
    /// Drei Asse zählen 33 (statt 30,5 bzw. 30) und sind das beste Blatt.
    var dreiAssen33 = false
    /// Höchstens so oft darf jeder Spieler je Runde schieben (nil = unbegrenzt).
    var schiebenLimit: Int?
    /// Wert von drei gleichen Karten: 30,5 oder 30.
    var dreiGleiche = 30.5
    var modus = SwModus.leben
    /// Rundenzahl im Punktemodus.
    var runden = 5

    static let standard = SchwimmenRegeln()
}

/// Punkte einer Hand nach den Regeln.
func swPunkte(_ hand: [SwKarte], _ r: SchwimmenRegeln) -> Double {
    guard hand.count == 3 else { return 0 }
    if Set(hand.map(\.wert)).count == 1 { return (r.dreiAssen33 && hand[0].wert == 14) ? 33 : r.dreiGleiche }
    return suitSummen(hand).max() ?? 0
}

private func suitSummen(_ hand: [SwKarte]) -> [Double] { (0..<4).map { f in hand.filter { $0.farbe == f }.reduce(0) { $0 + $1.augen } } }

/// 31 mit einer Farbe oder 33 mit drei Assen (dreiAssen33).
func swIstFeuer(_ hand: [SwKarte], _ r: SchwimmenRegeln) -> Bool {
    guard hand.count == 3 else { return false }
    if Set(hand.map(\.wert)).count == 1 { return r.dreiAssen33 && hand[0].wert == 14 }
    return suitSummen(hand).contains(31)
}

/// Farbe, die zählt (für „Herz 21“), nil bei drei gleichen Karten.
func swBesteFarbe(_ hand: [SwKarte]) -> Int? {
    guard hand.count == 3, Set(hand.map(\.wert)).count > 1 else { return nil }
    let s = suitSummen(hand), m = s.max() ?? 0
    return s.firstIndex(of: m)
}

struct SwEreignis: Codable, Equatable, Sendable {
    enum Art: Codable, Equatable, Sendable { case tauscht(hand: SwKarte, tisch: SwKarte), tauschtAlle, schiebt, klopft, feuer }
    var spieler: Int
    var art: Art
}

struct SchwimmenNeu: Codable, Equatable, Sendable {
    private(set) var regeln: SchwimmenRegeln
    private(set) var leben: [Int]
    private(set) var summen: [Double]
    private(set) var runde = 1
    private(set) var hand: [[SwKarte]] = []
    private(set) var tisch: [SwKarte] = []
    private(set) var stapel: [SwKarte] = []
    private(set) var dran = 0
    private(set) var klopfer: Int?
    private(set) var passInFolge = 0
    private(set) var geschoben: [Int]
    private(set) var rundeVorbei = false
    private(set) var verlierer: [Int] = []
    private(set) var feuerVon: Int?
    private(set) var beginner = 0
    private(set) var verlauf: [SwEreignis] = []
    /// Blatt 22 (EB2): das beste Blatt der ganzen Partie und wer es hatte. Optional, damit Stände von vor dem Update weiter laden (dann nil).
    private(set) var bestesBlatt: Double?
    private(set) var bestesBlattVon: Int?

    init<G: RandomNumberGenerator>(spieler: Int, regeln: SchwimmenRegeln, mit g: inout G) {
        self.regeln = regeln
        leben = Array(repeating: regeln.leben, count: spieler)
        summen = Array(repeating: 0, count: spieler)
        geschoben = Array(repeating: 0, count: spieler)
        hand = Array(repeating: [], count: spieler)
        teile(mit: &g)
    }

    /// Für Tests: feste Lage (ohne Austeilen).
    init(regeln: SchwimmenRegeln, leben: [Int], hand: [[SwKarte]], tisch: [SwKarte], stapel: [SwKarte] = [], dran: Int = 0) {
        self.regeln = regeln; self.leben = leben; self.hand = hand; self.tisch = tisch; self.stapel = stapel; self.dran = dran
        summen = Array(repeating: 0, count: leben.count); geschoben = Array(repeating: 0, count: leben.count)
    }

    var spielerZahl: Int { leben.count }
    /// Im Punktemodus spielen alle bis zum Schluss mit.
    var aktive: [Int] { regeln.modus == .punkte ? Array(leben.indices) : leben.indices.filter { leben[$0] >= 0 } }
    var punkte: [Double] { hand.map { swPunkte($0, regeln) } }
    var spielZuEnde: Bool { sieger != nil || (regeln.modus == .punkte && rundeVorbei && runde >= regeln.runden) }

    /// Sieger (Leben: letzter Überlebender; Punkte: höchste Summe nach der letzten Runde, bei Gleichstand der erste in Reihenfolge).
    var sieger: Int? {
        switch regeln.modus {
        case .leben: return aktive.count == 1 ? aktive[0] : nil
        case .punkte:
            guard rundeVorbei, runde >= regeln.runden else { return nil }
            return rangfolge.first
        }
    }

    /// Spieler vom Besten zum Schlechtesten.
    var rangfolge: [Int] {
        switch regeln.modus {
        case .punkte: return leben.indices.sorted { (-summen[$0], $0) < (-summen[$1], $1) }
        case .leben: return leben.indices.sorted { (-leben[$0], $0) < (-leben[$1], $1) }
        }
    }

    var kannSchieben: Bool {
        guard !rundeVorbei else { return false }
        guard let l = regeln.schiebenLimit else { return true }
        return geschoben[dran] < l
    }
    var kannKlopfen: Bool { !rundeVorbei && klopfer == nil }

    // MARK: Runden

    mutating func neueRunde<G: RandomNumberGenerator>(mit g: inout G) {
        guard rundeVorbei, !spielZuEnde else { return }
        runde += 1
        teile(mit: &g)
    }

    private mutating func teile<G: RandomNumberGenerator>(mit g: inout G) {
        var deck = SwKarte.alle.shuffled(using: &g)
        var neu: [[SwKarte]] = []
        let a = aktive
        for i in leben.indices {
            if a.contains(i) { neu.append(Array(deck.suffix(3))); deck.removeLast(3) } else { neu.append([]) }
        }
        hand = neu
        tisch = Array(deck.suffix(3)); deck.removeLast(3)
        stapel = deck
        klopfer = nil; passInFolge = 0; rundeVorbei = false; verlierer = []; feuerVon = nil
        geschoben = Array(repeating: 0, count: leben.count)
        verlauf = []
        dran = a.contains(beginner) ? beginner : a[0]
        if regeln.feuerSofort, let s = a.first(where: { swIstFeuer(hand[$0], regeln) }) { feuer(s) }
    }

    private mutating func weiter() {
        let a = aktive
        var n = (dran + 1) % leben.count
        while !a.contains(n) { n = (n + 1) % leben.count }
        dran = n
        if let k = klopfer, dran == k { rundeAuswerten() }
    }

    private mutating func nachZug() {
        if regeln.feuerSofort, swIstFeuer(hand[dran], regeln) { feuer(dran); return }
        weiter()
    }

    private mutating func protokoll(_ a: SwEreignis.Art) {
        verlauf.append(SwEreignis(spieler: dran, art: a)); if verlauf.count > 30 { verlauf.removeFirst() }
    }

    // MARK: Züge

    @discardableResult
    mutating func tauscheEine(hand h: Int, tisch t: Int) -> Bool {
        guard !rundeVorbei, hand[dran].indices.contains(h), tisch.indices.contains(t) else { return false }
        protokoll(.tauscht(hand: hand[dran][h], tisch: tisch[t]))
        swap(&hand[dran][h], &tisch[t]); passInFolge = 0; nachZug(); return true
    }

    @discardableResult
    mutating func tauscheAlle() -> Bool {
        guard !rundeVorbei else { return false }
        protokoll(.tauschtAlle)
        let t = tisch; tisch = hand[dran]; hand[dran] = t; passInFolge = 0; nachZug(); return true
    }

    @discardableResult
    mutating func schieben() -> Bool {
        guard kannSchieben else { return false }
        protokoll(.schiebt)
        geschoben[dran] += 1
        passInFolge += 1
        if passInFolge >= aktive.count, stapel.count >= 3 { tisch = Array(stapel.prefix(3)); stapel.removeFirst(3); passInFolge = 0 }
        weiter(); return true
    }

    @discardableResult
    mutating func klopfen() -> Bool {
        guard kannKlopfen else { return false }
        protokoll(.klopft)
        klopfer = dran; weiter(); return true
    }

    private mutating func feuer(_ s: Int) {
        protokoll(.feuer)
        rundeVorbei = true; feuerVon = s
        merkeBestesBlatt()
        if regeln.modus == .leben {
            verlierer = aktive.filter { $0 != s }
            for v in verlierer { leben[v] -= 1 }
        } else { buchePunkte() }
        beginner = (beginner + 1) % leben.count
    }

    /// Merkt das höchste Blatt dieser Runde, wenn es das bisher beste der Partie ist (bei Gleichstand gilt das frühere).
    private mutating func merkeBestesBlatt() {
        for i in aktive where hand.indices.contains(i) {
            let p = swPunkte(hand[i], regeln)
            if p > (bestesBlatt ?? -1) { bestesBlatt = p; bestesBlattVon = i }
        }
    }

    private mutating func rundeAuswerten() {
        rundeVorbei = true
        merkeBestesBlatt()
        let p = punkte
        if regeln.modus == .leben {
            let niedrigste = aktive.map { p[$0] }.min() ?? 0
            verlierer = aktive.filter { p[$0] == niedrigste }
            // Haben alle gleich viele Punkte, verliert niemand ein Leben
            if verlierer.count == aktive.count, aktive.count > 1 { verlierer = [] }
            for v in verlierer { leben[v] -= 1 }
        } else { buchePunkte() }
        beginner = (beginner + 1) % leben.count
    }

    private mutating func buchePunkte() { for (i, p) in punkte.enumerated() { summen[i] += p } }

    func schwimmt(_ i: Int) -> Bool { regeln.modus == .leben && leben[i] == 0 }
    /// Alle, die in der gerade beendeten Runde Karten hatten.
    var teilnehmerDieserRunde: [Int] { hand.indices.filter { !hand[$0].isEmpty } }

    // MARK: Vorschau

    /// Punkte der Hand des Spielers am Zug nach dem Tausch (ohne den Zug auszuführen).
    func vorschauEine(hand h: Int, tisch t: Int) -> Double {
        var n = hand[dran]; n[h] = tisch[t]; return swPunkte(n, regeln)
    }
    func vorschauAlle() -> Double { swPunkte(tisch, regeln) }

    // MARK: Computer

    enum Zug: Equatable { case eine(Int, Int), alle, schieben, klopfen }

    /// Schwellen der Stufe „schwer“ (aus der Simulation des Spielkerns übernommen).
    static let schwerSofort = 30.0, schwerFestgefahren = 27.0

    /// `stufe` 1 leicht (macht oft einen zufälligen Zug), 2 mittel (klopft ab 27, festgefahren ab 22), 3 schwer.
    func computerWahl<G: RandomNumberGenerator>(stufe: Int = 2, mit g: inout G) -> Zug {
        let h = hand[dran], jetzt = swPunkte(h, regeln)
        let darfSchieben = kannSchieben
        if stufe <= 1, Double.random(in: 0..<1, using: &g) < 0.4 {
            switch Int.random(in: 0..<4, using: &g) {
            case 0: return .alle
            case 1: return kannKlopfen ? .klopfen : (darfSchieben ? .schieben : .alle)
            case 2: return darfSchieben ? .schieben : .alle
            default: return .eine(Int.random(in: 0..<3, using: &g), Int.random(in: 0..<3, using: &g))
            }
        }
        var bestZug: Zug? = nil, bestWert = -1.0
        for a in 0..<3 { for b in 0..<3 {
            var n = h; n[a] = tisch[b]
            let w = swPunkte(n, regeln); if w > bestWert { bestWert = w; bestZug = .eine(a, b) }
        } }
        let alle = swPunkte(tisch, regeln)
        if alle > bestWert { bestWert = alle; bestZug = .alle }
        let besser = bestWert > jetzt
        let sofort = stufe >= 3 ? Self.schwerSofort : 27, festgefahren = stufe >= 3 ? Self.schwerFestgefahren : 22
        if kannKlopfen, jetzt >= sofort { return .klopfen }
        if !besser {
            if kannKlopfen, jetzt >= festgefahren { return .klopfen }
            if darfSchieben { return .schieben }
            // Schieben verboten und nichts hilft: kleinstes Übel
            return bestZug ?? .alle
        }
        return bestZug ?? .schieben
    }

    @discardableResult
    mutating func fuehreAus(_ z: Zug) -> Bool {
        switch z {
        case .eine(let a, let b): tauscheEine(hand: a, tisch: b)
        case .alle: tauscheAlle()
        case .schieben: schieben()
        case .klopfen: klopfen()
        }
    }
}

/// Namen für Anzeige und VoiceOver.
enum SwNamen {
    static func farbName(_ f: Int) -> String { [String(localized: "Kreuz"), String(localized: "Pik"), String(localized: "Herz"), String(localized: "Karo")][f] }
    static func karte(_ k: SwKarte) -> String { "\(k.symbol)\(k.name)" }
    static func zahl(_ p: Double) -> String { p == p.rounded() ? "\(Int(p))" : String(format: "%.1f", p).replacingOccurrences(of: ".", with: ",") }
}
