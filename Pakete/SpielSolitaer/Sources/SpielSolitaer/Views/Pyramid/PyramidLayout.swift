// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

/// Pyramid im Hochformat: 7 Reihen, Reihe r hat r + 1 Karten und ist um (6 − r) × ½ Kartenabstand eingerückt; Reihen überlappen
/// um 50 % der Höhe. Unten mittig Stapel (links) und Ablage (rechts), darunter „Durchgang 2/3“.
struct PyramidLayout: SolitaireLayout {
    typealias State = PyramidState

    static let margin: CGFloat = 8
    static let gap: CGFloat = 5
    static let aspect: CGFloat = 1.4
    static let rowStep: CGFloat = 0.5
    let rowStepValue: CGFloat

    let size: CGSize
    let cardWidth: CGFloat
    let cardHeight: CGFloat
    let topY: CGFloat
    /// Obere Kante von Stapel und Ablage
    let bottomRowY: CGFloat
    private let passes: Int
    private let leftHanded: Bool
    private let landscape: Bool
    /// Linke Kante der Pyramide (Mitte der Fläche im Hochformat, im Querformat Platz für Stapel und Ablage daneben)
    private let fieldX: CGFloat
    private let sideX: CGFloat

    private(set) var placements: [CardID: CardPlacement] = [:]
    private(set) var sources: [CardID: CardSource] = [:]
    private(set) var pileOf: [CardID: Pile] = [:]

    static func cardWidth(for width: CGFloat) -> CGFloat { (width - 2 * margin - 6 * gap) / 7 }

    init(state: PyramidState, size: CGSize, prefs: TablePrefs) {
        self.size = size
        leftHanded = prefs.leftHanded
        landscape = TableOrientation.isLandscape(size)
        if landscape {
            // Kartenbreite aus der Breite (Pyramide 7 Karten + Seitenspalte, höchstens 96 pt); die Höhe begrenzt nur so weit, dass
            // sieben Reihen mit Reihenabstand ≥ Indexhöhe + 3 pt untereinander passen (Karte bis 34 pt schmaler)
            let byWidth = (size.width - 2 * Self.margin - 6 * Self.gap - 28) / 8
            cardWidth = TableOrientation.fittingWidth(cap: min(byWidth, SideRails.maxCardWidth), floor: SideRails.minCardWidth) { w in
                6 * (TableOrientation.indexHeight(width: w, large: prefs.largeCards) + 3) + w * Self.aspect + 16 <= size.height
            }
        } else if TischLayout.entscheide(size) == .breitHoch {
            // Breites Hochformat (iPad): Karten aus der Breite (höchstens 150 pt), die Höhe begrenzt: Pyramide, Stapel und Ablage müssen passen
            cardWidth = TableOrientation.fittingWidth(cap: min(Self.cardWidth(for: size.width), TischMetrics.maxCardWidth), floor: SideRails.minCardWidth) { w in
                8 + 6 * Self.rowStep * w * Self.aspect + 2 * w * Self.aspect + 14 + 30 <= size.height
            }
        } else {
            cardWidth = Self.cardWidth(for: size.width)
        }
        cardHeight = cardWidth * Self.aspect
        // Reihenabstand: so groß wie es passt (bis 0,5 × Höhe), quer nie unter Indexhöhe + 3 pt
        rowStepValue = landscape
            ? min(Self.rowStep, max((TableOrientation.indexHeight(width: cardWidth, large: prefs.largeCards) + 3) / cardHeight,
                                    (size.height - 16 - cardHeight) / (6 * cardHeight)))
            : Self.rowStep
        passes = state.passes
        let pyramidHeight = 6 * rowStepValue * cardHeight + cardHeight
        if landscape {
            topY = 8
            bottomRowY = max(topY + pyramidHeight + 14, size.height - cardHeight - 30)
        } else {
            // Hochformat: Pyramide, Stapel und Ablage als ein Block, in der Höhe etwas über der Mitte (Faktor 0,45)
            let gapToStock: CGFloat = 40
            let block = pyramidHeight + gapToStock + cardHeight + 22          // 22: Zeile „Durchgang 1/3“ unter dem Stapel
            topY = max(8, (size.height - block) * 0.45)
            bottomRowY = topY + pyramidHeight + gapToStock
        }
        let pyramidWidth = 7 * cardWidth + 6 * Self.gap
        if landscape {
            // Pyramide und Seitenspalte zusammen mittig; Linkshänder: Seitenspalte links
            let block = pyramidWidth + 28 + cardWidth
            let left = (size.width - block) / 2
            fieldX = prefs.leftHanded ? left + cardWidth + 28 : left
            sideX = prefs.leftHanded ? left : left + pyramidWidth + 28
        } else {
            fieldX = (size.width - pyramidWidth) / 2
            sideX = 0
        }
        build(state)
    }

    var cardSize: CGSize { CGSize(width: cardWidth, height: cardHeight) }
    var cardIDs: [CardID] { CardID.all }
    var dropPiles: [Pile] { [] }
    func dropTarget(at point: CGPoint) -> Pile? { nil }

    // MARK: Plätze

    private var pitch: CGFloat { cardWidth + Self.gap }

    func placeFrame(_ k: Int) -> CGRect {
        let r = PyramidState.row(of: k), i = PyramidState.column(of: k)
        let rowWidth = CGFloat(r + 1) * cardWidth + CGFloat(r) * Self.gap
        let pyramidWidth = 7 * cardWidth + 6 * Self.gap
        let x = fieldX + (pyramidWidth - rowWidth) / 2 + CGFloat(i) * pitch
        return CGRect(x: x, y: topY + CGFloat(r) * rowStepValue * cardHeight, width: cardWidth, height: cardHeight)
    }

    /// Querformat: Stapel oben, Ablage darunter, rechts neben der Pyramide (Linkshänder links)
    private var sideTop: CGFloat { max(topY, (size.height - (2 * cardHeight + 34)) / 2) }
    var stockFrame: CGRect {
        landscape ? CGRect(x: sideX, y: sideTop, width: cardWidth, height: cardHeight)
                  : CGRect(x: size.width / 2 - cardWidth - 6, y: bottomRowY, width: cardWidth, height: cardHeight)
    }
    var wasteFrame: CGRect {
        landscape ? CGRect(x: sideX, y: sideTop + cardHeight + 34, width: cardWidth, height: cardHeight)
                  : CGRect(x: size.width / 2 + 6, y: bottomRowY, width: cardWidth, height: cardHeight)
    }

    var stockTapFrame: CGRect? { stockFrame }
    var stockCountCenter: CGPoint? {
        landscape ? CGPoint(x: stockFrame.midX, y: stockFrame.maxY + 12)
                  : CGPoint(x: size.width / 2, y: bottomRowY + cardHeight + 12)
    }
    var stockCaption: String? { String(localized: "Durchgang \(passes)/\(PyramidState.maxPasses)") }

    /// Leere Plätze: Stapel (Kreispfeil) und Ablage
    var slots: [SlotSpec] {
        [SlotSpec(id: 20, frame: stockFrame, symbol: "arrow.counterclockwise", dimmed: passes >= PyramidState.maxPasses),
         SlotSpec(id: 21, frame: wasteFrame)]
    }

    func targetFrame(_ pile: Pile) -> CGRect {
        switch pile {
        case let .column(k): placeFrame(k)
        case .waste: wasteFrame
        case .stock: stockFrame
        default: .zero
        }
    }

    func landingOrigin(_ pile: Pile) -> CGPoint { targetFrame(pile).origin }

    // MARK: Berechnung

    private mutating func build(_ state: PyramidState) {
        // Austeilen: alle 52 Karten verdeckt auf dem Stapel
        for (i, c) in state.stock.enumerated() {
            var f = stockFrame
            f.origin.y -= CGFloat(min(state.stock.count - 1 - i, 2))
            placements[c] = CardPlacement(frame: f, faceUp: false, z: Double(i) * 0.01)
            pileOf[c] = .stock
        }
        for (i, c) in state.waste.enumerated() {
            placements[c] = CardPlacement(frame: wasteFrame, faceUp: true, z: 200 + Double(i))
            pileOf[c] = .waste
            if i == state.waste.count - 1 { sources[c] = CardSource(pile: .waste, count: 1) }
        }
        // Untere Reihen liegen über den oberen
        for k in 0..<PyramidState.places {
            guard let c = state.pyramid[k] else { continue }
            let free = state.isFree(k)
            placements[c] = CardPlacement(frame: placeFrame(k), faceUp: true, z: 300 + Double(k), dimmed: !free, covered: !free)
            pileOf[c] = .column(k)
            if free { sources[c] = CardSource(pile: .column(k), count: 1) }
        }
    }

    // MARK: Sieg

    /// Wasserfall aus den abgeräumten Karten: alle 52, Könige zuerst, von der Spitze der Pyramide
    func waterfallCards() -> [(face: CardFace, origin: CGPoint)] {
        let origin = placeFrame(0).origin
        var out: [(CardFace, CGPoint)] = []
        for rank in stride(from: 13, through: 1, by: -1) {
            for suit in Suit.allCases { out.append((CardFace(rank: rank, suit: suit), origin)) }
        }
        return out
    }
}
