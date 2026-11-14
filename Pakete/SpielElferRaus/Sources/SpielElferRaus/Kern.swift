// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

// Regelkern von Elfer raus. Reine Logik ohne Oberfläche. Die Regeln sind in `ErRegeln` getrennt von der Spielmechanik,
// damit Philipp sie ändern kann (Standard „Elfer raus!“ mit 80 Karten, Variante „Kartendomino“ = die frühere Skat-Form).

struct ErKarte: Hashable, Codable, Sendable {
    var farbe: Int   // 0…3
    var wert: Int
    init(_ farbe: Int, _ wert: Int) { self.farbe = farbe; self.wert = wert }
}

enum ErVariante: String, Codable, CaseIterable, Sendable { case echt, kartendomino }

struct ErRegeln: Codable, Equatable, Sendable {
    var variante: ErVariante
    /// Kartenwerte des Blatts: 1…20 (80 Karten) bzw. 7…14 (Skatblatt, 32 Karten).
    var werte: ClosedRange<Int>
    /// Beliebig viele Karten je Zug (sonst genau eine).
    var mehrereKarten: Bool
    /// Wer nicht anlegen kann, zieht vom Stapel (sonst: passen).
    var ziehen: Bool
    /// Karten je Spieler; nil = alle Karten austeilen.
    var handGroesse: Int?
    /// Farbe, deren 11 beginnt (echt: Rot = 0; Kartendomino: Herz = 2).
    var startFarbe: Int

    static let mitte = 11

    static let echt = ErRegeln(variante: .echt, werte: 1...20, mehrereKarten: true, ziehen: true, handGroesse: 10, startFarbe: 0)
    static let kartendomino = ErRegeln(variante: .kartendomino, werte: 7...14, mehrereKarten: false, ziehen: false, handGroesse: nil, startFarbe: 2)
    static func fuer(_ v: ErVariante) -> ErRegeln { v == .echt ? .echt : .kartendomino }

    var blatt: [ErKarte] { (0..<4).flatMap { f in werte.map { ErKarte(f, $0) } } }
}

enum ErAktion: Equatable, Codable, Sendable {
    case lege(ErKarte), beende, ziehenOderPassen
}

struct ErEreignis: Codable, Equatable, Sendable {
    enum Art: Codable, Equatable, Sendable { case legt(ErKarte), zieht, passt, beendet }
    var spieler: Int
    var art: Art
}

struct ErSpiel: Codable, Equatable, Sendable {
    private(set) var regeln: ErRegeln
    private(set) var haende: [[ErKarte]]
    private(set) var stapel: [ErKarte]
    /// Je Farbe der ausgelegte Bereich.
    private(set) var reihen: [ClosedRange<Int>?]
    private(set) var dran = 0
    /// Karten, die der Spieler am Zug in diesem Zug schon gelegt hat.
    private(set) var gelegtImZug = 0
    private(set) var passenInFolge = 0
    private(set) var rundeBeendet = false
    private(set) var sieger: Int?
    private(set) var verlauf: [ErEreignis] = []

    init<G: RandomNumberGenerator>(spieler: Int, regeln: ErRegeln, mit g: inout G) {
        precondition(spieler >= 2)
        self.regeln = regeln
        var deck = regeln.blatt.shuffled(using: &g)
        reihen = Array(repeating: nil, count: 4)
        var h = Array(repeating: [ErKarte](), count: spieler)
        if let n = regeln.handGroesse {
            for _ in 0..<n { for s in 0..<spieler { h[s].append(deck.removeLast()) } }
        } else {
            var i = 0
            while !deck.isEmpty { h[i % spieler].append(deck.removeLast()); i += 1 }
        }
        haende = h.map { $0.sorted(by: Self.ordnung) }
        stapel = deck
        let start = ErKarte(regeln.startFarbe, ErRegeln.mitte)
        if let halter = haende.firstIndex(where: { $0.contains(start) }) {
            dran = halter
            lege(start)
        } else {
            stapel.removeAll { $0 == start }
            reihen[start.farbe] = start.wert...start.wert
        }
    }

    /// Für Tests: feste Lage.
    init(regeln: ErRegeln, haende: [[ErKarte]], stapel: [ErKarte] = [], reihen: [ClosedRange<Int>?], dran: Int) {
        self.regeln = regeln; self.haende = haende; self.stapel = stapel; self.reihen = reihen; self.dran = dran
    }

    static func ordnung(_ a: ErKarte, _ b: ErKarte) -> Bool { (a.farbe, a.wert) < (b.farbe, b.wert) }

    /// RT-003: Noch kein eigener Zug gemacht (der automatisch gelegte Startzug zählt nicht): dann dürfen Variante und Neuverteilung noch wechseln.
    var vorErstemEigenenZug: Bool { verlauf.count <= 1 }

    var spielerZahl: Int { haende.count }
    var rest: [Int] { haende.map { $0.reduce(0) { $0 + $1.wert } } }

    func darfAnlegen(_ k: ErKarte) -> Bool {
        guard !rundeBeendet, regeln.werte.contains(k.wert), (0..<4).contains(k.farbe) else { return false }
        if let r = reihen[k.farbe] { return k.wert == r.lowerBound - 1 || k.wert == r.upperBound + 1 }
        return k.wert == ErRegeln.mitte
    }

    var moegliche: [ErKarte] { rundeBeendet ? [] : haende[dran].filter(darfAnlegen) }

    /// Kann der Spieler am Zug jetzt „Zug beenden“ wählen? (Mindestens eine Karte gelegt.)
    var kannBeenden: Bool { !rundeBeendet && gelegtImZug >= 1 }
    /// Passen bzw. Ziehen ist nur erlaubt, wenn keine Karte passt (und noch nichts gelegt wurde).
    var kannZiehenOderPassen: Bool { !rundeBeendet && gelegtImZug == 0 && moegliche.isEmpty }
    /// Ob „ziehen“ statt „passen“ gilt (Regel an und Stapel nicht leer).
    var zieht: Bool { regeln.ziehen && !stapel.isEmpty }

    @discardableResult
    mutating func lege(_ k: ErKarte) -> Bool {
        guard !rundeBeendet, haende[dran].contains(k), darfAnlegen(k) else { return false }
        haende[dran].removeAll { $0 == k }
        reihen[k.farbe] = reihen[k.farbe].map { min($0.lowerBound, k.wert)...max($0.upperBound, k.wert) } ?? k.wert...k.wert
        protokoll(dran, .legt(k))
        gelegtImZug += 1; passenInFolge = 0
        if haende[dran].isEmpty { rundeBeendet = true; sieger = dran; return true }
        if !regeln.mehrereKarten { naechster() }
        return true
    }

    @discardableResult
    mutating func beende() -> Bool {
        guard kannBeenden else { return false }
        protokoll(dran, .beendet); naechster(); return true
    }

    /// Keine Karte passt: ziehen (eine Karte; passt sie, bleibt der Spieler dran) oder passen.
    @discardableResult
    mutating func ziehenOderPassen() -> Bool {
        guard kannZiehenOderPassen else { return false }
        if zieht {
            haende[dran].append(stapel.removeLast()); haende[dran].sort(by: Self.ordnung)
            protokoll(dran, .zieht)
            passenInFolge = 0
            if moegliche.isEmpty { naechster() }
        } else {
            protokoll(dran, .passt)
            passenInFolge += 1
            naechster()
            if passenInFolge >= spielerZahl { festgefahren() }
        }
        return true
    }

    private mutating func naechster() { dran = (dran + 1) % haende.count; gelegtImZug = 0 }

    private mutating func protokoll(_ s: Int, _ a: ErEreignis.Art) {
        verlauf.append(ErEreignis(spieler: s, art: a)); if verlauf.count > 40 { verlauf.removeFirst(verlauf.count - 40) }
    }

    /// Alle passen nacheinander und der Stapel ist leer: Runde endet, wer am wenigsten Restwert hat, gewinnt.
    private mutating func festgefahren() {
        rundeBeendet = true
        let r = rest
        sieger = r.indices.min { (r[$0], $0) < (r[$1], $1) }
    }

    /// T-082: Eine Siegerin oder ein Sieger steht nur fest, wenn niemand sonst denselben Restwert hat (festgefahrene Runde mit Gleichstand: keine).
    var siegerEindeutig: Bool {
        guard let s = sieger else { return false }
        let r = rest
        return r.filter { $0 == r[s] }.count == 1
    }

    /// Spieler nach Restwert (geringster zuerst; Gleichstand nach Platz am Tisch), Sieger immer vorn.
    var rangfolge: [Int] {
        let r = rest
        return haende.indices.sorted { a, b in
            if a == sieger { return true }
            if b == sieger { return false }
            return (r[a], a) < (r[b], b)
        }
    }

    // MARK: Computer

    private func bewertung(_ k: ErKarte, hand: [ErKarte]) -> Double {
        let eigene = Set(hand.filter { $0.farbe == k.farbe }.map(\.wert))
        let richtung = k.wert >= ErRegeln.mitte ? 1 : -1
        var kette = 0, w = k.wert + richtung
        while eigene.contains(w) { kette += 1; w += richtung }
        let folge = k.wert + richtung
        // die nächste Karte gehört mir nicht: ich öffne dem Nächsten eine Tür
        let oeffnet = regeln.werte.contains(folge) && !eigene.contains(folge) ? 1.0 : 0.0
        let neueFarbe = reihen[k.farbe] == nil ? 0.5 : 0
        let rand = (k.wert == regeln.werte.upperBound || k.wert == regeln.werte.lowerBound) ? 1.0 : 0
        // Hohe Karten loswerden (Strafpunkte)
        return Double(kette) * 2 - oeffnet * 1.5 - neueFarbe + rand + Double(k.wert) / 40
    }

    /// Der nächste Schritt des Computers. `fehler` (0…1): Wahrscheinlichkeit für eine zufällige Wahl bzw. frühes Beenden (leichte Stufen).
    func computerSchritt<G: RandomNumberGenerator>(fehler: Double = 0, mit g: inout G) -> ErAktion {
        let moeglich = moegliche
        let hand = haende[dran]
        if moeglich.isEmpty { return gelegtImZug >= 1 ? .beende : .ziehenOderPassen }
        if gelegtImZug >= 1 {
            if fehler > 0, Double.random(in: 0..<1, using: &g) < fehler / 2 { return .beende }
            let beste = moeglich.max { bewertung($0, hand: hand) < bewertung($1, hand: hand) }!
            // Nicht jede Tür öffnen: ist die beste Karte schlecht und die Hand noch groß, Zug beenden
            if bewertung(beste, hand: hand) < -1.0, hand.count > 2 { return .beende }
            return .lege(beste)
        }
        if fehler > 0, Double.random(in: 0..<1, using: &g) < fehler, let k = moeglich.randomElement(using: &g) { return .lege(k) }
        return .lege(moeglich.max { bewertung($0, hand: hand) < bewertung($1, hand: hand) }!)
    }

    @discardableResult
    mutating func fuehreAus(_ a: ErAktion) -> Bool {
        switch a {
        case .lege(let k): lege(k)
        case .beende: beende()
        case .ziehenOderPassen: ziehenOderPassen()
        }
    }
}

// MARK: Darstellung (Namen, ohne Oberfläche testbar)

enum ErNamen {
    static func name(_ k: ErKarte, _ v: ErVariante) -> String {
        v == .echt ? "\(k.wert)" : ["7", "8", "9", "10", "B", "D", "K", "A"][max(0, min(k.wert - 7, 7))]
    }
    /// Farbname für VoiceOver.
    static func farbName(_ f: Int, _ v: ErVariante) -> String {
        let n = v == .echt ? [String(localized: "Rot"), String(localized: "Gelb"), String(localized: "Grün"), String(localized: "Blau")]
                           : [String(localized: "Kreuz"), String(localized: "Pik"), String(localized: "Herz"), String(localized: "Karo")]
        return n[f]
    }
    /// Zeichen je Farbe (zweites Merkmal neben der Farbe).
    static func zeichen(_ f: Int, _ v: ErVariante) -> String {
        v == .echt ? ["●", "■", "▲", "◆"][f] : ["♣", "♠", "♥", "♦"][f]
    }
}
