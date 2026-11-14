// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if DEBUG && canImport(UIKit)
import SpieleKern
import MogelnKern

/// Nur Debug: Testzustand für `-testZustand`. Zwei Menschen; `MogelnComputer` (legt, zweifelt) spielt beide Plätze mit festem Zufall.
/// kurzVorEnde: Der Spieler am Zug legt gleich seine letzte Karte. ende: Partie gewonnen (die Ansicht meldet das Ende nach dem Laden selbst).
public enum MogelnTestzustand {
    @MainActor
    public static func ablegen(_ art: Testzustand.Art) {
        let s = Testzustand.suche { seed -> (Mogeln, Bool) in
            var g = SplitMix64(seed: seed)
            var m = Mogeln(spieler: 2, mit: &g)
            Testzustand.spiele(&m, grenze: 5000, fertig: { m in
                m.gewinner != nil || (art == .kurzVorEnde && m.phase == .legen && m.haende[m.dran].count == 1)
            }, schritt: { m in
                switch m.phase {
                case .legen: m.lege(MogelnComputer.lege(m))
                case .entscheiden:
                    if MogelnComputer.zweifelt(m, spieler: m.dran, stufe: 3, mit: &g) { m.anzweifeln() } else { m.glauben() }
                }
            })
            return (m, art == .ende ? m.gewinner != nil : m.gewinner == nil)
        }
        Testzustand.ablegen(s, kennung: "mogeln", spieler: 2)
    }
}
#endif
