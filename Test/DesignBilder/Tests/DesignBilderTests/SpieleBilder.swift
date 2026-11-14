// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import XCTest
import SwiftUI
import UIKit
import KlarGlas
import SpieleKern
import DesignBilder
@testable import SpielSchiebepuzzle
@testable import SpielFarbflut
@testable import SpielKoenigsweg
@testable import SpielMinensuche
@testable import SpielWortpfeil

/// Designwechsel D4 (3): Belegbilder der Rätsel- und Würfelspiele, die nur Rollen aus dem Baukasten lesen und deren Spielmaterial
/// feste Farben hat (Schiebepuzzle, Farbflut, Königsweg, Minensuche, Kreuzworträtsel). Startbild jedes Spiels, drei Designs, hell und dunkel.
@MainActor
final class SpieleBilder: XCTestCase {
    private func szene<V: View>(_ name: String, warm: Bool = true, _ ansicht: @autoclosure () -> V) {
        if warm { _ = ImageRenderer(content: ansicht().frame(width: 390, height: 844)).uiImage }   // richtet unter Mac Catalyst die App-Umgebung ein (Wurzeln mit NavigationStack laufen nach den anderen Szenen, ohne ImageRenderer)
        for d in DesignArt.allCases {
            for dunkel in Aufnahme.toene {
                let b = Aufnahme.fensterBild(ansicht(), design: d, dunkel: dunkel)
                XCTAssertTrue(Aufnahme.schreiben(b, name: Aufnahme.name(d, dunkel: dunkel, name)))
                print("BILD \(name) \(d.rawValue) \(dunkel) Inhalt \(Aufnahme.inhaltAnteil(b))")
            }
        }
        Design.art = .klar
    }

    func testSchiebepuzzle() { szene("schiebepuzzle", SchiebepuzzleSpiel(name: "Anna", ende: { _ in }, abbrechen: {})) }
    func testFarbflut() { szene("farbflut", FarbflutSpiel(name: "Anna", ende: { _ in }, abbrechen: {})) }
    func testKoenigsweg() {
        szene("koenigsweg", KoenigswegSpiel(teilnehmer: [SpielTeilnehmer(name: "Anna"), SpielTeilnehmer(name: "Ben")], ende: { _ in }, abbrechen: {}))
    }
    func testMinensuche() { szene("minensuche", warm: false, MinensucheNeuSpiel(name: "Anna", ende: { _ in }, abbrechen: {})) }
    func testWortpfeil() { szene("wortpfeil", warm: false, WortpfeilPartie(store: SpielWortpfeil.GameStore(), name: "Anna", ende: { _ in }, abbrechen: {})) }
}
#endif
