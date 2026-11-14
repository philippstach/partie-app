// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import SpielSchocken

@Suite("Stabilität")
struct StabilitaetTests {
    @Test func frischerZustandIstStimmig() {
        let z = Spielzustand(namen: ["A", "B", "C"], strategien: [.mensch, .gut, .einfach], optionen: .standard, beginner: 1)
        #expect(z.istStimmig)
    }

    @Test func beschaedigterZustandWirdErkannt() {
        var z = Spielzustand(namen: ["A", "B"], strategien: [.mensch, .gut], optionen: .standard, beginner: 0)
        z.strategien = [.mensch]
        #expect(!z.istStimmig)
        z = Spielzustand(namen: ["A", "B"], strategien: [.mensch, .gut], optionen: .standard, beginner: 0)
        z.runde.position = 7
        #expect(!z.istStimmig)
        z = Spielzustand(namen: ["A", "B"], strategien: [.mensch, .gut], optionen: .standard, beginner: 0)
        z.haelfte.stock = 5     // Deckel gehen verloren
        #expect(!z.istStimmig)
        z = Spielzustand(namen: ["A", "B"], strategien: [.mensch, .gut], optionen: .standard, beginner: 0)
        z.phase = .nachWurf     // kein laufender Zug
        #expect(!z.istStimmig)
    }

    @Test func zustandMittenImZugBleibtStimmig() throws {
        var q = SeedQuelle(seed: 3)
        var z = Spielzustand(namen: ["A", "B"], strategien: [.mensch, .gut], optionen: .standard, beginner: 0)
        z.wuerfeln(&q)
        #expect(z.istStimmig)
        let daten = try JSONEncoder().encode(Spielstand(zustand: z, quelle: q))
        let neu = try JSONDecoder().decode(Spielstand.self, from: daten)
        #expect(neu.zustand == z && neu.zustand.istStimmig)
    }

    @Test func repositoryLegtDefekteDateiZurSeite() throws {
        let ordner = FileManager.default.temporaryDirectory.appending(path: "schocken-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: ordner, withIntermediateDirectories: true)
        let repo = GameRepository(url: ordner.appending(path: "spielstand.json"))
        try Data("{kaputt".utf8).write(to: repo.url)
        #expect(repo.laden() == nil)
        #expect(!FileManager.default.fileExists(atPath: repo.url.path))
        #expect(FileManager.default.fileExists(atPath: ordner.appending(path: "spielstand-defekt.json").path))

        // gültiger Stand wird geladen
        let z = Spielzustand(namen: ["A", "B"], strategien: [.mensch, .gut], optionen: .standard, beginner: 0)
        try repo.speichern(Spielstand(zustand: z, quelle: SeedQuelle(seed: 1)))
        #expect(repo.laden()?.zustand == z)

        // lesbar, aber unstimmig (Spieler fehlen)
        var kaputt = z
        kaputt.strategien = []
        try repo.speichern(Spielstand(zustand: kaputt, quelle: SeedQuelle(seed: 1)))
        #expect(repo.laden() == nil)
    }
}
