// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if DEBUG && canImport(UIKit)
import SpieleKern
import KoenigswegKern

/// Nur Debug: Testzustand für `-testZustand`. Zwei Menschen; `computerZug` (mittel) spielt beide Plätze, die Münzwürfe kommen aus festem Zufall.
/// kurzVorEnde: Ein Spieler hat sechs Steine draußen und ist vor dem Wurf. ende: Sieger steht fest; das Spiel meldet das Ende nach dem Laden selbst.
public enum KoenigswegTestzustand {
    @MainActor
    public static func ablegen(_ art: Testzustand.Art) {
        // Münzwürfe mitzählen wie die Ansicht (`wirf`), damit „So fielen die Münzen“ am Endstand erscheint
        let s = Testzustand.suche { seed -> (stand: (Koenigsweg, WuerfelBilanz), treffer: Bool) in
            var g = SplitMix64(seed: seed)
            var k = Koenigsweg()
            var bilanz = WuerfelBilanz(namen: ["Spieler 1", "Spieler 2"], seiten: 5, kleinste: 0)
            Testzustand.spiele(&k, grenze: 5000, fertig: { m in
                m.sieger != nil || (art == .kurzVorEnde && m.wurf == nil && m.draussen(m.amZug) == Koenigsweg.steine - 1)
            }, schritt: { m in
                if m.wurf == nil {
                    let spieler = m.amZug
                    if m.wuerfeln(mit: &g), let w = m.letzterWurf { bilanz.zaehle(spieler: spieler, [w]) }
                }
                else if let z = m.computerZug(stufe: 2, mit: &g) { m.ziehe(z) }
            })
            return ((k, bilanz), art == .ende ? k.sieger != nil : k.sieger == nil)
        }
        Testzustand.ablegen(s.0, kennung: "koenigsweg", spieler: 2)
        s.1.sichern(spiel: "koenigsweg")
    }
}
#endif
