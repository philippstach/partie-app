// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if DEBUG && canImport(UIKit)
import SpieleKern
import RommeKern

/// Nur Debug: Testzustand für `-testZustand`. Zwei Menschen, eine Runde; `RommeComputer.zug` (schwer) spielt beide Plätze mit festem Zufall.
/// kurzVorEnde: Der Spieler am Zug hat nach seiner ersten Auslage nur noch höchstens zwei Karten. ende: Runde gewonnen (die Ansicht meldet das Ende nach dem Laden selbst).
public enum RommeTestzustand {
    @MainActor
    public static func ablegen(_ art: Testzustand.Art) {
        let s = Testzustand.suche { seed -> (Romme, Bool) in
            var g = SplitMix64(seed: seed)
            var r = Romme(spieler: 2, runden: 1, mit: &g)
            Testzustand.spiele(&r, grenze: 400, fertig: { m in
                m.gewinner != nil || (art == .kurzVorEnde && !m.gezogen && m.hatAusgelegt[m.dran] && m.haende[m.dran].count <= 2)
            }, schritt: { m in RommeComputer.zug(&m, stufe: 3, mit: &g) })
            return (r, art == .ende ? r.gewinner != nil : r.gewinner == nil)
        }
        Testzustand.ablegen(s, kennung: "romme", spieler: 2)
    }
}
#endif
