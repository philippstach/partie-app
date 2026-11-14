// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import SpieleKern
import Spiel10k

// 10k : die eine Fassung des Spiels in der Sammlung. Kern (Regeln, Store) geteilt, eigene Spielstände,
// Start/Spielerwahl/Ende über den SpielRahmen.
@MainActor
public struct ZehnKModul: SpielModul {
    public init() {}
    public let id = "10k-neu"
    public let name = "Zehntausend"
    public let gattung = Gattung.wuerfel
    public let farbe = AkzentFarbeWert.orange
    public let symbol = "die.face.5.fill"
    public let spielerzahl = 1...8
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        Quelle10k.lesen = { SpielerQuelle.bekannt.map { ($0.name, $0.avatar, $0.farbeHex) } }
        Quelle10k.melden = { SpielerQuelle.menschen($0) }
        return AnyView(
            SpielRahmen(id: id, name: name, untertitel: "Würfeln, bis es zehntausend sind", farbe: farbe, spieler: spielerzahl, computerErlaubt: true,
                        wuerfelWahl: true,
                        regeln: "Du würfelst mit fünf Würfeln. Nach jedem Wurf legst du mindestens einen Würfel mit Punkten raus: eine 1 zählt 100, eine 5 zählt 50, drei gleiche zählen Augenzahl mal 100 (drei Einsen 1.000), eine Straße 1.000. Dann hörst du auf und schreibst die Punkte an – oder du würfelst mit den übrigen Würfeln weiter. Bringt ein Wurf nichts, ist es eine Niete und alle Punkte dieses Zugs sind weg. Drei Nieten in Folge kosten Strafpunkte. Wer zuerst das Ziel erreicht, gewinnt. Die Regeln der Partie (Einstiegshürde, Mehrfache, drei Paare, sechs Würfel und mehr) stellst du auf der Spielseite vor dem Start ein.",
                        umgebung: umgebung) { teilnehmer, ende, abbrechen in
                ZehnKNeuSpiel(teilnehmer: teilnehmer, umgebung: umgebung, ende: ende, abbrechen: abbrechen)
            }
            .mitStartOptionen { _ in ZehnKStartOptionen() }   // Umbau E: Regeln der Partie und Bestenliste vor dem Start
            .mitZiel("Erreiche als Erster 10.000 Punkte. Du würfelst, schreibst Punkte an und entscheidest, ob du weiterwürfelst.")   // Fund 75
            .mitZielSchrittNeu(.ziel("Sei als Erster bei 10.000 Punkten. Du würfelst, legst Würfel mit Punkten raus und entscheidest: aufhören oder weiter? Wer zu gierig ist, verliert mit einem schlechten Wurf alles aus diesem Zug. Ihr spielt allein oder mit bis zu acht Leuten, auch mit dem Computer."))
            .mitAnleitung(RegelTexteNeu.anleitung(neu: [
                .figuren(symbol: "dice", titel: "Würfeln und rauslegen", text: "Wirf alle Würfel und lege mindestens einen mit Punkten raus. Eine 1 zählt 100, eine 5 zählt 50. Die anderen Zahlen bringen einzeln nichts. Gezählt wird nur, was in einem Wurf fällt.", figuren: ["⚀", "⚄"], bewegt: 0),
                .figuren(symbol: "square.stack.3d.up", titel: "Drilling und Straße", text: "Drei gleiche zählen Augenzahl mal 100, drei Vieren also 400. Drei Einsen bringen 1.000. Eine Straße, 1 bis 5 oder 2 bis 6, bringt auch 1.000, aber nur, wenn alle Würfel auf einmal fallen.", figuren: ["⚂", "⚂", "⚂"], bewegt: 0),
                .figuren(symbol: "flag.checkered", titel: "Aufhören oder weiter", text: "Tippe „Aufhören“, um die Punkte zu sichern, oder würfle mit den übrigen Würfeln weiter. Bringt ein Wurf keinen Punkt, ist es eine Niete: Alle Punkte dieses Zugs sind weg. Hast du alle Würfel rausgelegt, darfst du mit allen neu würfeln. Drei Nieten hintereinander kosten Strafpunkte, im Standard 500.", figuren: ["🏁"], bewegt: 0),
                .figuren(symbol: "arrow.right.arrow.left", titel: "Übernehmen", text: "Hört jemand auf und lässt Würfel liegen, darfst du sie samt seinen Punkten übernehmen und weiterwürfeln. Das lohnt sich bei vielen Punkten und mehreren freien Würfeln. Wirfst du dabei eine Niete, ist alles weg.", figuren: ["⚀", "⚄", "→", "🎲", "🎲", "🎲"], bewegt: nil),
                .figuren(symbol: "slider.horizontal.3", titel: "Eure Regeln", text: "Vor dem Start stellst du auf der Spielseite unter „Regeln der Partie“ ein, wie ihr spielt: ein kürzeres Ziel, sechs Würfel, nur Einsen und Fünfen als Drilling, eine Einstiegshürde und mehr. Die App merkt sich eure Regeln. Im Spiel kannst du sie unter „Mehr“ nur nachlesen. Alles Weitere steht unter „Alle Regeln lesen“.", figuren: ["⚙️", "5.000", "🎲"], bewegt: nil),
            ], alt: [
                .figuren(symbol: "dice", titel: "Würfeln und rauslegen", text: "Wirf alle Würfel und lege mindestens einen mit Punkten raus: Eine 1 zählt 100, eine 5 zählt 50.", figuren: ["⚀","⚄"], bewegt: 0),
                .figuren(symbol: "square.stack.3d.up", titel: "Drilling und Straße", text: "Drei gleiche zählen Augenzahl mal 100, drei Einsen 1.000. Eine Straße bringt 1.000.", figuren: ["⚂","⚂","⚂"], bewegt: 0),
                .figuren(symbol: "flag.checkered", titel: "Aufhören oder weiter", text: "Schreibe die Punkte an oder würfle weiter. Eine Niete löscht den Zug. Wer zuerst das Ziel erreicht, gewinnt.", figuren: ["🏁"], bewegt: 0),
            ]))
            .mitRegelWissen { ZehnKRegelAuskunft.wissen() }   // KI-3: „Frag nach den Regeln“ mit den Rechen-Werkzeugen von 10k
            .mitRegelnAnsicht { ZehnKRegelnAnsicht() })
    }
}
