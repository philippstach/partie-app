// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

// Schocken : die eine Fassung des Spiels in der Sammlung. Kern (Regeln, Computer, Spielzustand) geteilt, eigene Spielstände,
// Start/Spielerwahl/Ende über den SpielRahmen.
@MainActor
public struct SchockenModul: SpielModul {
    public init() {}
    public let id = "schocken-neu"
    public let name = "Schocken"
    public let gattung = Gattung.wuerfel
    public let farbe = AkzentFarbeWert.braun
    public let symbol = "square.stack.3d.up.fill"
    public let spielerzahl = 2...6
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(
            SpielRahmen(id: id, name: name, untertitel: "Würfeln, Deckel verteilen, nicht verlieren", farbe: farbe, spieler: spielerzahl, computerErlaubt: true,
                        wuerfelWahl: true,
                        regeln: "Jeder würfelt reihum mit drei Würfeln, höchstens dreimal. Nach jedem Wurf darfst du Würfel herauslegen und mit den übrigen weiterwürfeln; Einsen legst du heraus (mit der Hausregel „Beliebig“ jeden Würfel), zwei oder drei Sechsen darfst du zu Einsen umdrehen. Wer vorlegt, bestimmt, wie oft die anderen würfeln dürfen. Die Rangfolge: Zahl, Straße, General, bei Hausregel Jule (4-2-1), Schock (zwei Einsen plus eine Zahl), Schock aus (drei Einsen). Der schlechteste Wurf der Runde bekommt Deckel, so viele, wie der beste Wurf wert ist, erst aus dem Stock, danach vom Gewinner. Wer alle Deckel hat, verliert die Hälfte. Nach zwei Hälften spielen die beiden Verlierer das Finale, außer jemand hat beide verloren. Vor dem ersten Wurf kannst du die Hausregeln der Partie ändern.",
                        umgebung: umgebung) { teilnehmer, ende, abbrechen in
                SchockenNeuSpiel(teilnehmer: teilnehmer, umgebung: umgebung, ende: ende, abbrechen: abbrechen)
            }
            .mitZiel("Du willst nicht verlieren. Wer in einer Runde am schlechtesten würfelt, bekommt Deckel. Wer in einer Hälfte alle Deckel hat, verliert diese Hälfte. Wer zwei Hälften oder das Finale verliert, verliert die Partie.")   // Fund 43: ohne Spielwissen verständlich
            .mitRegelnAnsicht { SchockenRegelnAnsicht() }   // T-091 + Absturz-Fix: „Alle Regeln lesen“ zeigt die ausführliche Regelseite
            .mitZielSchrittNeu(.ziel("Bei Schocken willst du nicht verlieren. Ihr würfelt reihum mit drei Würfeln. Wer in einer Runde am schlechtesten würfelt, bekommt Deckel. Wer am Ende einer Hälfte alle Deckel hat, verliert sie. Wer beide Hälften oder das Finale verliert, verliert die Partie. Ihr spielt zu zweit bis zu sechst, gern auch gegen den Computer."))
            .mitAnleitung(RegelTexteNeu.anleitung(neu: RulesView.schritteNeu, alt: Array(RulesView.schritte.dropFirst())))   // Wischanleitung auch unter „Regeln ansehen“ der Spielseite (erster Schritt = Ziel, kommt aus mitZiel)
        )
    }
}
