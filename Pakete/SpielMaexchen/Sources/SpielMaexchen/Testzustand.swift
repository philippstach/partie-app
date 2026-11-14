// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if DEBUG && canImport(UIKit)
import SpieleKern
import MaexchenKern

/// Nur Debug: Testzustand für `-testZustand`. Zwei Menschen mit je drei Leben; `MaexchenComputer` (ansagen, zweifeln) spielt beide Plätze.
/// kurzVorEnde: Neue Runde, ein Spieler hat nur noch ein Leben. ende: ein Spieler übrig (Ende-Karte erscheint wie nach dem letzten Aufdecken).
public enum MaexchenTestzustand {
    @MainActor
    public static func ablegen(_ art: Testzustand.Art) {
        let s = Testzustand.suche { seed -> (Maexchen, Bool) in
            var g = SplitMix64(seed: seed)
            var m = Maexchen(spieler: 2, leben: 3)
            Testzustand.spiele(&m, grenze: 5000, fertig: { m in
                m.sieger != nil || (art == .kurzVorEnde && m.phase == .wuerfeln && m.ansage == nil && m.leben.contains(1))
            }, schritt: { m in
                switch m.phase {
                case .wuerfeln: m.wuerfeln(mit: &g)
                case .ansagen: m.ansagen(MaexchenComputer.ansage(m, stufe: 3, mit: &g))
                case .entscheiden:
                    if MaexchenComputer.zweifelt(m, stufe: 3, mit: &g) { m.zweifeln() } else { m.glauben() }
                }
            })
            return (m, art == .ende ? m.sieger != nil : m.sieger == nil)
        }
        Testzustand.ablegen(s, kennung: "maexchen", spieler: 2)
    }
}
#endif
