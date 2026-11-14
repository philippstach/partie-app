// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

/// Yukon wie Klondike ohne Stapel und Ablage: obere Reihe nur mit den 4 Zielen rechts (Linkshänder: links), darunter 7 Spalten.
/// Gleiche Kartenbreite und gleiche Fächer wie Klondike; jede offene Karte ist greifbar und nimmt alles darüber mit.
struct YukonLayout: SolitaireLayout {
    typealias State = YukonState

    static let margin = KlondikeLayout.margin
    static let gap = KlondikeLayout.gap

    let size: CGSize
    let leftHanded: Bool
    let cardWidth: CGFloat
    let cardHeight: CGFloat
    let topY: CGFloat = 6
    let rowY: CGFloat
    /// Linker Rand des Feldes; im Querformat ist das Feld mittig
    let originX: CGFloat
    let downStepValue: CGFloat
    let openStepBase: CGFloat
    /// Abstand zwischen Spalten (wächst bei großen Karten mit)
    let gapV: CGFloat
    private let strictFan: Bool
    let minOpenValue: CGFloat
    /// Offener Abstand für alle Spalten (wächst bis 0,42 × Höhe, so dass die längste Spalte gerade passt)
    private(set) var openBase: CGFloat = 0

    private(set) var placements: [CardID: CardPlacement] = [:]
    private(set) var sources: [CardID: CardSource] = [:]
    private(set) var pileOf: [CardID: Pile] = [:]
    private(set) var columnBottoms: [CGFloat] = []
    /// Querformat: Ziele senkrecht an der einen Seite (Linkshänder: rechts), Spalten über die volle Höhe
    private let rails: SideRails?
    private let unfolded: Int?
    private let largeIndex: Bool
    private(set) var collapsedBlocks: [CollapsedBlock] = []

    init(state: YukonState, size: CGSize, prefs: TablePrefs) {
        self.size = size
        leftHanded = prefs.leftHanded
        let large = prefs.largeCards
        let landscape = TableOrientation.isLandscape(size)
        downStepValue = large ? 0.12 : KlondikeLayout.downStep
        minOpenValue = landscape ? 0.16 : (large ? 0.16 : KlondikeLayout.minOpenStep)
        let wide = !landscape && TischLayout.entscheide(size) == .breitHoch
        strictFan = landscape || wide
        let fit = landscape ? SideRails.fit(in: size, columns: 7, gap: Self.gap, side: .none, aspect: KlondikeLayout.aspect, large: large) : nil
        cardWidth = fit?.cardWidth ?? (wide
            ? TischMetrics.portraitFit(size: size, columns: 7, baseGap: Self.gap, baseMargin: Self.margin, aspect: KlondikeLayout.aspect,
                                       topRowGap: 16, downs: 6, gaps: 12, downStep: 0.05, large: large)
            : KlondikeLayout.cardWidth(for: size.width))
        cardHeight = cardWidth * KlondikeLayout.aspect
        gapV = TischMetrics.gap(base: Self.gap, cardWidth: cardWidth)
        unfolded = prefs.unfolded
        largeIndex = large
        if let f = fit {
            rails = SideRails(width: size.width, cardWidth: cardWidth, cardHeight: cardHeight, columns: 7, gap: gapV, side: .none,
                                    foundationColumns: f.foundationColumns, leftHanded: prefs.leftHanded)
        } else { rails = nil }
        let baseStep = large ? 0.26 : KlondikeLayout.openStep
        // Querformat: offener Abstand nie unter Indexhöhe + 3 pt
        openStepBase = strictFan ? max(baseStep, (TableOrientation.indexHeight(width: cardWidth, large: large) + 3) / cardHeight) : baseStep
        originX = rails?.columnsX ?? (wide ? (size.width - (7 * cardWidth + 6 * gapV)) / 2 : Self.margin)
        rowY = landscape ? topY : topY + cardHeight + 16
        openBase = FanMetrics.growingOpenStep(columns: state.cols.map { ($0.down.count, $0.up.count) },
                                              available: size.height - rowY - cardHeight - 4,
                                              downPoints: cardHeight * downStepValue, cardHeight: cardHeight, base: openStepBase,
                                              cap: max(openStepBase, large ? 0.46 : FanMetrics.maxOpenStep))
        build(state)
    }

    var cardSize: CGSize { CGSize(width: cardWidth, height: cardHeight) }
    var cardIDs: [CardID] { CardID.all }
    var stockTapFrame: CGRect? { nil }
    var stockCountCenter: CGPoint? { nil }
    var stockCaption: String? { nil }
    var dropPiles: [Pile] { (0..<4).map { .foundation($0) } + (0..<7).map { .column($0) } }

    /// Leere Plätze: 7 Spalten und 4 Ziele mit Farbsymbol
    var slots: [SlotSpec] {
        var list: [SlotSpec] = (0..<7).map { SlotSpec(id: $0, frame: columnSlotFrame($0)) }
        list += (0..<4).map { SlotSpec(id: 10 + $0, frame: foundationFrame($0), symbol: Suit(rawValue: $0)!.symbolName, suit: Suit(rawValue: $0)) }
        return list
    }

    /// Siegesanimation: Könige zuerst, dann Dame … Ass; je Rang die vier Zielstapel
    func waterfallCards() -> [(face: CardFace, origin: CGPoint)] {
        var out: [(CardFace, CGPoint)] = []
        for rank in stride(from: 13, through: 1, by: -1) {
            for suit in Suit.allCases { out.append((CardFace(rank: rank, suit: suit), foundationFrame(suit.rawValue).origin)) }
        }
        return out
    }

    // MARK: Plätze

    func slotX(_ index: Int) -> CGFloat { originX + CGFloat(index) * (cardWidth + gapV) }

    /// Ziele rechtsbündig in den Spalten 3 … 6 (Linkshänder: links in 0 … 3)
    private func foundationSlot(_ f: Int) -> Int { leftHanded ? f : 3 + f }

    private func rect(slot: Int, y: CGFloat) -> CGRect { CGRect(x: slotX(slot), y: y, width: cardWidth, height: cardHeight) }

    func foundationFrame(_ f: Int) -> CGRect {
        guard let rails else { return rect(slot: foundationSlot(f), y: topY) }
        return rails.foundationFrame(f)
    }
    func columnSlotFrame(_ i: Int) -> CGRect { rect(slot: i, y: rowY) }

    func targetFrame(_ place: Pile) -> CGRect {
        switch place {
        case let .foundation(f): foundationFrame(f)
        case let .column(i): CGRect(x: slotX(i), y: rowY, width: cardWidth, height: max(cardHeight, columnBottoms[i] - rowY))
        case .stock, .waste, .cell: .zero
        }
    }

    /// Wo die erste verschobene Karte landen würde (für den Tipp)
    func landingOrigin(_ place: Pile) -> CGPoint {
        switch place {
        case let .foundation(f): return foundationFrame(f).origin
        case let .column(i):
            let lastTop = columnBottoms[i] - cardHeight
            let empty = lastTop <= rowY + 0.5 && columnBottoms[i] - rowY <= cardHeight + 0.5
            return CGPoint(x: slotX(i), y: empty ? rowY : lastTop + openBase)
        case .stock, .waste, .cell: return .zero
        }
    }

    // MARK: Berechnung

    private mutating func build(_ state: YukonState) {
        // Austeilen: alle 52 Karten verdeckt als Stapel in der Mitte der oberen Reihe
        if state.cols[0].down.count == 52 {
            let f = CGRect(x: (size.width - cardWidth) / 2, y: topY, width: cardWidth, height: cardHeight)
            for (i, c) in state.cols[0].down.enumerated() { placements[c] = CardPlacement(frame: f, faceUp: false, z: Double(i) * 0.01) }
            columnBottoms = Array(repeating: rowY + cardHeight, count: 7)
            return
        }

        // Ziele: Karten sind aus dem höchsten Wert abgeleitet
        for f in 0..<4 {
            let value = state.foundation[f]
            guard value > 0 else { continue }
            for rank in 1...value {
                let c = CardID(rank: rank, suit: Suit(rawValue: f)!)
                placements[c] = CardPlacement(frame: foundationFrame(f), faceUp: true, z: 100 + Double(rank), covered: rank != value)
                pileOf[c] = .foundation(f)
                if rank == value { sources[c] = CardSource(pile: .foundation(f), count: 1) }
            }
        }

        // Spalten: jede offene Karte ist greifbar und nimmt alles darüber mit
        columnBottoms = []
        collapsedBlocks = []
        for (ci, col) in state.cols.enumerated() {
            let plan = plan(for: col, column: ci)
            var y = rowY
            for (i, c) in col.down.enumerated() {
                pileOf[c] = .column(ci)
                placements[c] = CardPlacement(frame: CGRect(x: slotX(ci), y: y, width: cardWidth, height: cardHeight),
                                              faceUp: false, z: 300 + Double(i))
                y += plan.down
            }
            var bottom = y - (col.up.isEmpty ? plan.down : 0)
            for (i, c) in col.up.enumerated() {
                let top = plan.y(ofUp: i, from: y)
                pileOf[c] = .column(ci)
                placements[c] = CardPlacement(frame: CGRect(x: slotX(ci), y: top, width: cardWidth, height: cardHeight),
                                              faceUp: true, z: 300 + Double(col.down.count + i), covered: i < col.up.count - 1)
                if i >= plan.collapsed { sources[c] = CardSource(pile: .column(ci), count: col.up.count - i) }
                bottom = top
            }
            if plan.collapsed >= 2 {
                collapsedBlocks.append(CollapsedBlock(column: ci, frame: CGRect(
                    x: slotX(ci), y: y, width: cardWidth, height: CGFloat(plan.collapsed - 1) * ColumnPlan.blockStep + plan.open), count: plan.collapsed))
            }
            columnBottoms.append(col.down.isEmpty && col.up.isEmpty ? rowY + cardHeight : bottom + cardHeight)
        }
    }

    /// Abstände einer Spalte (Querformat: Mindestabstand ohne Ausnahme, sonst dichter Block, Antippen klappt ihn auf)
    func plan(for col: Column, column: Int? = nil) -> ColumnPlan {
        ColumnPlan.make(downCount: col.down.count, upCount: col.up.count, cardHeight: cardHeight, downStep: downStepValue,
                        openBase: openBase, minOpen: minOpenValue, minDownStep: KlondikeLayout.minDownStep,
                        available: size.height - rowY - cardHeight - 4, strict: strictFan,
                        ruleStep: TableOrientation.indexHeight(width: cardWidth, large: largeIndex) + 3,
                        unfolded: column != nil && column == unfolded)
    }

    /// Abstände in einer Spalte
    func steps(for col: Column) -> (down: CGFloat, open: CGFloat) {
        let p = plan(for: col)
        return (p.down, p.open)
    }

    // MARK: Ablegen

    /// Das Ziel unter einem Punkt (Mitte der untersten gezogenen Karte). Großzügig: Spalte bis zum unteren Rand.
    func dropTarget(at p: CGPoint) -> Pile? {
        for f in 0..<4 where foundationFrame(f).insetBy(dx: -gapV / 2, dy: -8).contains(p) { return .foundation(f) }
        guard p.y >= rowY - 4 else { return nil }
        for i in 0..<7 {
            let r = CGRect(x: slotX(i) - gapV / 2, y: rowY - 4, width: cardWidth + gapV, height: size.height)
            if r.contains(p) { return .column(i) }
        }
        return nil
    }
}
