// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import XCTest
import SwiftUI
import KlarGlas
import SpieleKern
import SpielHilfen
@testable import DesignBilder
import HuelleBilder

/// Designwechsel iPad: dieselben Szenen in allen drei Designs, hell und dunkel, in vier Größen (iPhone 390 × 844, iPad hoch 820 × 1180,
/// iPad quer 1180 × 820, Split View 507 × 1024) nach `$DESIGN_VERGLEICH` (Umgebungsvariable `TEST_RUNNER_DESIGN_VERGLEICH`).
/// Wird im alten und im neuen Stand ausgeführt (Werkzeug/designwechsel_ipad_vergleich.sh); nur Szenen, die es im alten Stand schon gab.
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

@MainActor
final class IPadVergleich: XCTestCase {
    static let groessen: [(String, CGSize, UserInterfaceSizeClass)] = [
        ("iphone", CGSize(width: 390, height: 844), .compact), ("ipad-hoch", CGSize(width: 820, height: 1180), .regular),
        ("ipad-quer", CGSize(width: 1180, height: 820), .regular), ("split", CGSize(width: 507, height: 1024), .compact),
    ]
    static var ziel: URL { URL(fileURLWithPath: ProcessInfo.processInfo.environment["DESIGN_VERGLEICH"] ?? NSTemporaryDirectory() + "ipad-vergleich") }

    private func szene(_ name: String, spielart: Design.Spielart? = nil, nur: [DesignArt] = DesignArt.allCases, _ ansicht: (DesignArt) -> AnyView) throws {
        try FileManager.default.createDirectory(at: Self.ziel, withIntermediateDirectories: true)
        Design.art = .klar; HuelleSzenen.rundeWaehlen()
        _ = ImageRenderer(content: Blatt().frame(width: 390, height: 844)).uiImage   // der erste ImageRenderer-Lauf richtet unter Mac Catalyst die App-Umgebung ein; erst danach geht das Fenster
        for design in nur {
            for (gname, groesse, klasse) in Self.groessen {
                for dunkel in [false, true] {
                    Design.art = design
                    HuelleSzenen.rundeWaehlen()
                    KlarGlasHaken.spielart = { spielart }
                    if let s = spielart { KlarGlasHaken.flaeche = { Design.werte.palette?[s]?.flaeche ?? Gattung.wuerfel.farbe.color }; KlarGlasHaken.accentText = { Design.werte.palette?[s]?.text ?? Color.accentColor } }
                    else { KlarGlasHaken.flaeche = { Design.werte.huelleFlaeche.color }; KlarGlasHaken.accentText = { Design.werte.huelleAkzent.color } }
                    let e = Aufnahme.seite(ansicht(design), design: design, dunkel: dunkel, groesse: groesse, klasse: klasse)
                    let daten = try XCTUnwrap(e.bild?.pngData(), "kein Bild: \(name) \(design) \(gname)")
                    try daten.write(to: Self.ziel.appendingPathComponent("\(design.rawValue)-\(dunkel ? "dunkel" : "hell")-\(name)-\(gname).png"))
                }
            }
        }
        Design.art = .klar
    }

    func testSieger() throws {
        try szene("sieger", spielart: .wuerfel) { _ in
            AnyView(SiegerBildschirm(symbol: "trophy.fill", titel: "Clara", untertitel: "247 Punkte · 13 Runden",
                                     rangliste: [.init(name: "Clara", punkte: "247"), .init(name: "Anna", punkte: "231"), .init(name: "Ben", punkte: "198")],
                                     info: "Serie Clara · Anna 5 : 4", teilen: {}, sekundaerTitel: "Zum Start", primaerTitel: "Revanche",
                                     schliessen: {}, sekundaer: {}, primaer: {}))
        }
    }
    func testZwischenstand() throws {
        try szene("zwischenstand", spielart: .wuerfel) { _ in
            AnyView(ZwischenstandBildschirm(symbol: "person.fill", titel: "Ben ist dran", untertitel: "Runde 7 von 13",
                                            rangliste: [.init(name: "Clara", punkte: "131"), .init(name: "Anna", punkte: "124"), .init(name: "Ben", punkte: "98")], weiter: {}))
        }
    }
    func testSpielStart() throws {
        let verzeichnis = SpielerVerzeichnis(ablage: SpeicherAblage())
        let statistik = StatistikDienst(ablage: SpeicherAblage())
        let anna = verzeichnis.anlegen(name: "Anna")
        for i in 0..<12 {
            statistik.melden(PartieErgebnis(spiel: "yacht-bild", teilnehmer: [.init(spielerID: anna.id, name: "Anna", platz: i % 3 == 0 ? 2 : 1, punkte: 180 + i * 6), .init(name: "Ben", platz: i % 3 == 0 ? 1 : 2, punkte: 170)]))
        }
        let umgebung = SpielUmgebung(spieler: verzeichnis, statistik: statistik, wuerfelQuelle: .app, zurueck: {})
        SpielRahmenHaken.bild = { _ in .init(farbe: Gattung.wuerfel.farbe.color, miniatur: .wuerfel, spielart: "Würfel") }
        try szene("spielstart", spielart: .wuerfel) { _ in
            AnyView(SpielRahmen(id: "yacht-bild", name: "Yacht", untertitel: "Fünf Würfel, drei Würfe, drei Wertungen", farbe: .indigo, spieler: 1...4,
                                computerErlaubt: true, wuerfelWahl: true, regeln: "Regeln", umgebung: umgebung) { _, _, _ in Color.clear })
        }
    }
    func testNeuesSpiel() throws {
        try szene("neuesspiel", spielart: .wuerfel) { _ in AnyView(Blatt()) }
    }
    func testWeitergeben() throws {
        try szene("weitergeben", spielart: .karten) { _ in
            AnyView(Color.clear.uebergabeSeite(teilnehmer: [SpielTeilnehmer(name: "Anna"), SpielTeilnehmer(name: "Ben")], amZug: 1))
        }
    }
    func testEinfuehrung() throws { try szene("einfuehrung") { _ in AnyView(HuelleSzenen.einfuehrung(0)) } }
    func testStartTinte() throws { try szene("start", nur: [.tinte]) { _ in AnyView(HuelleSzenen.startTinte) } }
    func testStartSalon() throws { try szene("start", nur: [.salon]) { _ in AnyView(HuelleSzenen.startSalon) } }
}
#endif
