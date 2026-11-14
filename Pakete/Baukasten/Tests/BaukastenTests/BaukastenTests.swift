// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Testing
import Foundation
@testable import Baukasten

@Suite("Akzent")
struct AkzentTests {
    @Test("Alle Farben erfüllen die Kontrastregeln des CI-Handbuchs")
    func kontrast() {
        for f in AkzentFarbe.alle {
            let w = f.pruefwerte
            #expect(Kontrast.verhaeltnis(0xFFFFFF, w.flaeche) >= 3.0, "Weiß auf \(f.name)")
            #expect(Kontrast.verhaeltnis(w.hell, 0xFFFFFF) >= 4.5, "Text hell \(f.name)")
            #expect(Kontrast.verhaeltnis(w.dunkel, 0x1C1C1E) >= 4.5, "Text dunkel \(f.name)")
        }
    }

    @Test("IDs sind eindeutig, Farbwahl wird gemerkt, Standard wird nicht gespeichert")
    @MainActor func speichern() {
        #expect(Set(AkzentFarbe.alle.map(\.id)).count == AkzentFarbe.alle.count)
        let s = FluechtigerSpeicher()
        let a = AkzentSpeicher(standard: .gruen, speicher: s)
        #expect(a.gewaehlt == .gruen)
        a.gewaehlt = .rot
        #expect(AkzentSpeicher(standard: .gruen, speicher: s).gewaehlt == .rot)
        a.gewaehlt = .gruen
        #expect(s.object(forKey: AkzentSpeicher.schluessel) == nil)
        s.set("gibtsnicht", forKey: AkzentSpeicher.schluessel)
        #expect(AkzentSpeicher(standard: .blau, speicher: s).gewaehlt == .blau)
    }
}

@Suite("Bewertung")
struct BewertungTests {
    final class Uhr { var jetzt = Date(timeIntervalSince1970: 1_800_000_000); func tage(_ n: Double) { jetzt += n * 86_400 } }

    func zaehler(_ s: WerteSpeicher, _ u: Uhr, version: String = "1.0") -> BewertungsZaehler {
        BewertungsZaehler(speicher: s, version: version, jetzt: { u.jetzt })
    }
    func bereit(_ z: BewertungsZaehler, _ u: Uhr) {
        for _ in 0..<5 { z.appGestartet() }
        for _ in 0..<3 { z.erfolgVerbuchen() }
        u.tage(8)
    }

    @Test("Nicht beim Anfang, erst nach Starts, Tagen und Erfolgen")
    func schwellen() {
        let u = Uhr(), z = zaehler(FluechtigerSpeicher(), u)
        z.appGestartet()
        #expect(!z.sollFragen())
        bereit(z, u)
        #expect(z.sollFragen())
    }

    @Test("Zu früh: keine Anfrage am ersten Tag, auch mit vielen Erfolgen")
    func ersterTag() {
        let u = Uhr(), z = zaehler(FluechtigerSpeicher(), u)
        for _ in 0..<5 { z.appGestartet() }
        for _ in 0..<10 { z.erfolgVerbuchen() }
        #expect(!z.sollFragen())
    }

    @Test("Nach einer Anfrage: Version gesperrt, Abstand, neue Erfolge nötig")
    func nachAnfrage() {
        let u = Uhr(), s = FluechtigerSpeicher(), z = zaehler(s, u)
        bereit(z, u)
        z.angefragtVerbuchen()
        #expect(!z.sollFragen())
        // neue Version, aber Abstand noch zu kurz
        let z2 = zaehler(s, u, version: "1.1")
        for _ in 0..<3 { z2.erfolgVerbuchen() }
        u.tage(30)
        #expect(!z2.sollFragen())
        u.tage(100)
        #expect(z2.sollFragen())
        // gleiche Version bleibt gesperrt
        #expect(!zaehler(s, u, version: "1.0").sollFragen())
    }

    @Test("Höchstens 3 pro Jahr")
    func jahresgrenze() {
        let u = Uhr(), s = FluechtigerSpeicher()
        var z = zaehler(s, u, version: "1.0")
        bereit(z, u)
        for i in 0..<3 {
            #expect(z.sollFragen())
            z.angefragtVerbuchen()
            u.tage(121)
            z = zaehler(s, u, version: "1.\(i + 1)")
            for _ in 0..<3 { z.erfolgVerbuchen() }
        }
        #expect(!z.sollFragen())   // 3 Anfragen in 363 Tagen
    }
}

@Suite("Trinkgeld, Links, Katalog, Über mich")
struct SonstigesTests {
    @Test func produktIDs() {
        #expect(TrinkgeldStufe.klein.produktID(bundleID: "de.philippstach.yacht") == "de.philippstach.yacht.trinkgeld.klein")
        #expect(Set(TrinkgeldStufe.standard.map(\.name)).count == 3)
    }

    @Test func links() {
        let l = AppLinks(key: "yacht", appStoreID: "123")
        #expect(l.support.absoluteString == "https://d2mb1iyjufn965.cloudfront.net/yacht/support.html")
        #expect(l.datenschutz.lastPathComponent == "datenschutz.html")
        #expect(l.bewertenURL?.absoluteString == "https://apps.apple.com/app/id123?action=write-review")
        #expect(AppLinks(key: "yacht").bewertenURL == nil)
        let wurzel = AppLinks(key: "10k", seitenOrdner: URL(string: AppLinks.basis))
        #expect(wurzel.support.absoluteString == "https://d2mb1iyjufn965.cloudfront.net/support.html")
    }

    @Test func katalog() {
        var k = EigeneAppKatalog.alle
        #expect(EigeneAppKatalog.fuer(aktuell: "yacht", kinderApp: false, katalog: k).isEmpty)   // keine App live
        k[0].appStoreID = "1"; k[8].appStoreID = "9"
        #expect(EigeneAppKatalog.fuer(aktuell: "yacht", kinderApp: false, katalog: k).map(\.id) == ["sudoku"])
        #expect(EigeneAppKatalog.fuer(aktuell: "sudoku", kinderApp: false, katalog: k).map(\.id) == ["yacht"])
        #expect(EigeneAppKatalog.fuer(aktuell: "yacht", kinderApp: true, katalog: k).isEmpty)
        #expect(k[0].storeURL?.absoluteString == "https://apps.apple.com/app/id1")   // Rückfall bei Ladefehler
        #expect(EigeneAppKatalog.alle[1].storeURL == nil)
        #expect(Set(EigeneAppKatalog.alle.map(\.id)).count == EigeneAppKatalog.alle.count)
    }

    @Test func ueberMich() {
        #expect(UeberMichInhalt.philipp != nil)   // am 03.11.2026 von Philipp freigegeben
        #expect(UeberMichInhalt.entwurf.istVollstaendig)
        #expect(UeberMichInhalt.entwurf.text(sprache: "fr").contains("Philipp"))
        #expect(UeberMichInhalt.entwurf.text(sprache: "it") == UeberMichInhalt.entwurf.text(sprache: "en"))
        #expect(!UeberMichInhalt.entwurf.texte.values.contains { $0.contains("@") || $0.localizedCaseInsensitiveContains("trinkgeld") })
        #expect(!UeberMichInhalt(name: "P", text: "kurz").istVollstaendig)
        #expect(UeberMichInhalt(name: "P", texte: ["de", "en", "es", "fr"].reduce(into: [:]) { $0[$1] = String(repeating: "a", count: 50) }).istVollstaendig)
        #expect(UeberMichZeile(nil) == nil)
    }
}

@Suite("Erinnerung")
struct ErinnerungTests {
    var kal: Calendar { var k = Calendar(identifier: .gregorian); k.timeZone = TimeZone(identifier: "UTC")!; return k }
    func um(_ h: Int) -> Date { kal.date(from: DateComponents(year: 2026, month: 11, day: 3, hour: h))! }

    @Test func heuteNochOffen() {
        let t = ErinnerungsPlan.termine(ab: um(10), stunde: 18, minute: 0, heuteErledigt: false, kalender: kal)
        #expect(t.count == 7 && t[0] == um(18))
    }
    @Test func heuteErledigtOderVorbei() {
        #expect(ErinnerungsPlan.termine(ab: um(10), stunde: 18, minute: 0, heuteErledigt: true, kalender: kal)[0] == um(18 + 24))
        #expect(ErinnerungsPlan.termine(ab: um(20), stunde: 18, minute: 0, heuteErledigt: false, kalender: kal)[0] == um(18 + 24))
        #expect(ErinnerungsPlan.termine(ab: um(20), stunde: 18, minute: 0, heuteErledigt: false, kalender: kal).count == 7)
    }
}
