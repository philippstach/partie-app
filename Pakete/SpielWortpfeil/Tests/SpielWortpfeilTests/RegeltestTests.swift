// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import SpielWortpfeil

typealias JSON = [String: Any]

struct RegeltestTests {
    // MARK: normalisierung.json

    @Test func normalisierung() {
        let faelle = (Shared.json("regeltests/normalisierung.json") as! JSON)["faelle"] as! [JSON]
        #expect(faelle.count > 10)
        for f in faelle {
            let eingabe = f["eingabe"] as! String
            #expect(Normalizer.normalize(eingabe) == f["erwartet"] as! String, "Eingabe: \(eingabe)")
        }
    }

    // MARK: pruefer.json

    @Test func pruefer() {
        let faelle = (Shared.json("regeltests/pruefer.json") as! JSON)["faelle"] as! [JSON]
        #expect(faelle.count >= 20)
        for f in faelle {
            let name = f["name"] as! String
            let puzzle = Shared.puzzle(f["raetsel"]!)
            #expect(Validator.check(puzzle) == f["fehler"] as! [String], "Fall: \(name)")
        }
    }

    // MARK: spiel.json

    @Test func spielSchrittFuerSchritt() {
        let datei = Shared.json("regeltests/spiel.json") as! JSON
        let puzzle = Shared.puzzle(datei["raetsel"]!)
        let faelle = datei["faelle"] as! [JSON]
        #expect(faelle.count >= 23)
        var schritte = 0
        for f in faelle {
            let name = f["name"] as! String
            var game = Game(puzzle: puzzle, startHelp: f["starthilfe"] as? Bool ?? false)
            for (i, schritt) in (f["schritte"] as! [JSON]).enumerated() {
                var ergebnis: Int?
                if let a = schritt["aktion"] as? JSON { ergebnis = Self.run(a, on: &game) }
                let kontext = "\(name), Schritt \(i)"
                Self.vergleiche(game, schritt["erwartet"] as! JSON, kontext)
                if let erwartet = schritt["ergebnis"] as? Int { #expect(ergebnis == erwartet, "\(kontext): Ergebnis") }
                schritte += 1
            }
        }
        #expect(schritte > 100)
    }

    static func run(_ a: JSON, on game: inout Game) -> Int? {
        switch a["aktion"] as! String {
        case "tippe": game.tap(Pos(a["zeile"] as! Int, a["spalte"] as! Int))
        case "buchstabe": game.type(a["zeichen"] as! String)
        case "loeschen": game.delete()
        case "naechsteFrage": game.moveToClue(step: 1)
        case "vorigeFrage": game.moveToClue(step: -1)
        case "buchstabeAufdecken": game.revealLetter()
        case "bleistiftUmschalten": game.togglePencil()
        case "wortAufdecken": game.revealWord()
        case "wortPruefen": return game.checkWord()
        case "raetselPruefen": return game.checkPuzzle()
        default: Issue.record("Unbekannte Aktion \(a["aktion"]!)")
        }
        return nil
    }

    static func vergleiche(_ g: Game, _ e: JSON, _ kontext: String) {
        let p = g.puzzle
        let zeilen = (0..<p.hoehe).map { r in
            String((0..<p.breite).map { c -> Character in
                let pos = Pos(r, c)
                return p.isLetter(pos) ? (g.entries[pos] ?? ".") : p.cell(pos)!
            })
        }
        #expect(zeilen == e["eintraege"] as! [String], "\(kontext): eintraege")
        let cursor = (e["cursor"] as? [Int]).map { Pos($0[0], $0[1]) }
        #expect(g.cursor == cursor, "\(kontext): cursor")
        #expect(g.direction.rawValue == e["richtung"] as! String, "\(kontext): richtung")
        let aktiv = (e["aktiveFrage"] as? [Any]).map { ($0[0] as! Int, $0[1] as! Int, $0[2] as! String) }
        if let a = aktiv, let c = g.activeClue {
            #expect(c.zeile == a.0 && c.spalte == a.1 && c.richtung == a.2, "\(kontext): aktiveFrage")
        } else {
            #expect(aktiv == nil && g.activeClue == nil, "\(kontext): aktiveFrage")
        }
        let paare: (Any?) -> [Pos] = { ($0 as! [[Int]]).map { Pos($0[0], $0[1]) }.sorted() }
        #expect(g.revealed.sorted() == paare(e["aufgedeckt"]), "\(kontext): aufgedeckt")
        #expect(g.marked.sorted() == paare(e["markiert"]), "\(kontext): markiert")
        #expect(g.hints == e["hilfen"] as! Int, "\(kontext): hilfen")
        #expect(g.uncertain.sorted() == paare(e["unsicher"]), "\(kontext): unsicher")
        #expect(g.pencil == e["bleistift"] as! Bool, "\(kontext): bleistift")
        if let l = e["loesung"] as? String { #expect(g.solutionProgress == l, "\(kontext): loesung") }
        #expect(g.status.rawValue == e["status"] as! String, "\(kontext): status")
    }

    // MARK: loesungswort.json

    @Test func loesungswortPruefer() {
        let faelle = (Shared.json("regeltests/loesungswort.json") as! JSON)["pruefer"] as! [JSON]
        for f in faelle {
            #expect(Validator.check(Shared.puzzle(f["raetsel"]!)) == f["fehler"] as! [String], Comment(rawValue: f["name"] as! String))
        }
    }

    @Test func loesungswortSpiel() {
        let d = (Shared.json("regeltests/loesungswort.json") as! JSON)["spiel"] as! JSON
        var game = Game(puzzle: Shared.puzzle(d["raetsel"]!))
        for (i, schritt) in (d["schritte"] as! [JSON]).enumerated() {
            if let a = schritt["aktion"] as? JSON { _ = Self.run(a, on: &game) }
            Self.vergleiche(game, schritt["erwartet"] as! JSON, "loesungswort, Schritt \(i)")
        }
    }

    // MARK: erfolge.json und empfehlung.json

    static func level(_ name: String) -> Level { Level(rawValue: name == "taeglich" ? "mittel" : name)! }

    @Test func erfolge() {
        let d = Shared.json("regeltests/erfolge.json") as! JSON
        let liste = (d["liste"] as! [JSON]).map { $0["id"] as! String }
        #expect(Achievements.all.map(\.id) == liste)               // gleiche Erfolge, gleiche Reihenfolge
        for f in d["faelle"] as! [JSON] {
            let st = f["statistik"] as! JSON
            func ints(_ k: String) -> [Level: Int] {
                Dictionary(uniqueKeysWithValues: ((st[k] as? [String: Int]) ?? [:]).map { (Self.level($0.key), $0.value) })
            }
            var i = AchievementInput()
            i.solved = ints("geloest"); i.withoutHelp = ints("ohneHilfe"); i.packSize = ints("paketgroesse")
            i.bestTime = Dictionary(uniqueKeysWithValues: ((st["bestzeit"] as? [String: Double]) ?? [:]).map { (Self.level($0.key), $0.value) })
            i.bestStreak = st["besteSerie"] as? Int ?? 0
            i.dailySolved = st["tagesGeloest"] as? Int ?? 0
            i.themesSolved = st["themenGeloest"] as? Int ?? 0
            #expect(Achievements.reached(i) == f["erwartet"] as! [String], Comment(rawValue: f["name"] as! String))
        }
    }

    @Test func empfehlung() {
        let faelle = (Shared.json("regeltests/empfehlung.json") as! JSON)["faelle"] as! [JSON]
        for f in faelle {
            let hints = (f["letzte"] as! [JSON]).map { $0["hilfen"] as! Int }
            let r = Recommendation.suggest(level: Level(rawValue: f["stufe"] as! String)!, hints: hints)
            #expect(r?.rawValue == f["erwartet"] as? String, Comment(rawValue: f["name"] as! String))
        }
    }

    // MARK: tage.json

    @Test func tagesindex() {
        let faelle = (Shared.json("regeltests/tage.json") as! JSON)["tagesindex"] as! [JSON]
        for f in faelle {
            let tag = Day(f["datum"] as! String)!
            #expect(Daily.index(day: tag, count: f["anzahl"] as! Int) == f["erwartet"] as! Int, "\(tag)")
        }
    }

    @Test func serie() {
        let faelle = (Shared.json("regeltests/tage.json") as! JSON)["serie"] as! [JSON]
        for f in faelle {
            let geloest = Set((f["geloest"] as! [String]).map { Day($0)! })
            let heute = Day(f["heute"] as! String)!
            #expect(Daily.streak(solved: geloest, today: heute) == f["erwartet"] as! Int, Comment(rawValue: f["name"] as! String))
        }
    }

    @Test func tagesindexOhneDatumsfehler() {
        // Hin- und Rückrechnung, Schaltjahr, Zeiten vor 2026 (negatives Modulo)
        for n in stride(from: -800, through: 800, by: 7) {
            let d = Day(number: n)
            #expect(Day(number: d.number) == d)
            #expect(Day(d.description) == d)
        }
        #expect(Day(2024, 2, 29).adding(days: 1) == Day(2024, 3, 1))
        #expect(Daily.index(day: Day(2025, 12, 31), count: 365) == 364)
    }

    @Test func tagUmZeitzoneStabil() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Pacific/Auckland")!
        let abends = cal.date(from: DateComponents(year: 2026, month: 10, day: 4, hour: 23, minute: 30))!
        #expect(Day(abends, calendar: cal) == Day(2026, 10, 4))
    }

    // MARK: Pakete

    @Test func alleEingebautenPaketeSindGueltig() throws {
        let ordner = Shared.root.appending(path: "raetsel")
        let dateien = try FileManager.default.contentsOfDirectory(at: ordner, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "json" }
        #expect(dateien.count >= 4)
        for url in dateien {
            let pack = try #require(PuzzlePack.load(from: url))
            #expect(!pack.raetsel.isEmpty, "\(url.lastPathComponent) ist leer")
            var ids = Set<String>()
            for p in pack.raetsel {
                #expect(Validator.check(p) == [], "\(url.lastPathComponent) \(p.id)")
                #expect(ids.insert(p.id).inserted, "doppelte ID \(p.id)")
                #expect(Game(puzzle: p).activeClue != nil, "\(p.id) hat keine erste Frage")
            }
        }
    }

    @Test func bibliothekLaedtAllePakete() {
        let lib = PackLibrary(directory: Shared.root.appending(path: "raetsel"))
        for l in Level.allCases { #expect(!lib.puzzles(l).isEmpty, "\(l)") }
        #expect(!lib.daily.isEmpty)
        #expect(lib.dailyPuzzle(for: Day(2026, 10, 4)) != nil)
    }

    @Test func kaputtesPaketFehltEinfach() {
        let ordner = FileManager.default.temporaryDirectory.appending(path: "kw-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: ordner, withIntermediateDirectories: true)
        try? Data("kein json".utf8).write(to: ordner.appending(path: "leicht.json"))
        let lib = PackLibrary(directory: ordner)
        #expect(lib.puzzles(.leicht).isEmpty)
        #expect(lib.isEmpty)
    }

    /// Das Tagespaket muss mindestens zwei Jahre ohne Wiederholung reichen (Index = Tage seit 01.01.2026).
    @Test func tagespaketReichtZweiJahreOhneWiederholung() {
        let lib = PackLibrary(directory: Shared.root.appending(path: "raetsel"))
        let alle = lib.daily
        #expect(alle.count >= 730)
        #expect(Set(alle.map(\.id)).count == alle.count)
        #expect(Set(alle.map { $0.gitter.joined() }).count == alle.count)
        // Jeder Tag von 01.01.2026 bis 31.12.2028 liefert ein anderes Rätsel als alle 729 Tage davor.
        let start = Day(2026, 1, 1).number, ende = Day(2028, 12, 31).number
        var gesehen = Set<String>()
        for n in start...ende {
            guard let p = lib.dailyPuzzle(for: Day(number: n)) else { Issue.record("kein Rätsel am Tag \(n)"); return }
            #expect(gesehen.insert(p.id).inserted, "Wiederholung am Tag \(Day(number: n))")
        }
    }
}
