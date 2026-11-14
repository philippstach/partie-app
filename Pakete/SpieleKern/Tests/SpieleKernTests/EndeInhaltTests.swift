// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// NICHT SYNTAXGEPRÜFT (Cloud-Chat EB-K). Blatt 22: Bausteine der Ergebnisseite (EndeWert, EndeBild, EndeAnordnung).
#if canImport(UIKit)
import XCTest
import SwiftUI
import KlarGlas
@testable import SpieleKern

@MainActor
final class EndeInhaltTests: XCTestCase {

    // MARK: EndeWert

    func testWertZeigtFestenText() {
        let w = EndeWert("Runden", "18")
        XCTAssertFalse(w.istDauer)
        XCTAssertEqual(w.text(dauer: 372), "18")
        XCTAssertEqual(w.titel, LocalizedStringKey("Runden"))
    }

    func testDauerNimmtDieDauerDesRahmens() {
        let d = EndeWert.dauer
        XCTAssertTrue(d.istDauer)
        XCTAssertEqual(d.titel, LocalizedStringKey("Dauer"))
        XCTAssertEqual(d.text(dauer: 372), Zeitformat.text(372))
        XCTAssertEqual(d.text(dauer: nil), "–")
        XCTAssertEqual(d.text(dauer: -5), Zeitformat.text(0), "negative Dauer wird zu 0")
    }

    // MARK: Wann der Standardinhalt gilt

    func testOhneWerteBildUndWuerfelBleibtDasSpielbild() {
        let e = SpielEnde(reihenfolge: ["Anna", "Ben"])
        XCTAssertFalse(EndeAnordnung.zeigtStandard(e))
    }

    func testLeereWuerfelbilanzZeigtKeinenStandardinhalt() {
        var e = SpielEnde(reihenfolge: ["Anna"])
        e.wuerfel = WuerfelBilanz(namen: ["Anna"])
        XCTAssertFalse(EndeAnordnung.zeigtStandard(e))
    }

    func testWerteBildOderGezaehlteWuerfelZeigenStandardinhalt() {
        var mitWerten = SpielEnde(reihenfolge: ["Anna"])
        mitWerten.werte = [.dauer]
        XCTAssertTrue(EndeAnordnung.zeigtStandard(mitWerten))

        var mitBild = SpielEnde(reihenfolge: ["Anna"])
        mitBild.bild = EndeBild(Text(verbatim: "Brett"), hoehe: 150) { _ in Color.clear }
        XCTAssertTrue(EndeAnordnung.zeigtStandard(mitBild))

        var mitWuerfeln = SpielEnde(reihenfolge: ["Anna", "Ben"])
        var b = WuerfelBilanz(namen: ["Anna", "Ben"])
        b.zaehle(spieler: 0, [6, 6, 1])
        mitWuerfeln.wuerfel = b
        XCTAssertTrue(EndeAnordnung.zeigtStandard(mitWuerfeln))
    }

    func testNeueFelderSindLeerVoreingestellt() {
        let e = SpielEnde(reihenfolge: ["Anna"])
        XCTAssertTrue(e.werte.isEmpty)
        XCTAssertNil(e.bild)
    }

    // MARK: Höchstens drei Wertzeilen

    func testHoechstensDreiWertzeilen() {
        let werte = [EndeWert("A", "1"), EndeWert("B", "2"), .dauer, EndeWert("D", "4")]
        let s = EndeAnordnung.sichtbar(werte)
        XCTAssertEqual(s.count, 3)
        XCTAssertEqual(s.map(\.titel), [LocalizedStringKey("A"), LocalizedStringKey("B"), LocalizedStringKey("Dauer")])
        XCTAssertEqual(EndeAnordnung.sichtbar([]).count, 0)
    }

    // MARK: Höhe der Bildkarte

    func testBildhoeheIPhone() {
        XCTAssertEqual(EndeAnordnung.bildHoehe(gewuenscht: 150, ipad: false, rangEintraege: 0), 150)
        XCTAssertEqual(EndeAnordnung.bildHoehe(gewuenscht: 500, ipad: false, rangEintraege: 2), 320)
        XCTAssertEqual(EndeAnordnung.bildHoehe(gewuenscht: 300, ipad: false, rangEintraege: 3), 220, "drei oder mehr in der Rangliste: höchstens 220")
        XCTAssertEqual(EndeAnordnung.bildHoehe(gewuenscht: 300, ipad: false, rangEintraege: 4), 220)
        XCTAssertEqual(EndeAnordnung.bildHoehe(gewuenscht: 150, ipad: false, rangEintraege: 4), 150)
    }

    func testBildhoeheIPad() {
        XCTAssertEqual(EndeAnordnung.bildHoehe(gewuenscht: 200, ipad: true, rangEintraege: 4), 260, accuracy: 0.001)
        XCTAssertEqual(EndeAnordnung.bildHoehe(gewuenscht: 400, ipad: true, rangEintraege: 0), 420)
    }

    func testBildhoeheNieZuKlein() {
        XCTAssertEqual(EndeAnordnung.bildHoehe(gewuenscht: 0, ipad: false, rangEintraege: 0), EndeAnordnung.mindestHoehe)
        XCTAssertEqual(EndeAnordnung.bildHoehe(gewuenscht: -10, ipad: true, rangEintraege: 0), EndeAnordnung.mindestHoehe)
        XCTAssertEqual(EndeAnordnung.bildHoehe(gewuenscht: .infinity, ipad: false, rangEintraege: 0), EndeAnordnung.mindestHoehe)
    }

    func testInnenflaecheOhneRand() {
        XCTAssertEqual(EndeAnordnung.innen(CGSize(width: 353, height: 150)), CGSize(width: 325, height: 122))
        XCTAssertEqual(EndeAnordnung.innen(CGSize(width: 10, height: 10)), .zero)
    }

    // MARK: Würfelbild

    func testBalken() {
        XCTAssertEqual(EndeAnordnung.balkenHoechst(personen: 2), 44)
        XCTAssertEqual(EndeAnordnung.balkenHoechst(personen: 3), 28)
        XCTAssertEqual(EndeAnordnung.balken(10, maximum: 10, hoechst: 44), 44)
        XCTAssertEqual(EndeAnordnung.balken(5, maximum: 10, hoechst: 44), 22)
        XCTAssertEqual(EndeAnordnung.balken(0, maximum: 10, hoechst: 44), 2, "eine Null bleibt als Strich sichtbar")
        XCTAssertEqual(EndeAnordnung.balken(0, maximum: 0, hoechst: 44), 2)
    }

    func testMuenzenZeigenZifferUndEigeneUeberschrift() {
        let muenzen = WuerfelBilanz(namen: ["Anna"], seiten: 5, kleinste: 0)   // Königsweg
        XCTAssertTrue(EndeAnordnung.zeigtZiffer(muenzen))
        XCTAssertEqual(EndeAnordnung.wuerfelTitel(muenzen), LocalizedStringKey("So fielen die Münzen"))

        let wuerfel = WuerfelBilanz(namen: ["Anna"])
        XCTAssertFalse(EndeAnordnung.zeigtZiffer(wuerfel))
        XCTAssertEqual(EndeAnordnung.wuerfelTitel(wuerfel), LocalizedStringKey("So fielen die Würfel"))
    }

    // MARK: Das Bild hält den Stand als Wert fest

    func testBildBekommtDieInnenflaeche() {
        var bekommen: CGSize?
        let b = EndeBild(Text(verbatim: "Test"), hoehe: 150) { groesse in
            let _ = { bekommen = groesse }()
            Color.clear
        }
        _ = b.inhalt(CGSize(width: 325, height: 122))
        XCTAssertEqual(bekommen, CGSize(width: 325, height: 122))
        XCTAssertEqual(b.hoehe, 150)
    }
}
#endif
