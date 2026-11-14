// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Testing
@testable import SpielWortpfeil

/// Rechnet die Farbpaare des Kreuzworträtsels nach (WCAG): kleiner Text mindestens 4,5:1, große Zeichen und Flächen mindestens 3:1.
/// Jede Prüfung läuft für hell und dunkel.
struct FarbKontrastTests {
    private func beide(_ vorn: KwFarbe.Paar, _ hinten: KwFarbe.Paar) -> [Double] {
        [KwFarbe.kontrast(vorn.hell, hinten.hell), KwFarbe.kontrast(vorn.dunkel, hinten.dunkel)]
    }

    @Test func fragetextImFragefeld() {
        for k in beide(KwFarbe.frageTinte, KwFarbe.feldFrage) { #expect(k >= 7) }   // kleinste Schrift der App
    }

    @Test func aktiveFrageInvertiert() {
        for k in beide(KwFarbe.aufAkzent, KwFarbe.akzent) { #expect(k >= 4.5) }
    }

    @Test func akzentAlsTextAufKarteFeldUndSeite() {
        for grund in [KwFarbe.karte, KwFarbe.feldLeer, KwFarbe.feldFrage, KwFarbe.papier] {
            for k in beide(KwFarbe.akzent, grund) { #expect(k >= 4.5) }
        }
    }

    @Test func heldenkarte() {
        for k in beide(KwFarbe.aufHeld, KwFarbe.held) { #expect(k >= 4.5) }
        // Nebentext mit 85 % Deckkraft
        let hell = KwFarbe.gemischt(KwFarbe.aufHeld.hell, ueber: KwFarbe.held.hell, deckkraft: 0.85)
        let dunkel = KwFarbe.gemischt(KwFarbe.aufHeld.dunkel, ueber: KwFarbe.held.dunkel, deckkraft: 0.85)
        #expect(KwFarbe.kontrast(hell, KwFarbe.held.hell) >= 4.5)
        #expect(KwFarbe.kontrast(dunkel, KwFarbe.held.dunkel) >= 4.5)
        // „Spielen“-Pille: Heldenfarbe auf Weiß
        for k in beide(KwFarbe.held, KwFarbe.aufHeld) { #expect(k >= 4.5) }
    }

    @Test func buchstabenAufMarkierung() {
        // Tinte (schwarz/weiß) auf Wort- und Cursor-Markierung
        let tinte = KwFarbe.Paar(hell: 0x000000, dunkel: 0xFFFFFF)
        let wort = KwFarbe.Paar(hell: KwFarbe.gemischt(KwFarbe.akzent.hell, ueber: KwFarbe.feldLeer.hell, deckkraft: KwFarbe.wortMarkierung.hell),
                                dunkel: KwFarbe.gemischt(KwFarbe.akzent.dunkel, ueber: KwFarbe.feldLeer.dunkel, deckkraft: KwFarbe.wortMarkierung.dunkel))
        let cursor = KwFarbe.Paar(hell: KwFarbe.gemischt(KwFarbe.akzent.hell, ueber: KwFarbe.feldLeer.hell, deckkraft: KwFarbe.cursorMarkierung.hell),
                                  dunkel: KwFarbe.gemischt(KwFarbe.akzent.dunkel, ueber: KwFarbe.feldLeer.dunkel, deckkraft: KwFarbe.cursorMarkierung.dunkel))
        for k in beide(tinte, wort) + beide(tinte, cursor) { #expect(k >= 7) }
        // Cursor hebt sich vom markierten Wort und vom leeren Feld ab
        for k in beide(cursor, KwFarbe.feldLeer) { #expect(k >= 1.5) }
    }

    @Test func bleistiftUndFehlerLesbar() {
        let stiftHell = KwFarbe.gemischt(0x000000, ueber: KwFarbe.feldLeer.hell, deckkraft: KwFarbe.bleistift)
        let stiftDunkel = KwFarbe.gemischt(0xFFFFFF, ueber: KwFarbe.feldLeer.dunkel, deckkraft: KwFarbe.bleistift)
        #expect(KwFarbe.kontrast(stiftHell, KwFarbe.feldLeer.hell) >= 4.5)
        #expect(KwFarbe.kontrast(stiftDunkel, KwFarbe.feldLeer.dunkel) >= 4.5)
        // Falsche Buchstaben auf dem zart rot getönten Feld
        let grundHell = KwFarbe.gemischt(KwFarbe.fehler.hell, ueber: KwFarbe.feldLeer.hell, deckkraft: 0.14)
        let grundDunkel = KwFarbe.gemischt(KwFarbe.fehler.dunkel, ueber: KwFarbe.feldLeer.dunkel, deckkraft: 0.14)
        #expect(KwFarbe.kontrast(KwFarbe.fehler.hell, grundHell) >= 4.5)
        #expect(KwFarbe.kontrast(KwFarbe.fehler.dunkel, grundDunkel) >= 4.5)
    }

    @Test func gitterlinienUndFelderUnterscheidbar() {
        for k in beide(KwFarbe.linie, KwFarbe.feldLeer) { #expect(k >= 2) }
        for k in beide(KwFarbe.feldSperre, KwFarbe.feldLeer) { #expect(k >= 1.15) }
        for k in beide(KwFarbe.akzent, KwFarbe.papier) { #expect(k >= 3) }   // Rahmen des Gitters
    }
}
