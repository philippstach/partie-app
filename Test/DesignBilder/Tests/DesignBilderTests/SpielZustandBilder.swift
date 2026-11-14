// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import XCTest
import SwiftUI
import UIKit
import KlarGlas
import Baukasten
import SpieleKern
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

/// Designwechsel D4 (3): das echte Spielbild jedes Startspiels mit einem Spielzustand, drei Designs, hell und dunkel
/// (Bilder `<design>-<hell|dunkel>-spiel-<spiel>.png`). Erst über `ImageRenderer`; bleibt das Bild leer (ScrollView, NavigationStack), über das Fenster.
@MainActor
final class SpielZustandBilder: XCTestCase {
    private let anna = SpielTeilnehmer(name: "Anna"), ben = SpielTeilnehmer(name: "Ben")

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

    func testFarbflut() {
        var g = SystemRandomNumberGenerator()
        let f = Farbflut(groesse: 8, farben: 4, luft: 4, mit: &g)
        szene("farbflut", .raetsel) { FarbflutSpiel(name: "Anna", ende: { _ in }, abbrechen: {}, vorgabe: f) }
    }
    func testKoenigsweg() {
        szene("koenigsweg", .wuerfel) { KoenigswegSpiel(teilnehmer: [anna, ben], ende: { _ in }, abbrechen: {}, imBrett: true) }
    }
    func testMinensuche() throws {
        let ordner = URL.applicationSupportDirectory.appending(path: "Minensuche", directoryHint: .isDirectory)
        let vorhanden = FileManager.default.fileExists(atPath: ordner.path)
        let m = SpielModell()
        m.neu(.leicht)
        m.aufdecken(Position(zeile: 3, spalte: 3))
        szene("minensuche", .raetsel, warm: false) { SpielView(abbrechen: {}).environment(m) }
        if !vorhanden { try? FileManager.default.removeItem(at: ordner) }
        SpielStand.loeschen(SpielModell.standKennung)
    }
    func testWortpfeil() throws {
        var u = URL(fileURLWithPath: #filePath)
        for _ in 0..<4 { u.deleteLastPathComponent() }     // …/Arbeit/Test/DesignBilder/Tests/DesignBilderTests → Arbeit
        let raetsel = u.deletingLastPathComponent().appending(path: "App/Ressourcen/raetsel")
        XCTAssertTrue(FileManager.default.fileExists(atPath: raetsel.path), "Rätsel-Ordner fehlt")
        let url = FileManager.default.temporaryDirectory.appending(path: "dw-kreuzwort.json")
        try? FileManager.default.removeItem(at: url)
        let prefs = SpielWortpfeil.AppPreferences(defaults: UserDefaults(suiteName: "dw-kreuzwort")!)
        prefs.introSeen = true
        let store = SpielWortpfeil.GameStore(repository: SpielWortpfeil.GameRepository(url: url), preferences: prefs, library: SpielWortpfeil.PackLibrary(directory: raetsel))
        store.startNewGame(.mittel)
        store.revealLetter()
        szene("kreuzwort", .wort) { SpielWortpfeil.GameView().environment(store).tint(Color.kwAkzent) }
    }
    func testMauMau() { szene("maumau", .karten) { MauMauNeuSpiel(teilnehmer: [anna, ben], ende: { _ in }, abbrechen: {}) } }
    func testSchwimmen() { szene("schwimmen", .karten) { SchwimmenNeuSpiel(teilnehmer: [anna, ben], ende: { _ in }, abbrechen: {}) } }
    func testElferRaus() { szene("elferraus", .karten) { ElferNeuSpiel(teilnehmer: [anna, ben], ende: { _ in }, abbrechen: {}) } }
    func testSiebzehn() { szene("siebzehn", .karten) { SiebzehnSpiel(teilnehmer: [anna, ben], ende: { _ in }, abbrechen: {}) } }
    func testMaexchen() { szene("maexchen", .wuerfel) { MaexchenSpiel(teilnehmer: [anna, ben], ende: { _ in }, abbrechen: {}, quelle: .app) } }
    func testChicago() { szene("chicago", .wuerfel) { ChicagoSpiel(teilnehmer: [anna, ben], ende: { _ in }, abbrechen: {}, quelle: .app) } }
    func testPokerwurf() { szene("pokerwurf", .wuerfel) { PokerwurfSpiel(teilnehmer: [anna, ben], ende: { _ in }, abbrechen: {}, quelle: .app) } }
    func testRauswurf() { szene("rauswurf", .brett) { RauswurfNeuWurzel(teilnehmer: [anna, ben], ende: { _ in }, abbrechen: {}) } }
    func testRauswurfBrett() {
        let repo = SpielRauswurf.GameRepository(url: FileManager.default.temporaryDirectory.appending(path: "dw-rauswurf.json"))
        repo.loeschen()
        let store = SpielRauswurf.GameStore(repository: repo)
        let prefs = SpielRauswurf.AppPreferences(defaults: UserDefaults(suiteName: "dw-rauswurf") ?? .standard)
        store.neuePartie(spieler: [SpielRauswurf.Spieler(name: "Anna", avatar: "😎", strategie: .mensch, sitz: 0), SpielRauswurf.Spieler(name: "Ben", avatar: "🤠", strategie: .mensch, sitz: 2)],
                         optionen: SpielRauswurf.Spielart.schnell.optionen)
        let spiel = SpielController(store: store, prefs: prefs)
        szene("rauswurf-brett", .brett) { SpielRauswurf.NeuSpielView(abbrechen: {}).environment(store).environment(prefs).environment(spiel).environment(\.brettTheme, BrettTheme.fuerDesign(.standard)) }
    }
    /// Rauswurf-Brett mitten im Spiel: einige Züge beider Spieler sind gespielt (Würfel zufällig, erster erlaubter Zug).
    func testRauswurfMitte() {
        let repo = SpielRauswurf.GameRepository(url: FileManager.default.temporaryDirectory.appending(path: "dw-rauswurf-mitte.json"))
        repo.loeschen()
        let store = SpielRauswurf.GameStore(repository: repo)
        let prefs = SpielRauswurf.AppPreferences(defaults: UserDefaults(suiteName: "dw-rauswurf-mitte") ?? .standard)
        store.neuePartie(spieler: [SpielRauswurf.Spieler(name: "Anna", avatar: "😎", strategie: .mensch, sitz: 0), SpielRauswurf.Spieler(name: "Ben", avatar: "🤠", strategie: .mensch, sitz: 2)],
                         optionen: SpielRauswurf.Spielart.schnell.optionen)
        for _ in 0..<60 {
            guard let z = store.zustand else { break }
            if z.phase == .vorWurf { store.wuerfeln() }
            else if z.phase == .wahl, let zug = z.partie.spielzug.erlaubt.first { store.ziehe(zug) }
            else { store.verfallenWeiter() }
        }
        let spiel = SpielController(store: store, prefs: prefs)
        szene("rauswurf-mitte", .brett) { SpielRauswurf.NeuSpielView(abbrechen: {}).environment(store).environment(prefs).environment(spiel).environment(\.brettTheme, BrettTheme.fuerDesign(.standard)) }
    }
    func testGalgen() { szene("galgen", .wort) { NeuSpiel(teilnehmer: [anna], ende: { _ in }, abbrechen: {}) } }
}
#endif
