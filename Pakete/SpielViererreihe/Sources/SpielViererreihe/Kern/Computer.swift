// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

enum Stufe: String, Codable, CaseIterable, Sendable {
    case leicht, mittel, geuebt, stark
}

/// Der Computer-Gegner (SPEZIFIKATION Abschnitt 7). Reine Logik: bekommt eine Stellung, gibt eine Spalte zurück.
/// Zufall kommt nur aus der hineingereichten Quelle. Darf auf einem Hintergrund-Task laufen.
enum Computer {
    static let mittelTiefe = 4
    /// Wert einer gewonnenen Endstellung: `gewinn - Anzahl Steine`.
    static let gewinn = 10_000
    static let unendlich = 1_000_000
    /// Zeitlimit der Stufe stark in der App.
    static let starkZeitlimit = 1.0

    /// Wählt die Spalte für den Spieler am Zug. `zeitlimit` und `maxTiefe` betreffen nur die Stufe stark.
    static func waehle<Q: Zufallsquelle>(_ stufe: Stufe, _ partie: Partie, zufall: inout Q,
                                         zeitlimit: Double? = starkZeitlimit, maxTiefe: Int = Partie.felder) -> Int {
        switch stufe {
        case .leicht: leicht(partie, zufall: &zufall)
        case .mittel: mittel(partie, zufall: &zufall)
        case .geuebt: GeuebterComputer.waehle(partie, zufall: &zufall)
        case .stark: StarkerComputer(zeitlimit: zeitlimit, maxTiefe: maxTiefe).waehle(partie)
        }
    }

    /// Zufall wird nur gezogen, wenn es mehr als eine Möglichkeit gibt.
    static func zufaellig<Q: Zufallsquelle>(_ liste: [Int], _ zufall: inout Q) -> Int {
        liste.count == 1 ? liste[0] : liste[zufall.naechste(liste.count)]
    }

    // MARK: Leicht

    static func leicht<Q: Zufallsquelle>(_ p: Partie, zufall: inout Q) -> Int {
        let ich = p.naechsterSpieler
        if let s = p.sofortgewinne(fuer: ich).first { return s }
        if let s = p.sofortgewinne(fuer: 3 - ich).first { return s }
        return zufaellig(p.legaleSpalten, &zufall)
    }

    // MARK: Mittel

    /// Exakter Minimax-Wert (ohne Abschneiden) aus Sicht des Spielers am Zug.
    static func negamax(_ p: Partie, tiefe: Int) -> Int {
        if p.status == .gewonnen { return -(gewinn - p.zuege.count) }
        if p.status == .unentschieden { return 0 }
        if tiefe == 0 { return Bewertung.wert(p, fuer: p.naechsterSpieler) }
        var best = -unendlich
        for s in p.legaleSpalten {
            var k = p
            try! k.einwerfen(s)
            best = max(best, -negamax(k, tiefe: tiefe - 1))
        }
        return best
    }

    /// Wert jeder Spalte (`nil` = nicht spielbar): Minimax über 4 Halbzüge einschließlich des eigenen Zugs.
    static func mittelWerte(_ p: Partie) -> [Int?] {
        var werte = [Int?](repeating: nil, count: Partie.spalten)
        for s in p.legaleSpalten {
            var k = p
            try! k.einwerfen(s)
            werte[s] = -negamax(k, tiefe: mittelTiefe - 1)
        }
        return werte
    }

    static func mittel<Q: Zufallsquelle>(_ p: Partie, zufall: inout Q) -> Int {
        let werte = mittelWerte(p)
        let best = werte.compactMap { $0 }.max()!
        let beste = (0..<Partie.spalten).filter { werte[$0] == best }
        return zufaellig(beste, &zufall)
    }
}
