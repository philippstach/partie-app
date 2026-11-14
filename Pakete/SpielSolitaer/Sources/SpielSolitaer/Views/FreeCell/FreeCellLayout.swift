// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

/// FreeCell im Hochformat: obere Reihe mit 4 Zellen und 4 Zielen, darunter 8 Spalten. Linkshänder gespiegelt (Ziele links).
struct FreeCellLayout: SolitaireLayout {
    typealias State = FreeCellState

    static let margin: CGFloat = 6
    static let gap: CGFloat = 4
    static let openStep: CGFloat = 0.27
    static let minOpenStep: CGFloat = 0.20

    let size: CGSize
    let leftHanded: Bool
    let cardWidth: CGFloat
    let cardHeight: CGFloat
    let topY: CGFloat = 6
    let rowY: CGFloat
    /// Linker Rand des Feldes; im Querformat ist das Feld mittig
    let originX: CGFloat
    /// Querformat: Ziele links, Zellen rechts (Linkshänder gespiegelt), Spalten über die volle Höhe
    private let rails: SideRails?
    private let unfolded: Int?
    private let largeIndex: Bool
    private(set) var collapsedBlocks: [CollapsedBlock] = []

    private(set) var placements: [CardID: CardPlacement] = [:]
    private(set) var sources: [CardID: CardSource] = [:]
    /// Offener Abstand für alle Spalten (0,27 … 0,42 × Höhe, so dass die längste Spalte gerade passt)
    private(set) var openBase: CGFloat = 0
    private(set) var pileOf: [CardID: Pile] = [:]
    private(set) var columnBottoms: [CGFloat] = []

    static func cardWidth(for width: CGFloat) -> CGFloat {
        (width - 2 * margin - 7 * gap) / 8
    }

    /// Querformat: Zellen als Seitenspalte rechts, Ziele links, Lesbarkeitsregel (Abstand ≥ Indexhöhe + 3 pt, Karte bis 34 pt schmaler)
    static func landscapeFit(in size: CGSize, large: Bool) -> (cardWidth: CGFloat, foundationColumns: Int) {
        SideRails.fit(in: size, columns: 8, gap: gap, side: .cells, aspect: Theme.cardAspect, large: large)
    }

    /// Breites Hochformat (iPad hoch): Karten aus der Breite, begrenzt durch die Höhe
    static func wideFit(in size: CGSize, large: Bool) -> CGFloat {
        TischMetrics.portraitFit(size: size, columns: 8, baseGap: gap, baseMargin: margin, aspect: Theme.cardAspect, topRowGap: 16,
                                 downs: 0, gaps: 12, downStep: 0, large: large)
    }

    static func cardWidth(in size: CGSize, large: Bool = false) -> CGFloat {
        if TableOrientation.isLandscape(size) { return landscapeFit(in: size, large: large).cardWidth }
        return TischLayout.entscheide(size) == .breitHoch ? wideFit(in: size, large: large) : cardWidth(for: size.width)
    }

    /// Groß: offener Abstand 0,26 statt 0,27
    let openStepBase: CGFloat
    /// Im Querformat darf der Fächer (aufgeklappt) enger werden (0,16 statt 0,20)
    /// Abstand zwischen Spalten (wächst bei großen Karten mit)
    let gapV: CGFloat
    private let strictFan: Bool
    var minStep: CGFloat { strictFan ? 0.16 : Self.minOpenStep }

    init(state: FreeCellState, size: CGSize, prefs: TablePrefs) {
        self.size = size
        leftHanded = prefs.leftHanded
        let fit = TableOrientation.isLandscape(size) ? Self.landscapeFit(in: size, large: prefs.largeCards) : nil
        let landscape = TableOrientation.isLandscape(size)
        let wide = !landscape && TischLayout.entscheide(size) == .breitHoch
        strictFan = landscape || wide
        cardWidth = fit?.cardWidth ?? (wide ? Self.wideFit(in: size, large: prefs.largeCards) : Self.cardWidth(for: size.width))
        cardHeight = cardWidth * Theme.cardAspect
        gapV = TischMetrics.gap(base: Self.gap, cardWidth: cardWidth)
        let baseStep = prefs.largeCards ? 0.26 : Self.openStep
        // Querformat: offener Abstand nie unter Indexhöhe + 3 pt
        openStepBase = strictFan ? max(baseStep, (TableOrientation.indexHeight(width: cardWidth, large: prefs.largeCards) + 3) / cardHeight) : baseStep
        unfolded = prefs.unfolded
        largeIndex = prefs.largeCards
        if let f = fit {
            rails = SideRails(width: size.width, cardWidth: cardWidth, cardHeight: cardHeight, columns: 8, gap: gapV, side: .cells,
                                    foundationColumns: f.foundationColumns, leftHanded: prefs.leftHanded)
        } else { rails = nil }
        originX = rails?.columnsX ?? (wide ? (size.width - (8 * cardWidth + 7 * gapV)) / 2 : Self.margin)
        rowY = landscape ? topY : topY + cardHeight + 16
        openBase = FanMetrics.growingOpenStep(columns: state.cols.map { (0, $0.count) },
                                              available: size.height - rowY - cardHeight - 4,
                                              downPoints: 0, cardHeight: cardHeight, base: openStepBase,
                                              cap: max(openStepBase, prefs.largeCards ? 0.46 : FanMetrics.maxOpenStep))
        build(state)
    }

    // MARK: Plätze

    func slotX(_ index: Int) -> CGFloat { originX + CGFloat(index) * (cardWidth + gapV) }

    private func rect(slot: Int, y: CGFloat) -> CGRect { CGRect(x: slotX(slot), y: y, width: cardWidth, height: cardHeight) }

    /// Zellen links, Ziele rechts (Linkshänder gespiegelt)
    func cellFrame(_ i: Int) -> CGRect {
        guard let rails else { return rect(slot: leftHanded ? 4 + i : i, y: topY) }
        return rails.cellFrame(i)
    }
    func foundationFrame(_ f: Int) -> CGRect {
        guard let rails else { return rect(slot: leftHanded ? f : 4 + f, y: topY) }
        return rails.foundationFrame(f)
    }
    func columnSlotFrame(_ i: Int) -> CGRect { rect(slot: i, y: rowY) }

    var cardSize: CGSize { CGSize(width: cardWidth, height: cardHeight) }
    var cardIDs: [CardID] { CardID.all }
    var stockTapFrame: CGRect? { nil }
    var stockCountCenter: CGPoint? { nil }
    var stockCaption: String? { nil }
    var dropPiles: [Pile] { (0..<8).map { .column($0) } + (0..<4).map { .cell($0) } + (0..<4).map { .foundation($0) } }

    /// Leere Plätze: 8 Spalten, 4 Zellen (gefüllte Fläche, ohne Symbol), 4 Ziele (Farbsymbol)
    var slots: [SlotSpec] {
        var list: [SlotSpec] = (0..<8).map { SlotSpec(id: $0, frame: columnSlotFrame($0)) }
        list += (0..<4).map { SlotSpec(id: 10 + $0, frame: cellFrame($0)) }
        list += (0..<4).map { SlotSpec(id: 20 + $0, frame: foundationFrame($0), symbol: Suit(rawValue: $0)!.symbolName, suit: Suit(rawValue: $0)) }
        return list
    }

    func targetFrame(_ pile: Pile) -> CGRect {
        switch pile {
        case let .column(i): CGRect(x: slotX(i), y: rowY, width: cardWidth, height: max(cardHeight, columnBottoms[i] - rowY))
        case let .cell(i): cellFrame(i)
        case let .foundation(f): foundationFrame(f)
        case .stock, .waste: .zero
        }
    }

    /// Wo die erste verschobene Karte landen würde (für den Tipp)
    func landingOrigin(_ pile: Pile) -> CGPoint {
        switch pile {
        case let .column(i):
            let lastTop = columnBottoms[i] - cardHeight
            let empty = columnBottoms[i] - rowY <= cardHeight + 0.5
            return CGPoint(x: slotX(i), y: empty ? rowY : lastTop + openBase)
        case let .cell(i): return cellFrame(i).origin
        case let .foundation(f): return foundationFrame(f).origin
        case .stock, .waste: return .zero
        }
    }

    // MARK: Berechnung

    private mutating func build(_ state: FreeCellState) {
        // Austeilen: alle 52 Karten verdeckt als Stapel in der Mitte der oberen Reihe
        if state.cols[0].count == 52 {
            let f = CGRect(x: (size.width - cardWidth) / 2, y: topY, width: cardWidth, height: cardHeight)
            for (i, c) in state.cols[0].enumerated() { placements[c] = CardPlacement(frame: f, faceUp: false, z: Double(i) * 0.01) }
            columnBottoms = Array(repeating: rowY + cardHeight, count: 8)
            return
        }

        for (i, c) in state.cells.enumerated() {
            guard let c else { continue }
            placements[c] = CardPlacement(frame: cellFrame(i), faceUp: true, z: 50)
            pileOf[c] = .cell(i)
            sources[c] = CardSource(pile: .cell(i), count: 1)
        }
        // Ziele: Karten sind aus dem höchsten Wert abgeleitet (feste Farbe je Ziel)
        for f in 0..<4 where state.foundation[f] > 0 {
            for rank in 1...state.foundation[f] {
                let id = CardID(rank: rank, suit: Suit(rawValue: f)!)
                placements[id] = CardPlacement(frame: foundationFrame(f), faceUp: true, z: 100 + Double(rank), covered: rank != state.foundation[f])
                pileOf[id] = .foundation(f)
            }
        }
        columnBottoms = []
        collapsedBlocks = []
        for (ci, col) in state.cols.enumerated() {
            let plan = plan(for: col, column: ci)
            let movable = FreeCellRules.runLength(col)
            var bottom = rowY
            for (i, c) in col.enumerated() {
                pileOf[c] = .column(ci)
                let top = plan.y(ofUp: i, from: rowY)
                placements[c] = CardPlacement(frame: CGRect(x: slotX(ci), y: top, width: cardWidth, height: cardHeight),
                                              faceUp: true, z: 300 + Double(i), covered: i < col.count - 1)
                if i >= col.count - movable, i >= plan.collapsed { sources[c] = CardSource(pile: .column(ci), count: col.count - i) }
                bottom = top
            }
            if plan.collapsed >= 2 {
                collapsedBlocks.append(CollapsedBlock(column: ci, frame: CGRect(
                    x: slotX(ci), y: rowY, width: cardWidth, height: CGFloat(plan.collapsed - 1) * ColumnPlan.blockStep + plan.open), count: plan.collapsed))
            }
            columnBottoms.append(col.isEmpty ? rowY + cardHeight : bottom + cardHeight)
        }
    }

    /// Abstände einer Spalte (Querformat: Mindestabstand ohne Ausnahme, sonst dichter Block, Antippen klappt ihn auf)
    func plan(for col: [CardID], column: Int? = nil) -> ColumnPlan {
        ColumnPlan.make(downCount: 0, upCount: col.count, cardHeight: cardHeight, downStep: 0, openBase: openBase, minOpen: minStep,
                        minDownStep: 0, available: size.height - rowY - cardHeight - 4, strict: strictFan,
                        ruleStep: TableOrientation.indexHeight(width: cardWidth, large: largeIndex) + 3,
                        unfolded: column != nil && column == unfolded)
    }

    /// Abstand in einer Spalte; zu lange Spalten werden bis 0,20 × Höhe gestaucht (Querformat: bis zum Mindestabstand)
    func openStepFor(_ col: [CardID]) -> CGFloat { plan(for: col).open }

    // MARK: Ablegen

    /// Ziel unter der Mitte der untersten gezogenen Karte: Zellen und Ziele oben, sonst die Spalte (bis zum unteren Rand)
    func dropTarget(at p: CGPoint) -> Pile? {
        for i in 0..<4 where cellFrame(i).insetBy(dx: -gapV / 2, dy: -8).contains(p) { return .cell(i) }
        for f in 0..<4 where foundationFrame(f).insetBy(dx: -gapV / 2, dy: -8).contains(p) { return .foundation(f) }
        guard p.y >= rowY - 4 else { return nil }
        for i in 0..<8 {
            let r = CGRect(x: slotX(i) - gapV / 2, y: rowY - 4, width: cardWidth + gapV, height: size.height)
            if r.contains(p) { return .column(i) }
        }
        return nil
    }

    // MARK: Sieg

    func waterfallCards() -> [(face: CardFace, origin: CGPoint)] {
        var out: [(CardFace, CGPoint)] = []
        for rank in stride(from: 13, through: 1, by: -1) {
            for suit in Suit.allCases { out.append((CardFace(rank: rank, suit: suit), foundationFrame(suit.rawValue).origin)) }
        }
        return out
    }
}
