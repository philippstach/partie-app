// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SpielSolitaer

/// Gerätegrößen (G): alle sieben Spiele hoch und quer auf den kleinsten und größten iPhones (genaue Punktmaße), normale und große Karten:
/// alles liegt im Feld, Karten nicht schmaler als 40 pt (Spider/TriPeaks 30 pt)
final class GeraeteTests: XCTestCase {
    struct Geraet {
        var name: String
        var screen: CGSize        // hochkant (Punkte)
        var insetTop: CGFloat
        var insetBottom: CGFloat
        var insetSide: CGFloat    // quer, seitlich (Notch / Dynamic Island)
    }
    static let geraete = [Geraet(name: "iPhone SE 3", screen: CGSize(width: 375, height: 667), insetTop: 20, insetBottom: 0, insetSide: 0),
                          Geraet(name: "iPhone 13 mini", screen: CGSize(width: 375, height: 812), insetTop: 50, insetBottom: 34, insetSide: 44),
                          Geraet(name: "iPhone 17e", screen: CGSize(width: 390, height: 844), insetTop: 47, insetBottom: 34, insetSide: 47),
                          Geraet(name: "iPhone 17 Pro", screen: CGSize(width: 402, height: 874), insetTop: 62, insetBottom: 34, insetSide: 62),
                          Geraet(name: "iPhone 17 Pro Max", screen: CGSize(width: 440, height: 956), insetTop: 62, insetBottom: 34, insetSide: 62)]

    /// Tischfläche hochkant: Bildschirm minus Ränder, Kopfzeile samt Abstand (50 pt) und untere Leiste (56 pt)
    static func tischHoch(_ g: Geraet) -> CGSize { CGSize(width: g.screen.width, height: g.screen.height - g.insetTop - g.insetBottom - 50 - 56) }
    /// Tischfläche quer: gedrehter Bildschirm minus seitliche Ränder und senkrechte Leiste (72 pt), Kopfzeile (50 pt) und unten
    static func tischQuer(_ g: Geraet) -> CGSize {
        CGSize(width: g.screen.height - 2 * g.insetSide - 72, height: g.screen.width - min(g.insetBottom, 21) - 50)
    }

    private func check<R: SolitaireRules, L: SolitaireLayout>(_ rules: R.Type, _ layoutType: L.Type, _ mode: GameMode,
                                                              file: StaticString = #filePath, line: UInt = #line) where L.State == R.State {
        for g in Self.geraete {
            for (lage, size) in [("hoch", Self.tischHoch(g)), ("quer", Self.tischQuer(g))] {
                for large in [false, true] {
                    for left in [false, true] {
                        let layout = L(state: R.deal(seed: 7, mode: mode), size: size, prefs: TablePrefs(leftHanded: left, largeCards: large))
                        let tag = "\(mode.kind) \(g.name) \(lage) gross=\(large) links=\(left) \(Int(size.width))×\(Int(size.height))"
                        // Spider (10 Spalten) und TriPeaks (10 Karten in der unteren Reihe) sind hochkant bauartbedingt schmaler: dort ≥ 30 pt
                        let minWidth: CGFloat = [.spider, .tripeaks].contains(mode.kind) ? 30 : 40
                        XCTAssertGreaterThanOrEqual(layout.cardSize.width, minWidth, "\(tag): Karte zu schmal", file: file, line: line)
                        let bounds = CGRect(origin: .zero, size: size).insetBy(dx: -0.5, dy: -0.5)
                        for (id, p) in layout.placements {
                            let w = p.frame.width * p.scale, h = p.frame.height * p.scale
                            let v = CGRect(x: p.frame.midX - w / 2, y: p.frame.midY - h / 2, width: w, height: h)
                            XCTAssertTrue(bounds.contains(v), "\(tag): Karte \(id) \(v) außerhalb", file: file, line: line)
                        }
                    }
                }
            }
        }
    }

    func testKlondike() { check(KlondikeRules.self, KlondikeLayout.self, .klondike(1)); check(KlondikeRules.self, KlondikeLayout.self, .klondike(3)) }
    func testSpider() { check(SpiderRules.self, SpiderLayout.self, .spider(1)); check(SpiderRules.self, SpiderLayout.self, .spider(4)) }
    func testFreeCell() { check(FreeCellRules.self, FreeCellLayout.self, GameMode(kind: .freecell, option: 0)) }
    func testPyramid() { check(PyramidRules.self, PyramidLayout.self, GameMode(kind: .pyramid, option: 0)) }
    func testTriPeaks() { check(TriPeaksRules.self, TriPeaksLayout.self, GameMode(kind: .tripeaks, option: 0)) }
    func testGolf() { check(GolfRules.self, GolfLayout.self, GameMode(kind: .golf, option: 0)) }
    func testYukon() { check(YukonRules.self, YukonLayout.self, .yukon) }

    /// U3: Pyramid, TriPeaks und Golf hochkant – der Block aus Feld und Stapel/Ablage steht senkrecht etwas über der Mitte
    /// (oberer Rand ≈ 0,45 des freien Platzes), nicht oben am Rand klebend
    private func checkMittig<R: SolitaireRules, L: SolitaireLayout>(_ rules: R.Type, _ layoutType: L.Type, _ mode: GameMode, file: StaticString = #filePath, line: UInt = #line) where L.State == R.State {
        let sizes = [CGSize(width: 402, height: 640), CGSize(width: 1032, height: 1240), CGSize(width: 820, height: 1000)]
        for size in sizes {
            let layout = L(state: R.deal(seed: 7, mode: mode), size: size, prefs: TablePrefs())
            var minY = CGFloat.infinity, maxY = -CGFloat.infinity
            for (_, p) in layout.placements { minY = min(minY, p.frame.minY); maxY = max(maxY, p.frame.maxY) }
            let free = size.height - (maxY - minY)
            guard free > 120 else { continue }
            let anteil = minY / free
            XCTAssertGreaterThan(anteil, 0.25, "\(mode.kind) \(size): Block klebt oben (\(Int(anteil * 100)) % des freien Platzes oben)", file: file, line: line)
            XCTAssertLessThan(anteil, 0.55, "\(mode.kind) \(size): Block zu weit unten", file: file, line: line)
        }
    }

    func testPyramidTriPeaksGolfSenkrechtMittig() {
        checkMittig(PyramidRules.self, PyramidLayout.self, GameMode(kind: .pyramid, option: 0))
        checkMittig(TriPeaksRules.self, TriPeaksLayout.self, GameMode(kind: .tripeaks, option: 0))
        checkMittig(GolfRules.self, GolfLayout.self, GameMode(kind: .golf, option: 0))
    }
}
