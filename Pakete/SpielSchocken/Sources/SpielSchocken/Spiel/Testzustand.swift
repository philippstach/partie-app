// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if DEBUG
import KlarGlas
import SpieleKern
import Foundation

/// Nur Debug: Testzustand für `-testZustand`. Zwei Computer (gut) spielen eine ganze Partie mit festem Würfelzufall zu Ende (Seed 4); danach
/// sind beide Plätze Menschen („Spieler 1/2“). ende: Partie vorbei (Endkarte beim Öffnen). kurzVorEnde: Beginn der vorletzten Runde der letzten
/// Hälfte (Phase „Vor dem Wurf“), derselbe Lauf, nur früher angehalten.
public enum SchockenTestzustand {
    private static func spiele(seed: UInt64, stopp: (Spielzustand) -> Bool) -> (z: Spielzustand, q: SeedQuelle) {
        var q = SeedQuelle(seed: seed)
        let namen = ["Spieler 1", "Spieler 2"]
        // Tinte: wie NeuAblage.starten für Spieler ohne Profil der Anfangsbuchstabe statt Standard-Emoji (T-046, Blatt 6); Klar und Salon wie vorher
        let avatare: [String]? = Design.ist(.tinte) ? namen.map { Spieler.abzeichen(name: $0, zeichen: nil) } : nil
        var z = Spielzustand(namen: namen, strategien: [.gut, .gut], avatare: avatare, optionen: .standard, beginner: 0)
        var n = 0
        while z.phase != .partieVorbei, !stopp(z), n < 20_000 {
            n += 1
            switch z.phase {
            case .computer:
                if let lage = z.lage {
                    if !z.fuehreAus(Computer.entscheide(.gut, lage), &q) { _ = z.fuehreAus(.stehen, &q) }
                } else { z.wuerfeln(&q) }
            case .zugEnde: z.zugWeiter()
            case .rundenwertung: z.rundeWeiter()
            case .haelfteVorbei: z.haelfteWeiter()
            default: return (z, q)
            }
        }
        return (z, q)
    }

    @MainActor
    public static func ablegen(_ art: Testzustand.Art) {
        let ganz = spiele(seed: 4) { _ in false }
        var (z, q) = ganz
        if art == .kurzVorEnde {
            let letzte = ganz.z.haelfte.art, n = ganz.z.haelfte.runden
            (z, q) = spiele(seed: 4) { s in
                s.haelfte.art == letzte && s.phase == .computer && s.runde.position == 0 && s.runde.zug == nil && s.haelfte.runden >= max(0, n - 2)
            }
        }
        z.strategien = [.mensch, .mensch]
        if z.phase == .computer { z.phase = .vorWurf }
        try? GameRepository(url: NeuAblage.ordner.appending(path: "spielstand.json")).speichern(Spielstand(zustand: z, quelle: q))
        SpielStand.sichern(NeuAblage.Marker(offen: true), spiel: NeuAblage.id)
        Testzustand.melden(kennung: NeuAblage.id, spieler: 2)
    }
}
#endif
