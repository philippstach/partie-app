// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

/// Reine Funktion: Zustand + Fläche → Position jeder Karte. Alle Bewegungen entstehen, indem sich dieses Ergebnis ändert.
struct KlondikeLayout: SolitaireLayout {
    typealias State = GameState

    static let margin: CGFloat = 8
    static let gap: CGFloat = 5
    static let aspect: CGFloat = 1.4
    static let openStep: CGFloat = 0.27
    static let downStep: CGFloat = 0.10
    static let minOpenStep: CGFloat = 0.17
    static let minDownStep: CGFloat = 0.05
    static let fanStep: CGFloat = 0.30

    let size: CGSize
    let leftHanded: Bool
    let cardWidth: CGFloat
    let cardHeight: CGFloat
    let topY: CGFloat = 6
    let rowY: CGFloat
    /// Linker Rand des Feldes; im Querformat ist das Feld mittig
    let originX: CGFloat
    /// Querformat: Ziele links, Stapel/Ablage rechts (Linkshänder gespiegelt), Spalten über die volle Höhe
    private let rails: SideRails?
    private let unfolded: Int?
    private(set) var collapsedBlocks: [CollapsedBlock] = []

    private(set) var placements: [CardID: CardPlacement] = [:]
    private(set) var sources: [CardID: CardSource] = [:]
    /// Offener Abstand für alle Spalten (0,27 … 0,42 × Höhe, so dass die längste Spalte gerade passt)
    private(set) var openBase: CGFloat = 0
    private(set) var pileOf: [CardID: Pile] = [:]
    private var wasteIsEmpty = true
    private var stockCount = 0
    private(set) var columnBottoms: [CGFloat] = []

    static func cardWidth(for width: CGFloat) -> CGFloat {
        (width - 2 * margin - 6 * gap) / 7
    }

    /// Querformat: Seitenspalte für Stapel und Ablage (Ablage fächert bis 0,6 × Breite zur Seite)
    /// Querformat: Kartenbreite aus der Breite (9 Plätze nebeneinander), siehe `SideRails.fit`
    static func landscapeFit(in size: CGSize, large: Bool) -> (cardWidth: CGFloat, foundationColumns: Int) {
        SideRails.fit(in: size, columns: 7, gap: gap, side: .stockWaste, aspect: aspect, large: large)
    }

    /// Breites Hochformat (iPad hoch, Split View ab 600 pt): Karten aus der Breite, obere Reihe oben, Spalten darunter
    static func wideFit(in size: CGSize, large: Bool) -> CGFloat {
        TischMetrics.portraitFit(size: size, columns: 7, baseGap: gap, baseMargin: margin, aspect: aspect, topRowGap: 22,
                                 downs: 6, gaps: 12, downStep: 0.05, large: large)
    }

    static func cardWidth(in size: CGSize, large: Bool = false) -> CGFloat {
        if TableOrientation.isLandscape(size) { return landscapeFit(in: size, large: large).cardWidth }
        return TischLayout.entscheide(size) == .breitHoch ? wideFit(in: size, large: large) : cardWidth(for: size.width)
    }

    init(state: GameState, size: CGSize, prefs: TablePrefs) {
        self.init(state: state, size: size, leftHanded: prefs.leftHanded, large: prefs.largeCards, unfolded: prefs.unfolded)
    }

    /// Fächer-Abstände: Normal verdeckt 0,10 · offen 0,27 · Untergrenze 0,17; Groß verdeckt 0,12 · offen 0,26 · Untergrenze 0,16 (× Kartenhöhe)
    let downStepValue: CGFloat
    let openStepBase: CGFloat
    let minOpenValue: CGFloat
    private let largeIndex: Bool
    /// Mindestabstand Indexhöhe + 3 pt (Querformat und breites Hochformat)
    private let strictFan: Bool
    /// Abstand zwischen Spalten (wächst bei großen Karten mit)
    let gapV: CGFloat

    init(state: GameState, size: CGSize, leftHanded: Bool, large: Bool = false, unfolded: Int? = nil) {
        self.size = size
        self.leftHanded = leftHanded
        largeIndex = large
        downStepValue = large ? 0.12 : Self.downStep
        let landscape = TableOrientation.isLandscape(size)
        let wide = !landscape && TischLayout.entscheide(size) == .breitHoch
        strictFan = landscape || wide
        minOpenValue = landscape ? 0.16 : (large ? 0.16 : Self.minOpenStep)
        let fit = landscape ? Self.landscapeFit(in: size, large: large) : nil
        cardWidth = fit?.cardWidth ?? (wide ? Self.wideFit(in: size, large: large) : Self.cardWidth(for: size.width))
        cardHeight = cardWidth * Self.aspect
        gapV = TischMetrics.gap(base: Self.gap, cardWidth: cardWidth)
        let baseStep = large ? 0.26 : Self.openStep
        // Querformat und breites Hochformat: offener Abstand nie unter Indexhöhe + 3 pt
        openStepBase = strictFan ? max(baseStep, (TableOrientation.indexHeight(width: cardWidth, large: large) + 3) / cardHeight) : baseStep
        self.unfolded = unfolded
        if let f = fit {
            rails = SideRails(width: size.width, cardWidth: cardWidth, cardHeight: cardHeight, columns: 7, gap: gapV,
                                    side: .stockWaste, foundationColumns: f.foundationColumns, leftHanded: leftHanded)
        } else { rails = nil }
        // Breites Hochformat: Tisch mittig mit wachsendem Rand; sonst links mit dem festen Rand
        originX = rails?.columnsX ?? (wide ? (size.width - (7 * cardWidth + 6 * gapV)) / 2 : Self.margin)
        rowY = landscape ? topY : topY + cardHeight + 22   // Querformat: keine obere Reihe; sonst Platz für die Zahl unter dem Stapel
        openBase = FanMetrics.growingOpenStep(columns: state.cols.map { ($0.down.count, $0.up.count) },
                                              available: size.height - rowY - cardHeight - 4,
                                              downPoints: cardHeight * downStepValue, cardHeight: cardHeight, base: openStepBase,
                                              cap: max(openStepBase, large ? 0.46 : FanMetrics.maxOpenStep))
        wasteIsEmpty = state.waste.isEmpty
        stockCount = state.stock.count
        build(state)
    }

    var cardSize: CGSize { CGSize(width: cardWidth, height: cardHeight) }
    var cardIDs: [CardID] { CardID.all }
    var stockTapFrame: CGRect? { stockFrame }
    var stockCaption: String? { stockCount > 0 ? "\(stockCount)" : nil }
    var stockCountCenter: CGPoint? { CGPoint(x: stockFrame.midX, y: stockFrame.maxY + 11) }
    var dropPiles: [Pile] { (0..<4).map { .foundation($0) } + (0..<7).map { .column($0) } }

    /// Leere Plätze: 7 Spalten, 4 Ziele mit Farbsymbol, Stapel (Kreispfeil) und Ablage
    var slots: [SlotSpec] {
        var list: [SlotSpec] = (0..<7).map { SlotSpec(id: $0, frame: columnSlotFrame($0)) }
        list += (0..<4).map { SlotSpec(id: 10 + $0, frame: foundationFrame($0), symbol: Suit(rawValue: $0)!.symbolName, suit: Suit(rawValue: $0)) }
        list.append(SlotSpec(id: 20, frame: stockFrame, symbol: "arrow.counterclockwise", dimmed: wasteIsEmpty))
        list.append(SlotSpec(id: 21, frame: wasteFrame))
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

    /// Spalten der oberen Reihe (0…6)
    private var stockSlot: Int { leftHanded ? 0 : 6 }
    private var wasteSlot: Int { leftHanded ? 1 : 5 }
    private func foundationSlot(_ f: Int) -> Int { leftHanded ? 3 + f : f }

    private func rect(slot: Int, y: CGFloat) -> CGRect {
        CGRect(x: slotX(slot), y: y, width: cardWidth, height: cardHeight)
    }

    /// Querformat: Stapel oben, Ablage darunter; die oberste Ablagekarte liegt am äußeren Rand, der Fächer wächst zu den Spalten hin
    private var sideSlotX: CGFloat { (rails?.sideX ?? 0) + (leftHanded ? 0 : (SideRails.wasteFactor - 1) * cardWidth) }
    var stockFrame: CGRect {
        rails != nil ? CGRect(x: sideSlotX, y: topY, width: cardWidth, height: cardHeight) : rect(slot: stockSlot, y: topY)
    }
    var wasteFrame: CGRect {
        rails != nil ? CGRect(x: sideSlotX, y: topY + cardHeight + 28, width: cardWidth, height: cardHeight) : rect(slot: wasteSlot, y: topY)
    }
    func foundationFrame(_ f: Int) -> CGRect {
        guard let rails else { return rect(slot: foundationSlot(f), y: topY) }
        return rails.foundationFrame(f)
    }
    func columnSlotFrame(_ i: Int) -> CGRect { rect(slot: i, y: rowY) }

    /// Das Feld, in dem ein Zug landet (für Tipp und Hervorhebung)
    func targetFrame(_ place: Pile) -> CGRect {
        switch place {
        case .waste: wasteFrame
        case .stock: stockFrame
        case .cell: .zero
        case let .foundation(f): foundationFrame(f)
        case let .column(i):
            CGRect(x: slotX(i), y: rowY, width: cardWidth, height: max(cardHeight, columnBottoms[i] - rowY))
        }
    }

    /// Wo die erste verschobene Karte landen würde (für den Tipp)
    func landingOrigin(_ place: Pile) -> CGPoint {
        switch place {
        case .waste: return wasteFrame.origin
        case .stock: return stockFrame.origin
        case .cell: return .zero
        case let .foundation(f): return foundationFrame(f).origin
        case let .column(i):
            let lastTop = columnBottoms[i] - cardHeight
            let empty = lastTop <= rowY + 0.5 && columnBottoms[i] - rowY <= cardHeight + 0.5
            return CGPoint(x: slotX(i), y: empty ? rowY : lastTop + openBase)
        }
    }

    // MARK: Berechnung

    private mutating func build(_ state: GameState) {
        // Stapel: unten → oben, leicht versetzt für die Dicke
        for (i, c) in state.stock.enumerated() {
            let depth = state.stock.count - 1 - i
            var f = stockFrame
            f.origin.y -= CGFloat(min(depth, 2)) * 1.0
            placements[c] = CardPlacement(frame: f, faceUp: false, z: Double(i) * 0.01)
            pileOf[c] = .stock
        }

        // Ablage: die `fan` obersten Karten nach rechts aufgefächert
        for (i, c) in state.waste.enumerated() {
            let fromTop = state.waste.count - 1 - i
            var f = wasteFrame
            // Fächer zur Lücke hin: oberste Karte genau auf dem Ablageplatz, ältere rechtshändig nach links, linkshändig nach rechts
            if fromTop < state.fan { f.origin.x += CGFloat(fromTop) * cardWidth * (rails != nil ? 0.15 : Self.fanStep) * (leftHanded ? 1 : -1) }
            placements[c] = CardPlacement(frame: f, faceUp: true, z: 200 + Double(i), covered: fromTop != 0)
            pileOf[c] = .waste
            if fromTop == 0 { sources[c] = CardSource(pile: .waste, count: 1) }
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

        // Spalten
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
        let landscape = strictFan
        return ColumnPlan.make(downCount: col.down.count, upCount: col.up.count, cardHeight: cardHeight, downStep: downStepValue,
                               openBase: openBase, minOpen: minOpenValue, minDownStep: Self.minDownStep,
                               available: size.height - rowY - cardHeight - 4, strict: landscape,
                               ruleStep: TableOrientation.indexHeight(width: cardWidth, large: largeIndex) + 3,
                               unfolded: column != nil && column == unfolded)
    }

    /// Abstände in einer Spalte; zu lange Spalten werden zuerst bei den offenen, dann bei den verdeckten Karten gestaucht.
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
