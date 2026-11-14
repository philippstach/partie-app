// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if DEBUG && canImport(UIKit)
import SpieleKern
import KakuroKern

/// Nur Debug: Testzustand für `-testZustand`. Rätsel 5×5 aus festem Zufall (Zahl der Felder wie beim Start „klein“).
/// kurzVorEnde: alles ausgefüllt bis auf ein Feld (die gelöste Ziffer fehlt). ende: ganz gelöst; die Ansicht meldet das Ende nach dem Laden selbst.
public enum KakuroTestzustand {
    @MainActor
    public static func ablegen(_ art: Testzustand.Art) {
        var g = SplitMix64(seed: 5)
        var k = Kakuro.zufaellig(n: 5, mit: &g)
        k.loesen()
        if art == .kurzVorEnde, let f = k.weiss.indices.first(where: { k.weiss[$0] && !k.vorgaben.contains($0) }) { k.setze(f, 0) }
        Testzustand.ablegen(KakuroStand(spiel: k, sekunden: 95, tipps: 0, tag: false), kennung: "kakuro", spieler: 1)
    }
}
#endif
