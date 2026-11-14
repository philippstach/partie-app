// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if DEBUG && canImport(UIKit)
import SpieleKern
import ChicagoKern

/// Nur Debug: Testzustand für `-testZustand`. Zwei Menschen; die Würfe kommen aus festem Zufall, `weiter()` wie im Spiel.
/// kurzVorEnde: letzte Runde (Ziel 12), der zweite Spieler ist dran, noch nicht geworfen. ende: Partie beendet (die Ansicht meldet das Ende nach dem Laden selbst).
public enum ChicagoTestzustand {
    @MainActor
    public static func ablegen(_ art: Testzustand.Art) {
        var g = SplitMix64(seed: 3)
        var s = Chicago(spieler: 2)
        Testzustand.spiele(&s, fertig: { m in
            m.beendet || (art == .kurzVorEnde && m.runde == 10 && m.dran == 1 && m.versuche == 0 && m.treffer == nil)
        }, schritt: { m in
            if m.darfWerfen { m.wuerfeln(mit: &g) } else { m.weiter() }
        })
        Testzustand.ablegen(s, kennung: "chicago", spieler: 2)
    }
}
#endif
