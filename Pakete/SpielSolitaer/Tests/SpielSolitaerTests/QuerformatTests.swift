// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SpielSolitaer

/// Querformat (Q0): Kartenbreite aus der Breite, Tisch füllt die Breite neben der Leiste, Karten quer ≥ hoch,
/// alles bleibt im Feld, Stapel/Ablage überdecken nichts; dazu R2b/R2c (Mindestabstand, Seitenspalten, „+N“-Block)
final class QuerformatTests: XCTestCase {
    /// iPhones quer: Bildschirm (Punkte), seitlicher Rand (Dynamic Island / Notch), unten (Home-Indikator)
    struct Device {
        var name: String
        var screen: CGSize
        var insetX: CGFloat
        var insetBottom: CGFloat
        /// Tischfläche: Bildschirm minus Ränder, minus senkrechte Leiste (72 pt) und Kopfzeile samt Abstand (50 pt)
        var table: CGSize { CGSize(width: screen.width - 2 * insetX - 72, height: screen.height - insetBottom - 50) }
        /// Breite im Hochformat
        var portraitWidth: CGFloat { screen.height }
    }
    static let devices = [Device(name: "iPhone 17 Pro Max", screen: CGSize(width: 956, height: 440), insetX: 62, insetBottom: 21),
                          Device(name: "iPhone 17 Pro", screen: CGSize(width: 874, height: 402), insetX: 62, insetBottom: 21),
                          Device(name: "iPhone 13 mini", screen: CGSize(width: 812, height: 375), insetX: 44, insetBottom: 21),
                          Device(name: "iPhone SE", screen: CGSize(width: 667, height: 375), insetX: 0, insetBottom: 0)]
    private var sizes: [CGSize] { Self.devices.map(\.table) }

    /// Ein Platz so groß, wie er gezeichnet wird (Spider quer: Seitenleiste in 0,6-facher Größe)
    private func visible(_ p: CardPlacement) -> CGRect {
        let w = p.frame.width * p.scale, h = p.frame.height * p.scale
        return CGRect(x: p.frame.midX - w / 2, y: p.frame.midY - h / 2, width: w, height: h)
    }

    private func check<R: SolitaireRules, L: SolitaireLayout>(_ rules: R.Type, _ layoutType: L.Type, _ mode: GameMode, portraitWidth: (CGFloat) -> CGFloat,
                                                              file: StaticString = #filePath, line: UInt = #line) where L.State == R.State {
        for device in Self.devices {
            let size = device.table
            for left in [false, true] {
                let state = R.deal(seed: 7, mode: mode)
                let layout = L(state: state, size: size, prefs: TablePrefs(leftHanded: left, largeCards: false))
                let tag = "\(mode.kind) \(device.name) links=\(left)"
                XCTAssertTrue(TableOrientation.isLandscape(size), tag, file: file, line: line)
                let bounds = CGRect(origin: .zero, size: size).insetBy(dx: -0.5, dy: -0.5)
                XCTAssertLessThanOrEqual(layout.cardSize.width, SideRails.maxCardWidth + 0.001, tag, file: file, line: line)
                // Karten quer mindestens so groß wie im Hochformat
                XCTAssertGreaterThanOrEqual(layout.cardSize.width, portraitWidth(device.portraitWidth) - 0.01, "\(tag): quer kleiner als hoch", file: file, line: line)
                var minX = CGFloat.infinity, maxX = -CGFloat.infinity
                for (id, p) in layout.placements {
                    let v = visible(p)
                    XCTAssertTrue(bounds.contains(v), "\(tag) Karte \(id) \(v)", file: file, line: line)
                    minX = min(minX, v.minX); maxX = max(maxX, v.maxX)
                }
                for slot in layout.slots { minX = min(minX, slot.frame.midX - slot.frame.width * slot.scale / 2); maxX = max(maxX, slot.frame.midX + slot.frame.width * slot.scale / 2) }
                // Der Tisch nutzt mindestens 85 % der Breite neben der Leiste
                XCTAssertGreaterThanOrEqual((maxX - minX) / size.width, 0.85, "\(tag): Tisch füllt nur \(Int((maxX - minX) / size.width * 100)) % der Breite", file: file, line: line)
                // Stapel/Ablage dürfen nicht über anderen Plätzen liegen (Spalten, Ziele, Pyramide, Gipfel)
                if let stock = layout.stockTapFrame {
                    for slot in layout.slots where slot.frame != layout.stockTapFrame && !slot.frame.isEmpty {
                        let a = CGRect(x: slot.frame.midX - slot.frame.width * slot.scale / 2, y: slot.frame.midY - slot.frame.height * slot.scale / 2,
                                       width: slot.frame.width * slot.scale, height: slot.frame.height * slot.scale)
                        if a.insetBy(dx: 1, dy: 1).intersects(stock) && a != layout.targetFrame(.waste) && !(a.midX == stock.midX && a.midY == stock.midY) {
                            XCTFail("\(tag) Platz \(a) überdeckt Stapel \(stock)", file: file, line: line)
                        }
                    }
                    for (id, p) in layout.placements where layout.pileOf[id] != .stock && layout.pileOf[id] != .waste {
                        if visible(p).insetBy(dx: 1, dy: 1).intersects(stock) { XCTFail("\(tag) Karte \(id) liegt auf dem Stapel", file: file, line: line) }
                    }
                }
            }
        }
    }

    func testKlondikeQuer() { check(KlondikeRules.self, KlondikeLayout.self, .klondike(1), portraitWidth: { KlondikeLayout.cardWidth(for: $0) }) }
    func testSpiderQuer() { check(SpiderRules.self, SpiderLayout.self, .spider(2), portraitWidth: { SpiderLayout.cardWidth(for: $0) }) }
    func testFreeCellQuer() { check(FreeCellRules.self, FreeCellLayout.self, GameMode(kind: .freecell, option: 0), portraitWidth: { FreeCellLayout.cardWidth(for: $0) }) }
    func testPyramidQuer() { check(PyramidRules.self, PyramidLayout.self, GameMode(kind: .pyramid, option: 0), portraitWidth: { PyramidLayout.cardWidth(for: $0) }) }
    func testTriPeaksQuer() { check(TriPeaksRules.self, TriPeaksLayout.self, GameMode(kind: .tripeaks, option: 0), portraitWidth: { TriPeaksLayout.cardWidth(for: $0) }) }
    func testGolfQuer() { check(GolfRules.self, GolfLayout.self, GameMode(kind: .golf, option: 0), portraitWidth: { GolfLayout.cardWidth(for: $0) }) }
    func testYukonQuer() { check(YukonRules.self, YukonLayout.self, .yukon, portraitWidth: { KlondikeLayout.cardWidth(for: $0) }) }

    func testHochformatBleibtUnveraendert() {
        let size = CGSize(width: 393, height: 600)
        XCTAssertFalse(TableOrientation.isLandscape(size))
        let k = KlondikeLayout(state: GameState(), size: size, prefs: TablePrefs())
        XCTAssertEqual(k.originX, KlondikeLayout.margin)
        XCTAssertEqual(k.cardWidth, KlondikeLayout.cardWidth(for: size.width), accuracy: 0.001)
    }

    // MARK: R2c – Ziele und Seitenspalte, volle Höhe, Mindestabstand ohne Ausnahme

    /// Kleinstes iPhone quer (667 × 375): Tischfläche neben der senkrechten Leiste
    private let smallest = Device(name: "iPhone 13 mini", screen: CGSize(width: 812, height: 375), insetX: 44, insetBottom: 21).table

    private func longKlondike(up: Int) -> GameState {
        var g = GameState()
        let all = CardID.all
        g.cols[0] = Column(down: Array(all[0..<6]), up: Array(all[6..<(6 + up)]))
        g.cols[1] = Column(down: Array(all[30..<35]), up: Array(all[35..<39]))
        return g
    }

    /// Alle offenen Karten einer Spalte: ohne Block liegen die Oberkanten mindestens Indexhöhe auseinander
    private func assertReadable(_ placements: [CardID: CardPlacement], column: [CardID], width: CGFloat, large: Bool = false, _ msg: String, line: UInt = #line) {
        let ys = column.compactMap { placements[$0]?.frame.minY }
        let index = TableOrientation.indexHeight(width: width, large: large)
        for (a, b) in zip(ys, ys.dropFirst()) where b - a > ColumnPlan.blockStep + 0.01 {      // dichter Block: bewusst eng
            XCTAssertGreaterThanOrEqual(b - a, index + 3 - 0.01, msg, line: line)
        }
    }

    func testKlondikeSechsVerdecktDreizehnOffenQuerLesbar() {
        for left in [false, true] {
            let g = longKlondike(up: 13)
            let layout = KlondikeLayout(state: g, size: smallest, prefs: TablePrefs(leftHanded: left))
            XCTAssertGreaterThanOrEqual(layout.cardWidth, SideRails.minCardWidth, "Karte ≥ 34 pt")
            XCTAssertEqual(layout.rowY, SideRails.topY, "keine obere Reihe: Spalten über die volle Höhe")
            // Auf dem kleinsten iPhone reichen 310 pt für 6 + 13 Karten nicht: dann ein kleiner Block, nie ein Abstand unter der Regel
            XCTAssertGreaterThanOrEqual(13 - (layout.collapsedBlocks.first?.count ?? 0), 5, "mindestens 5 offene Karten voll, Rest im Block")
            assertReadable(layout.placements, column: g.cols[0].up, width: layout.cardWidth, "Abstand links=\(left)")
            let roomy = KlondikeLayout(state: g, size: CGSize(width: 640, height: 360), prefs: TablePrefs(leftHanded: left))
            XCTAssertGreaterThanOrEqual(13 - (roomy.collapsedBlocks.first?.count ?? 0), 6, "mit mehr Höhe mindestens 6 offene Karten voll")
            assertReadable(roomy.placements, column: g.cols[0].up, width: roomy.cardWidth, "Abstand groß links=\(left)")
            XCTAssertLessThanOrEqual(layout.columnBottoms.max() ?? 0, smallest.height + 0.5)
            // Ziele senkrecht an der einen, Stapel/Ablage an der anderen Seite
            let f = (0..<4).map { layout.foundationFrame($0) }
            XCTAssertLessThanOrEqual(Set(f.map(\.minX)).count, 2, "Ziele senkrecht oder 2 × 2")
            XCTAssertEqual(f.map(\.minY), f.map(\.minY).sorted())
            XCTAssertEqual(layout.stockFrame.minX < f[0].minX, left, "Linkshänder gespiegelt")
            for c in layout.placements.keys where layout.pileOf[c] == .column(0) || layout.pileOf[c] == .column(6) {
                XCTAssertFalse(layout.placements[c]!.frame.intersects(f[0]), "Spalte überdeckt Ziel")
            }
        }
    }

    func testZuLangeSpalteWirdBlockMitZaehler() {
        let g = longKlondike(up: 19)
        let layout = KlondikeLayout(state: g, size: smallest, prefs: TablePrefs())
        let block = layout.collapsedBlocks.first
        XCTAssertNotNil(block)
        XCTAssertEqual(block?.column, 0)
        XCTAssertGreaterThanOrEqual(block?.count ?? 0, 2)
        let up = g.cols[0].up
        let full = up.count - (block?.count ?? 0)
        XCTAssertLessThanOrEqual(full, ColumnPlan.maxFull, "höchstens 12 Karten voll")
        // Karten im Block sind nicht greifbar, die vollen schon
        for (i, c) in up.enumerated() { XCTAssertEqual(layout.sources[c] != nil, i >= up.count - full, "Karte \(i)") }
        assertReadable(layout.placements, column: Array(up.suffix(full)), width: layout.cardWidth, "volle Karten lesbar")
        XCTAssertLessThanOrEqual(layout.columnBottoms.max() ?? 0, smallest.height + 0.5)
        // Aufklappen: alle Karten greifbar, nichts läuft über den Rand
        let open = KlondikeLayout(state: g, size: smallest, prefs: TablePrefs(unfolded: 0))
        XCTAssertTrue(open.collapsedBlocks.isEmpty)
        XCTAssertEqual(up.filter { open.sources[$0] != nil }.count, up.count)
        XCTAssertLessThanOrEqual(open.columnBottoms[0], smallest.height + 0.5)
    }

    func testYukonQuerLesbarUndBlock() {
        var s = YukonState()
        let all = CardID.all
        s.cols[6] = Column(down: Array(all[0..<6]), up: Array(all[6..<19]))
        s.cols[2] = Column(down: Array(all[20..<22]), up: Array(all[22..<40]))        // 18 offene: Block
        let layout = YukonLayout(state: s, size: smallest, prefs: TablePrefs())
        XCTAssertGreaterThanOrEqual(layout.cardWidth, SideRails.minCardWidth)
        XCTAssertTrue(layout.collapsedBlocks.map(\.column).contains(2), "18 offene Karten: Block")
        XCTAssertGreaterThanOrEqual(13 - (layout.collapsedBlocks.first { $0.column == 6 }?.count ?? 0), 4, "13 offene: mindestens 4 voll (Karte + 3 Fächerstufen)")
        assertReadable(layout.placements, column: s.cols[6].up, width: layout.cardWidth, "Yukon 13 offene")
        XCTAssertLessThanOrEqual(layout.columnBottoms.max() ?? 0, smallest.height + 0.5)
        // Ziele rechts im Hochformat bleiben unverändert: Linkshänder quer = Ziele rechts
        let rechts = YukonLayout(state: s, size: smallest, prefs: TablePrefs(leftHanded: true))
        XCTAssertGreaterThan(rechts.foundationFrame(0).minX, rechts.slotX(6))
        XCTAssertLessThan(layout.foundationFrame(0).minX, layout.slotX(0))
    }

    func testFreeCellQuerZellenRechtsZieleLinks() {
        var f = FreeCellState()
        f.cols[0] = Array(CardID.all[0..<13])
        let layout = FreeCellLayout(state: f, size: smallest, prefs: TablePrefs())
        XCTAssertGreaterThanOrEqual(layout.cardWidth, SideRails.minCardWidth)
        XCTAssertLessThan(layout.foundationFrame(0).maxX, layout.slotX(0))
        XCTAssertGreaterThan(layout.cellFrame(0).minX, layout.slotX(7) + layout.cardWidth)
        XCTAssertEqual(Set((0..<4).map { layout.cellFrame($0).minX }).count, 1)
        assertReadable(layout.placements, column: f.cols[0], width: layout.cardWidth, "FreeCell 13 Karten")
        XCTAssertLessThanOrEqual(layout.columnBottoms.max() ?? 0, smallest.height + 0.5)
    }
}
