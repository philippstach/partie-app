// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if DEBUG && canImport(UIKit)
import SpieleKern
import MinensucheKern

/// Nur Debug: Testzustand für `-testZustand`. Stufe „Leicht“, Brett aus festem Zufall (Seed 12), erster Zug in der Mitte; danach werden alle
/// sicheren Felder bis auf eines mit normalen Aufdeck-Zügen geöffnet (das eine bleibt verdeckt, es löst keine Flut aus).
/// kurzVorEnde: Stand mit genau einem sicheren Feld offen (bis dahin 95 s). ende: derselbe Stand, die Ansicht deckt das letzte Feld nach dem Laden
/// selbst auf (Sieg, Ende-Karte). Ein Minentreffer lässt sich im Stand kurzVorEnde zum Prüfen der Niederlage von Hand auslösen.
public enum MinensucheTestzustand {
    @MainActor
    public static func ablegen(_ art: Testzustand.Art) {
        var basis = Spiel(stufe: .leicht, seed: 12)
        let m = basis.mass
        basis.aufdecken(Position(zeile: m.zeilen / 2, spalte: m.spalten / 2))
        func ausser(_ ziel: Int) -> Spiel {
            var s = basis
            for i in 0..<m.felder where i != ziel && !s.istMine(m.position(i)) && s.feld(m.position(i)) != .aufgedeckt && !s.istZuende {
                s.aufdecken(m.position(i))
            }
            return s
        }
        var gewaehlt = basis
        for c in (0..<m.felder).reversed() where !basis.istMine(m.position(c)) {
            let s = ausser(c)
            if s.status == .laeuft { gewaehlt = s; break }
        }
        gewaehlt.dauer = 95
        Testzustand.ablegen(SpielModell.Gespeichert(spiel: gewaehlt, stufe: .leicht, art: .stufe), kennung: SpielModell.standKennung, spieler: 1)
    }
}
#endif
