// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if DEBUG && canImport(UIKit)
import SpieleKern
import HerzensjagdKern

/// Nur Debug: Testzustand für `-testZustand`. Vier Menschen, Ziel 50, ohne Weitergeben; `computerWahl` spielt alle Plätze mit festem Zufall.
/// kurzVorEnde: Start des letzten Stichs der Runde, in der das Ziel erreicht wird. ende: Partie vorbei (die Ansicht meldet das Ende nach dem Laden selbst).
public enum HerzensjagdTestzustand {
    @MainActor
    public static func ablegen(_ art: Testzustand.Art) {
        // Lauf 1 bis zum Ende, damit klar ist, in welcher Runde die Partie endet; Lauf 2 (gleicher Seed) hält davor an.
        func lauf(_ seed: UInt64, bisRunde: Int?) -> Herzensjagd {
            var g = SplitMix64(seed: seed)
            var s = Herzensjagd(ziel: 50, weitergeben: false, mit: &g)
            Testzustand.spiele(&s, grenze: 5000, fertig: { m in
                if let r = bisRunde { return m.runde == r && m.stichNummer == 12 && m.stich.isEmpty && !m.rundeFertig }
                return m.vorbei
            }, schritt: { m in
                if m.stichVoll { m.stichAbschliessen(mit: &g) }
                else if m.rundeFertig { m.naechsteRunde(mit: &g) }
                else { m.spiele(m.computerWahl(m.amZug)) }
            })
            return s
        }
        let seed: UInt64 = 5
        let ende = lauf(seed, bisRunde: nil)
        let s = art == .ende ? ende : lauf(seed, bisRunde: ende.runde)
        Testzustand.ablegen(s, kennung: "herzensjagd", spieler: 4)
    }
}
#endif
