// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Bewegung einer Figur (SPEZIFIKATION Abschnitt 5).
struct Zug: Codable, Equatable, Hashable, Sendable {
    /// Relative Position vorher (-1 = aus dem Haus).
    var von: Int
    /// Relative Position nachher.
    var nach: Int
    /// Geschlagener Spieler oder nil.
    var schlaegt: Int?
}

/// Was ein ausgeführter Zug mit welcher Figur gemacht hat (für Animationen und Ansagen).
struct Bewegung: Equatable, Sendable {
    var spieler: Int
    var figur: Int
    var zug: Zug
    /// Geschlagene Figur (Spieler, Figur-Index) und ihre relative Position vor dem Schlagen.
    var geschlagen: (spieler: Int, figur: Int, rel: Int)?

    static func == (a: Bewegung, b: Bewegung) -> Bool {
        a.spieler == b.spieler && a.figur == b.figur && a.zug == b.zug
            && a.geschlagen?.spieler == b.geschlagen?.spieler && a.geschlagen?.figur == b.geschlagen?.figur
            && a.geschlagen?.rel == b.geschlagen?.rel
    }
}

extension Lage {
    private func ziel(von: Int, _ w: Int) -> Int { von == Brettmass.haus ? 0 : von + w }

    /// Alle Züge, die die Bewegungsregeln erlauben, noch ohne Pflichten. Nach `von` aufsteigend, jede Position nur einmal.
    func alleZuege(_ p: Int, _ w: Int, _ opt: Optionen = .standard) -> [Zug] {
        let eigene = figuren[p]
        var zuege: [Zug] = []
        for von in Set(eigene).sorted() {
            if von == Brettmass.haus && w != 6 { continue }
            let nach = ziel(von: von, w)
            if nach > Brettmass.zielLetztes { continue }            // über das Ziel hinaus
            if eigene.contains(nach) { continue }                   // eigene Figur steht dort
            if nach >= Brettmass.zielErstes && !opt.zielUeberspringen {
                let ab = max(von + 1, Brettmass.zielErstes)
                if ab < nach && (ab ..< nach).contains(where: { eigene.contains($0) }) { continue }
            }
            var schlaegt: Int?
            if nach < Brettmass.lauf, let b = besetzer(feld(sitze[p], nach)) {
                if !opt.rauswerfen { continue }                     // Kinder-Regel: fremd besetzte Felder sind gesperrt
                // RT-040: Im Team (2 gegen 2, nur mit vier Spielern) wird der Partner nicht geschlagen; sein Feld ist wie ein eigenes gesperrt
                if opt.teams && sitze.count == 4 && Partie.team(von: b.spieler) == Partie.team(von: p) { continue }
                schlaegt = b.spieler
            }
            zuege.append(Zug(von: von, nach: nach, schlaegt: schlaegt))
        }
        return zuege
    }

    /// Erlaubte Züge nach allen Pflichten (Raus → Startfeld räumen → Schlagpflicht).
    func moeglicheZuege(_ p: Int, _ w: Int, _ opt: Optionen = .standard) -> [Zug] {
        let zuege = alleZuege(p, w, opt)
        let eigene = figuren[p]
        let imHaus = eigene.contains(Brettmass.haus)
        if opt.rausPflicht && w == 6 {
            let raus = zuege.filter { $0.von == Brettmass.haus }
            if !raus.isEmpty { return raus }
        }
        if opt.startfeldRaeumen && imHaus && eigene.contains(0) {
            let weg = zuege.filter { $0.von == 0 }
            if !weg.isEmpty { return weg }
        }
        if opt.schlagpflicht {
            let schlag = zuege.filter { $0.schlaegt != nil }
            if !schlag.isEmpty { return schlag }
        }
        return zuege
    }

    /// Kann der Spieler mit keiner Augenzahl von 1 bis 5 ziehen? Dann gelten die drei Versuche.
    func blockiert(_ p: Int, _ opt: Optionen = .standard) -> Bool {
        (1 ... 5).allSatisfy { alleZuege(p, $0, opt).isEmpty }
    }

    /// Führt den Zug aus. Aus dem Haus kommt die Figur mit dem kleinsten Index.
    @discardableResult
    mutating func fuehreAus(_ p: Int, _ z: Zug) -> Bewegung {
        let k = figuren[p].firstIndex(of: z.von)!
        var geschlagen: (spieler: Int, figur: Int, rel: Int)?
        if z.schlaegt != nil, let b = besetzer(feld(sitze[p], z.nach)) {
            geschlagen = (b.spieler, b.figur, figuren[b.spieler][b.figur])
            figuren[b.spieler][b.figur] = Brettmass.haus
        }
        figuren[p][k] = z.nach
        return Bewegung(spieler: p, figur: k, zug: z, geschlagen: geschlagen)
    }
}
