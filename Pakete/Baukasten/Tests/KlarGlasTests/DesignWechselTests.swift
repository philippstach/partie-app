// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Testing
import Foundation
import SwiftUI
@testable import KlarGlas

// Designwechsel (KlarGlas 2.16): die Design-Ebene. Die Tests fassen die echte Auswahl (`DesignWahl.geteilt`) nicht an,
// damit parallel laufende Tests (Theme-Werte) nicht kippen: Werte kommen aus `DesignWerte.fuer`, Speichern/Laden läuft
// über eine eigene Ablage.

@Suite("Designwechsel: Werte")
struct DesignWerteTests {
    @Test("klar liefert die heutigen Zahlen (Ecken 8/12/20/28/32, Titel 56, Seitenrand 16)")
    func klarWieHeute() {
        let k = DesignWerte.klar
        #expect(k.eckeKlein == 8 && k.eckeFeld == 12 && k.eckeKarte == 20 && k.eckeLeiste == 28 && k.eckeSheet == 32)
        #expect(k.titelGroesse == 56 && k.titelGewicht == .bold && k.titelLaufweite == -0.03)
        #expect(k.seitenRand == 16 && k.zahlDesign == .rounded && !k.serif)
        // Farbrollen sind in klar die Systemfarben (kein Hex), die Spielart-Farben die Familienfarben (keine Palette).
        #expect(k.seitenGrund == nil && k.kartenGrund == nil && k.feldGrund == nil && k.linie == nil && k.schrift == nil)
        #expect(k.schriftZweit == nil && k.schriftBlass == nil && k.knopf == nil && k.schriftAufKnopf == nil && k.palette == nil)
        #expect(k.huelleFlaeche == FarbPaar(0x1F3A5F) && k.huelleAkzent == FarbPaar(0x1658D8, 0x6FA8FF))
    }

    @Test("Voreinstellung ist klar: Theme und Design geben die heutigen Werte")
    func voreinstellung() {
        #expect(DesignWahl.gespeichert(in: UserDefaults(suiteName: "klarglas-test-leer-\(UUID().uuidString)")!) == .klar)
        #expect(Design.art == .klar)
        #expect(Design.Ecke.karte == 20 && Design.Ecke.feld == 12 && Design.Ecke.leiste == 28 && Design.Ecke.sheet == 32 && Design.Ecke.klein == 8)
        #expect(Design.Abstand.xs == 4 && Design.Abstand.s == 8 && Design.Abstand.m == 12 && Design.Abstand.l == 16 && Design.Abstand.xl == 24)
        #expect(Design.Abstand.seite == 16 && Design.Schrift.titel == 56 && Design.Schrift.schlagzeile == 34)
        #expect(Design.zahlDesign == .rounded && Design.mitKarten && Design.spielFarben == nil)
    }

    @Test("Formwerte von Tinte und Salon wie im Auftrag")
    func form() {
        let t = DesignWerte.tinte, s = DesignWerte.salon
        #expect(t.eckeKarte == 0 && t.eckeFeld == 4 && t.eckeLeiste == 0 && t.eckeSheet == 16 && t.seitenRand == 20 && t.knopfRand == 1.5)
        #expect(s.eckeKarte == 0 && s.eckeFeld == 2 && s.eckeLeiste == 0 && s.eckeSheet == 0 && s.seitenRand == 22 && s.knopfRand == 2)
        #expect(t.titelGroesse == 46 && t.schlagzeileGroesse == 54 && t.nameGroesse == 21 && t.nebenGroesse == 18 && t.labelSperrung == 0.12)
        #expect(s.titelGroesse == 72 && s.schlagzeileGroesse == 84 && s.nameGroesse == 24 && s.nebenGroesse == 20 && s.labelSperrung == 0.14)
        #expect(t.serif && s.serif && t.zahlDesign == .serif && s.zahlDesign == .serif)
    }

    @Test("Jedes Design kennt alle sechs Spielarten")
    func paletteVollstaendig() {
        for w in [DesignWerte.tinte, .salon] {
            #expect(Set(w.palette?.keys.map(\.rawValue) ?? []) == Set(Design.Spielart.allCases.map(\.rawValue)))
        }
        #expect(DesignArt.allCases.map(\.rawValue) == ["klar", "tinte", "salon"])
        #expect(DesignArt.allCases.allSatisfy { !$0.name.isEmpty && !$0.kurztext.isEmpty })
    }
}

@Suite("Designwechsel: Auswahl speichern")
struct DesignWahlTests {
    func ablage() -> (UserDefaults, String) {
        let name = "klarglas-test-\(UUID().uuidString)"
        return (UserDefaults(suiteName: name)!, name)
    }

    @Test("Speichern und Laden über eine eigene Ablage")
    func rundreise() {
        let (a, name) = ablage()
        defer { a.removePersistentDomain(forName: name) }
        let wahl = DesignWahl(ablage: a)
        #expect(wahl.art == .klar)
        wahl.art = .salon
        #expect(a.string(forKey: DesignWahl.schluessel) == "salon")
        #expect(DesignWahl(ablage: a).art == .salon)
        wahl.art = .tinte
        #expect(DesignWahl.gespeichert(in: a) == .tinte)
        wahl.art = .klar   // ausdrücklich gespeichert, auch wenn es die Voreinstellung ist
        #expect(a.string(forKey: DesignWahl.schluessel) == "klar" && DesignWahl(ablage: a).art == .klar)
    }

    @Test("Unbekannter Wert ergibt klar")
    func unbekannt() {
        let (a, name) = ablage()
        defer { a.removePersistentDomain(forName: name) }
        a.set("neon", forKey: DesignWahl.schluessel)
        #expect(DesignWahl(ablage: a).art == .klar)
    }

    @Test("Der Wechsel wird beobachtet (Ansichten zeichnen neu)")
    func beobachtbar() {
        let (a, name) = ablage()
        defer { a.removePersistentDomain(forName: name) }
        let wahl = DesignWahl(ablage: a)
        final class Merker: @unchecked Sendable { var gemeldet = false }
        let m = Merker()
        withObservationTracking { _ = wahl.art } onChange: { m.gemeldet = true }
        wahl.art = .tinte
        #expect(m.gemeldet)
        m.gemeldet = false
        withObservationTracking { _ = wahl.art } onChange: { m.gemeldet = true }
        wahl.art = .tinte   // kein Wechsel, keine Meldung
        #expect(!m.gemeldet)
    }
}

@Suite("Designwechsel: Kontrast")
struct DesignKontrastTests {
    static let neue: [DesignWerte] = [.tinte, .salon]

    @Test("Kontrastformel (WCAG)")
    func formel() {
        #expect(abs(Kontrast.verhaeltnis(0x000000, 0xFFFFFF) - 21) < 0.01)
        #expect(Kontrast.verhaeltnis(0x777777, 0x777777) == 1)
        #expect(Kontrast.verhaeltnis(0x1B1B1F, 0xFBFBF8) == Kontrast.verhaeltnis(0xFBFBF8, 0x1B1B1F))
    }

    @Test("Schrift, Schrift zweit, Hüllen-Akzent und Knopf: mindestens 4,5:1 in hell und dunkel", arguments: neue)
    func rollen(w: DesignWerte) throws {
        let seite = try #require(w.seitenGrund), karte = try #require(w.kartenGrund), feld = try #require(w.feldGrund)
        let schrift = try #require(w.schrift), zweit = try #require(w.schriftZweit)
        let knopf = try #require(w.knopf), aufKnopf = try #require(w.schriftAufKnopf)
        for dunkel in [false, true] {
            func h(_ p: FarbPaar) -> UInt32 { dunkel ? p.dunkel : p.hell }
            for grund in [seite, karte, feld] {
                #expect(Kontrast.verhaeltnis(h(schrift), h(grund)) >= 4.5, "\(w.art) Schrift, dunkel \(dunkel)")
                #expect(Kontrast.verhaeltnis(h(zweit), h(grund)) >= 4.5, "\(w.art) Schrift zweit, dunkel \(dunkel)")
                #expect(Kontrast.verhaeltnis(h(w.huelleAkzent), h(grund)) >= 4.5, "\(w.art) Hüllen-Akzent, dunkel \(dunkel)")
            }
            #expect(Kontrast.verhaeltnis(h(aufKnopf), h(knopf)) >= 4.5, "\(w.art) Knopf, dunkel \(dunkel)")
            #expect(Kontrast.verhaeltnis(h(w.aufHuelleFlaeche), h(w.huelleFlaeche)) >= 3, "\(w.art) Hüllenfläche, dunkel \(dunkel)")
        }
    }

    @Test("Spielart-Palette: Text ≥ 4,5:1 auf Seiten- und Kartengrund, Schrift auf Fläche ≥ 3:1", arguments: neue)
    func palette(w: DesignWerte) throws {
        let seite = try #require(w.seitenGrund), karte = try #require(w.kartenGrund)
        for (art, f) in try #require(w.palette) {
            #expect(Kontrast.verhaeltnis(f.textHell, seite.hell) >= 4.5 && Kontrast.verhaeltnis(f.textHell, karte.hell) >= 4.5, "\(w.art) \(art) Text hell")
            #expect(Kontrast.verhaeltnis(f.textDunkel, seite.dunkel) >= 4.5 && Kontrast.verhaeltnis(f.textDunkel, karte.dunkel) >= 4.5, "\(w.art) \(art) Text dunkel")
            #expect(Kontrast.verhaeltnis(f.aufFlaecheHell, f.flaecheHell) >= 3, "\(w.art) \(art) Schrift auf Fläche hell")
            #expect(Kontrast.verhaeltnis(f.aufFlaecheDunkel, f.flaecheDunkel) >= 3, "\(w.art) \(art) Schrift auf Fläche dunkel")
            // Kleine Schrift auf der Fläche: die angepasste Fläche erreicht 4,5:1 und bleibt nahe am Original.
            for (fl, auf) in [(f.flaecheHell, f.aufFlaecheHell), (f.flaecheDunkel, f.aufFlaecheDunkel)] {
                let tief = Kontrast.angepasst(flaeche: fl, schrift: auf)
                #expect(Kontrast.verhaeltnis(tief, auf) >= 4.5, "\(w.art) \(art) kleine Schrift")
                if Kontrast.verhaeltnis(fl, auf) >= 4.5 { #expect(tief == fl) }
            }
        }
    }

    @Test("Salon: Sieger-, Niederlage-, Remis- und Spieler-Seite lesbar (≥ 4,5:1)")
    func salonSeiten() throws {
        let s = DesignWerte.salon
        for seite in [try #require(s.siegerSeite), try #require(s.niederlageSeite), try #require(s.remisSeite), try #require(s.spielerSeite)] {
            #expect(Kontrast.verhaeltnis(seite.flaeche, seite.schrift) >= 4.5)
        }
        #expect(s.siegerSeite?.flaeche == 0x7A2E3D && s.spielerSeite?.flaeche == 0xD9A441)
    }
}

@Suite("Designwechsel: Bausteine")
struct DesignBausteinTests {
    @Test("Fläche für kleine Schrift: nur so weit verschoben wie nötig, Richtung stimmt")
    func angepassteFlaeche() {
        // Terrakotta mit Creme-Schrift (3,68:1) wird abgedunkelt, Senf mit Espresso (7,68:1) bleibt.
        let terrakotta = Kontrast.angepasst(flaeche: 0xC8553D, schrift: 0xF3EBDD)
        #expect(terrakotta != 0xC8553D && Kontrast.leuchtdichte(terrakotta) < Kontrast.leuchtdichte(0xC8553D))
        #expect(Kontrast.verhaeltnis(terrakotta, 0xF3EBDD) >= 4.5 && Kontrast.verhaeltnis(terrakotta, 0xF3EBDD) < 4.9)
        #expect(Kontrast.angepasst(flaeche: 0xD9A441, schrift: 0x1E1A17) == 0xD9A441)
        // Dunkle Schrift auf zu dunkler Fläche: die Fläche wird heller.
        let petrol = Kontrast.angepasst(flaeche: 0x3F8A8F, schrift: 0x1E1A17)
        #expect(Kontrast.leuchtdichte(petrol) > Kontrast.leuchtdichte(0x3F8A8F) && Kontrast.verhaeltnis(petrol, 0x1E1A17) >= 4.5)
    }

    @Test("Schrift-Rollen: klar bleibt bei den heutigen Größen")
    func schriftRollen() {
        #expect(Design.Schrift.titel == 56 && Design.Schrift.titelLaufweite(56) == -0.03 * 56)
        #expect(Design.Schrift.labelSperrung == 0)
        #expect(Design.Schrift.skaliert(20, hoechstens: 1.0) == 20)   // Obergrenze greift
    }

    @Test("Knopf- und Hüllenfarben der neuen Designs sind vollständig")
    func knopfFarben() {
        for w in [DesignWerte.tinte, .salon] {
            #expect(w.knopf != nil && w.schriftAufKnopf != nil && w.knopfRand > 0 && w.linienStaerke == 1)
        }
        #expect(DesignWerte.klar.knopfRand == 0)
        #expect(DesignWerte.salon.huelleFlaeche == FarbPaar(0xC8553D) && DesignWerte.salon.huelleAkzent == FarbPaar(0x9E3E2A, 0xE88D78))
        #expect(DesignWerte.tinte.huelleFlaeche == FarbPaar(0x1B1B1F, 0xEDEDE8))
    }
}

struct DesignVoreinstellungTests {
    @Test("Ohne Wahl gilt die Voreinstellung der App; eine gespeicherte Wahl (auch klar) bleibt")
    func voreinstellung() {
        let name = "klarglas-test-\(UUID().uuidString)"
        let a = UserDefaults(suiteName: name)!
        defer { a.removePersistentDomain(forName: name) }
        #expect(DesignWahl.gespeichert(in: a, fallsLeer: .tinte) == .tinte)
        a.set("klar", forKey: DesignWahl.schluessel)
        #expect(DesignWahl.gespeichert(in: a, fallsLeer: .tinte) == .klar)
        a.set("salon", forKey: DesignWahl.schluessel)
        #expect(DesignWahl.gespeichert(in: a, fallsLeer: .tinte) == .salon)
        a.set("neon", forKey: DesignWahl.schluessel)
        #expect(DesignWahl.gespeichert(in: a, fallsLeer: .tinte) == .tinte)
    }
}
