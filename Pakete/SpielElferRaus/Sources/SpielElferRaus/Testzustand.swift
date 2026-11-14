// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if DEBUG && canImport(UIKit)
import SpieleKern

/// Nur Debug: Testzustand für `-testZustand`. Zwei Menschen, „Elfer raus“; `computerSchritt` spielt beide Plätze mit festem Zufall.
/// kurzVorEnde: Der Spieler am Zug hat nur noch eine Karte, und sie passt. ende: Runde beendet, Sieger steht fest.
public enum ElferRausTestzustand {
    @MainActor
    public static func ablegen(_ art: Testzustand.Art) {
        let s = Testzustand.suche { seed -> (ErSpiel, Bool) in
            var g = SplitMix64(seed: seed)
            var s = ErSpiel(spieler: 2, regeln: .echt, mit: &g)
            Testzustand.spiele(&s, fertig: { m in
                m.rundeBeendet || (art == .kurzVorEnde && m.gelegtImZug == 0 && m.haende[m.dran].count == 1 && !m.moegliche.isEmpty)
            }, schritt: { m in
                let a = m.computerSchritt(mit: &g)
                m.fuehreAus(a)
            })
            return (s, art == .ende ? s.rundeBeendet : !s.rundeBeendet)
        }
        Testzustand.ablegen(s, kennung: ElferRausModul.kennung, spieler: 2)
    }
}
#endif
