// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if DEBUG && canImport(UIKit)
import SpieleKern
import MauMauKern

/// Nur Debug: Testzustand für `-testZustand` (siehe `Testzustand`). Zwei Menschen, Standardregeln, fester Zufall; die Computerwahl
/// (`NComputer.beste`) spielt beide Seiten bis kurz vor das Ende oder bis zum Sieg. Die Ansicht meldet das Ende nach dem Laden selbst (Ende-Karte).
public enum MauMauTestzustand {
    @MainActor
    public static func ablegen(_ art: Testzustand.Art) {
        var g = SplitMix64(seed: 7)
        var s = NMauMau(spieler: 2, regeln: .standard, mit: &g)
        Testzustand.spiele(&s, fertig: { m in
            m.sieger != nil || (art == .kurzVorEnde && m.haende[m.dran].count == 1 && !m.spielbareIndizes.isEmpty)
        }, schritt: { m in
            if let z = NComputer.beste(m) { m.spiele(z.index, wunsch: z.wunsch, mau: true) } else { m.ziehen(mit: &g) }
        })
        Testzustand.ablegen(MauMauNeuStand(spiel: s, runden: nil), kennung: MauMauModul.kennung, spieler: 2)
    }
}
#endif
