// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import XCTest
import SwiftUI
import UIKit
import KlarGlas
import Baukasten
import SpieleKern
import KoenigswegKern
import MaexchenKern
import HerzensjagdKern
import RommeKern
import MogelnKern
import PokerwurfKern
import DesignBilder
import FarbflutKern
import MinensucheKern
@testable import SpielFarbflut
@testable import SpielKoenigsweg
@testable import SpielMinensuche
@testable import SpielWortpfeil
@testable import SpielMauMau
@testable import SpielSchwimmen
@testable import SpielElferRaus
@testable import SpielSiebzehn
@testable import SpielMaexchen
@testable import SpielChicago
@testable import SpielPokerwurf
@testable import SpielRauswurf
@testable import SpielGalgenmaennchen
@testable import SpielHerzensjagd
@testable import SpielRomme
@testable import SpielMogeln

struct FesterZufall: RandomNumberGenerator {
    var z: UInt64
    init(_ s: UInt64) { z = s }
    mutating func next() -> UInt64 { z &+= 0x9E3779B97F4A7C15; var x = z; x = (x ^ (x >> 30)) &* 0xBF58476D1CE4E5B9; x = (x ^ (x >> 27)) &* 0x94D049BB133111EB; return x ^ (x >> 31) }
}

/// Designwechsel Block 2: Spielbilder mit Spielmaterial im Zug (Würfel, Münzen, Galgen mit Figur und Wortanzeige), drei Designs, hell und dunkel.
@MainActor
final class SpielZugBilder: XCTestCase {
    private let anna = SpielTeilnehmer(name: "Anna"), ben = SpielTeilnehmer(name: "Ben", computer: true)   // nur ein Mensch: kein Sichtschutz

    private func szene<V: View>(_ name: String, _ gattung: Gattung, warm: Bool = true, _ ansicht: () -> V) {
        KlarGlasHaken.spielart = { gattung.designSpielart }
        KlarGlasHaken.flaeche = { gattung.farbe.color }
        KlarGlasHaken.accentText = { gattung.farbe.textFarbe }
        if warm { _ = ImageRenderer(content: ansicht().frame(width: 390, height: 844)).uiImage }   // richtet unter Mac Catalyst die App-Umgebung ein (Minensuche: NavigationStack stürzt im ImageRenderer ab, läuft nach den anderen)
        for d in DesignArt.allCases {
            Design.art = d   // vor dem Aufbau der Ansicht: Farben und Tint kommen aus dem Design
            for dunkel in Aufnahme.toene {
                var b: UIImage?
                do { b = Aufnahme.fensterBild(ansicht().tint(gattung.farbe.color), design: d, dunkel: dunkel) }
                XCTAssertTrue(Aufnahme.schreiben(b, name: Aufnahme.name(d, dunkel: dunkel, "spiel-" + name)))
                print("BILD spiel-\(name) \(d.rawValue) \(dunkel) Inhalt \(String(format: "%.3f", Aufnahme.inhaltAnteil(b)))")
            }
        }
        Design.art = .klar
    }

    func testMaexchenImZug() {
        var m = Maexchen(spieler: 2); m.setzeWurf(5, 3)
        szene("maexchen-zug", .wuerfel) { MaexchenSpiel(teilnehmer: [anna, ben], ende: { _ in }, abbrechen: {}, quelle: .app, vorgabe: m) }
    }
    func testPokerwurfImZug() {
        var p = Pokerwurf(spieler: 2); var g = FesterZufall(7)   // gleiche Würfel in jedem Lauf (Bildvergleich)
        p.wuerfeln(mit: &g); p.halte(0); p.halte(3)
        szene("pokerwurf-zug", .wuerfel) { PokerwurfSpiel(teilnehmer: [anna, ben], ende: { _ in }, abbrechen: {}, quelle: .app, vorgabe: p) }
    }
    func testKoenigswegImZug() {
        let k = Koenigsweg(steine: [[4, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1], [5, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0]], amZug: 0, wurf: 3)
        szene("koenigsweg-zug", .wuerfel) { KoenigswegSpiel(teilnehmer: [anna, ben], ende: { _ in }, abbrechen: {}, imBrett: true, vorgabe: k) }
    }
    func testHerzensjagd() {
        var z = FesterZufall(11)   // feste Hände: Bildvergleich der ganzen Szene
        let h = Herzensjagd(mit: &z)
        szene("herzensjagd-zug", .karten) { HerzensjagdSpiel(teilnehmer: [anna, ben, SpielTeilnehmer(name: "Cem", computer: true), SpielTeilnehmer(name: "Dana", computer: true)], ende: { _ in }, abbrechen: {}, vorgabe: h) }
    }
    func testRommeMitte() {
        // Anna hat gezogen und gelegt: Tisch mit Satz und Folge, Hand mit Joker, Ablage mit offener Karte.
        let r = Romme(haende: [[RKarte(0, 2, 1), RKarte(1, 5, 1), RKarte(2, 9, 1), RKarte(3, 11, 1), RKarte(0, 13, 1), RKarte(1, 3, 1), RKarte(0, 0, 1), RKarte(2, 4, 1)],
                               [RKarte(1, 8, 2), RKarte(2, 10, 2), RKarte(3, 1, 2), RKarte(0, 6, 2), RKarte(1, 12, 2), RKarte(3, 7, 2), RKarte(2, 2, 2)]],
                      stapel: (1...20).map { RKarte($0 % 4, ($0 % 13) + 1, 3) }, ablage: [RKarte(3, 9, 2)],
                      tisch: [[RKarte(0, 7, 1), RKarte(1, 7, 1), RKarte(2, 7, 1)], [RKarte(3, 4, 1), RKarte(3, 5, 1), RKarte(3, 6, 1), RKarte(3, 7, 1)]],
                      hatAusgelegt: [true, true], dran: 0, gezogen: true)
        szene("romme-mitte", .karten) { RommeSpiel(teilnehmer: [anna, ben], ende: { _ in }, abbrechen: {}, vorgabe: r) }
    }
    func testMogelnMitte() {
        // Ben (Computer) hat zwei Karten verdeckt gelegt und behauptet „9“; Anna muss glauben oder anzweifeln.
        var m = Mogeln(haende: [[MoKarte(0, 7), MoKarte(1, 8), MoKarte(2, 9), MoKarte(3, 10), MoKarte(0, 11), MoKarte(1, 12), MoKarte(2, 13)],
                                [MoKarte(1, 9), MoKarte(2, 9), MoKarte(3, 7), MoKarte(0, 14), MoKarte(1, 11), MoKarte(2, 12), MoKarte(3, 13), MoKarte(0, 8)]], dran: 1, rang: 9)
        m.lege([0, 2])
        szene("mogeln-mitte", .karten) { MogelnSpiel(teilnehmer: [anna, ben], ende: { _ in }, abbrechen: {}, vorgabe: m) }
    }
    func testGalgenLaeuft() {
        var g = Game(solution: "BALLON", language: .de, difficulty: nil, displayText: "Ballon")
        for c in ["A", "L", "E", "X", "Q"] { _ = g.guess(c) }
        let stand = NeuStand(modus: .single, sprache: .de, game: g)
        szene("galgen-lauf", .wort) { NeuSpielView(stand: .constant(stand), abbrechen: {}, weiter: {}) }
    }
}
#endif
