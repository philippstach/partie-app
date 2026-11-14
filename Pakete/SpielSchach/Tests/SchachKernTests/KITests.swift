// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SchachKern

final class SchachKITests: XCTestCase {
    /// Stellung aus FEN (Zeile 0 = Reihe 8).
    private func fen(_ f: String) -> Schach {
        let teile = f.split(separator: " ").map(String.init)
        var b = [Int](repeating: 0, count: 64); var i = 0
        let wert: [Character: Int] = ["p": 1, "n": 2, "b": 3, "r": 4, "q": 5, "k": 6]
        for ch in teile[0] {
            if ch == "/" { continue }
            if let n = ch.wholeNumberValue { i += n; continue }
            let v = wert[Character(ch.lowercased())]!; b[i] = ch.isUppercase ? v : -v; i += 1
        }
        let r = teile.count > 2 ? teile[2] : "-"
        let rochade = [r.contains("K"), r.contains("Q"), r.contains("k"), r.contains("q")]
        var ep: Int? = nil
        if teile.count > 3, teile[3] != "-" { let c = Int(teile[3].unicodeScalars.first!.value) - 97; let reihe = Int(String(teile[3].last!))!; ep = (8 - reihe) * 8 + c }
        return Schach(brett: b, dran: teile[1] == "w" ? 1 : -1, rochade: rochade, enPassant: ep)
    }
    private func perft(_ s: Schach, _ t: Int) -> Int {
        if t == 0 { return 1 }
        return s.zuege.reduce(0) { sum, z in var n = s; n.ziehe(z); return sum + perft(n, t - 1) }
    }

    func testPerftKiwipete() {
        let s = fen("r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq -")
        XCTAssertEqual(perft(s, 1), 48); XCTAssertEqual(perft(s, 2), 2039)
    }
    func testPerftEndspielStellung() {
        let s = fen("8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - -")
        XCTAssertEqual(perft(s, 1), 14); XCTAssertEqual(perft(s, 2), 191); XCTAssertEqual(perft(s, 3), 2812)
    }
    func testPerftUmwandlungsStellung() {
        let s = fen("r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq -")
        XCTAssertEqual(perft(s, 1), 6); XCTAssertEqual(perft(s, 2), 264)
    }
    func testStufenSindGestaffelt() {
        XCTAssertLessThan(SchachStaerke.leicht.tiefe, SchachStaerke.mittel.tiefe)
        XCTAssertLessThan(SchachStaerke.mittel.tiefe, SchachStaerke.schwer.tiefe)
        XCTAssertGreaterThan(SchachStaerke.leicht.fehler, SchachStaerke.mittel.fehler)
        XCTAssertEqual(SchachStaerke.schwer.fehler, 0)
    }
    func testJedeStufeSpieltNurLegaleZuege() {
        for st in stufenFuerLauf(SchachStaerke.allCases) {
            var s = Schach(); var n = 0
            while !s.zuege.isEmpty, !s.remis, n < 30 { let z = SchachComputer.wahl(s, staerke: st)!; XCTAssertTrue(s.ziehe(z), "\(st)"); n += 1 }
        }
    }
    func testSchwerNimmtHaengendeDame() {
        // Schwarze Dame d5 steht ungedeckt vor dem weißen Läufer b3; Weiß am Zug.
        let s = fen("4k3/8/8/3q4/8/1B6/8/4K3 w - -")
        let z = SchachComputer.wahl(s, staerke: .schwer)!
        XCTAssertEqual(z.nach, 3 * 8 + 3)
    }
    func testSchwerFindetMattInZwei() {
        // Leiterstellung: Weiß Ta1/Tb2 gegen König h8 → 1.Ta7 (oder Tb7) und 2.Th... – Matt in zwei mit Doppelturm.
        let s = fen("7k/8/8/8/8/8/1R6/R3K3 w - -")
        var n = s
        for _ in 0..<4 { guard let z = SchachComputer.wahl(n, staerke: .schwer) else { break }; n.ziehe(z) }
        XCTAssertTrue(n.schachmatt)
    }
    func testSchwerLaesstKeineFigurHaengen() {
        // Weißer Springer c3 wird vom Bauern d4... einfach: ein einzügiger Verlust der Dame darf nicht passieren.
        let s = fen("rnb1kbnr/pppp1ppp/8/4p3/4P2q/5N2/PPPP1PPP/RNBQKB1R w KQkq -")
        let z = SchachComputer.wahl(s, staerke: .schwer)!
        var n = s; n.ziehe(z)
        let schlimmsteAntwort = n.zuege.map { a -> Int in var k = n; k.ziehe(a); return k.brett.filter { $0 == 5 }.count }.min()!
        XCTAssertEqual(schlimmsteAntwort, 1)     // Weiß behält seine Dame
    }
    func testBewertungIstSeitensymmetrisch() {
        let s = fen("rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3")
        let gespiegelt = fen("rnbqkbnr/pppp1ppp/8/4p3/8/8/PPPPPPPP/RNBQKBNR w KQkq e6")
        XCTAssertEqual(SchachComputer.bewerteNeu(s, fuer: 1), SchachComputer.bewerteNeu(gespiegelt, fuer: -1))
    }
    func testBauernUmwandlungImEndspiel() {
        var s = fen("8/P7/8/8/8/8/k7/4K3 w - -")
        var dame = false
        for _ in 0..<3 {
            s.ziehe(SchachComputer.wahl(s, staerke: .schwer)!)
            if s.brett.contains(5) { dame = true; break }
            guard let a = SchachComputer.wahl(s, staerke: .mittel) else { break }; s.ziehe(a)
        }
        XCTAssertTrue(dame)
    }
}

/// Debug-Läufe sind etwa zehnmal langsamer: dort nur die leichten und mittleren Stufen, im Release alle.
func stufenFuerLauf<S>(_ alle: [S]) -> [S] {
    #if DEBUG
    return Array(alle.prefix(2))
    #else
    return alle
    #endif
}
