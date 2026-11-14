// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import XCTest
import SwiftUI
import KlarGlas
import SpieleKern
@testable import DesignBilder
import HuelleBilder

/// Bestandsaufnahme iPad (nur Bilder, nichts umgebaut): Start, Gewinnerseite, Zwischenstand, Spiel-Startseite, „Neues Spiel“ in Tinte und Salon,
/// hell, in iPad-Größe hoch (820 × 1180) und quer (1180 × 820), mit horizontaler Größenklasse „regular“.
@MainActor
class IPadBilder: XCTestCase {
    static let hoch = CGSize(width: 820, height: 1180)
    static let quer = CGSize(width: 1180, height: 820)

    override func setUp() async throws {
        await MainActor.run {
            KlarGlasHaken.spielart = { nil }
            KlarGlasHaken.flaeche = { Design.werte.huelleFlaeche.color }
            KlarGlasHaken.accentText = { Design.werte.huelleAkzent.color }
            HuelleSzenen.rundeWaehlen()
        }
    }
    override func tearDown() async throws { await MainActor.run { Design.art = .klar; AktuelleRunde.speichern([]) } }

    private func ipad(_ szene: String, spielart: Design.Spielart? = nil, _ ansicht: @escaping (DesignArt) -> AnyView) {
        for (suffix, groesse) in [("ipad-hoch", Self.hoch), ("ipad-quer", Self.quer)] {
            for design in [DesignArt.tinte, .salon] {
                Design.art = design
                KlarGlasHaken.spielart = { spielart }
                if let s = spielart { KlarGlasHaken.flaeche = { Design.werte.palette?[s]?.flaeche }; KlarGlasHaken.accentText = { Design.werte.palette?[s]?.text ?? Color.schrift } }
                let v = ansicht(design).environment(\.horizontalSizeClass, .regular)
                let e = Aufnahme.seite(v, design: design, dunkel: false, groesse: groesse)
                Aufnahme.schreiben(e.bild, name: Aufnahme.name(design, dunkel: false, "\(szene)-\(suffix)"))
                print("BILD \(design.rawValue)-hell-\(szene)-\(suffix) [\(e.verfahren)]")
            }
        }
    }

    func testIPadStart() { ipad("start") { $0 == .salon ? AnyView(HuelleSzenen.startSalon) : AnyView(HuelleSzenen.startTinte) } }

    func testIPadSieger() {
        ipad("sieger", spielart: .wuerfel) { _ in
            AnyView(SiegerBildschirm(symbol: "trophy.fill", titel: "Clara", untertitel: "247 Punkte · 13 Runden",
                                     rangliste: [.init(name: "Clara", punkte: "247"), .init(name: "Anna", punkte: "231"), .init(name: "Ben", punkte: "198")],
                                     info: "Serie Clara · Anna 5 : 4", teilen: {}, sekundaerTitel: "Zum Start", primaerTitel: "Revanche",
                                     schliessen: {}, sekundaer: {}, primaer: {}))
        }
    }

    func testIPadZwischenstand() {
        ipad("zwischenstand", spielart: .wuerfel) { _ in
            AnyView(ZwischenstandBildschirm(symbol: "person.fill", titel: "Ben ist dran", untertitel: "Runde 7 von 13",
                                            rangliste: [.init(name: "Clara", punkte: "131"), .init(name: "Anna", punkte: "124"), .init(name: "Ben", punkte: "98")], weiter: {}))
        }
    }

    func testIPadSpielStart() {
        let verzeichnis = SpielerVerzeichnis(ablage: SpeicherAblage())
        let statistik = StatistikDienst(ablage: SpeicherAblage())
        let anna = verzeichnis.anlegen(name: "Anna")
        for i in 0..<12 {
            statistik.melden(PartieErgebnis(spiel: "yacht-bild", teilnehmer: [.init(spielerID: anna.id, name: "Anna", platz: i % 3 == 0 ? 2 : 1, punkte: 180 + i * 6),
                                                                              .init(name: "Ben", platz: i % 3 == 0 ? 1 : 2, punkte: 170)]))
        }
        let umgebung = SpielUmgebung(spieler: verzeichnis, statistik: statistik, wuerfelQuelle: .app, zurueck: {})
        SpielRahmenHaken.bild = { _ in .init(farbe: Gattung.wuerfel.farbe.color, miniatur: .wuerfel, spielart: "Würfel") }
        ipad("spielstart", spielart: .wuerfel) { _ in
            AnyView(SpielRahmen(id: "yacht-bild", name: "Yacht", untertitel: "Fünf Würfel, drei Würfe, drei Wertungen", farbe: .indigo, spieler: 1...4,
                                computerErlaubt: true, wuerfelWahl: true, regeln: "Regeln", umgebung: umgebung) { _, _, _ in Color.clear })
        }
    }

    func testIPadNeuesSpiel() {
        struct Blatt: View {
            @State var spieler = [SpielerEintrag(name: "Anna", farbeHex: Spieler.farbenHex[0]), SpielerEintrag(name: "Ben", farbeHex: Spieler.farbenHex[3]), SpielerEintrag(name: "Computer", art: "computer")]
            @State var stufe = 1
            var body: some View {
                NeuesSpielBlatt(schliessen: {}, los: {}) {
                    NeuesSpielKarte("Spieler") { SpielerListe(spieler: $spieler, arten: [SpielerArt(id: "mensch", name: "Mensch"), SpielerArt(id: "computer", name: "Computer", symbol: "cpu")]) }
                    StufenWahl(stufen: [.init(id: 0, name: "Leicht"), .init(id: 1, name: "Mittel", untertitel: "Der Computer spielt ordentlich."), .init(id: 2, name: "Schwer")], auswahl: $stufe)
                }
            }
        }
        ipad("neuesspiel", spielart: .wuerfel) { _ in AnyView(Blatt()) }
    }

    func testIPadEinfuehrung() { ipad("einfuehrung-1") { _ in AnyView(HuelleSzenen.einfuehrung(0)) } }
}
#endif
