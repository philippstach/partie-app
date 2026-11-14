// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

/// Golf im Hochformat: 7 Spalten wie Klondike (gleiche Kartenbreite), je 5 offene Karten nach unten gefächert, nur die oberste ist spielbar.
/// Unten wie TriPeaks: Stapel links (mit Anzahl), Ablage mittig 1,3-fach, darüber „Kette n“ in Gold; liegt ein König oben, zeigt ein Schloss: nur der Stapel hilft.
struct GolfLayout: SolitaireLayout {
    typealias State = GolfState

    static let margin: CGFloat = 8
    static let gap: CGFloat = 5
    static let aspect: CGFloat = 1.4
    static let wasteScale: CGFloat = 1.3
    static let minOpenStep: CGFloat = 0.20

    let size: CGSize
    let cardWidth: CGFloat
    let cardHeight: CGFloat
    let topY: CGFloat
    let bottomRowY: CGFloat
    let openStep: CGFloat
    private let stockCountValue: Int
    private let chain: Int
    private let kingOnWaste: Bool
    private let landscape: Bool
    /// Linke Kante der Spalten und Mitte der Seitenspalte (Querformat: Stapel und Ablage rechts, Linkshänder links)
    private let fieldX: CGFloat
    private let sideMid: CGFloat

    private(set) var placements: [CardID: CardPlacement] = [:]
    private(set) var sources: [CardID: CardSource] = [:]
    private(set) var pileOf: [CardID: Pile] = [:]

    static func cardWidth(for width: CGFloat) -> CGFloat { (width - 2 * margin - 6 * gap) / 7 }

    init(state: GolfState, size: CGSize, prefs: TablePrefs) {
        self.size = size
        landscape = TableOrientation.isLandscape(size)
        let fieldWidthFor: (CGFloat) -> CGFloat = { 7 * $0 + 6 * Self.gap }
        if landscape {
            // Kartenbreite aus der Breite (7 Spalten + Seitenspalte, höchstens 96 pt); die Höhe begrenzt nur so weit,
            // dass die fünf Karten einer Spalte mit Abstand ≥ Indexhöhe + 3 pt untereinander passen (Karte bis 34 pt schmaler)
            let byWidth = (size.width - 2 * Self.margin - 6 * Self.gap - 28) / (7 + Self.wasteScale)
            cardWidth = TableOrientation.fittingWidth(cap: min(byWidth, SideRails.maxCardWidth), floor: SideRails.minCardWidth) { w in
                w * Self.aspect + 4 * (TableOrientation.indexHeight(width: w, large: prefs.largeCards) + 3) <= size.height - 24
            }
        } else {
            cardWidth = Self.cardWidth(for: size.width)
        }
        cardHeight = cardWidth * Self.aspect
        if landscape {
            let sideWidth = cardWidth * Self.wasteScale
            let fieldWidth = fieldWidthFor(cardWidth)
            let left = (size.width - (fieldWidth + 28 + sideWidth)) / 2
            fieldX = prefs.leftHanded ? left + sideWidth + 28 : left
            sideMid = prefs.leftHanded ? left + sideWidth / 2 : left + fieldWidth + 28 + sideWidth / 2
        } else {
            fieldX = Self.margin
            sideMid = size.width / 2
        }
        stockCountValue = state.stock.count
        chain = state.chain
        kingOnWaste = state.waste.last?.rank == 13
        // Spalten + Abstand + Ablage als ein Block, etwas über der Mitte. Der Fächer wächst bis 0,42 (Groß 0,46) und schrumpft, wenn es eng wird.
        let wasteHeight = cardHeight * Self.wasteScale
        let gapBetween: CGFloat = 56
        let rest = wasteHeight + gapBetween + 22 + 24
        let cap = prefs.largeCards ? 0.46 : FanMetrics.maxOpenStep
        let available = size.height - rest - cardHeight - 12
        if landscape {
            let minStep = TableOrientation.indexHeight(width: cardWidth, large: prefs.largeCards) + 3
            openStep = max(minStep, min(cardHeight * cap, (size.height - 24 - cardHeight) / CGFloat(GolfState.columnHeight - 1)))
            let columnsHeight = cardHeight + openStep * CGFloat(GolfState.columnHeight - 1)
            topY = max(10, (size.height - columnsHeight) / 2)
            bottomRowY = topY
        } else {
            openStep = max(cardHeight * Self.minOpenStep, min(cardHeight * cap, available / CGFloat(GolfState.columnHeight - 1)))
            let columnsHeight = cardHeight + openStep * CGFloat(GolfState.columnHeight - 1)
            let block = columnsHeight + gapBetween + wasteHeight + 22
            topY = max(12, (size.height - block) * 0.45)
            bottomRowY = topY + columnsHeight + gapBetween
        }
        build(state)
    }

    var cardSize: CGSize { CGSize(width: cardWidth, height: cardHeight) }
    var cardIDs: [CardID] { CardID.all }
    var dropPiles: [Pile] { [] }
    func dropTarget(at point: CGPoint) -> Pile? { nil }

    // MARK: Plätze

    func slotX(_ i: Int) -> CGFloat { fieldX + CGFloat(i) * (cardWidth + Self.gap) }

    func columnSlotFrame(_ i: Int) -> CGRect { CGRect(x: slotX(i), y: topY, width: cardWidth, height: cardHeight) }

    func cardFrame(column i: Int, index p: Int) -> CGRect {
        CGRect(x: slotX(i), y: topY + CGFloat(p) * openStep, width: cardWidth, height: cardHeight)
    }

    /// Stapel und Ablage stehen nebeneinander und sind zusammen mittig zentriert
    private var pairLeft: CGFloat { (size.width - (cardWidth + 24 + cardWidth * Self.wasteScale)) / 2 }
    /// Querformat: Seitenspalte (Stapel, Zahl, Ablage, Kette) mittig in der Höhe
    private var sideTop: CGFloat { max(8, (size.height - (cardHeight + 26 + cardHeight * Self.wasteScale + 26)) / 2) }
    private var landscapeWasteCenterY: CGFloat { sideTop + cardHeight + 26 + cardHeight * Self.wasteScale / 2 }
    var stockFrame: CGRect {
        if landscape { return CGRect(x: sideMid - cardWidth / 2, y: sideTop, width: cardWidth, height: cardHeight) }
        return CGRect(x: pairLeft, y: bottomRowY + (cardHeight * Self.wasteScale - cardHeight) / 2, width: cardWidth, height: cardHeight)
    }
    var wasteFrame: CGRect {
        if landscape { return CGRect(x: sideMid - cardWidth / 2, y: landscapeWasteCenterY - cardHeight / 2, width: cardWidth, height: cardHeight) }
        let center = pairLeft + cardWidth + 24 + cardWidth * Self.wasteScale / 2
        return CGRect(x: center - cardWidth / 2, y: bottomRowY + (cardHeight * Self.wasteScale - cardHeight) / 2, width: cardWidth, height: cardHeight)
    }

    var stockTapFrame: CGRect? { stockFrame }
    var stockCountCenter: CGPoint? { CGPoint(x: stockFrame.midX, y: stockFrame.maxY + 12) }
    var stockCaption: String? { stockCountValue > 0 ? "\(stockCountValue)" : nil }
    var badge: (text: String, center: CGPoint, glow: Bool)? {
        guard chain >= 2 else { return nil }
        let y = landscape ? landscapeWasteCenterY + cardHeight * Self.wasteScale / 2 + 16 : bottomRowY - 18
        return (String(localized: "Kette \(chain)"), CGPoint(x: wasteFrame.midX, y: y), chain >= 5)
    }
    /// Schloss an der Ablage-Ecke, wenn ein König oben liegt
    var cornerSymbol: (name: String, center: CGPoint, label: String)? {
        guard kingOnWaste else { return nil }
        let f = wasteFrame.insetBy(dx: -cardWidth * (Self.wasteScale - 1) / 2, dy: -cardHeight * (Self.wasteScale - 1) / 2)
        return ("lock.fill", CGPoint(x: f.maxX + 6, y: f.minY + 6), String(localized: "König – nur der Stapel hilft weiter"))
    }

    var slots: [SlotSpec] {
        (0..<GolfState.columnCount).map { SlotSpec(id: $0, frame: columnSlotFrame($0)) }
            + [SlotSpec(id: 20, frame: stockFrame, dimmed: true), SlotSpec(id: 21, frame: wasteFrame)]
    }

    func targetFrame(_ pile: Pile) -> CGRect {
        switch pile {
        case let .column(k): cardFrame(column: k, index: max(0, lastIndex[k] ?? 0))
        case .waste: wasteFrame.insetBy(dx: -cardWidth * (Self.wasteScale - 1) / 2, dy: -cardHeight * (Self.wasteScale - 1) / 2)
        case .stock: stockFrame
        default: .zero
        }
    }

    func landingOrigin(_ pile: Pile) -> CGPoint { targetFrame(pile).origin }

    // MARK: Berechnung

    private var lastIndex: [Int: Int] = [:]

    private mutating func build(_ state: GolfState) {
        for (i, c) in state.stock.enumerated() {
            var f = stockFrame
            f.origin.y -= CGFloat(min(state.stock.count - 1 - i, 2))
            placements[c] = CardPlacement(frame: f, faceUp: false, z: Double(i) * 0.01)
            pileOf[c] = .stock
        }
        for (i, c) in state.waste.enumerated() {
            placements[c] = CardPlacement(frame: wasteFrame, faceUp: true, z: 200 + Double(i), scale: Self.wasteScale)
            pileOf[c] = .waste
        }
        for (k, col) in state.cols.enumerated() {
            for (p, c) in col.enumerated() {
                let top = p == col.count - 1
                placements[c] = CardPlacement(frame: cardFrame(column: k, index: p), faceUp: true, z: 300 + Double(p), covered: !top)
                pileOf[c] = .column(k)
                if top { sources[c] = CardSource(pile: .column(k), count: 1) }
            }
            lastIndex[k] = col.count - 1
        }
    }

    // MARK: Sieg

    func waterfallCards() -> [(face: CardFace, origin: CGPoint)] {
        let origin = wasteFrame.origin
        var out: [(CardFace, CGPoint)] = []
        for rank in stride(from: 13, through: 1, by: -1) {
            for suit in Suit.allCases { out.append((CardFace(rank: rank, suit: suit), origin)) }
        }
        return out
    }
}
