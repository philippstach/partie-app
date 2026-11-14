// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if DEBUG && canImport(UIKit)
import SpieleKern
import SiebzehnKern

/// Nur Debug: Testzustand für `-testZustand`. Zwei Menschen mit je 20 Chips und Einsatz 10; die Grundstrategie des Computers
/// (`computerNimmtKarte`, `computerVerdoppelt`) spielt beide Plätze mit festem Zufall.
/// kurzVorEnde: neue Hand, ein Spieler hat nur noch genau den Einsatz (verliert er, ist Schluss). ende: Hand vorbei, einer hat zu wenig Chips (die Ansicht meldet das Ende nach dem Laden selbst).
public enum SiebzehnTestzustand {
    @MainActor
    public static func ablegen(_ art: Testzustand.Art) {
        let s = Testzustand.suche { seed -> (Siebzehn, Bool) in
            var g = SplitMix64(seed: seed)
            var s = Siebzehn(spieler: 2, chips: 20, einsatz: 10, mit: &g)
            Testzustand.spiele(&s, grenze: 2000, fertig: { m in
                (m.vorbei && m.aktive.count < 2)
                    || (art == .kurzVorEnde && !m.vorbei && !m.bankDran && m.dran == 0 && m.spieler[0].count == 2 && m.chips.contains(m.einsatzJeHand))
            }, schritt: { m in
                if m.vorbei { m.austeilen(mit: &g); return }
                let bank = m.bank.first?.augen ?? 10
                if m.kannVerdoppeln, Siebzehn.computerVerdoppelt(hand: m.spieler[m.dran], bankOffen: bank) { m.verdoppeln(); return }
                if Siebzehn.computerNimmtKarte(hand: m.spieler[m.dran], bankOffen: bank) { m.karte() } else { m.halten() }
            })
            return (s, art == .ende ? (s.vorbei && s.aktive.count < 2) : !s.vorbei)
        }
        Testzustand.ablegen(s, kennung: "siebzehnundvier", spieler: 2)
    }
}
#endif
