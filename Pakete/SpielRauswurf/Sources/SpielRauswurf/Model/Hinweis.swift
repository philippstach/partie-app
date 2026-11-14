// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Welche Pflicht die erlaubten Züge gerade einschränkt (für die Hinweiszeile).
enum Pflicht: Equatable, Sendable {
    case raus, startfeld, schlagen
}

extension Spielzustand {
    /// Die Pflicht, die gerade gilt, oder nil. Nur sinnvoll in der Phase `wahl`.
    var pflicht: Pflicht? {
        let sp = partie.spielzug
        guard let w = sp.augen, !sp.erlaubt.isEmpty else { return nil }
        let p = amZug
        let alle = lage.alleZuege(p, w, optionen)
        let erlaubt = sp.erlaubt
        let eigene = lage.figuren[p]
        if optionen.rausPflicht && w == 6 && erlaubt.allSatisfy({ $0.von == Brettmass.haus }) { return .raus }
        if optionen.startfeldRaeumen && eigene.contains(Brettmass.haus) && eigene.contains(0)
            && erlaubt.allSatisfy({ $0.von == 0 }) && alle.count > erlaubt.count { return .startfeld }
        if optionen.schlagpflicht && erlaubt.allSatisfy({ $0.schlaegt != nil }) && alle.count > erlaubt.count { return .schlagen }
        return nil
    }

    /// Verbleibende Versuche für eine 6, wenn die drei Versuche gelten (Spieler blockiert), sonst nil.
    var versucheUebrig: Int? {
        guard optionen.dreiVersuche, lage.blockiert(amZug, optionen), partie.spielzug.stand == .vorWurf || partie.spielzug.stand == .verfallen else { return nil }
        return max(0, 3 - partie.spielzug.fehlversuche)
    }

    /// Welche Figuren haben einen erlaubten Zug? Aus dem Haus leuchtet nur die Figur mit dem kleinsten Index.
    var bewegliche: Set<FigurID> {
        guard partie.spielzug.stand == .wahl else { return [] }
        let p = amZug
        var ergebnis = Set<FigurID>()
        for z in partie.spielzug.erlaubt {
            if let k = lage.figuren[p].firstIndex(of: z.von) { ergebnis.insert(FigurID(spieler: p, figur: k)) }
        }
        return ergebnis
    }

    /// Der erlaubte Zug für eine angetippte Figur (Hausfiguren: der Zug aus dem Haus).
    func zug(fuer id: FigurID) -> Zug? {
        guard id.spieler == amZug, partie.spielzug.stand == .wahl else { return nil }
        let rel = lage.figuren[id.spieler][id.figur]
        return partie.spielzug.erlaubt.first { $0.von == rel }
    }
}
