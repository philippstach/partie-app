// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SpielSolitaer

/// iPad: Tischklasse nach Fensterbreite, Kartenbreiten und Platzbedarf auf iPad-Größen (hoch, quer, Split View, Stage Manager)
final class IPadTests: XCTestCase {
    struct Fenster { var name: String; var size: CGSize }
    static let fenster = [Fenster(name: "iPad mini hoch", size: CGSize(width: 744, height: 1133)),
                          Fenster(name: "iPad mini quer", size: CGSize(width: 1133, height: 744)),
                          Fenster(name: "iPad hoch", size: CGSize(width: 820, height: 1180)),
                          Fenster(name: "iPad Air 13 hoch", size: CGSize(width: 1032, height: 1376)),
                          Fenster(name: "iPad Pro 13 hoch", size: CGSize(width: 1032, height: 1376)),
                          Fenster(name: "iPad Pro 13 quer", size: CGSize(width: 1376, height: 1032)),
                          Fenster(name: "Pro 13 quer Split ½", size: CGSize(width: 678, height: 1032)),
                          Fenster(name: "Pro 13 quer Split ⅔", size: CGSize(width: 1032, height: 1032)),
                          Fenster(name: "Pro 13 quer Split ⅓", size: CGSize(width: 438, height: 1032)),
                          Fenster(name: "Stage Manager klein", size: CGSize(width: 700, height: 520))]

    /// Tischfläche: Fenster minus Kopfzeile (mit Statusleisten-Abstand 64 pt) und Leiste (quer senkrecht 72 pt, sonst unten 72 pt)
    static func tisch(_ f: Fenster) -> CGSize {
        TischLayout.entscheide(f.size) == .breitQuer ? CGSize(width: f.size.width - 72, height: f.size.height - 64)
                                                     : CGSize(width: f.size.width, height: f.size.height - 64 - 72)
    }

    func testEntscheide() {
        XCTAssertEqual(TischLayout.entscheide(breite: 599, hoehe: 1000), .schmal)
        XCTAssertEqual(TischLayout.entscheide(breite: 600, hoehe: 1000), .breitHoch)
        XCTAssertEqual(TischLayout.entscheide(breite: 1032, hoehe: 1376), .breitHoch)
        XCTAssertEqual(TischLayout.entscheide(breite: 1000, hoehe: 1000), .breitHoch)
        XCTAssertEqual(TischLayout.entscheide(breite: 1160, hoehe: 1000), .breitQuer)
        XCTAssertEqual(TischLayout.entscheide(breite: 1376, hoehe: 1032), .breitQuer)
        XCTAssertEqual(TischLayout.entscheide(breite: 438, hoehe: 1032), .schmal)
        XCTAssertEqual(TischLayout.entscheide(breite: 667, hoehe: 375), .breitQuer, "Drehen ändert die Klasse")
    }

    private func check<R: SolitaireRules, L: SolitaireLayout>(_ rules: R.Type, _ layoutType: L.Type, _ mode: GameMode,
                                                              file: StaticString = #filePath, line: UInt = #line) where L.State == R.State {
        for f in Self.fenster {
            let size = Self.tisch(f)
            for left in [false, true] {
                let layout = L(state: R.deal(seed: 7, mode: mode), size: size, prefs: TablePrefs(leftHanded: left, largeCards: false))
                let tag = "\(mode.kind) \(f.name) links=\(left)"
                XCTAssertLessThanOrEqual(layout.cardSize.width, TischMetrics.maxCardWidth + 0.001, tag, file: file, line: line)
                XCTAssertGreaterThanOrEqual(layout.cardSize.width, 40, tag, file: file, line: line)
                let bounds = CGRect(origin: .zero, size: size).insetBy(dx: -0.5, dy: -0.5)
                for (id, p) in layout.placements {
                    let w = p.frame.width * p.scale, h = p.frame.height * p.scale
                    let v = CGRect(x: p.frame.midX - w / 2, y: p.frame.midY - h / 2, width: w, height: h)
                    XCTAssertTrue(bounds.contains(v), "\(tag) Karte \(id) \(v) außerhalb \(size)", file: file, line: line)
                }
            }
        }
    }

    func testKlondike() { check(KlondikeRules.self, KlondikeLayout.self, .klondike(1)); check(KlondikeRules.self, KlondikeLayout.self, .klondike(3)) }
    func testSpider() { check(SpiderRules.self, SpiderLayout.self, .spider(2)) }
    func testFreeCell() { check(FreeCellRules.self, FreeCellLayout.self, GameMode(kind: .freecell, option: 0)) }
    func testPyramid() { check(PyramidRules.self, PyramidLayout.self, GameMode(kind: .pyramid, option: 0)) }
    func testTriPeaks() { check(TriPeaksRules.self, TriPeaksLayout.self, GameMode(kind: .tripeaks, option: 0)) }
    func testGolf() { check(GolfRules.self, GolfLayout.self, GameMode(kind: .golf, option: 0)) }
    func testYukon() { check(YukonRules.self, YukonLayout.self, .yukon) }

    /// Auf iPad-Breiten sind die Karten deutlich größer als auf dem iPhone (Klondike hoch: ≥ 100 pt auf dem Pro 13″)
    func testKartenWachsen() {
        let pro = Self.tisch(Self.fenster[4]), schmal = Self.tisch(Self.fenster[8])
        XCTAssertGreaterThanOrEqual(KlondikeLayout.cardWidth(in: pro), 100)
        XCTAssertLessThan(KlondikeLayout.cardWidth(in: schmal), 70, "Split ⅓ bleibt wie ein großes iPhone")
        XCTAssertEqual(KlondikeLayout.cardWidth(in: CGSize(width: 393, height: 600)), KlondikeLayout.cardWidth(for: 393), accuracy: 0.001, "iPhone unverändert")
    }
}
