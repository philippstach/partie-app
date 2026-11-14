// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Stufe geübt (SPEZIFIKATION 7.6), zwischen mittel und stark: Suche über 6 Halbzüge, aber in etwa jedem
/// vierten Zug spielt sie bewusst den zweitbesten Zug – nie, wenn das einen sicheren Gewinn verschenkt.
/// Die Werte sind exakt (Referenz `geuebt_werte` in `Referenz/viergewinnt.py`), deshalb ohne Tabelle und ohne Abkürzungen.
enum GeuebterComputer {
    static let tiefe = 6
    /// `naechste(4) == 0` → zweitbester Zug.
    static let fehlerNenner = 4

    /// Legale Spalten ohne Geschenk an den Gegner (sonst alle), in der Reihenfolge 3, 2, 4, 1, 5, 0, 6.
    static func kandidaten(_ p: Partie) -> [Int] {
        let (ich, maske) = Bitbrett.von(p)
        let legal = p.legaleSpalten
        let gegnerGewinn = Bitbrett.gewinnfelder(ich ^ maske, maske)
        let sicher = legal.filter { c in
            let zug = (maske &+ Bitbrett.untersterBit(c)) & Bitbrett.spalte(c)
            return (zug << 1) & gegnerGewinn == 0
        }
        let wahl = sicher.isEmpty ? legal : sicher
        return Bitbrett.mitteZuerst.filter { wahl.contains($0) }
    }

    /// Exakter Suchwert je Kandidat aus Sicht des Spielers am Zug, einschließlich seines Zugs.
    static func werte(_ p: Partie, tiefe: Int = GeuebterComputer.tiefe) -> [Int: Int] {
        let (ich, maske) = Bitbrett.von(p)
        let n = p.zuege.count
        var werte: [Int: Int] = [:]
        for c in kandidaten(p) {
            let zug = (maske &+ Bitbrett.untersterBit(c)) & Bitbrett.spalte(c)
            werte[c] = -suche(ich ^ maske, maske | zug, n + 1, tiefe - 1, -Computer.unendlich, Computer.unendlich)
        }
        return werte
    }

    static func waehle<Q: Zufallsquelle>(_ p: Partie, zufall: inout Q) -> Int {
        let ich = p.naechsterSpieler
        if p.zuege.isEmpty { return 3 }
        if let s = p.sofortgewinne(fuer: ich).first { return s }
        if let s = p.sofortgewinne(fuer: 3 - ich).first { return s }
        let w = werte(p)
        let rang = Bitbrett.mitteZuerst
        let reihenfolge = w.keys.sorted { a, b in
            w[a]! != w[b]! ? w[a]! > w[b]! : rang.firstIndex(of: a)! < rang.firstIndex(of: b)!
        }
        let bester = reihenfolge[0]
        guard reihenfolge.count >= 2 else { return bester }
        let zweiter = reihenfolge[1]
        let bewiesen = Computer.gewinn - Partie.felder
        // Kein Fehler, wenn der beste Zug sicher gewinnt oder der zweitbeste sicher verliert
        if w[bester]! >= bewiesen || w[zweiter]! <= -bewiesen { return bester }
        return zufall.naechste(fehlerNenner) == 0 ? zweiter : bester
    }

    /// Negamax mit Alpha-Beta wie in der Referenz (`Stark._suche` ohne Zeitlimit): Blätter mit `bewertung`,
    /// Endstellungen `±(10000 − Steine)`.
    private static func suche(_ ich: UInt64, _ maske: UInt64, _ zuege: Int, _ tiefe: Int, _ alphaEin: Int, _ beta: Int) -> Int {
        var alpha = alphaEin
        let moeglich = (maske &+ Bitbrett.unten) & Bitbrett.brettMaske
        if Bitbrett.gewinnfelder(ich, maske) & moeglich != 0 { return Computer.gewinn - (zuege + 1) }
        if zuege == Partie.felder { return 0 }
        if tiefe == 0 { return Bitbrett.bewertung(ich: ich, maske: maske) }
        var best = -Computer.unendlich
        for c in Bitbrett.mitteZuerst {
            let zug = moeglich & Bitbrett.spalte(c)
            if zug == 0 { continue }
            let w = -suche(ich ^ maske, maske | zug, zuege + 1, tiefe - 1, -beta, -alpha)
            if w > best { best = w }
            if w > alpha { alpha = w }
            if alpha >= beta { break }
        }
        return best
    }
}
