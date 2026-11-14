// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SpielSolitaer

/// Prüft jede Datei aus `Shared/regeltests/spider/` vollständig. Gleiche Karten aus verschiedenen Sätzen sind für die Regeln
/// gleich, deshalb werden Zustände über ihre Kartennamen („TH“) verglichen, wie im Test-JSON.
final class SpiderRegeltestsTests: XCTestCase {
    // MARK: Hilfen

    private struct Names: Equatable {
        var farben: Int
        var stapel: [String]
        var spalten: [[[String]]]       // je Spalte [verdeckt, offen]
        var fertig: [String]
        var punkte: Int
        var zuege: Int
        var ausgeteilt: Int
    }

    private func name(_ c: CardID, _ s: SpiderState) -> String {
        String(CardID.rankLetters[s.rank(c) - 1]) + String(CardID.suitLetters[s.suit(c)])
    }

    private func names(_ s: SpiderState) -> Names {
        Names(farben: s.suits, stapel: s.stock.map { name($0, s) },
              spalten: s.cols.map { [$0.down.map { name($0, s) }, $0.up.map { name($0, s) }] },
              fertig: s.done.map { String(CardID.suitLetters[$0.suit]) },
              punkte: s.score, zuege: s.moves, ausgeteilt: s.deals)
    }

    private func strings(_ any: Any?) -> [String] { any as? [String] ?? [] }

    private func names(json d: [String: Any]) -> Names {
        let cols = (d["spalten"] as! [[String: Any]]).map { [strings($0["verdeckt"]), strings($0["offen"])] }
        let padded = cols + Array(repeating: [[], []], count: 10 - cols.count)
        return Names(farben: d["farben"] as! Int, stapel: strings(d["stapel"]), spalten: padded, fertig: strings(d["fertig"]),
                     punkte: d["punkte"] as? Int ?? 500, zuege: d["zuege"] as? Int ?? 0, ausgeteilt: d["ausgeteilt"] as? Int ?? 0)
    }

    /// Wie `State.from_json` der Referenz: Karten bekommen der Reihe nach freie Nummern passender Farbe
    private func state(_ d: [String: Any]) -> SpiderState {
        let suits = d["farben"] as! Int
        var free: [String: [Int]] = [:]
        for n in 0..<104 {
            let key = String(CardID.rankLetters[SpiderState.rank(of: CardID(n)) - 1]) + String(CardID.suitLetters[SpiderState.suit(of: CardID(n), suits: suits)])
            free[key, default: []].append(n)
        }
        func take(_ nm: String) -> CardID { CardID(free[nm]!.removeFirst()) }
        var cols = (d["spalten"] as! [[String: Any]]).map { Column(down: strings($0["verdeckt"]).map(take), up: strings($0["offen"]).map(take)) }
        while cols.count < 10 { cols.append(Column()) }
        let stock = strings(d["stapel"]).map(take)
        let done = strings(d["fertig"]).map { DoneRun(suit: CardID.suitLetters.firstIndex(of: $0.first!)!) }
        return SpiderState(suits: suits, stock: stock, cols: cols, done: done,
                           score: d["punkte"] as? Int ?? 500, moves: d["zuege"] as? Int ?? 0, deals: d["ausgeteilt"] as? Int ?? 0)
    }

    /// Zug in der Schreibweise der Tests; „Z“ = Abräumen (bei uns `.foundation(Anzahl fertiger Reihen)`)
    private func text(_ m: Move) -> String {
        switch m {
        case .draw: return "stapel"
        case let .move(from, to, n):
            func p(_ x: Pile) -> String {
                switch x {
                case let .column(i): "S\(i)"
                case .foundation: "Z"
                default: "?"
                }
            }
            return "\(p(from))>\(p(to))x\(n)"
        }
    }

    private func text(json d: [String: Any]) -> String {
        if d["von"] as! String == "stapel" { return "stapel" }
        return "\(d["von"] as! String)>\(d["nach"] as! String)x\(d["anzahl"] as? Int ?? 1)"
    }

    private func move(_ d: [String: Any], in s: SpiderState) -> Move {
        if d["von"] as! String == "stapel" { return .draw }
        func pile(_ x: String) -> Pile { x == "Z" ? .foundation(s.done.count) : .column(Int(x.dropFirst())!) }
        return .move(from: pile(d["von"] as! String), to: pile(d["nach"] as! String), count: d["anzahl"] as? Int ?? 1)
    }

    private func column(_ x: String) -> Pile { .column(Int(x.dropFirst())!) }

    // MARK: Tests

    func testZufall() throws {
        let faelle = try TestJSON.cases("spider/zufall")
        XCTAssertFalse(faelle.isEmpty)
        for f in faelle {
            let seed = UInt64(f["seed"] as! Int)
            let erwartet = f["gemischt"] as! [Int]
            XCTAssertEqual(SpiderRules.shuffledDeck(seed: seed).prefix(erwartet.count).map(\.number), erwartet, "Seed \(seed)")
        }
    }

    func testGeben() throws {
        let faelle = try TestJSON.cases("spider/geben")
        XCTAssertFalse(faelle.isEmpty)
        for f in faelle {
            let s = SpiderRules.deal(seed: UInt64(f["seed"] as! Int), mode: .spider(f["farben"] as! Int))
            XCTAssertEqual(names(s), names(json: f["zustand"] as! [String: Any]), "Seed \(f["seed"]!)")
            XCTAssertEqual(s.stock.count, 50)
        }
    }

    func testZuege() throws {
        let faelle = try TestJSON.cases("spider/zuege")
        XCTAssertFalse(faelle.isEmpty)
        for f in faelle {
            let titel = f["titel"] as! String
            let start = state(f["start"] as! [String: Any])
            let ergebnis = SpiderRules.apply(start, move(f["zug"] as! [String: Any], in: start))
            if f["erlaubt"] as! Bool {
                let s = try XCTUnwrap(ergebnis, titel)
                XCTAssertEqual(names(s), names(json: f["danach"] as! [String: Any]), titel)
            } else {
                XCTAssertNil(ergebnis, "\(titel): sollte unerlaubt sein")
            }
        }
    }

    func testTippen() throws {
        let faelle = try TestJSON.cases("spider/tippen")
        XCTAssertFalse(faelle.isEmpty)
        for f in faelle {
            let start = state(f["start"] as! [String: Any])
            let ziel = SpiderRules.tapTarget(start, from: column(f["quelle"] as! String), count: f["anzahl"] as! Int)
            let erwartet = (f["zug"] as? [String: Any]).map { text(json: $0) }
            XCTAssertEqual(ziel.map(text), erwartet, f["titel"] as! String)
        }
    }

    func testAbraeumen() throws {
        let faelle = try TestJSON.cases("spider/abraeumen")
        XCTAssertFalse(faelle.isEmpty)
        for f in faelle {
            let start = state(f["start"] as! [String: Any])
            let erwartet = (f["zuege"] as! [[String: Any]]).map { text(json: $0) }
            XCTAssertEqual(SpiderRules.autoMoves(start, autoFoundation: true).map(text), erwartet, f["titel"] as! String)
        }
    }

    func testTipp() throws {
        let faelle = try TestJSON.cases("spider/tipp")
        XCTAssertFalse(faelle.isEmpty)
        for f in faelle {
            let titel = f["titel"] as! String
            let start = state(f["start"] as! [String: Any])
            let erwartet = (f["tipp"] as? [String: Any]).map { text(json: $0) }
            XCTAssertEqual(SpiderRules.hint(start).map(text), erwartet, titel)
            XCTAssertEqual(SpiderRules.isStuck(start), f["festgefahren"] as! Bool, titel)
        }
    }

    func testPartien() throws {
        let faelle = try TestJSON.cases("spider/partien")
        XCTAssertFalse(faelle.isEmpty)
        for f in faelle {
            let titel = f["titel"] as! String
            var s = SpiderRules.deal(seed: UInt64(f["seed"] as! Int), mode: .spider(f["farben"] as! Int))
            for (i, z) in (f["zuege"] as! [[String: Any]]).enumerated() {
                guard let n = SpiderRules.apply(s, move(z, in: s)) else { return XCTFail("\(titel): Zug \(i) \(z) unerlaubt") }
                s = n
            }
            XCTAssertEqual(names(s), names(json: f["ende"] as! [String: Any]), titel)
            XCTAssertEqual(s.isWon, f["gewonnen"] as! Bool, titel)
        }
    }

    func testZustandCodableMitStandardwerten() throws {
        let leer = try JSONDecoder().decode(SpiderState.self, from: Data("{}".utf8))
        XCTAssertEqual(leer.cols.count, 10)
        XCTAssertEqual(leer.score, 500)
        let s = SpiderRules.deal(seed: 5, mode: .spider(2))
        XCTAssertEqual(try JSONDecoder().decode(SpiderState.self, from: JSONEncoder().encode(s)), s)
    }

    func testFertigeReiheKenntIhreKarten() throws {
        // König bis Ass in Herz auf S0: wird abgeräumt, die 13 Karten bleiben für die Animation erhalten
        var s = SpiderState(suits: 2)
        s.cols[0] = Column(down: [], up: (0..<13).reversed().map { CardID(13 + $0) })   // Satz 1 = Herz
        let moves = SpiderRules.autoMoves(s, autoFoundation: true)
        XCTAssertEqual(moves.count, 1)
        let t = try XCTUnwrap(SpiderRules.apply(s, moves[0]))
        XCTAssertEqual(t.done.count, 1)
        XCTAssertEqual(t.done[0].cards.count, 13)
        XCTAssertEqual(t.done[0].suit, 1)
        XCTAssertEqual(t.score, 600)
        XCTAssertEqual(t.moves, 0)
    }
}
