// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if DEBUG && canImport(UIKit)
import SpieleKern
import PokerwurfKern

/// Nur Debug: Testzustand für `-testZustand`. Zwei Menschen; `computerHalten` bestimmt, welche Würfel gehalten werden (fester Zufall).
/// kurzVorEnde: fünfte und letzte Runde, der zweite Spieler ist dran, noch nicht gewürfelt. ende: fünfte Runde gewertet (die Ansicht meldet das Ende nach dem Laden selbst).
public enum PokerwurfTestzustand {
    @MainActor
    public static func ablegen(_ art: Testzustand.Art) {
        var g = SplitMix64(seed: 9)
        var s = Pokerwurf(spieler: 2)
        let letzte = Pokerwurf.runden - 1
        // Würfelzählung wie in der Ansicht (`wirf`): nur neu geworfene Würfel, damit „So fielen die Würfel“ am Endstand erscheint
        var bilanz = WuerfelBilanz(namen: ["Spieler 1", "Spieler 2"])
        func wurf(_ m: inout Pokerwurf, _ g: inout SplitMix64) {
            let vorher = m
            m.wuerfeln(mit: &g)
            guard m.wuerfe != vorher.wuerfe else { return }
            let frei = (0..<5).filter { vorher.wuerfe == 0 || !vorher.becher.gehalten[$0] }
            bilanz.zaehle(spieler: vorher.amZug, frei.map { m.becher.augen[$0] })
        }
        Testzustand.spiele(&s, fertig: { m in
            (m.runde == letzte && m.rundeGewertet) || (art == .kurzVorEnde && m.runde == letzte && m.amZug == 1 && m.wuerfe == 0 && !m.rundeGewertet)
        }, schritt: { m in
            if m.rundeGewertet { m.naechsteRunde(); return }
            wurf(&m, &g)
            while m.wuerfe < 3 {
                let halten = Pokerwurf.computerHalten(m.becher.augen)
                for i in 0..<5 where halten[i] != m.becher.gehalten[i] { m.halte(i) }
                if !m.kannWuerfeln { break }
                wurf(&m, &g)
            }
            m.fertig()
        })
        bilanz.sichern(spiel: "pokerwurf")
        Testzustand.ablegen(s, kennung: "pokerwurf", spieler: 2)
    }
}
#endif
