// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if DEBUG
import SpieleKern

/// Nur Debug: Testzustand für `-testZustand`. Zwei Computer (gut) spielen mit festem Würfelzufall (Seed 1…60, der erste Lauf mit Treffer);
/// angehalten wird vor dem Wurf, sobald ein Spieler drei seiner vier Figuren im Ziel hat.
/// kurzVorEnde: beide Plätze sind Menschen („Spieler 1/2“). ende: beide Plätze bleiben Computer, die App spielt die letzten Züge nach dem Laden
/// selbst bis zum Sieg (Sieger-Moment, Ende-Karte).
public enum RauswurfTestzustand {
    @MainActor
    public static func ablegen(_ art: Testzustand.Art) {
        var z = Testzustand.suche { seed -> (Spielzustand, Bool) in
            let sp = (0..<2).map { Spieler(name: "Spieler \($0 + 1)", avatar: "\($0 + 1)", strategie: .gut, sitz: $0 * 2) }
            var lauf = Spielzustand(spieler: sp, optionen: .standard, seed: seed)
            Testzustand.spiele(&lauf, grenze: 20_000, fertig: { s in
                s.partie.vorbei || (s.partie.spielzug.stand == .vorWurf && s.partie.lage.figuren.contains { $0.filter { $0 >= Brettmass.zielErstes }.count >= 3 })
            }, schritt: { $0.computerSchritt() })
            return (lauf, !lauf.partie.vorbei)
        }
        if art == .kurzVorEnde { for i in z.spieler.indices { z.spieler[i].strategie = .mensch } }
        Testzustand.ablegen(Spielstand(zustand: z, dauerSekunden: 120), kennung: NeuLogik.id, spieler: 2)
    }
}
#endif
