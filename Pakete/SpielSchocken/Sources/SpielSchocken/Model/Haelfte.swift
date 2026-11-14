// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Ergebnis einer gewerteten Runde (ohne den Zustand zu ändern).
struct Rundenausgang: Codable, Hashable {
    var verlierer: Int
    var gewinner: Int
    /// tatsächlich bewegte Deckel (bei Schock aus: alle, die der Verlierer bekommt)
    var deckel: Int
    var ausStock: Bool
    var schockAus: Bool
}

/// Bestimmt Verlierer, Gewinner und Deckelzahl. `ergebnisse` in Spielreihenfolge der Runde.
func werteRunde(_ ergebnisse: [(spieler: Int, ergebnis: Ergebnis)], haelfte h: Haelfte) -> Rundenausgang {
    var verlierer = ergebnisse[0], gewinner = ergebnisse[0]
    for e in ergebnisse.dropFirst() {
        if istBesser(verlierer.ergebnis, e.ergebnis) { verlierer = e }
        if istBesser(e.ergebnis, gewinner.ergebnis) { gewinner = e }
    }
    let bester = gewinner.ergebnis.wertung
    if bester.art == .schockAus && h.schockAusEndet {
        return Rundenausgang(verlierer: verlierer.spieler, gewinner: gewinner.spieler,
                             deckel: h.gesamt - h.deckelVon(verlierer.spieler), ausStock: h.stock > 0, schockAus: true)
    }
    // Schock aus ohne „beendet die Hälfte“ zählt wie ein Wurf mit allen Deckeln der Hälfte
    let wert = bester.art == .schockAus ? h.gesamt : bester.deckel
    if h.stock > 0 {
        return Rundenausgang(verlierer: verlierer.spieler, gewinner: gewinner.spieler,
                             deckel: min(wert, h.stock), ausStock: true, schockAus: false)
    }
    return Rundenausgang(verlierer: verlierer.spieler, gewinner: gewinner.spieler,
                         deckel: min(wert, h.deckelVon(gewinner.spieler)), ausStock: false, schockAus: false)
}

/// Eine Hälfte (oder das Finale): spielt, bis einer alle Deckel hat.
struct Haelfte: Codable, Equatable {
    enum Art: String, Codable { case haelfte1, haelfte2, finale }

    var art: Art
    /// Spielerindizes, die mitspielen (Sitzreihenfolge)
    var spieler: [Int]
    var beginner: Int
    /// Deckel pro Hälfte (aus den Optionen)
    var gesamt: Int
    var stock: Int
    /// Deckel je Spieler, parallel zu `spieler`
    var deckel: [Int]
    /// ausgeschiedene Spielerindizes, aufsteigend
    var raus: [Int] = []
    var verlierer: Int?
    /// gewertete Runden dieser Hälfte
    var runden = 0
    /// Hausregel „Schock aus beendet die Hälfte“ (Standard an)
    var schockAusEndet = true

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        art = try c.decode(Art.self, forKey: .art)
        spieler = try c.decode([Int].self, forKey: .spieler)
        beginner = try c.decode(Int.self, forKey: .beginner)
        gesamt = try c.decodeIfPresent(Int.self, forKey: .gesamt) ?? 13
        stock = try c.decode(Int.self, forKey: .stock)
        deckel = try c.decode([Int].self, forKey: .deckel)
        raus = try c.decodeIfPresent([Int].self, forKey: .raus) ?? []
        verlierer = try c.decodeIfPresent(Int.self, forKey: .verlierer)
        runden = try c.decodeIfPresent(Int.self, forKey: .runden) ?? 0
        schockAusEndet = try c.decodeIfPresent(Bool.self, forKey: .schockAusEndet) ?? true
    }

    init(art: Art, spieler: [Int], beginner: Int, optionen: Optionen) {
        self.art = art
        self.spieler = spieler
        self.beginner = beginner
        gesamt = optionen.deckel
        schockAusEndet = optionen.schockAusEndet
        stock = optionen.deckel
        deckel = Array(repeating: 0, count: spieler.count)
    }

    func deckelVon(_ s: Int) -> Int { deckel[spieler.firstIndex(of: s)!] }

    /// Stand in Reihenfolge von `spieler`.
    var stand: [Int] { deckel }

    var aktive: [Int] { spieler.filter { !raus.contains($0) } }

    /// Aktive Spieler ab `beginner`, dann in Sitzreihenfolge.
    func reihenfolge(ab beginner: Int) -> [Int] {
        let akt = aktive
        let i = akt.firstIndex(of: beginner)!
        return Array(akt[i...] + akt[..<i])
    }

    mutating func wendeAn(_ a: Rundenausgang) {
        runden += 1
        let v = spieler.firstIndex(of: a.verlierer)!
        let g = spieler.firstIndex(of: a.gewinner)!
        if a.schockAus {
            deckel = Array(repeating: 0, count: spieler.count)
            stock = 0
            deckel[v] = gesamt
        } else if a.ausStock {
            stock -= a.deckel
            deckel[v] += a.deckel
        } else {
            deckel[g] -= a.deckel
            deckel[v] += a.deckel
        }
        if stock == 0 {
            for (i, s) in spieler.enumerated() where deckel[i] == 0 && !raus.contains(s) { raus.append(s) }
            raus.sort()
        }
        if deckel[v] == gesamt { verlierer = a.verlierer }
    }
}

/// Was kommt nach den bisher gespielten Hälften?
struct PartieAblauf: Equatable {
    enum Naechste: String { case haelfte2, finale }
    var naechste: Naechste?
    var verlierer: Int?
    var finaleSpieler: [Int]
}

func partieAblauf(haelftenVerlierer v: [Int], optionen: Optionen) -> PartieAblauf {
    if optionen.spiellaenge == .haelfte { return PartieAblauf(naechste: nil, verlierer: v[0], finaleSpieler: []) }
    switch v.count {
    case 1: return PartieAblauf(naechste: .haelfte2, verlierer: nil, finaleSpieler: [])
    case 2:
        if v[0] == v[1] { return PartieAblauf(naechste: nil, verlierer: v[0], finaleSpieler: []) }
        return PartieAblauf(naechste: .finale, verlierer: nil, finaleSpieler: v.sorted())
    default: return PartieAblauf(naechste: nil, verlierer: v[2], finaleSpieler: [])
    }
}
