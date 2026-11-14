// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import Baukasten
import SpieleKern

/// Solitär : die eine Fassung des Spiels in der Sammlung. Regelkern, Store und Tischansichten werden geteilt (dasselbe Paket),
/// neu sind Hülle (`SpielRahmen`), Variantenwahl mit Tagesziel, Spielbildschirm in kleinen Teilen und eigene Spielstände (`solitaer-neu`).
///
@MainActor
public struct SolitaerModul: SpielModul {
    public init() {}
    public static let kennung = NeuText.kennung
    public let id = SolitaerModul.kennung
    public let name = "Solitär"
    public let gattung = Gattung.karten
    public let farbe = AkzentFarbeWert.gruen
    public let symbol = "suit.spade.fill"
    public let spielerzahl = 1...1
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(
            SpielRahmen(id: id, name: name, untertitel: "Sieben Kartenspiele allein", farbe: farbe, spieler: 1...1,
                        regeln: "Solitär spielst du allein. Es gibt sieben Spiele: Klondike (1 oder 3 Karten), Spider (1, 2 oder 4 Farben), FreeCell, Pyramide, TriPeaks, Golf und Yukon. Meist legst du alle Karten nach Farben von Ass bis König auf die vier Zielstapel; beim Spider bildest du Reihen von König bis Ass, bei Pyramide, TriPeaks und Golf räumst du den Tisch ab. Tippe eine Karte an, sie springt an den besten Platz, oder ziehe sie mit dem Finger. „Tipp“ zeigt einen Zug, „Zurück“ nimmt Züge zurück, bei „Zurück“ gedrückt halten spult schnell. Jeden Tag gibt es ein Tagesspiel mit Kalender; gewonnene Partien zählen für Serien, Erfolge und Wochenziele.",
                        einzelText: "Du spielst allein.", umgebung: umgebung) { teilnehmer, ende, _ in
                NeuWurzel(name: teilnehmer.first?.name ?? "", ende: ende, zurSammlung: umgebung.zurueck)
            }
            .mitStartOptionen { _ in NeuStartWahl() }   // Design-Runde 3: Spielwahl auf der Spielseite (nur Tinte, sonst leer)
            .mitZiel("Lege alle Karten nach Farben von Ass bis König auf die Zielstapel, oder räume den Tisch ab.")
            .mitAnleitung(RulesView.schritte)
        )
    }
}
