// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import XCTest
import SwiftUI
import KlarGlas
import SpieleKern
@testable import DesignBilder

/// Seiten der Stufen A bis C, die im Baukasten und im Kern liegen: Gewinnerseite (Sieg, Niederlage, Punkte-Ende),
/// Zwischenstand, Spiel-Startseite, Gerät weitergeben, Blatt „Neues Spiel“, Design-Auswahl.
@MainActor
class SeitenBilder: XCTestCase {
    override func setUp() async throws {
        await MainActor.run {
            // Wie in der App: ein Würfelspiel ist offen (Spielart-Farben), Clara steht mit Farbe im Verzeichnis.
            KlarGlasHaken.spielart = { .wuerfel }
            KlarGlasHaken.spielName = { "Yacht" }
            KlarGlasHaken.flaeche = { Gattung.wuerfel.farbe.color }
            KlarGlasHaken.accentText = { Gattung.wuerfel.farbe.textFarbe }
            KlarGlasHaken.spielerBild = { name in name == "Clara" ? (bild: nil, farbe: Spieler.farbe(2), zeichen: nil) : nil }
            SpielRahmenHaken.bild = { _ in .init(farbe: Gattung.wuerfel.farbe.color, miniatur: .wuerfel, spielart: "Würfel") }
        }
    }

    override func tearDown() async throws { await MainActor.run { Design.art = .klar } }

    func testSieger() {
        let leer = Aufnahme.alle("sieger") {
            SiegerBildschirm(symbol: "trophy.fill", titel: "Clara", untertitel: "247 Punkte · 13 Runden",
                             rangliste: [.init(name: "Clara", punkte: "247"), .init(name: "Anna", punkte: "231"), .init(name: "Ben", punkte: "198")],
                             info: "Serie Clara · Anna 5 : 4", teilen: {}, sekundaerTitel: "Zum Start", primaerTitel: "Revanche",
                             schliessen: {}, sekundaer: {}, primaer: {})
        }
        XCTAssertEqual(leer, [])
    }

    func testNiederlage() {
        let leer = Aufnahme.alle("verloren") {
            SiegerBildschirm(symbol: "flag.checkered", titel: "Verloren", untertitel: "Der Computer war diesmal schneller.",
                             teilen: {}, sekundaerTitel: "Zum Start", primaerTitel: "Noch einmal", schliessen: {}, sekundaer: {}, primaer: {})
        }
        XCTAssertEqual(leer, [])
    }

    func testPunkteEnde() {
        let leer = Aufnahme.alle("rekord") {
            SiegerBildschirm(symbol: "trophy.fill", titel: "Neuer Rekord!", untertitel: "1240 Punkte", info: "Rekord bisher: 980",
                             teilen: {}, sekundaerTitel: "Zum Start", primaerTitel: "Noch einmal", schliessen: {}, sekundaer: {}, primaer: {})
        }
        XCTAssertEqual(leer, [])
    }

    func testZwischenstand() {
        let leer = Aufnahme.alle("zwischenstand") {
            ZwischenstandBildschirm(symbol: "person.fill", titel: "Ben ist dran", untertitel: "Runde 7 von 13",
                                    rangliste: [.init(name: "Clara", punkte: "131"), .init(name: "Anna", punkte: "124"), .init(name: "Ben", punkte: "98")], weiter: {})
        }
        XCTAssertEqual(leer, [])
    }

    func testSpielStart() {
        let verzeichnis = SpielerVerzeichnis(ablage: SpeicherAblage())
        let statistik = StatistikDienst(ablage: SpeicherAblage())
        let anna = verzeichnis.anlegen(name: "Anna")
        for i in 0..<12 {
            statistik.melden(PartieErgebnis(spiel: "yacht-bild", teilnehmer: [.init(spielerID: anna.id, name: "Anna", platz: i % 3 == 0 ? 2 : 1, punkte: 180 + i * 6),
                                                                              .init(name: "Ben", platz: i % 3 == 0 ? 1 : 2, punkte: 170)]))
        }
        let umgebung = SpielUmgebung(spieler: verzeichnis, statistik: statistik, wuerfelQuelle: .app, zurueck: {})
        let leer = Aufnahme.alle("spielstart") {
            SpielRahmen(id: "yacht-bild", name: "Yacht", untertitel: "Fünf Würfel, drei Würfe, drei Wertungen", farbe: .indigo, spieler: 1...4,
                        computerErlaubt: true, wuerfelWahl: true, regeln: "Regeln", umgebung: umgebung) { _, _, _ in Color.clear }
        }
        XCTAssertEqual(leer, [])
    }

    func testGeraetWeitergeben() {
        let leer = Aufnahme.alle("weitergeben", groesse: CGSize(width: 390, height: 420)) {
            SichtschutzKarte(name: "Ben", aufdecken: {}).padding(Theme.seitenRand)
        }
        XCTAssertEqual(leer, [])
    }

    func testNeuesSpiel() {
        struct Blatt: View {
            @State var spieler = [SpielerEintrag(name: "Anna", farbeHex: Spieler.farbenHex[0]), SpielerEintrag(name: "Ben", farbeHex: Spieler.farbenHex[3]),
                                  SpielerEintrag(name: "Computer", art: "computer")]
            @State var stufe = 1
            @State var joker = true
            var body: some View {
                NeuesSpielBlatt(schliessen: {}, los: {}) {
                    NeuesSpielKarte("Spieler") {
                        SpielerListe(spieler: $spieler, arten: [SpielerArt(id: "mensch", name: "Mensch"), SpielerArt(id: "computer", name: "Computer", symbol: "cpu")])
                    }
                    StufenWahl(stufen: [.init(id: 0, name: "Leicht"), .init(id: 1, name: "Mittel", untertitel: "Der Computer spielt ordentlich."), .init(id: 2, name: "Schwer")], auswahl: $stufe)
                    NeuesSpielKarte("Varianten") {
                        Toggle("Joker-Regel", isOn: $joker)
                        Toggle("Zweite Yacht zählt 100", isOn: .constant(false))
                    }
                }
            }
        }
        let leer = Aufnahme.alle("neuesspiel") { Blatt() }
        XCTAssertEqual(leer, [])
    }

    func testDesignAuswahl() {
        let leer = Aufnahme.alle("auswahl", groesse: CGSize(width: 390, height: 300)) {
            DesignAuswahl().padding(Theme.seitenRand)
        }
        XCTAssertEqual(leer, [])
    }

    /// Abschnitt „Start und Aussehen“ der Einstellungen (Darstellung, Design, Sprache, Schalter) wie in `EinstAussehen`, ohne Navigationsleiste.
    func testAussehen() {
        struct Blatt: View {
            @State var dar: Darstellung = .system
            @State var an = false
            var body: some View {
                Form {
                    Group {
                        Section {
                            DarstellungsAuswahl(darstellung: $dar)
                            DesignAuswahl()
                            LabeledContent("Sprache") { Button("Deutsch") {} }
                            Toggle(isOn: $an) { Text("Farben unterscheidbar"); Text("Zeigt zu jeder Spielart ein Zeichen.") }
                        }
                        Section { Picker(selection: .constant(""), label: Text("Beim Öffnen zeigen")) { Text("Startseite").tag("") } } header: { Text("Start") }
                    }.designZeilen()
                }.designListe()
            }
        }
        let leer = Aufnahme.alle("aussehen", groesse: CGSize(width: 390, height: 640)) { Blatt() }
        XCTAssertEqual(leer, [])
    }
}
#endif
