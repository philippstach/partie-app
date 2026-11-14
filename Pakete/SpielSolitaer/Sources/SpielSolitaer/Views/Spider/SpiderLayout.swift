// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

/// Spider im Hochformat: 10 Spalten, obere Reihe mit den fertigen Reihen links und dem Stapel rechts (Linkshänder gespiegelt).
struct SpiderLayout: SolitaireLayout {
    typealias State = SpiderState

    static let margin: CGFloat = 4
    static let gap: CGFloat = 3
    static let openStep: CGFloat = 0.32
    static let maxOpenStep = FanMetrics.maxOpenStep     // ist viel Platz frei, wächst der offene Abstand bis hierher
    static let downStep: CGFloat = 0.08
    static let minOpenStep: CGFloat = 0.30
    static let minDownStep: CGFloat = 0.04
    static let doneOffset: CGFloat = 0.45      // fertige Reihen: König um 0,45 × Breite versetzt
    static let stockOffset: CGFloat = 0.18     // übrige Austeil-Runden: Rücken leicht versetzt

    let size: CGSize
    let leftHanded: Bool
    let cardWidth: CGFloat
    let cardHeight: CGFloat
    let topY: CGFloat = 6
    let rowY: CGFloat
    let originX: CGFloat
    /// Querformat: Stapel und fertige Reihen als schmale Seitenleiste (0,6 × Kartenbreite) neben den Spalten
    private let railX: CGFloat
    private let landscape: Bool
    /// Querformat und breites Hochformat: Fächerabstand mindestens Indexhöhe + 3 pt
    private let strictFan: Bool
    /// Abstand zwischen Spalten (wächst bei großen Karten mit)
    let gapV: CGFloat
    private let unfolded: Int?
    private let largeIndex: Bool
    private(set) var collapsedBlocks: [CollapsedBlock] = []
    static let railScale: CGFloat = 0.6

    private(set) var placements: [CardID: CardPlacement] = [:]
    private(set) var sources: [CardID: CardSource] = [:]
    private(set) var pileOf: [CardID: Pile] = [:]
    private(set) var columnBottoms: [CGFloat] = []
    private let stockCount: Int
    private let doneSuits: [Int]
    private var emptyColumns: [Int] = []
    /// Offener Abstand für alle Spalten: 0,32 …0,42 × Höhe, so dass die längste Spalte gerade passt (darunter stauchen die Spalten einzeln)
    private(set) var openBase: CGFloat = 0

    static func cardWidth(for width: CGFloat) -> CGFloat {
        (width - 2 * margin - 9 * gap) / 10
    }

    init(state: SpiderState, size: CGSize, prefs: TablePrefs) {
        self.size = size
        leftHanded = prefs.leftHanded
        let landscape = TableOrientation.isLandscape(size)
        self.landscape = landscape
        let wide = !landscape && TischLayout.entscheide(size) == .breitHoch
        strictFan = landscape || wide
        unfolded = prefs.unfolded
        largeIndex = prefs.largeCards
        if landscape {
            // Kartenbreite aus der Breite (10 Spalten + Seitenleiste von 0,6 Kartenbreite, höchstens 96 pt); die Höhe begrenzt nur so weit,
            // dass eine Karte plus 3 Fächerstufen (Indexhöhe + 3 pt) unter die Kopfzeile passen. Der Rest: Mindestabstand und „+N“-Block.
            let m = TischMetrics.margin(base: SideRails.margin, width: size.width), rail = SideRails.railGap
            let byWidth = (size.width - 2 * m - 9 * Self.gap - rail) / (10 + Self.railScale)
            cardWidth = TableOrientation.fittingWidth(cap: min(byWidth, SideRails.maxCardWidth), floor: SideRails.minCardWidth) { w in
                SideRails.topY + w * Theme.cardAspect + 3 * (TableOrientation.indexHeight(width: w, large: prefs.largeCards) + 3) + 4 <= size.height
            }
        } else {
            cardWidth = wide ? TischMetrics.portraitFit(size: size, columns: 10, baseGap: Self.gap, baseMargin: Self.margin, aspect: Theme.cardAspect,
                                                         topRowGap: 22, downs: 5, gaps: 13, downStep: Self.downStep, large: prefs.largeCards)
                             : Self.cardWidth(for: size.width)
        }
        cardHeight = cardWidth * Theme.cardAspect
        gapV = wide ? TischMetrics.gap(base: Self.gap, cardWidth: cardWidth) : Self.gap
        if landscape {
            let block = 10 * cardWidth + 9 * Self.gap + SideRails.railGap + Self.railScale * cardWidth
            let left = (size.width - block) / 2
            let railWidth = Self.railScale * cardWidth
            originX = prefs.leftHanded ? left + railWidth + SideRails.railGap : left
            railX = prefs.leftHanded ? left : left + 10 * cardWidth + 9 * Self.gap + SideRails.railGap
        } else {
            originX = wide ? (size.width - (10 * cardWidth + 9 * gapV)) / 2 : Self.margin
            railX = 0
        }
        rowY = landscape ? topY : topY + cardHeight + 22
        stockCount = state.stock.count
        doneSuits = state.done.map(\.suit)
        let baseStep = strictFan ? max(Self.openStep, (TableOrientation.indexHeight(width: cardWidth, large: prefs.largeCards) + 3) / cardHeight) : Self.openStep
        openBase = Self.growingOpenStep(state, size: size, cardHeight: cardHeight, rowY: rowY, base: baseStep, cap: max(baseStep, Self.maxOpenStep))
        emptyColumns = state.cols.indices.filter { state.cols[$0].up.isEmpty && state.cols[$0].down.isEmpty }
        build(state)
    }

    /// Gleicher offener Abstand für alle Spalten: so groß wie möglich (höchstens 0,42), aber nie kleiner als der Standard 0,32
    static func growingOpenStep(_ state: SpiderState, size: CGSize, cardHeight: CGFloat, rowY: CGFloat, base: CGFloat = openStep,
                                cap: CGFloat = maxOpenStep) -> CGFloat {
        FanMetrics.growingOpenStep(columns: state.cols.map { ($0.down.count, $0.up.count) },
                                   available: size.height - rowY - cardHeight - 4, downPoints: cardHeight * downStep,
                                   cardHeight: cardHeight, base: base, cap: cap)
    }

    // MARK: Plätze

    func columnX(_ i: Int) -> CGFloat { originX + CGFloat(i) * (cardWidth + gapV) }

    /// Mitte der Seitenleiste (Querformat)
    private var railMidX: CGFloat { railX + Self.railScale * cardWidth / 2 }
    private var stockMidY: CGFloat { topY + Self.railScale * cardHeight / 2 }
    private var doneTop: CGFloat { topY + Self.railScale * cardHeight + 28 }
    /// Abstand der fertigen Reihen in der Seitenleiste: Indexhöhe der kleinen Karte + 3 pt, enger wenn es sonst nicht passt
    private var doneStepLandscape: CGFloat {
        let want = TableOrientation.indexHeight(width: Self.railScale * cardWidth, large: largeIndex) + 3
        return max(8, min(want, (size.height - doneTop - Self.railScale * cardHeight - 6) / 7))
    }
    private func railFrame(midX: CGFloat, midY: CGFloat) -> CGRect {
        CGRect(x: midX - cardWidth / 2, y: midY - cardHeight / 2, width: cardWidth, height: cardHeight)
    }

    /// Rahmen der Stapelkarten (in voller Kartengröße; quer wird sie auf 0,6 verkleinert gezeichnet)
    var stockFrame: CGRect {
        landscape ? railFrame(midX: railMidX, midY: stockMidY) : CGRect(x: columnX(leftHanded ? 0 : 9), y: topY, width: cardWidth, height: cardHeight)
    }
    /// So groß, wie der Stapel gezeichnet wird (zum Antippen und Hervorheben)
    var stockVisibleFrame: CGRect {
        guard landscape else { return stockFrame }
        let w = Self.railScale * cardWidth, h = Self.railScale * cardHeight
        return CGRect(x: railMidX - w / 2, y: stockMidY - h / 2, width: w, height: h)
    }

    /// Platz der k-ten fertigen Reihe: links (Linkshänder rechts), jeweils um 0,45 × Breite versetzt
    func doneFrame(_ k: Int) -> CGRect {
        if landscape {
            return railFrame(midX: railMidX, midY: doneTop + Self.railScale * cardHeight / 2 + CGFloat(k) * doneStepLandscape)
        }
        let step = cardWidth * Self.doneOffset
        let x = leftHanded
            ? originX + 9 * (cardWidth + gapV) - CGFloat(k) * step
            : originX + CGFloat(k) * step
        return CGRect(x: x, y: topY, width: cardWidth, height: cardHeight)
    }

    func columnSlotFrame(_ i: Int) -> CGRect {
        CGRect(x: columnX(i), y: rowY, width: cardWidth, height: cardHeight)
    }

    var cardSize: CGSize { CGSize(width: cardWidth, height: cardHeight) }
    var cardIDs: [CardID] { (0..<104).map(CardID.init) }
    var stockTapFrame: CGRect? { stockVisibleFrame }
    var stockCountCenter: CGPoint? { CGPoint(x: stockVisibleFrame.midX, y: stockVisibleFrame.maxY + 11) }
    var emptyColumnFrames: [CGRect] { emptyColumns.map(columnSlotFrame) }
    var dropPiles: [Pile] { (0..<10).map { .column($0) } }

    /// Übrige Austeil-Runden (5 … 1)
    var dealsLeft: Int { (stockCount + 9) / 10 }

    var stockCaption: String? { dealsLeft > 0 ? String(localized: "noch \(dealsLeft)×") : nil }

    /// Leere Plätze: 10 Spalten, einer für die fertigen Reihen („K“-Umriss), der Stapel
    var slots: [SlotSpec] {
        var list: [SlotSpec] = (0..<10).map { SlotSpec(id: $0, frame: columnSlotFrame($0)) }
        let s: CGFloat = landscape ? Self.railScale : 1
        list.append(SlotSpec(id: 20, frame: doneFrame(0), label: "K", scale: s))
        list.append(SlotSpec(id: 21, frame: stockFrame, dimmed: stockCount == 0, scale: s))
        return list
    }

    func targetFrame(_ pile: Pile) -> CGRect {
        switch pile {
        case let .column(i):
            CGRect(x: columnX(i), y: rowY, width: cardWidth, height: max(cardHeight, columnBottoms[i] - rowY))
        case let .foundation(k): landscape ? scaledAroundCenter(doneFrame(k)) : doneFrame(k)
        case .stock: stockVisibleFrame
        case .waste, .cell: .zero
        }
    }

    private func scaledAroundCenter(_ f: CGRect) -> CGRect {
        let w = f.width * Self.railScale, h = f.height * Self.railScale
        return CGRect(x: f.midX - w / 2, y: f.midY - h / 2, width: w, height: h)
    }

    /// Wo die erste verschobene Karte landen würde (für den Tipp)
    func landingOrigin(_ pile: Pile) -> CGPoint {
        switch pile {
        case let .column(i):
            let lastTop = columnBottoms[i] - cardHeight
            let empty = columnBottoms[i] - rowY <= cardHeight + 0.5
            return CGPoint(x: columnX(i), y: empty ? rowY : lastTop + cardHeight * Self.openStep)
        case let .foundation(k): return doneFrame(k).origin
        case .stock: return stockFrame.origin
        case .waste, .cell: return .zero
        }
    }

    // MARK: Berechnung

    private mutating func build(_ state: SpiderState) {
        // Stapel: Rücken je Austeil-Runde (10 Karten) leicht versetzt
        let groups = max(1, (state.stock.count + 9) / 10)
        for (i, c) in state.stock.enumerated() {
            let group = i / 10
            var f = stockFrame
            f.origin.x -= CGFloat(groups - 1 - group) * cardWidth * Self.stockOffset * (landscape ? Self.railScale * Self.railScale : 1) * (leftHanded ? -1 : 1)
            placements[c] = CardPlacement(frame: f, faceUp: false, z: Double(i) * 0.01, scale: landscape ? Self.railScale : 1)
            pileOf[c] = .stock
        }

        // Fertige Reihen: König liegt oben, die übrigen 12 darunter auf demselben Platz
        for (k, run) in state.done.enumerated() {
            for (i, c) in run.cards.enumerated() {
                pileOf[c] = .foundation(k)
                placements[c] = CardPlacement(frame: doneFrame(k), faceUp: true, z: 100 + Double(k) * 20 + Double(13 - i), scale: landscape ? Self.railScale : 1)
            }
        }

        // Spalten; beweglich ist nur die oberste Reihe gleicher Farbe
        columnBottoms = []
        collapsedBlocks = []
        for (ci, col) in state.cols.enumerated() {
            let plan = plan(for: col, column: ci)
            let movable = SpiderRules.runLength(state, col)
            var y = rowY
            for (i, c) in col.down.enumerated() {
                pileOf[c] = .column(ci)
                placements[c] = CardPlacement(frame: CGRect(x: columnX(ci), y: y, width: cardWidth, height: cardHeight),
                                              faceUp: false, z: 300 + Double(i))
                y += plan.down
            }
            var bottom = y - (col.up.isEmpty ? plan.down : 0)
            for (i, c) in col.up.enumerated() {
                let top = plan.y(ofUp: i, from: y)
                pileOf[c] = .column(ci)
                placements[c] = CardPlacement(frame: CGRect(x: columnX(ci), y: top, width: cardWidth, height: cardHeight),
                                              faceUp: true, z: 300 + Double(col.down.count + i))
                if i >= col.up.count - movable, i >= plan.collapsed { sources[c] = CardSource(pile: .column(ci), count: col.up.count - i) }
                bottom = top
            }
            if plan.collapsed >= 2 {
                collapsedBlocks.append(CollapsedBlock(column: ci, frame: CGRect(
                    x: columnX(ci), y: y, width: cardWidth, height: CGFloat(plan.collapsed - 1) * ColumnPlan.blockStep + plan.open), count: plan.collapsed))
            }
            columnBottoms.append(col.down.isEmpty && col.up.isEmpty ? rowY + cardHeight : bottom + cardHeight)
        }
    }

    /// Abstände einer Spalte (Querformat: Mindestabstand ohne Ausnahme, sonst dichter Block, Antippen klappt ihn auf)
    func plan(for col: Column, column: Int? = nil) -> ColumnPlan {
        ColumnPlan.make(downCount: col.down.count, upCount: col.up.count, cardHeight: cardHeight, downStep: Self.downStep, openBase: openBase,
                        minOpen: Self.minOpenStep, minDownStep: Self.minDownStep, available: size.height - rowY - cardHeight - 4,
                        strict: strictFan, ruleStep: TableOrientation.indexHeight(width: cardWidth, large: largeIndex) + 3,
                        unfolded: column != nil && column == unfolded)
    }

    /// Abstände in einer Spalte; zu lange Spalten werden zuerst bei den offenen, dann bei den verdeckten Karten gestaucht
    func steps(for col: Column) -> (down: CGFloat, open: CGFloat) {
        let p = plan(for: col)
        return (p.down, p.open)
    }

    // MARK: Ablegen

    /// Spalte unter der Mitte der untersten gezogenen Karte, großzügig bis zum unteren Rand
    func dropTarget(at p: CGPoint) -> Pile? {
        guard p.y >= rowY - 4 else { return nil }
        for i in 0..<10 {
            let r = CGRect(x: columnX(i) - gapV / 2, y: rowY - 4, width: cardWidth + gapV, height: size.height)
            if r.contains(p) { return .column(i) }
        }
        return nil
    }

    // MARK: Sieg

    /// Siegesanimation: die Könige zuerst, dann abwärts bis zur 7; je Rang die acht fertigen Reihen
    func waterfallCards() -> [(face: CardFace, origin: CGPoint)] {
        var out: [(CardFace, CGPoint)] = []
        for rank in stride(from: 13, through: 7, by: -1) {
            for (k, suit) in doneSuits.enumerated() {
                out.append((CardFace(rank: rank, suit: (Suit(rawValue: suit) ?? .spades)), doneFrame(k).origin))
            }
        }
        return out
    }
}
