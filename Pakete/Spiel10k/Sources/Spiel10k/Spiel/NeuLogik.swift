// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import SpieleKern
import KlarGlas

/// Was ein Zug einer Person zuletzt gebracht hat (Spielerleiste, „Frühere Runden“).
nonisolated enum NeuZelle: Equatable, Sendable {
    case leer
    case punkte(Int)
    case niete
    case strafe(Int)
}

/// Reine Hilfsfunktionen für „10k“ – ohne Oberfläche, damit sie sich testen lassen.
nonisolated enum NeuLogik {
    /// Ergebnis des letzten Zugs dieser Person; `leer`, solange sie noch nicht dran war.
    static func zuwachs(_ g: GameState, player: Int) -> NeuZelle {
        guard let r = g.log.last(where: { $0.player == player }) else { return .leer }
        return zelle(r)
    }

    static func zelle(_ r: TurnRecord) -> NeuZelle {
        if r.penalty > 0 { return .strafe(r.penalty) }
        return r.points > 0 ? .punkte(r.points) : .niete
    }

    /// Die letzten `anzahl` Runden vor dem letzten Zug (der steht schon in der Spielerleiste): je Runde eine Zelle pro Person.
    /// Gibt `(Rundennummer, Zellen)` zurück, älteste zuerst. Im Stechen leer (dort zeigt die Stechen-Karte den Stand).
    static func fruehereRunden(_ g: GameState, anzahl: Int) -> [(runde: Int, zellen: [NeuZelle])] {
        guard anzahl > 0, g.tiebreak == nil, !g.players.isEmpty else { return [] }
        let n = g.players.count
        let log = Array(g.log.dropLast())
        guard !log.isEmpty else { return [] }
        var runden: [(Int, [NeuZelle])] = []
        var start = 0
        while start < log.count {
            var zellen = Array(repeating: NeuZelle.leer, count: n)
            for r in log[start..<min(start + n, log.count)] { zellen[r.player] = zelle(r) }
            runden.append((start / n + 1, zellen))
            start += n
        }
        return runden.suffix(anzahl).map { (runde: $0.0, zellen: $0.1) }
    }

    /// Höhenklassen des Spielbildschirms, gemessen als Fensterhöhe ohne Statusleiste:
    /// SE 375×667 ≈ 647, 390×844 ≈ 797, Pro Max 430×932 ≈ 873.
    static let hoeheMittel: CGFloat = 700
    static let hoeheGross: CGFloat = 840

    /// Wie viele frühere Runden passen bei dieser Fensterhöhe (SE 0, 390×844 zwei, Pro Max drei).
    static func fruehereRundenAnzahl(hoehe: CGFloat, grosseSchrift: Bool) -> Int {
        if grosseSchrift || hoehe < hoeheMittel { return 0 }
        return hoehe < hoeheGross ? 2 : 3
    }

    /// Größte Würfelkante für die Fensterhöhe (SE 56, 390×844 bis 90, Pro Max bis 112).
    static func wuerfelHoechstens(hoehe: CGFloat, grosseSchrift: Bool = false) -> CGFloat {
        if grosseSchrift || hoehe < hoeheMittel { return 56 }
        return hoehe < hoeheGross ? 90 : 112
    }

    /// Kantenlänge und Spaltenzahl für `n` Würfel in einem Feld: eine oder zwei Reihen, je nachdem was größer wird
    /// (bei gleicher Größe lieber eine Reihe).
    static func wuerfelRaster(n: Int, breite: CGFloat, hoehe: CGFloat, abstand: CGFloat, hoechstens: CGFloat) -> (kante: CGFloat, spalten: Int) {
        guard n > 0, breite > 0, hoehe > 0 else { return (hoechstens, max(n, 1)) }
        var best: (kante: CGFloat, spalten: Int)?
        for reihen in 1...2 {
            let spalten = Int((Double(n) / Double(reihen)).rounded(.up))
            let kb = (breite - CGFloat(spalten - 1) * abstand) / CGFloat(spalten)
            let kh = (hoehe - CGFloat(reihen - 1) * abstand) / CGFloat(reihen)
            let k = max(min(hoechstens, kb, kh), 1)
            if best == nil || k > best!.kante + 0.5 { best = (k, spalten) }
        }
        return best!
    }

    /// Ende für den SpielRahmen: Sieger zuerst, dann nach Punkten; gleiche Plätze bei gleichem Stand.
    static func ende(_ g: GameState) -> SpielEnde {
        let n = g.players.count
        let order = g.players.indices.sorted { a, b in
            let wa = g.winners.contains(a), wb = g.winners.contains(b)
            if wa != wb { return wa }
            if g.players[a].score != g.players[b].score { return g.players[a].score > g.players[b].score }
            return a < b
        }
        func platz(_ i: Int) -> Int {
            if g.winners.contains(i) { return 1 }
            return 1 + g.players.indices.filter { j in
                g.winners.contains(j) || g.players[j].score > g.players[i].score
            }.count
        }
        let best = g.players.map(\.bestTurn).max() ?? 0
        let runden = g.log.count / max(n, 1)
        // Blatt 22 (EB-2, Schritt 1): Runden und bester Zug sind jetzt Wertzeilen; der Satz nennt nur noch das Ziel (allein: kein Satz, der Rahmen zeigt die Punkte)
        // Fund 9: „Ziel erreicht“ nur, wenn es jemand erreicht hat; sonst endete die Partie am Rundenlimit
        let zielErreicht = g.players.contains { $0.score >= g.settings.goal }
        let info: String? = n > 1 ? (zielErreicht ? String(localized: "Ziel \(Theme.points(g.settings.goal)) erreicht.") : String(localized: "Rundenlimit erreicht.")) : nil
        var e = SpielEnde(reihenfolge: order.map { g.players[$0].name },
                          punkte: order.map { Theme.points(g.players[$0].score) },
                          plaetze: n > 1 ? order.map(platz) : nil,
                          info: info,
                          einzel: n > 1 ? .gewonnen : .punkte)   // C-035: allein ist 10k ein Punktespiel ohne Sieg
        e.werte = [EndeWert("Runden", "\(runden)"), EndeWert("Bester Zug", Theme.points(best))]
        // Blatt 22 (EB2, Schritt 2): Würfelbild aus der Zählung; ein alter Stand oder eine Partie nur mit Punkteingabe hat keine, dann kein Bild
        if let a = g.augen, a.count == n, a.allSatisfy({ $0.count == 6 }) {
            var b = WuerfelBilanz(namen: g.players.map(\.name))
            b.augen = a
            if let t = g.augenGetippt, t.count == n { b.eingetippt = t }
            if !b.leer { e.wuerfel = b }
        }
        return e
    }
}
