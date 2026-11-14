// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Testing
import CoreGraphics
@testable import SpielViererreihe

@Suite("Layout und Ausrichtung")
struct LayoutTests {
    @Test func layoutNachBreiteNichtNachGeraet() {
        #expect(Layout.entscheide(breite: 400, hoehe: 800, kompakteBreite: true) == .kompakt)
        #expect(Layout.entscheide(breite: 320, hoehe: 1000, kompakteBreite: true) == .kompakt, "iPad in schmalem Split View")
        #expect(Layout.entscheide(breite: 820, hoehe: 1180, kompakteBreite: false) == .breitHoch)
        #expect(Layout.entscheide(breite: 1180, hoehe: 820, kompakteBreite: false) == .breitQuer)
        #expect(Layout.entscheide(breite: 700, hoehe: 700, kompakteBreite: false) == .breitHoch, "quadratisch zählt als hoch")
    }

    @Test func massFunktionen() {
        #expect(Layout.brettKante(verfuegbareBreite: 1000, verfuegbareHoehe: 1500) == 720)
        #expect(Layout.brettKante(verfuegbareBreite: 600, verfuegbareHoehe: 500) == 500)
        #expect(Layout.brettKante(verfuegbareBreite: -5, verfuegbareHoehe: 500) == 0)
        #expect(Layout.seitenleiste(breite: 900) == 320)
        #expect(Layout.seitenleiste(breite: 1100) > 320 && Layout.seitenleiste(breite: 1100) < 380)
        #expect(Layout.seitenleiste(breite: 2000) == 380)
        #expect(Layout.kachelSpalten(breite: 300, kachel: 52, abstand: 8) == 5)
        #expect(Layout.kachelSpalten(breite: 10, kachel: 52, abstand: 8) == 1)
    }

    @Test func ausrichtungOhneZweispielerPartie() {
        #expect(erlaubteAusrichtungen(geraet: .iPhone, sitzordnung: nil, aktuell: .portrait) == .portrait)
        #expect(erlaubteAusrichtungen(geraet: .iPhone, sitzordnung: .nebeneinander, aktuell: .landscapeLeft) == .portrait)
        #expect(erlaubteAusrichtungen(geraet: .iPad, sitzordnung: nil, aktuell: .landscapeRight) == .alle)
        #expect(erlaubteAusrichtungen(geraet: .iPad, sitzordnung: .nebeneinander, aktuell: .portrait) == .alle)
    }

    @Test func ausrichtungGegenueber() {
        #expect(erlaubteAusrichtungen(geraet: .iPhone, sitzordnung: .gegenueber, aktuell: .portrait) == .portrait)
        #expect(erlaubteAusrichtungen(geraet: .iPad, sitzordnung: .gegenueber, aktuell: .portraitUpsideDown) == .portraitUpsideDown,
                "in der aktuellen Hochformat-Lage")
        #expect(erlaubteAusrichtungen(geraet: .iPad, sitzordnung: .gegenueber, aktuell: .landscapeLeft) == .portrait,
                "aus dem Querformat ins Hochformat")
    }

    @Test func ausrichtungSeitlich() {
        #expect(erlaubteAusrichtungen(geraet: .iPhone, sitzordnung: .seitlich, aktuell: .portrait) == .quer)
        #expect(erlaubteAusrichtungen(geraet: .iPhone, sitzordnung: .seitlich, aktuell: .landscapeRight) == .landscapeRight)
        #expect(erlaubteAusrichtungen(geraet: .iPad, sitzordnung: .seitlich, aktuell: .landscapeLeft) == .landscapeLeft)
        #expect(erlaubteAusrichtungen(geraet: .iPad, sitzordnung: .seitlich, aktuell: .portrait) == .quer)
    }
}
