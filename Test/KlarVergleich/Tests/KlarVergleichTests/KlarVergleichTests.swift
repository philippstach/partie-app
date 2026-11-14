// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import XCTest
import SwiftUI
import UIKit
import KlarGlas
import SpieleKern
import KlarFangen

/// Zeichnet feste Szenen in „Klar & Glas“, hell und dunkel. Der Code benutzt nur, was es in Build 12 schon gab,
/// und läuft deshalb unverändert gegen den alten und den neuen Stand (siehe Package.swift).
/// Zielordner: Umgebungsvariable `KLAR_ZIEL`.
@MainActor
final class KlarVergleichTests: XCTestCase {
    static let telefon = CGSize(width: 390, height: 844)
    static var fenster: UIWindow?

    static var ordner: URL { URL(fileURLWithPath: ProcessInfo.processInfo.environment["KLAR_ZIEL"] ?? NSTemporaryDirectory() + "klar-vergleich") }

    override func setUp() async throws {
        await MainActor.run {
            // Wie in der App mit einem offenen Würfelspiel
            KlarGlasHaken.flaeche = { Gattung.wuerfel.farbe.color }
            KlarGlasHaken.accentText = { Gattung.wuerfel.farbe.textFarbe }
            SpielRahmenHaken.bild = { _ in .init(farbe: Gattung.wuerfel.farbe.color, miniatur: .wuerfel) }
            #if NEU
            Design.art = .klar
            KlarGlasHaken.spielart = { .wuerfel }
            KlarGlasHaken.spielName = { "Yacht" }
            KlarGlasHaken.spielerBild = { name in name == "Clara" ? (bild: nil, farbe: Spieler.farbe(2), zeichen: nil) : nil }
            #endif
        }
    }

    private func rahmen<V: View>(_ ansicht: V, dunkel: Bool, groesse: CGSize) -> some View {
        let v = ansicht.frame(width: groesse.width, height: groesse.height).background(Color(.systemGroupedBackground))
        #if NEU
        return v.designWurzel().environment(\.colorScheme, dunkel ? .dark : .light)
        #else
        return v.environment(\.colorScheme, dunkel ? .dark : .light)
        #endif
    }

    private func renderer<V: View>(_ ansicht: V, dunkel: Bool, groesse: CGSize) -> UIImage? {
        let r = ImageRenderer(content: rahmen(ansicht, dunkel: dunkel, groesse: groesse))
        r.scale = 2
        r.proposedSize = ProposedViewSize(groesse)
        return r.uiImage
    }

    private func fensterBild<V: View>(_ ansicht: V, dunkel: Bool, groesse: CGSize) -> UIImage? {
        let host = UIHostingController(rootView: rahmen(ansicht, dunkel: dunkel, groesse: groesse))
        host.overrideUserInterfaceStyle = dunkel ? .dark : .light
        var bild: UIImage?
        let schritt = {
            let f: UIWindow
            if let vorhanden = Self.fenster { f = vorhanden } else {
                f = UIWindow(frame: CGRect(origin: .zero, size: groesse))
                Self.fenster = f
            }
            if f.isHidden { f.isHidden = false }
            f.frame = CGRect(origin: .zero, size: groesse)
            f.overrideUserInterfaceStyle = dunkel ? .dark : .light
            f.rootViewController = host
            host.view.frame = f.bounds
            host.view.setNeedsLayout(); host.view.layoutIfNeeded()
            RunLoop.main.run(until: Date().addingTimeInterval(0.4))
            let format = UIGraphicsImageRendererFormat(); format.scale = 2
            bild = UIGraphicsImageRenderer(size: groesse, format: format).image { kontext in
                if !host.view.drawHierarchy(in: CGRect(origin: .zero, size: groesse), afterScreenUpdates: true) {
                    host.view.layer.render(in: kontext.cgContext)
                }
            }
        }
        for _ in 0..<3 where bild == nil { _ = KlarVergleichVersuche(schritt) }
        return bild
    }

    private func schreiben(_ bild: UIImage?, _ name: String) {
        guard let daten = bild?.pngData() else { XCTFail("kein Bild: \(name)"); return }
        try? FileManager.default.createDirectory(at: Self.ordner, withIntermediateDirectories: true)
        XCTAssertNoThrow(try daten.write(to: Self.ordner.appendingPathComponent(name + ".png")))
        print("BILD \(name)")
    }

    /// Jede Szene über beide Verfahren: Fenster (zeichnet ScrollView und Glas) und `ImageRenderer`.
    private func beide<V: View>(_ szene: String, groesse: CGSize = telefon, _ ansicht: () -> V) {
        for dunkel in [false, true] {
            let ton = dunkel ? "dunkel" : "hell"
            // Reihenfolge wichtig: Der erste `ImageRenderer`-Lauf richtet unter Mac Catalyst die App-Umgebung ein;
            // ein Fenster davor scheitert mit „NSApplication has not been created yet“.
            schreiben(renderer(ansicht(), dunkel: dunkel, groesse: groesse), "\(szene)-\(ton)-renderer")
            schreiben(fensterBild(ansicht(), dunkel: dunkel, groesse: groesse), "\(szene)-\(ton)-fenster")
        }
    }

    struct Bogen: View {
        var body: some View {
            VStack(alignment: .leading, spacing: Theme.kartenAbstand) {
                SpielKopf(mitte: "Runde 7 · Anna würfelt", mitteKurz: "Runde 7", linksAktion: {}) {
                    RundKnopfMenue(beschriftung: "Menü") { Button("Regeln") {} }
                }
                .padding(.horizontal, -Theme.seitenRand)
                StartTitel("Partie")
                SectionLabel("Abschnitt")
                HStack(spacing: Design.Abstand.s) {
                    StatusChip(symbol: "lightbulb", text: "3")
                    StatusChip(text: Text(verbatim: "liegt hinten"), ton: .warnung)
                    StatusChip(text: Text(verbatim: "neutral"), ton: .neutral)
                }
                WeiterspielenKarte(zeit: "4:12", beschreibung: "Sudoku", fortschritt: 0.4) {}
                SpielZeile(name: "Yacht", untertitel: Text(verbatim: "Würfel · 1–4 Spieler"), farbe: Gattung.wuerfel.farbe.color, miniatur: .wuerfel, hell: true) {}
                SpielZeile(name: "Solitär", untertitel: Text(verbatim: "Karten · 1 Spieler"), farbe: Gattung.karten.farbe.color, miniatur: .kartenstapel, favorit: true, hell: true) {}
                StatistikZeile(titel: "Statistik", werte: [.init(zahl: "48", name: "Partien"), .init(zahl: "21", name: "Siege"), .init(zahl: "3", name: "Serie")]) {}
                SpielerLeiste(eintraege: [.init(id: "a", name: "Anna", farbe: Spieler.farbe(0), wert: "124"), .init(id: "b", name: "Ben", farbe: Spieler.farbe(3), wert: "98"),
                                          .init(id: "c", name: "Clara", farbe: Spieler.farbe(2), wert: "131")], aktiv: "a")
                HinweisKarte(symbol: "lightbulb", titel: Text(verbatim: "Tipp"), text: Text(verbatim: "In dieser Reihe fehlen noch 1, 2 und 4."))
                Spacer(minLength: 0)
                AktionsLeiste(eintraege: [.init(symbol: "arrow.uturn.backward", titel: "Rückgängig") {}, .init(symbol: "delete.left", titel: "Löschen") {},
                                          .init(symbol: "pencil", titel: "Notizen", aktiv: true) {}, .init(symbol: "lightbulb", titel: "Tipp") {}])
                    .padding(.horizontal, -Theme.seitenRand)
                HStack(spacing: Design.Abstand.s) {
                    Button("Eintragen") {}.zweitKnopf()
                    Button("Würfeln") {}.hauptKnopf()
                }
            }
            .padding(.horizontal, Theme.seitenRand).padding(.vertical, 12)
        }
    }

    /// Stufe D: Kartenset (nur Typen, die es in Build 12 schon gab)
    /// Bogen mit dem Kartenset: alle vier Farben, Bildkarten, Rückseite, gewählt, markiert, gedimmt, leerer Platz, vier Größen, spanisches Blatt.
    /// Dieselbe Ansicht steht auch im Klar-Vergleich (Test/KlarVergleich), dort mit dem Stand von Build 12 gezeichnet.
    struct KartenBogen: View {
        private func zeile(_ g: KartenGroesse, _ karten: [SkatKarte?]) -> some View {
            HStack(spacing: 8) { ForEach(Array(karten.enumerated()), id: \.offset) { _, k in SkatKartenBild(k, groesse: g) } }
        }
        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                zeile(.normal, [SkatKarte(.herz, 10), SkatKarte(.pik, 7), SkatKarte(.karo, 12), SkatKarte(.kreuz, 14), SkatKarte(.herz, 2)])
                zeile(.gross, [SkatKarte(.herz, 13), SkatKarte(.pik, 12), SkatKarte(.karo, 9), SkatKarte(.kreuz, 11)])
                HStack(spacing: 8) {
                    SkatKartenBild(nil)
                    SkatKartenBild(SkatKarte(.herz, 13), gewaehlt: true)
                    SkatKartenBild(SkatKarte(.pik, 8), markiert: true)
                    SkatKartenBild(SkatKarte(.karo, 5), gedimmt: true)
                    KartenPlatz()
                }
                .padding(.top, 10)
                HStack(spacing: 6) {
                    SkatKartenBild(SkatKarte(.herz, 6), groesse: .klein); SkatKartenBild(SkatKarte(.kreuz, 10), groesse: .klein)
                    SkatKartenBild(SkatKarte(.karo, 14), groesse: .klein); SkatKartenBild(nil, groesse: .klein); KartenPlatz(groesse: .klein)
                }
                HStack(alignment: .top, spacing: 12) {
                    SkatKartenBild(SkatKarte(.herz, 14), groesse: .riesig)
                    SkatKartenBild(nil, groesse: .riesig)
                    VStack(spacing: 6) {
                        HStack(spacing: 6) { SpanischeKarteBild(rang: 3, farbe: 0, groesse: .klein); SpanischeKarteBild(rang: 7, farbe: 1, groesse: .klein) }
                        HStack(spacing: 6) { SpanischeKarteBild(rang: 11, farbe: 2, groesse: .klein); SpanischeKarteBild(rang: 1, farbe: 3, groesse: .klein) }
                    }
                }
            }
            .padding(.horizontal, 20).padding(.vertical, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    func testKarten() { beide("karten", groesse: CGSize(width: 390, height: 640)) { KartenBogen() } }

    func testBausteine() { beide("bausteine", groesse: CGSize(width: 390, height: 1040)) { Bogen() } }

    func testSieger() {
        beide("sieger") {
            SiegerBildschirm(symbol: "trophy.fill", titel: "Clara", untertitel: "247 Punkte · 13 Runden",
                             rangliste: [.init(name: "Clara", punkte: "247"), .init(name: "Anna", punkte: "231"), .init(name: "Ben", punkte: "198")],
                             info: "Serie Clara · Anna 5 : 4", teilen: {}, sekundaerTitel: "Zum Start", primaerTitel: "Revanche",
                             schliessen: {}, sekundaer: {}, primaer: {})
        }
    }

    func testVerloren() {
        beide("verloren") {
            SiegerBildschirm(symbol: "flag.checkered", titel: "Verloren", untertitel: "Der Computer war diesmal schneller.",
                             teilen: {}, sekundaerTitel: "Zum Start", primaerTitel: "Noch einmal", schliessen: {}, sekundaer: {}, primaer: {})
        }
    }

    func testRekord() {
        beide("rekord") {
            SiegerBildschirm(symbol: "trophy.fill", titel: "Neuer Rekord!", untertitel: "1240 Punkte", info: "Rekord bisher: 980",
                             teilen: {}, sekundaerTitel: "Zum Start", primaerTitel: "Noch einmal", schliessen: {}, sekundaer: {}, primaer: {})
        }
    }

    func testZwischenstand() {
        beide("zwischenstand") {
            ZwischenstandBildschirm(symbol: "person.fill", titel: "Ben ist dran", untertitel: "Runde 7 von 13",
                                    rangliste: [.init(name: "Clara", punkte: "131"), .init(name: "Anna", punkte: "124"), .init(name: "Ben", punkte: "98")], weiter: {})
        }
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
        beide("spielstart") {
            SpielRahmen(id: "yacht-bild", name: "Yacht", untertitel: "Fünf Würfel, drei Würfe, drei Wertungen", farbe: .indigo, spieler: 1...4,
                        computerErlaubt: true, wuerfelWahl: true, regeln: "Regeln", umgebung: umgebung) { _, _, _ in Color.clear }
        }
    }

    func testWeitergeben() {
        beide("weitergeben", groesse: CGSize(width: 390, height: 420)) {
            SichtschutzKarte(name: "Ben", aufdecken: {}).padding(Theme.seitenRand)
        }
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
        beide("neuesspiel") { Blatt() }
    }

    /// Weitere Bausteine, die in den Spielen und auf den gemeinsamen Seiten vorkommen.
    func testWeitereBausteine() {
        struct Bogen2: View {
            var body: some View {
                VStack(alignment: .leading, spacing: Theme.kartenAbstand) {
                    HStack(spacing: Design.Abstand.s) {
                        FilterChip("Alle", aktiv: true) {}
                        FilterChip("Karten", punkt: Gattung.karten.farbe.color, aktiv: false) {}
                        FilterChip("Würfel", symbol: "dice", aktiv: false) {}
                    }
                    SpielfeldKarte { Text(verbatim: "Spielfeld").frame(maxWidth: .infinity, minHeight: 80) }
                    TagesKarte(titel: "Tagesrätsel", datum: "10. November", woche: [true, true, false, true, false, false, false], serie: "Serie 2", aktion: {})
                    AuswahlZeile(symbol: "dice.fill", titel: "Freies Spiel", untertitel: "Ohne Wertung", laeuft: true, aktion: {}) { EmptyView() }
                    HStack(spacing: Design.Abstand.s) {
                        StatusPille(text: "Am Zug")
                        RundKnopf(symbol: "gearshape", beschriftung: "Einstellungen") {}
                        RundKnopf(symbol: "questionmark", beschriftung: "Hilfe", klein: true) {}
                    }
                    EinstellungsKopf(gruppe: .aussehen)
                    VStack(spacing: 8) { Text(verbatim: "Karte").font(.headline); Text(verbatim: "Inhalt einer Karte").foregroundStyle(.secondary) }
                        .frame(maxWidth: .infinity).card()
                    Text(verbatim: "Gespeichert").toast()
                    Spacer(minLength: 0)
                }
                .padding(Theme.seitenRand)
            }
        }
        beide("bausteine2", groesse: CGSize(width: 390, height: 760)) { Bogen2() }
    }
}
#endif
