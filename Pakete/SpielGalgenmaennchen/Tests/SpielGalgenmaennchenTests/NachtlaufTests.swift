// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import SpielGalgenmaennchen

@MainActor
struct NachtlaufTests {
    @Test func beschaedigteSpielstandDateiWirdGesichertStattUeberschrieben() throws {
        let ordner = FileManager.default.temporaryDirectory.appending(path: "galgen-nacht-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: ordner, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: ordner) }
        let datei = ordner.appending(path: "galgen.json")
        try Data("{ kaputt".utf8).write(to: datei)
        #expect(GameRepository(url: datei).load() == SaveData())
        let uebrig = try FileManager.default.contentsOfDirectory(atPath: ordner.path)
        #expect(uebrig.contains { $0.hasPrefix("galgen.corrupt-") }, "Sicherungskopie fehlt: \\(uebrig)")
        #expect(!uebrig.contains("galgen.json"))
    }

    @Test func platzierungenBeiGleichstand() {
        #expect(PartyMatch.places([23, 12, 12]) == [1, 2, 2])
        #expect(PartyMatch.places([12, 23, 12, 5]) == [2, 1, 2, 4])
        #expect(PartyMatch.places([10, 10, 10]) == [1, 1, 1])
        #expect(PartyMatch.places([5, 3]) == [1, 2])
    }

    @Test func tagesKeyGregorianischBeiBuddhistischemKalender() {
        let datum = Date(timeIntervalSince1970: 1_793_000_000)
        var buddhistisch = Calendar(identifier: .buddhist)
        buddhistisch.timeZone = .current
        #expect(DayKey.string(for: datum).hasPrefix("2026"))
        #expect(DayKey.string(for: datum, calendar: buddhistisch).hasPrefix("2569"))
    }
}
