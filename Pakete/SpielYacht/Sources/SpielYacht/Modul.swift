// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern
import SpielHilfen

// Yacht : die eine Fassung des Spiels in der Sammlung. Regeln, Computer und Spielstand geteilt, eigene Spielstände,
// Start/Spielerwahl/Ende über den SpielRahmen, drei Wertungen wählbar.
@MainActor
public struct YachtModul: SpielModul {
    public init() {}
    public let id = "yacht-neu"
    public let name = "Yacht"
    public let gattung = Gattung.wuerfel
    public let farbe = AkzentFarbeWert.indigo
    public let symbol = "dice.fill"
    public let spielerzahl = 1...4
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(
            SpielRahmen(id: id, name: name, untertitel: "Fünf Würfel, drei Würfe, drei Wertungen", farbe: farbe, spieler: spielerzahl, computerErlaubt: true,
                        wuerfelWahl: true,
                        regeln: "Du würfelst bis zu dreimal mit fünf Würfeln und hältst dazwischen die Würfel, die du behalten willst. Danach trägst du das Ergebnis in ein freies Feld des Blocks ein: Einser bis Sechser zählen die Augen, dazu kommen Pasch, Full House, Straßen und Yacht (fünf gleiche). Passt nichts, streichst du ein Feld. Wer nach allen Runden die meisten Punkte hat, gewinnt. Vor dem ersten Wurf wählst du die Wertung: Klassisch, Yatzy oder die Original-Yacht.",
                        umgebung: umgebung) { teilnehmer, ende, abbrechen in
                YachtNeuSpiel(teilnehmer: teilnehmer, umgebung: umgebung, ende: ende, abbrechen: abbrechen)
            }
            .mitZiel("Hole die meisten Punkte. Allein: schlage deinen Rekord.")
            .mitRegelnAnsicht { RulesDetailView() }   // T-091: „Alle Regeln lesen“ zeigt die ausführliche Regelseite mit Wertungstabelle
            .mitZielSchrittNeu(.ziel("Hole die meisten Punkte. Du würfelst mit fünf Würfeln und füllst Feld für Feld deine Wertungstabelle. Jedes Feld nur einmal. Wer am Ende die meisten Punkte hat, gewinnt. Allein spielst du gegen deinen Rekord. Das Spiel ist auch als Kniffel bekannt."))
            .mitAnleitung(RegelTexteNeu.anleitung(neu: RulesView.schritteNeu, alt: Array(RulesView.schritte.dropFirst())))   // Wischanleitung auch unter „Regeln ansehen“ der Spielseite (erster Schritt = Ziel, kommt aus mitZiel)
            .mitStartInhalt { aktionen in TagesKarte(spiel: "yacht", spielName: name, titel: "Tageswürfel heute", aktionen: aktionen) }   // 1.0 (P5): Tageswürfel mit Serie
        )
    }
}
