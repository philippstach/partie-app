// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SpielSolitaer

@MainActor
final class StoreTests: XCTestCase {
    private func prefs() -> AppPreferences { AppPreferences(defaults: UserDefaults(suiteName: UUID().uuidString)!) }

    private func tempURL() -> URL { FileManager.default.temporaryDirectory.appending(path: "solitaer-\(UUID().uuidString).json") }

    /// Zustand, in dem nach 1 Zug (Ass → Ziel) die Zwei automatisch folgt
    private func autoState() -> GameState {
        var s = GameState()
        s.cols[0] = Column(up: [CardID(rank: 2, suit: .spades), CardID(rank: 1, suit: .spades)])
        s.cols[1] = Column(up: [CardID(rank: 1, suit: .hearts)])
        return s
    }

    func testRueckgaengigNimmtSpielerzugUndAutoAblagenZusammenZurueck() async throws {
        let p = prefs(); p.autoFoundation = true                       // Standard ist Selbst: hier „Automatisch“
        let store = GameStore<KlondikeRules>(mode: .klondike(1), prefs: p, seed: 1, url: nil)
        let start = autoState()
        store.load(state: start)
        XCTAssertTrue(store.perform(.move(from: .column(0), to: .foundation(0), count: 1)))
        try await Task.sleep(for: .milliseconds(600))
        // Ass Pik (Spieler) + 2 Pik und Ass Herz (automatisch)
        XCTAssertEqual(store.state.foundation, [2, 1, 0, 0])
        XCTAssertEqual(store.state.moves, 3)
        store.undo()
        XCTAssertEqual(store.state, start)
        XCTAssertFalse(store.canUndo)
    }

    func testNeueEingabeBeendetAutoZuegeSofort() {
        let p = prefs(); p.autoFoundation = true
        let store = GameStore<KlondikeRules>(mode: .klondike(1), prefs: p, seed: 1, url: nil)
        store.load(state: autoState())
        store.perform(.move(from: .column(0), to: .foundation(0), count: 1))
        store.flush()
        XCTAssertEqual(store.state.foundation, [2, 1, 0, 0])
    }

    func testSpeichernUndLaden() async throws {
        let url = tempURL()
        defer { try? FileManager.default.removeItem(at: url) }
        let p = prefs()
        let store = GameStore<KlondikeRules>(mode: .klondike(1), prefs: p, seed: 7, url: url)
        store.drawStock()
        store.drawStock()
        store.pauseClock()
        await store.settleSaves()
        let geladen = GameStore<KlondikeRules>(mode: .klondike(1), prefs: p, url: url)
        XCTAssertEqual(geladen.state, store.state)
        XCTAssertEqual(geladen.deal, store.deal)
        XCTAssertEqual(geladen.canUndo, true)
    }

    func testFehlendeFelderBeimLaden() throws {
        let url = tempURL()
        defer { try? FileManager.default.removeItem(at: url) }
        let state = Deal.deal(seed: 3, draw: 1)
        let json = "{\"state\":\(String(data: try JSONEncoder().encode(state), encoding: .utf8)!)}"
        try json.write(to: url, atomically: true, encoding: .utf8)
        let geladen = GameStore<KlondikeRules>(mode: .klondike(1), prefs: prefs(), url: url)
        XCTAssertEqual(geladen.state, state)
        XCTAssertFalse(geladen.canUndo)
        XCTAssertEqual(geladen.elapsed, 0)
        let leer = try JSONDecoder().decode(GameState.self, from: Data("{}".utf8))
        XCTAssertEqual(leer.cols.count, 7)
        XCTAssertEqual(leer.foundation, [0, 0, 0, 0])
    }

    func testErstspielerHinweiseNurEinmal() {
        let p = prefs()
        let store = GameStore<KlondikeRules>(mode: .klondike(1), prefs: p, seed: 1, url: nil)
        store.showFirstHint(.tap)
        XCTAssertEqual(store.activeFirstHint, .tap)
        store.dismissFirstHint()
        store.showFirstHint(.tap)                      // schon gesehen → nicht noch einmal
        XCTAssertNil(store.activeFirstHint)
        XCTAssertTrue(p.seenHints.contains("tap"))
        p.seenHints = []                               // „Hinweise wieder zeigen“
        store.showFirstHint(.tap)
        XCTAssertEqual(store.activeFirstHint, .tap)
    }

    func testHinweisStapelLeerBeiVollerAblage() {
        let store = GameStore<KlondikeRules>(mode: .klondike(1), prefs: prefs(), seed: 1, url: nil)
        var s = GameState()
        s.stock = [CardID(5)]
        s.cols[0] = Column(up: [CardID(40)])
        store.load(state: s)
        store.drawStock()                              // letzte Karte gezogen: Stapel leer, Ablage voll
        XCTAssertEqual(store.activeFirstHint, .recycle)
    }

    func testEreignisse() {
        let store = GameStore<KlondikeRules>(mode: .klondike(1), prefs: prefs(), seed: 1, url: nil)
        var log: [String] = []
        store.onEvent = { e in
            switch e {
            case .started: log.append("start")
            case .won: log.append("won")
            case .abandoned: log.append("abandoned")
            case .chain: log.append("chain")
            case .account: log.append("account")
            }
        }
        store.newGame()                       // noch kein Zug → nichts verlassen
        XCTAssertEqual(log, [])
        store.drawStock(); store.drawStock()
        XCTAssertEqual(log, ["start"])
        store.newGame()
        XCTAssertEqual(log, ["start", "abandoned"])
        var fast = GameState()
        fast.foundation = [13, 13, 13, 12]
        fast.cols[0] = Column(up: [CardID(rank: 13, suit: .clubs)])
        store.load(state: fast)
        store.perform(.move(from: .column(0), to: .foundation(3), count: 1))
        XCTAssertEqual(log.last, "won")
        XCTAssertFalse(store.canUndo)         // nach dem Sieg kein Rückgängig
    }

    func testNeuesSpielWaehltLoesbareListePartie() {
        let p = prefs()
        let store = GameStore<KlondikeRules>(mode: .klondike(1), prefs: p, seed: 1, url: nil)
        store.newGame()
        XCTAssertEqual(store.deal.kind, .solvable)
        XCTAssertTrue(DealCatalog.shared.seeds(draw: 1).contains(store.deal.seed))
        let alt = store.deal
        store.restartSameDeal()
        XCTAssertEqual(store.deal, alt)
        XCTAssertEqual(store.state, Deal.deal(seed: alt.seed, draw: 1))
    }

    func testZeitLaeuftErstAbErstemZug() {
        let store = GameStore<KlondikeRules>(mode: .klondike(1), prefs: prefs(), seed: 1, url: nil)
        store.resumeClock()
        XCTAssertNil(store.runningSince)
        store.drawStock()
        XCTAssertNotNil(store.runningSince)
        store.pauseClock()
        XCTAssertNil(store.runningSince)
    }
}

final class LayoutTests: XCTestCase {
    /// Eine Spalte mit 19 Karten (6 verdeckt, 13 offen) muss auch auf dem kleinsten Bildschirm (iPhone SE) hineinpassen.
    func testLangeSpalteBeiIPhoneSE() {
        var s = GameState()
        let run = (1...13).reversed().map { r in CardID(rank: r, suit: r % 2 == 0 ? .hearts : .clubs) }
        s.cols[6] = Column(down: (14...19).map { CardID($0 + 20) }, up: run)
        // iPhone SE: 375 × 667, abzüglich Kopfzeile (44), Leiste (56) und Statusleiste (20)
        let size = CGSize(width: 375, height: 667 - 44 - 56 - 20)
        let layout = KlondikeLayout(state: s, size: size, leftHanded: false)
        let lowest = s.cols[6].up.last!
        XCTAssertLessThanOrEqual(layout.placements[lowest]!.frame.maxY, size.height)
        // jede offene Karte bleibt am oberen Streifen erkennbar (Abstand ≥ 0,17 Kartenhöhe)
        let a = layout.placements[run[11]]!.frame, b = layout.placements[run[12]]!.frame
        XCTAssertGreaterThanOrEqual(b.minY - a.minY, layout.cardHeight * 0.17 - 0.01)
    }

    func testAlle52KartenHabenEinenPlatz() {
        let layout = KlondikeLayout(state: Deal.deal(seed: 1, draw: 1), size: CGSize(width: 402, height: 700), leftHanded: false)
        XCTAssertEqual(layout.placements.count, 52)
    }

    func testAblegenZielUnterMitteDerKarte() {
        let layout = KlondikeLayout(state: Deal.deal(seed: 1, draw: 1), size: CGSize(width: 402, height: 700), leftHanded: false)
        XCTAssertEqual(layout.dropTarget(at: CGPoint(x: layout.slotX(3) + 5, y: layout.rowY + 300)), .column(3))
        XCTAssertEqual(layout.dropTarget(at: CGPoint(x: layout.slotX(1) + 5, y: layout.topY + 20)), .foundation(1))
        XCTAssertNil(layout.dropTarget(at: CGPoint(x: layout.slotX(5), y: layout.topY + 20)))
    }

    func testLinkshaenderSpiegeltObereReihe() {
        let s = Deal.deal(seed: 1, draw: 1)
        let rechts = KlondikeLayout(state: s, size: CGSize(width: 402, height: 700), leftHanded: false)
        let links = KlondikeLayout(state: s, size: CGSize(width: 402, height: 700), leftHanded: true)
        XCTAssertGreaterThan(rechts.stockFrame.minX, rechts.foundationFrame(3).minX)
        XCTAssertLessThan(links.stockFrame.minX, links.foundationFrame(0).minX)
    }

    func testObereReiheRechtshaendig() {
        let layout = KlondikeLayout(state: Deal.deal(seed: 1, draw: 1), size: CGSize(width: 402, height: 700), leftHanded: false)
        // Ziele 0–3, Platz 4 frei, Ablage 5, Stapel 6
        for f in 0..<4 { XCTAssertEqual(layout.foundationFrame(f).minX, layout.slotX(f), accuracy: 0.01) }
        XCTAssertEqual(layout.wasteFrame.minX, layout.slotX(5), accuracy: 0.01)
        XCTAssertEqual(layout.stockFrame.minX, layout.slotX(6), accuracy: 0.01)
    }

    func testObereReiheLinkshaendig() {
        let layout = KlondikeLayout(state: Deal.deal(seed: 1, draw: 1), size: CGSize(width: 402, height: 700), leftHanded: true)
        // Stapel 0, Ablage 1, Lücke 2, Ziele 3–6
        XCTAssertEqual(layout.stockFrame.minX, layout.slotX(0), accuracy: 0.01)
        XCTAssertEqual(layout.wasteFrame.minX, layout.slotX(1), accuracy: 0.01)
        for f in 0..<4 { XCTAssertEqual(layout.foundationFrame(f).minX, layout.slotX(3 + f), accuracy: 0.01) }
    }

    func testFaecherZurLueckeHin() {
        var s = GameState(draw: 3)
        s.waste = [CardID(1), CardID(2), CardID(3), CardID(4)]
        s.fan = 3
        for left in [false, true] {
            let layout = KlondikeLayout(state: s, size: CGSize(width: 402, height: 700), leftHanded: left)
            let step = layout.cardWidth * KlondikeLayout.fanStep
            let top = layout.placements[CardID(4)]!.frame, mid = layout.placements[CardID(3)]!.frame
            let old = layout.placements[CardID(2)]!.frame, hidden = layout.placements[CardID(1)]!.frame
            XCTAssertEqual(top.minX, layout.wasteFrame.minX, accuracy: 0.01)          // oberste liegt auf dem Platz
            let dir: CGFloat = left ? 1 : -1                                          // Richtung zur Lücke
            XCTAssertEqual(mid.minX - top.minX, dir * step, accuracy: 0.01)
            XCTAssertEqual(old.minX - top.minX, dir * 2 * step, accuracy: 0.01)
            XCTAssertEqual(hidden.minX, top.minX, accuracy: 0.01)                      // nicht gefächerte Karten liegen unter der obersten
            // der Fächer ragt nie über den Stapel
            let all = [top, mid, old]
            for f in all { XCTAssertFalse(f.intersects(layout.stockFrame), "links=\(left)") }
        }
    }
}

final class SpiderLayoutTests: XCTestCase {
    private let size = CGSize(width: 402, height: 640)

    func testWenigKartenFaecherWaechstBisMaximum() {
        let s = SpiderRules.deal(seed: 1, mode: .spider(2))
        let layout = SpiderLayout(state: s, size: size, prefs: TablePrefs())
        XCTAssertEqual(layout.openBase, layout.cardHeight * SpiderLayout.maxOpenStep, accuracy: 0.01)
    }

    func testLangeSpalteBegrenztDasWachstum() {
        var s = SpiderState(suits: 2)
        // 12 verdeckte + 13 offene Karten in einer Spalte: füllt den Platz
        s.cols[0] = Column(down: (0..<12).map(CardID.init), up: (20..<33).map(CardID.init))
        let klein = CGSize(width: 402, height: 420)          // wenig Platz, wie bei kleinen Geräten
        let layout = SpiderLayout(state: s, size: klein, prefs: TablePrefs())
        XCTAssertLessThan(layout.openBase, layout.cardHeight * SpiderLayout.maxOpenStep)
        XCTAssertGreaterThanOrEqual(layout.openBase, layout.cardHeight * SpiderLayout.openStep - 0.01)
        let last = s.cols[0].up.last!
        XCTAssertLessThanOrEqual(layout.placements[last]!.frame.maxY, klein.height)
    }

    func testAlle104KartenUndBeweglicheReihe() {
        let s = SpiderRules.deal(seed: 2, mode: .spider(1))
        let layout = SpiderLayout(state: s, size: size, prefs: TablePrefs())
        XCTAssertEqual(layout.placements.count, 104)
        // jede Spalte: nur die oberste Reihe gleicher Farbe ist anfassbar
        for (i, col) in s.cols.enumerated() {
            let movable = SpiderRules.runLength(s, col)
            let withSource = col.up.filter { layout.sources[$0] != nil }.count
            XCTAssertEqual(withSource, movable, "Spalte \(i)")
        }
    }

    func testObereReiheLinkshaenderGespiegelt() {
        let s = SpiderRules.deal(seed: 1, mode: .spider(2))
        let rechts = SpiderLayout(state: s, size: size, prefs: TablePrefs(leftHanded: false))
        let links = SpiderLayout(state: s, size: size, prefs: TablePrefs(leftHanded: true))
        XCTAssertGreaterThan(rechts.stockFrame.minX, rechts.doneFrame(0).minX)       // Stapel rechts, fertige Reihen links
        XCTAssertLessThan(links.stockFrame.minX, links.doneFrame(0).minX)            // gespiegelt
        XCTAssertEqual(rechts.dealsLeft, 5)
    }
}

final class FanMetricsTests: XCTestCase {
    func testWenigKartenWaechstBisMaximum() {
        let h: CGFloat = 70
        let step = FanMetrics.growingOpenStep(columns: [(2, 3), (0, 1), (4, 6)], available: 500, downPoints: 7, cardHeight: h, base: 0.27)
        XCTAssertEqual(step, h * 0.42, accuracy: 0.001)
    }

    func testLangeSpalteBegrenztAufStandard() {
        let h: CGFloat = 70
        // 6 verdeckt + 13 offen auf wenig Platz: nicht über den Standard hinaus, nicht darunter
        let step = FanMetrics.growingOpenStep(columns: [(6, 13)], available: 200, downPoints: 7, cardHeight: h, base: 0.27)
        XCTAssertEqual(step, h * 0.27, accuracy: 0.001)
    }

    func testZwischenStandardUndMaximum() {
        let h: CGFloat = 70
        // Längste Spalte: 12 Lücken, 4 verdeckt (je 7) → (available − 28) / 12
        let step = FanMetrics.growingOpenStep(columns: [(4, 13), (1, 2)], available: 28 + 12 * 25, downPoints: 7, cardHeight: h, base: 0.27)
        XCTAssertEqual(step, 25, accuracy: 0.001)
        XCTAssertGreaterThan(step, h * 0.27)
        XCTAssertLessThan(step, h * 0.42)
    }

    func testAlleDreiLayoutsNutzenDieGemeinsameRechnung() {
        let size = CGSize(width: 402, height: 640)
        let k = KlondikeLayout(state: Deal.deal(seed: 1, draw: 1), size: size, prefs: TablePrefs())
        XCTAssertEqual(k.openBase, k.cardHeight * FanMetrics.maxOpenStep, accuracy: 0.01)
        let f = FreeCellLayout(state: FreeCellRules.deal(seed: 1, mode: .freecell), size: size, prefs: TablePrefs())
        XCTAssertEqual(f.openBase, f.cardHeight * FanMetrics.maxOpenStep, accuracy: 0.01)
        let s = SpiderLayout(state: SpiderRules.deal(seed: 1, mode: .spider(2)), size: size, prefs: TablePrefs())
        XCTAssertEqual(s.openBase, s.cardHeight * FanMetrics.maxOpenStep, accuracy: 0.01)
    }
}
