// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if DEBUG && canImport(UIKit)
import SpieleKern

/// Nur Debug: Testzustand für `-testZustand`. Drei Menschen, Leben-Modus; die Computerwahl (`computerWahl`, schwer) spielt alle Plätze.
/// kurzVorEnde: Runde beginnt, zwei Spieler übrig, einer „schwimmt“ (0 Leben). ende: Partie vorbei; die Ansicht meldet das Ende nach dem Laden selbst (Ende-Karte).
public enum SchwimmenTestzustand {
    @MainActor
    public static func ablegen(_ art: Testzustand.Art) {
        let s = Testzustand.suche { seed -> (SchwimmenNeu, Bool) in
            var g = SplitMix64(seed: seed)
            var s = SchwimmenNeu(spieler: 3, regeln: .standard, mit: &g)
            Testzustand.spiele(&s, fertig: { m in
                m.spielZuEnde || (art == .kurzVorEnde && !m.rundeVorbei && m.aktive.count == 2 && m.aktive.contains { m.leben[$0] == 0 })
            }, schritt: { m in
                if m.rundeVorbei { m.neueRunde(mit: &g); return }
                switch m.computerWahl(stufe: 3, mit: &g) {
                case .eine(let h, let t): m.tauscheEine(hand: h, tisch: t)
                case .alle: m.tauscheAlle()
                case .schieben: m.schieben()
                case .klopfen: m.klopfen()
                }
            })
            return (s, art == .ende ? s.spielZuEnde : (!s.spielZuEnde && !s.rundeVorbei))
        }
        Testzustand.ablegen(s, kennung: SchwimmenModul.kennung, spieler: 3)
    }
}
#endif
