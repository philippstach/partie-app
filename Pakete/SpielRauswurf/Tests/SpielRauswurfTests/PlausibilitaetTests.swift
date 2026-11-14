// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import SpielRauswurf
import enum SpieleKern.Avatare

@Suite("Plausibilität und Sicherung")
struct PlausibilitaetTests {
    private static let spieler = [Spieler(name: "A", avatar: Avatare.standard(0), strategie: .mensch, sitz: 0),
                                  Spieler(name: "B", avatar: Avatare.standard(1), strategie: .gut, sitz: 2)]

    private func neu() -> Spielzustand { Spielzustand(spieler: Self.spieler, optionen: .standard, seed: 5) }

    @Test func gueltigerStandIstPlausibel() {
        #expect(neu().istPlausibel)
    }

    @Test func ungueltigeStaendeWerdenErkannt() throws {
        // Spieler am Zug außerhalb des Bereichs
        var z = neu()
        z.partie.amZug = 7
        #expect(!z.istPlausibel)
        // Figur außerhalb des Bretts
        z = neu()
        z.partie.lage.figuren[0][0] = 99
        #expect(!z.istPlausibel)
        // Zugspieler passt nicht zum Spieler am Zug
        z = neu()
        z.partie.spielzug.spieler = 1
        z.partie.amZug = 0
        #expect(!z.istPlausibel)
        // Doppelte Platzierung
        z = neu()
        z.partie.platzierung = [0, 0]
        #expect(!z.istPlausibel)
    }

    @Test func beschaedigtesSpielstandsfileWirdBeiseitegelegtStattAbzustuerzen() throws {
        let ordner = FileManager.default.temporaryDirectory.appending(path: "ludo-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: ordner, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: ordner) }
        let datei = ordner.appending(path: "spielstand.json")
        try Data("{ kaputt".utf8).write(to: datei)
        #expect(GameRepository(url: datei).laden() == nil)
        #expect(!FileManager.default.fileExists(atPath: datei.path))
        #expect(FileManager.default.fileExists(atPath: ordner.appending(path: "spielstand.defekt.json").path))
    }

    @Test func standardnamenFolgenDerSprache() {
        #expect(Spielernamen.istIch("Ich") && Spielernamen.istIch("Me") && Spielernamen.istIch("Yo") && Spielernamen.istIch("Moi"))
        #expect(!Spielernamen.istIch("Anna"))
        #expect(Spielernamen.computer.count == 4)
    }

    @Test func teamsAlsHausregelUeberlebenSpeichern() throws {
        var o = Optionen()
        o.teams = true
        let z = Spielzustand(spieler: Self.spieler, optionen: o, seed: 1)
        let neuGeladen = try JSONDecoder().decode(Spielzustand.self, from: JSONEncoder().encode(z))
        #expect(neuGeladen.optionen.teams)
    }

    /// T-051: Der Teams-Schalter der Neues-Spiel-Karte schreibt über ganz `Optionen` in die Einstellungen; zweimal umschalten, jedes Mal gespeichert.
    @MainActor @Test func teamsSchalterSchreibtZurueckUndSpeichert() throws {
        let suite = "de.philippstach.partie.test-t051"
        let d = try #require(UserDefaults(suiteName: suite))
        d.removePersistentDomain(forName: suite)
        defer { d.removePersistentDomain(forName: suite) }
        let prefs = AppPreferences(defaults: d)
        #expect(!prefs.hausregeln.teams)
        for neu in [true, false, true] {
            var o = prefs.hausregeln; o.teams = neu; prefs.hausregeln = o   // genau das tut der Schalter
            #expect(prefs.hausregeln.teams == neu)
            #expect(AppPreferences(defaults: d).hausregeln.teams == neu, "frisch geladen: gespeichert")
        }
        #expect(Spielart.erkennen(prefs.hausregeln) == nil, "mit Teams: Eigene Regeln")
    }
}
