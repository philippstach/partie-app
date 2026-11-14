// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Bitbrett: Spalte `c` belegt die Bits `c*7 … c*7+5`, Bit `c*7+6` ist Wächter (wie in der Referenz).
enum Bitbrett {
    static let h1 = Partie.zeilen + 1
    static let unten: UInt64 = (0..<Partie.spalten).reduce(0) { $0 | (1 << UInt64($1 * h1)) }
    static let brettMaske: UInt64 = unten * ((1 << UInt64(Partie.zeilen)) - 1)
    static let mitteZuerst = [3, 2, 4, 1, 5, 0, 6]

    static func spalte(_ c: Int) -> UInt64 { ((1 << UInt64(Partie.zeilen)) - 1) << UInt64(c * h1) }
    static func untersterBit(_ c: Int) -> UInt64 { 1 << UInt64(c * h1) }

    /// Leere Felder, die für `pos` eine Vierer-Reihe vollenden würden.
    @inline(__always)
    static func gewinnfelder(_ pos: UInt64, _ maske: UInt64) -> UInt64 {
        // senkrecht (nur nach oben), dann waagerecht (Abstand 7), diagonal \ (Abstand 6) und diagonal / (Abstand 8)
        var r = (pos << 1) & (pos << 2) & (pos << 3)
        r |= richtung(pos, 7) | richtung(pos, 6) | richtung(pos, 8)
        return r & (brettMaske ^ maske)
    }

    @inline(__always)
    private static func richtung(_ pos: UInt64, _ d: UInt64) -> UInt64 {
        var r: UInt64 = 0
        var p = (pos << d) & (pos << (2 * d))
        r |= p & (pos << (3 * d))
        r |= p & (pos >> d)
        p = (pos >> d) & (pos >> (2 * d))
        r |= p & (pos << d)
        r |= p & (pos >> (3 * d))
        return r
    }

    /// `ich` = Steine des Spielers am Zug, `maske` = alle Steine.
    static func von(_ partie: Partie) -> (ich: UInt64, maske: UInt64) {
        var ich: UInt64 = 0, maske: UInt64 = 0
        let amZug = partie.naechsterSpieler
        for s in 0..<Partie.spalten {
            for z in 0..<partie.hoehen[s] {
                let bit: UInt64 = 1 << UInt64(s * h1 + z)
                maske |= bit
                if partie.brett[s][z] == amZug { ich |= bit }
            }
        }
        return (ich, maske)
    }

    /// Die 69 Fenster als Bitmasken.
    static let fenster: [UInt64] = Bewertung.fenster.map { zellen in
        zellen.reduce(0) { $0 | (1 << UInt64($1.spalte * h1 + $1.zeile)) }
    }

    /// Dieselbe Heuristik wie `Bewertung.wert`, auf dem Bitbrett.
    static func bewertung(ich: UInt64, maske: UInt64) -> Int {
        let gegner = ich ^ maske
        var w = 0
        for f in fenster {
            let e = (ich & f).nonzeroBitCount, g = (gegner & f).nonzeroBitCount
            if e > 0 && g > 0 { continue }
            if e == 3 { w += 5 } else if e == 2 { w += 2 }
            if g == 3 { w -= 5 } else if g == 2 { w -= 2 }
        }
        let mitte = spalte(3)
        return w + 3 * ((ich & mitte).nonzeroBitCount - (gegner & mitte).nonzeroBitCount)
    }
}

/// Stufe stark (SPEZIFIKATION 7.4): iterative Vertiefung mit Alpha-Beta und Transpositionstabelle auf dem Bitbrett.
/// Deterministisch, wenn nur `maxTiefe` begrenzt ist (Tests); in der App begrenzt das Zeitlimit.
/// Bricht ab, wenn der umgebende `Task` abgebrochen wird. Dann ist das Ergebnis nicht zu gebrauchen.
final class StarkerComputer {
    let zeitlimit: Double?
    let maxTiefe: Int

    init(zeitlimit: Double? = Computer.starkZeitlimit, maxTiefe: Int = Partie.felder) {
        self.zeitlimit = zeitlimit
        self.maxTiefe = maxTiefe
    }

    /// Zuletzt erreichte vollständige Tiefe (zur Information und für Tests).
    private(set) var erreichteTiefe = 0
    private(set) var knoten = 0

    private struct Abbruch: Error {}

    private enum Grenze: UInt8 { case leer, exakt, untere, obere }

    private struct Eintrag {
        var schluessel: UInt64 = 0
        var wert: Int32 = 0
        var tiefe: Int8 = 0
        var grenze: Grenze = .leer
        var zug: Int8 = -1
    }

    private static let tabellenBits = 20
    private var tabelle: [Eintrag] = []
    private var frist: UInt64?
    private var zaehler = 0

    func waehle(_ p: Partie) -> Int {
        let ich = p.naechsterSpieler
        if p.zuege.isEmpty { return 3 }
        if let s = p.sofortgewinne(fuer: ich).first { return s }
        if let s = p.sofortgewinne(fuer: 3 - ich).first { return s }

        let (bIch, maske) = Bitbrett.von(p)
        let n = p.zuege.count
        let legal = p.legaleSpalten
        // Züge, die dem Gegner direkt darüber einen Gewinn schenken, nur wenn nichts anderes geht
        let gegnerGewinn = Bitbrett.gewinnfelder(bIch ^ maske, maske)
        let sicher = legal.filter { c in
            let zug = (maske &+ Bitbrett.untersterBit(c)) & Bitbrett.spalte(c)
            return (zug << 1) & gegnerGewinn == 0
        }
        var kandidaten = Bitbrett.mitteZuerst.filter { (sicher.isEmpty ? legal : sicher).contains($0) }
        if kandidaten.count == 1 { return kandidaten[0] }

        tabelle = Array(repeating: Eintrag(), count: 1 << Self.tabellenBits)
        zaehler = 0
        knoten = 0
        erreichteTiefe = 0
        frist = zeitlimit.map { DispatchTime.now().uptimeNanoseconds + UInt64($0 * 1_000_000_000) }

        var bester = kandidaten[0]
        let hoechste = min(maxTiefe, Partie.felder - n)
        guard hoechste >= 1 else { return bester }
        for tiefe in 1...hoechste {
            var werte: [Int: Int] = [:]
            var alpha = -Computer.unendlich
            do {
                for c in kandidaten {
                    let zug = (maske &+ Bitbrett.untersterBit(c)) & Bitbrett.spalte(c)
                    let w = try -suche(bIch ^ maske, maske | zug, n + 1, tiefe - 1, -Computer.unendlich, -alpha)
                    werte[c] = w
                    alpha = max(alpha, w)
                }
            } catch {
                break
            }
            let best = werte.values.max()!
            bester = kandidaten.first { werte[$0] == best }!
            erreichteTiefe = tiefe
            kandidaten.sort { a, b in
                werte[a]! != werte[b]! ? werte[a]! > werte[b]! : Bitbrett.mitteZuerst.firstIndex(of: a)! < Bitbrett.mitteZuerst.firstIndex(of: b)!
            }
            if abs(best) >= Computer.gewinn - Partie.felder { break } // Ergebnis bewiesen
        }
        return bester
    }

    /// Negamax mit Alpha-Beta (fail-soft). `ich` = Steine des Spielers am Zug, `zuege` = Steine auf dem Brett.
    private func suche(_ ich: UInt64, _ maske: UInt64, _ zuege: Int, _ tiefe: Int,
                       _ alphaEin: Int, _ betaEin: Int) throws -> Int {
        zaehler &+= 1
        knoten &+= 1
        if zaehler & 1023 == 0 {
            if Task.isCancelled { throw Abbruch() }
            if let frist, DispatchTime.now().uptimeNanoseconds > frist { throw Abbruch() }
        }
        var alpha = alphaEin, beta = betaEin
        var moeglich = (maske &+ Bitbrett.unten) & Bitbrett.brettMaske
        if Bitbrett.gewinnfelder(ich, maske) & moeglich != 0 { return Computer.gewinn - (zuege + 1) }
        if zuege == Partie.felder { return 0 }
        // Der Gegner gewinnt mit dem nächsten Stein: blocken oder verlieren
        let gegnerGewinn = Bitbrett.gewinnfelder(ich ^ maske, maske)
        let erzwungen = moeglich & gegnerGewinn
        let verloren = -(Computer.gewinn - (zuege + 2))
        if erzwungen != 0 {
            if erzwungen & (erzwungen &- 1) != 0 { return verloren }
            moeglich = erzwungen
        }
        moeglich &= ~(gegnerGewinn >> 1) // nicht unter ein Gewinnfeld des Gegners ziehen
        if moeglich == 0 { return verloren }
        if tiefe == 0 { return Bitbrett.bewertung(ich: ich, maske: maske) }

        let schluessel = ich &+ maske
        let platz = Int(truncatingIfNeeded: (schluessel &* 0x9E37_79B9_7F4A_7C15) >> UInt64(64 - Self.tabellenBits))
        var hashZug = -1
        let e = tabelle[platz]
        if e.grenze != .leer && e.schluessel == schluessel {
            hashZug = Int(e.zug)
            if Int(e.tiefe) >= tiefe {
                let w = Int(e.wert)
                switch e.grenze {
                case .exakt: return w
                case .untere: alpha = max(alpha, w)
                case .obere: beta = min(beta, w)
                case .leer: break
                }
                if alpha >= beta { return w }
            }
        }

        var reihenfolge = Bitbrett.mitteZuerst
        if hashZug >= 0, let i = reihenfolge.firstIndex(of: hashZug) {
            reihenfolge.remove(at: i)
            reihenfolge.insert(hashZug, at: 0)
        }
        var best = -Computer.unendlich
        var besterZug = -1
        let alpha0 = alphaEin
        for c in reihenfolge {
            let zug = moeglich & Bitbrett.spalte(c)
            if zug == 0 { continue }
            let w = try -suche(ich ^ maske, maske | zug, zuege + 1, tiefe - 1, -beta, -alpha)
            if w > best { best = w; besterZug = c }
            if w > alpha { alpha = w }
            if alpha >= beta { break }
        }
        let grenze: Grenze = best <= alpha0 ? .obere : (best >= beta ? .untere : .exakt)
        let alt = tabelle[platz]
        if alt.grenze == .leer || alt.schluessel == schluessel || Int(alt.tiefe) <= tiefe {
            tabelle[platz] = Eintrag(schluessel: schluessel, wert: Int32(best), tiefe: Int8(tiefe),
                                     grenze: grenze, zug: Int8(besterZug))
        }
        return best
    }
}
