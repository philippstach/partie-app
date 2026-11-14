// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import XCTest
import SwiftUI
import UIKit
import KlarGlas
import DesignBilder
@testable import SpielWortpfeil

/// Klar-Vergleich Designwechsel: Kreuzworträtsel-Spielbild (Rätsel aus App/Ressourcen/raetsel, Starthilfe aus, ein aufgedeckter Buchstabe)
/// in „Klar & Glas“, hell und dunkel, als PNG nach `$KLAR_ZIEL` (`TEST_RUNNER_KLAR_ZIEL`). Läuft unverändert im alten und im neuen Stand.
@MainActor
final class KlarSpielTests: XCTestCase {
    func testSpielbild() throws {
        guard let ziel = ProcessInfo.processInfo.environment["KLAR_ZIEL"], !ziel.isEmpty else { return }
        var u = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { u.deleteLastPathComponent() }     // …/Arbeit/Pakete/SpielWortpfeil/Tests/WortpfeilKlarTests/<Datei> → Arbeit
        let raetsel = u.appending(path: "App/Ressourcen/raetsel")
        XCTAssertTrue(FileManager.default.fileExists(atPath: raetsel.path), "Rätsel-Ordner fehlt: \(raetsel.path)")
        let url = FileManager.default.temporaryDirectory.appending(path: "klar-kreuzwort.json")
        try? FileManager.default.removeItem(at: url)
        let prefs = AppPreferences(defaults: UserDefaults(suiteName: "klar-kreuzwort")!)
        prefs.showErrors = false; prefs.showTimer = true; prefs.introSeen = true
        // Feste Uhr für gleichbleibende Bilder: 4. Oktober 2026, 12:00 in Berlin
        var kalender = Calendar(identifier: .gregorian)
        kalender.timeZone = TimeZone(identifier: "Europe/Berlin")!
        let noon = Day(2026, 10, 4).date(calendar: kalender)
        let store = GameStore(repository: GameRepository(url: url), preferences: prefs, library: PackLibrary(directory: raetsel), calendar: kalender, now: { noon })
        store.freezeTime = true
        store.startNewGame(.mittel)
        store.revealLetter()
        try FileManager.default.createDirectory(atPath: ziel, withIntermediateDirectories: true)
        _ = ImageRenderer(content: GameView().environment(store).frame(width: 390, height: 844)).uiImage   // richtet unter Mac Catalyst die App-Umgebung ein
        for dunkel in [false, true] {
            let b = Aufnahme.fensterBild(GameView().environment(store).tint(Color.kwAkzent), design: .klar, dunkel: dunkel)
            let daten = try XCTUnwrap(b?.pngData())
            XCTAssertGreaterThan(Aufnahme.inhaltAnteil(b), 0.05, "leeres Bild")
            try daten.write(to: URL(fileURLWithPath: ziel).appendingPathComponent("kreuzwort-spiel-\(dunkel ? "dunkel" : "hell").png"))
        }
    }
}
#endif
