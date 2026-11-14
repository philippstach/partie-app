// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

/// TriPeaks im Hochformat: drei Gipfel nebeneinander (Reihe 3 zehn Karten breit), Reihen überlappen um 50 % der Höhe.
/// Unten Stapel (links, mit Anzahl) und Ablage (mittig, 1,3-fach), darüber „Kette n“ in Gold.
struct TriPeaksLayout: SolitaireLayout {
    typealias State = TriPeaksState

    static let margin: CGFloat = 4
    static let gap: CGFloat = 3
    static let aspect: CGFloat = 1.4
    static let rowStep: CGFloat = 0.5
    let rowStepValue: CGFloat
    static let wasteScale: CGFloat = 1.3

    let size: CGSize
    let cardWidth: CGFloat
    let cardHeight: CGFloat
    let topY: CGFloat
    let bottomRowY: CGFloat
    private let stockCountValue: Int
    private let chain: Int
    private let landscape: Bool
    /// Linke Kante der Gipfel und Mitte der Seitenspalte (Querformat: Stapel und Ablage rechts, Linkshänder links)
    private let fieldX: CGFloat
    private let sideMid: CGFloat

    private(set) var placements: [CardID: CardPlacement] = [:]
    private(set) var sources: [CardID: CardSource] = [:]
    private(set) var pileOf: [CardID: Pile] = [:]

    static func cardWidth(for width: CGFloat) -> CGFloat { (width - 2 * margin - 9 * gap) / 10 }

    init(state: TriPeaksState, size: CGSize, prefs: TablePrefs) {
        self.size = size
        landscape = TableOrientation.isLandscape(size)
        if landscape {
            // Kartenbreite aus der Breite (10 Karten + Seitenspalte, höchstens 96 pt); die Höhe begrenzt nur so weit, dass vier Reihen
            // mit Reihenabstand ≥ Indexhöhe + 3 pt und die Seitenspalte (Stapel, Ablage 1,3-fach) untereinander passen (Karte bis 34 pt schmaler)
            let side: CGFloat = 26
            let byWidth = (size.width - 2 * Self.margin - 9 * Self.gap - side) / (10 + Self.wasteScale)
            cardWidth = TableOrientation.fittingWidth(cap: min(byWidth, SideRails.maxCardWidth), floor: SideRails.minCardWidth) { w in
                let h = w * Self.aspect
                return 3 * (TableOrientation.indexHeight(width: w, large: prefs.largeCards) + 3) + h + 20 <= size.height
                    && h + 26 + h * Self.wasteScale + 26 + 16 <= size.height
            }
        } else {
            cardWidth = Self.cardWidth(for: size.width)
        }
        cardHeight = cardWidth * Self.aspect
        rowStepValue = landscape
            ? min(Self.rowStep, max((TableOrientation.indexHeight(width: cardWidth, large: prefs.largeCards) + 3) / cardHeight,
                                    (size.height - 20 - cardHeight) / (3 * cardHeight)))
            : Self.rowStep
        stockCountValue = state.stock.count
        chain = state.chain
        let fieldWidth = 10 * cardWidth + 9 * Self.gap
        if landscape {
            let sideWidth = cardWidth * Self.wasteScale
            let left = (size.width - (fieldWidth + 26 + sideWidth)) / 2
            fieldX = prefs.leftHanded ? left + sideWidth + 26 : left
            sideMid = prefs.leftHanded ? left + sideWidth / 2 : left + fieldWidth + 26 + sideWidth / 2
        } else {
            fieldX = (size.width - fieldWidth) / 2
            sideMid = size.width / 2
        }
        // Gipfel + Abstand + „Kette“-Zeile + Ablage als ein Block, in der Höhe etwas über der Mitte
        let peaksHeight = 3 * rowStepValue * cardHeight + cardHeight
        let wasteHeight = cardHeight * Self.wasteScale
        let gapBetween: CGFloat = 56
        let block = peaksHeight + gapBetween + wasteHeight + 22      // 22: Stapelzahl unter dem Stapel
        if landscape {
            topY = max(10, (size.height - peaksHeight) / 2)
            bottomRowY = topY      // Seitenspalte beginnt auf Höhe der Gipfel
        } else {
            topY = max(12, (size.height - block) * 0.45)
            bottomRowY = topY + peaksHeight + gapBetween
        }
        build(state)
    }

    var cardSize: CGSize { CGSize(width: cardWidth, height: cardHeight) }
    var cardIDs: [CardID] { CardID.all }
    var dropPiles: [Pile] { [] }
    func dropTarget(at point: CGPoint) -> Pile? { nil }

    // MARK: Plätze

    private var pitch: CGFloat { cardWidth + Self.gap }

    /// Waagerechte Lage in Kartenabständen (Reihe 3: 0…9, darüber jeweils mittig über den verdeckten Karten)
    private func slotUnits(_ t: Int) -> CGFloat {
        let i = TriPeaksState.index(of: t)
        switch TriPeaksState.row(of: t) {
        case 3: return CGFloat(i)
        case 2: return CGFloat(i) + 0.5
        case 1: return CGFloat(i / 2 * 3 + 1 + i % 2)
        default: return CGFloat(i) * 3 + 1.5
        }
    }

    func placeFrame(_ t: Int) -> CGRect {
        let r = TriPeaksState.row(of: t)
        return CGRect(x: fieldX + slotUnits(t) * pitch, y: topY + CGFloat(r) * rowStepValue * cardHeight, width: cardWidth, height: cardHeight)
    }

    /// Stapel links, Ablage mittig (der Rahmen ist die Größe einer normalen Karte, die Ablagekarte wird 1,3-fach gezeichnet)
    var stockFrame: CGRect {
        if landscape { return CGRect(x: sideMid - cardWidth / 2, y: sideTop, width: cardWidth, height: cardHeight) }
        let wasteW = cardWidth * Self.wasteScale
        return CGRect(x: size.width / 2 - wasteW / 2 - 28 - cardWidth, y: bottomRowY + (cardHeight * Self.wasteScale - cardHeight) / 2,
                      width: cardWidth, height: cardHeight)
    }
    /// Querformat: Seitenspalte (Stapel, Zahl, Ablage, Kette) mittig in der Höhe
    private var sideTop: CGFloat { max(8, (size.height - (cardHeight + 26 + cardHeight * Self.wasteScale + 26)) / 2) }
    private var landscapeWasteCenterY: CGFloat { sideTop + cardHeight + 26 + cardHeight * Self.wasteScale / 2 }
    var wasteFrame: CGRect {
        if landscape { return CGRect(x: sideMid - cardWidth / 2, y: landscapeWasteCenterY - cardHeight / 2, width: cardWidth, height: cardHeight) }
        return CGRect(x: (size.width - cardWidth) / 2, y: bottomRowY + (cardHeight * Self.wasteScale - cardHeight) / 2,
                                    width: cardWidth, height: cardHeight) }

    var stockTapFrame: CGRect? { stockFrame }
    var stockCountCenter: CGPoint? { CGPoint(x: stockFrame.midX, y: stockFrame.maxY + 12) }
    var stockCaption: String? { stockCountValue > 0 ? "\(stockCountValue)" : nil }
    var badge: (text: String, center: CGPoint, glow: Bool)? {
        guard chain >= 2 else { return nil }
        let center = landscape ? CGPoint(x: sideMid, y: landscapeWasteCenterY + cardHeight * Self.wasteScale / 2 + 16)
                               : CGPoint(x: size.width / 2, y: bottomRowY - 18)
        return (String(localized: "Kette \(chain)"), center, chain >= 5)
    }

    var slots: [SlotSpec] {
        [SlotSpec(id: 20, frame: stockFrame, dimmed: true), SlotSpec(id: 21, frame: wasteFrame)]
    }

    func targetFrame(_ pile: Pile) -> CGRect {
        switch pile {
        case let .column(k): placeFrame(k)
        case .waste:
            // Die Ablagekarte wird 1,3-fach gezeichnet: Hervorhebung passend dazu
            wasteFrame.insetBy(dx: -cardWidth * (Self.wasteScale - 1) / 2, dy: -cardHeight * (Self.wasteScale - 1) / 2)
        case .stock: stockFrame
        default: .zero
        }
    }

    func landingOrigin(_ pile: Pile) -> CGPoint { targetFrame(pile).origin }

    // MARK: Berechnung

    private mutating func build(_ state: TriPeaksState) {
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
        // Untere Reihen liegen über den oberen
        for t in 0..<TriPeaksState.places {
            guard let c = state.peaks[t] else { continue }
            let free = state.isFree(t)
            placements[c] = CardPlacement(frame: placeFrame(t), faceUp: free, z: 300 + Double(t))
            pileOf[c] = .column(t)
            if free { sources[c] = CardSource(pile: .column(t), count: 1) }
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
