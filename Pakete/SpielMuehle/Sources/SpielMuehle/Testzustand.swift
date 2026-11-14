// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if DEBUG && canImport(UIKit)
import SpieleKern
import MuehleKern

/// Nur Debug: Testzustand für `-testZustand`. Klassische Regel, zwei Menschen. Beide Seiten spielen zufällige legale Züge aus festem Zufall
/// (Seed 1…60, der erste Lauf mit Treffer); Spieler 1 nimmt eine Mühle, wenn er sie bilden kann. Angehalten wird, wenn Spieler 1 einen Stein
/// entfernen muss und dieser eine Zug die Partie entscheidet (Gegner unter drei Steinen).
/// kurzVorEnde: genau dieser Stand (Spieler 1 tippt den Stein, der entfernt werden soll). ende: derselbe Stand, die Ansicht spielt den
/// entscheidenden Zug nach dem Laden selbst (Ende-Karte).
public enum MuehleTestzustand {
    @MainActor
    public static func ablegen(_ art: Testzustand.Art) {
        let m = Testzustand.suche { seed -> (Muehle, Bool) in
            var g = SplitMix64(seed: seed)
            var m = Muehle(regeln: .klassisch, beginner: 1)
            for _ in 0..<600 {
                if m.vorbei { break }
                let alle = m.zuege()
                guard !alle.isEmpty else { break }
                if m.mussEntfernen, m.dran == 1, alle.contains(where: { var k = m; k.spiele($0); return k.sieger == 1 }) { return (m, true) }
                var wahl = alle
                if m.dran == 1 {
                    let muehlen = alle.filter { var k = m; k.spiele($0); return k.mussEntfernen }
                    if !muehlen.isEmpty { wahl = muehlen }
                }
                m.spiele(wahl[Int.random(in: 0..<wahl.count, using: &g)])
            }
            return (m, false)
        }
        Testzustand.ablegen(MuehleStand(spiel: m, verlauf: []), kennung: "muehle", spieler: 2)
    }
}
#endif
