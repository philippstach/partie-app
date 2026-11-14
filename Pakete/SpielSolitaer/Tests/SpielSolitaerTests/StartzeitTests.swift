// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SpielSolitaer

/// Misst, wie lange der Start dauert (Ziel: Tisch in unter 0,5 s sichtbar; hier die Teile, die vor dem ersten Bild laufen)
@MainActor
final class StartzeitTests: XCTestCase {
    private func ms(_ block: () -> Void) -> Double {
        let t = CFAbsoluteTimeGetCurrent()
        block()
        return (CFAbsoluteTimeGetCurrent() - t) * 1000
    }

    func testKatalogLadenIstSchnell() {
        let listen = ms { _ = DealCatalog.load() }
        print("STARTZEIT Listen laden: \(Int(listen)) ms")
        XCTAssertLessThan(listen, 250, "Listen laden dauert zu lange")
    }

    func testAppModelStartMitSpielstand() {
        let folder = FileManager.default.temporaryDirectory.appending(path: "start-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let prefs = AppPreferences(defaults: UserDefaults(suiteName: "sz-\(UUID().uuidString)")!, photoFolder: folder)
        prefs.welcomeSeen = true
        _ = DealCatalog.shared                       // zählt zum Start (statische Konstante), hier schon einmal geladen
        let t = ms {
            let app = AppModel(prefs: prefs, stats: StatsStore(url: folder.appending(path: "statistik.json")), folder: folder)
            _ = app.session
        }
        print("STARTZEIT AppModel + Statistik: \(Int(t)) ms")
        XCTAssertLessThan(t, 200)
    }

    func testLoesungenWerdenNichtBeimStartGeladen() {
        // Die Lösungsdateien (Ordner „loesungen“) liest nur SolutionLibrary – und nur beim Ansehen einer Lösung
        let t = ms { _ = SolutionLibrary.hasSolution(for: DealInfo(seed: 1, mode: .klondike(1), kind: .solvable)) }
        XCTAssertLessThan(t, 50, "hasSolution darf nur die schon geladenen Listen nutzen")
    }
}
