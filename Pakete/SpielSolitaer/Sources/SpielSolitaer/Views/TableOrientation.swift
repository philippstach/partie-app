// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

/// Layout nach verfügbarer Fläche, nie nach Gerät (SPEZIFIKATION-IPAD §1)
enum TischLayout: Equatable {
    /// Breite < 600 pt: iPhone hoch (auch iPad im schmalen Split View)
    case schmal
    /// Breite ≥ 600 pt, nicht deutlich breiter als hoch: iPhone-Hochformat mit Kartenbreite aus der Breite
    case breitHoch
    /// Breite ≥ 600 pt und Breite > Höhe × 1,15: Querformat (Seitenplätze, senkrechte Leiste)
    case breitQuer

    static let grenze: CGFloat = 600

    static func entscheide(breite: CGFloat, hoehe: CGFloat) -> TischLayout {
        guard breite >= grenze else { return .schmal }
        return breite > hoehe * 1.15 ? .breitQuer : .breitHoch
    }

    static func entscheide(_ size: CGSize) -> TischLayout { entscheide(breite: size.width, hoehe: size.height) }
}

/// Maße, die auf großen Flächen (iPad) mitwachsen; auf dem iPhone ändern sie nichts
enum TischMetrics {
    /// Größte Kartenbreite (iPad 150 pt, iPhone erreicht sie nie)
    static let maxCardWidth: CGFloat = 150
    /// Abstand zwischen Karten: ab Karten über 96 pt wächst er mit (0,06 × Breite), sonst der Grundwert
    static func gap(base: CGFloat, cardWidth w: CGFloat) -> CGFloat { w > 96 ? max(base, 0.06 * w) : base }
    /// Rand: auf großen Flächen (Breite ≥ 900 pt) mindestens 2 % der Breite
    static func margin(base: CGFloat, width: CGFloat) -> CGFloat { width >= 900 ? max(base, 0.02 * width) : base }

    /// Breites Hochformat (`.breitHoch`): Kartenbreite aus der Breite (höchstens 150 pt), begrenzt nur so weit, dass die obere Reihe und die
    /// längste Spalte (`downs` verdeckte Karten, `gaps` Fächerstufen von Indexhöhe + 3 pt) auf die Höhe passen.
    static func portraitFit(size: CGSize, columns: Int, baseGap: CGFloat, baseMargin: CGFloat, aspect: CGFloat, topRowGap: CGFloat,
                            downs: Int, gaps: Int, downStep: CGFloat, large: Bool) -> CGFloat {
        var w = maxCardWidth
        while w > SideRails.minCardWidth {
            let gap = Self.gap(base: baseGap, cardWidth: w), m = margin(base: baseMargin, width: size.width)
            let h = w * aspect
            let fitsWidth = CGFloat(columns) * w + CGFloat(columns - 1) * gap + 2 * m <= size.width
            let step = TableOrientation.indexHeight(width: w, large: large) + 3
            let need = 6 + h + topRowGap + h + 4 + CGFloat(downs) * downStep * h + CGFloat(gaps) * step
            if fitsWidth, need <= size.height { return w }
            w -= 0.5
        }
        return SideRails.minCardWidth
    }
}

/// Hoch- oder Querformat des Tisches; im Querformat rechnen alle Layouts nach der Höhe statt nach der Breite
enum TableOrientation {
    static func isLandscape(_ size: CGSize) -> Bool { size.width > size.height * 1.15 }

    /// Höhe des Index (Wert + Symbol) oben links auf einer Karte dieser Breite
    static func indexHeight(width: CGFloat, large: Bool) -> CGFloat {
        width < 42 ? width * 0.56 : width * (large ? 0.56 : 0.47)
    }

    /// Lesbarkeitsregel im Querformat: der Abstand offener Karten ist nie kleiner als Indexhöhe + 3 pt.
    /// Gesucht ist die größte Kartenbreite ≤ `cap` (nicht unter `floor`), bei der `fits` (Kartenbreite → passt der Fächer?) gilt.
    static func fittingWidth(cap: CGFloat, floor: CGFloat = 40, fits: (CGFloat) -> Bool) -> CGFloat {
        var w = cap
        while w > floor, !fits(w) { w -= 0.5 }
        return max(w, min(cap, floor))
    }
}

/// Querformat ohne obere Reihe (Klondike, FreeCell, Yukon): die Ziele stehen senkrecht an der einen Seite der Spalten,
/// Stapel und Ablage bzw. die Zellen senkrecht an der anderen. Linkshänder: alles gespiegelt. Spalten haben die volle Höhe.
/// Passen vier Karten nicht übereinander, stehen Ziele (und Zellen) 2 × 2.
struct SideRails {
    static let railGap: CGFloat = 16
    static let vGap: CGFloat = 6
    static let topY: CGFloat = 6
    static let margin: CGFloat = 8
    /// Kleinste und größte Kartenbreite im Querformat
    static let minCardWidth: CGFloat = 34
    static let maxCardWidth: CGFloat = TischMetrics.maxCardWidth
    /// Breite der Ablage-Seitenspalte (Klondike): Karte + Platz für den Fächer bei „3 Karten ziehen“
    static let wasteFactor: CGFloat = 1.3

    enum Side { case none, stockWaste, cells }

    /// Linke Kante der Spalten, der Ziele und der Seitenspalte
    let columnsX: CGFloat
    let foundationX: CGFloat
    let sideX: CGFloat
    /// Ziele (und Zellen) in 1 Spalte (senkrecht) oder 2 Spalten (2 × 2)
    let foundationColumns: Int
    let cardWidth: CGFloat
    let cardHeight: CGFloat
    let gap: CGFloat
    /// Breite des Abstands zwischen Ziele/Spalten/Seitenspalte: mindestens `railGap`, wächst, wenn Breite übrig bleibt (höchstens +28 pt je Seite)
    let rail: CGFloat

    static func foundationWidth(_ w: CGFloat, columns fc: Int, gap: CGFloat) -> CGFloat { CGFloat(fc) * w + CGFloat(fc - 1) * gap }

    static func sideWidth(_ side: Side, cardWidth w: CGFloat, columns fc: Int, gap: CGFloat) -> CGFloat {
        switch side {
        case .none: 0
        case .stockWaste: wasteFactor * w
        case .cells: foundationWidth(w, columns: fc, gap: gap)
        }
    }

    static func blockWidth(cardWidth w: CGFloat, columns: Int, gap: CGFloat, side: Side, foundationColumns fc: Int) -> CGFloat {
        let s = sideWidth(side, cardWidth: w, columns: fc, gap: gap)
        return foundationWidth(w, columns: fc, gap: gap) + railGap + CGFloat(columns) * w + CGFloat(columns - 1) * gap + (s > 0 ? railGap + s : 0)
    }

    init(width: CGFloat, cardWidth w: CGFloat, cardHeight h: CGFloat, columns: Int, gap: CGFloat, side: Side, foundationColumns fc: Int, leftHanded: Bool) {
        cardWidth = w; cardHeight = h; self.gap = gap; foundationColumns = fc
        let fW = Self.foundationWidth(w, columns: fc, gap: gap)
        let sW = Self.sideWidth(side, cardWidth: w, columns: fc, gap: gap)
        let cols = CGFloat(columns) * w + CGFloat(columns - 1) * gap
        // Bleibt Breite übrig (Höhe begrenzt die Karte), geht sie in die Abstände neben den Spalten, damit der Tisch die Breite füllt
        let base = Self.blockWidth(cardWidth: w, columns: columns, gap: gap, side: side, foundationColumns: fc)
        let leftover = max(0, width - 2 * TischMetrics.margin(base: Self.margin, width: width) - base)
        rail = Self.railGap + min(leftover / (sW > 0 ? 2 : 1), 28)
        let used = fW + rail + cols + (sW > 0 ? rail + sW : 0)
        let left = (width - used) / 2
        if leftHanded {
            // [Seite][Spalten][Ziele]
            let sideBlock = sW > 0 ? sW + rail : 0
            sideX = left
            columnsX = left + sideBlock
            foundationX = columnsX + cols + rail
        } else {
            // [Ziele][Spalten][Seite]
            foundationX = left
            columnsX = left + fW + rail
            sideX = columnsX + cols + rail
        }
    }

    /// Platz k der Ziele bzw. Zellen: 1 Spalte senkrecht oder 2 × 2 (Zeile k / 2, Spalte k % 2), ab `x0`
    func stackedFrame(_ k: Int, x0: CGFloat) -> CGRect {
        let col = foundationColumns == 1 ? 0 : k % foundationColumns
        let row = foundationColumns == 1 ? k : k / foundationColumns
        return CGRect(x: x0 + CGFloat(col) * (cardWidth + gap), y: Self.topY + CGFloat(row) * (cardHeight + Self.vGap), width: cardWidth, height: cardHeight)
    }
    func foundationFrame(_ f: Int) -> CGRect { stackedFrame(f, x0: foundationX) }
    func cellFrame(_ i: Int) -> CGRect { stackedFrame(i, x0: sideX) }

    static func stackHeight(cardHeight h: CGFloat, rows: Int) -> CGFloat { CGFloat(rows) * h + CGFloat(rows - 1) * vGap + 2 * topY }

    /// Querformat, Kartenbreite zuerst aus der Breite (alle Plätze nebeneinander, höchstens 96 pt). Die Höhe begrenzt nur so weit,
    /// dass eine Karte plus 3 Fächerstufen (Indexhöhe + 3 pt) unter die Kopfzeile passen und die Ziele senkrecht oder 2 × 2 stehen.
    /// Länge der Spalten regeln danach Mindestabstand und „+N“-Block.
    static func fit(in size: CGSize, columns: Int, gap baseGap: CGFloat, side: Side, aspect: CGFloat, large: Bool) -> (cardWidth: CGFloat, foundationColumns: Int) {
        var w = maxCardWidth
        while w >= minCardWidth {
            let gap = TischMetrics.gap(base: baseGap, cardWidth: w)
            let margin = TischMetrics.margin(base: Self.margin, width: size.width)
            let h = w * aspect
            if topY + h + 3 * (TableOrientation.indexHeight(width: w, large: large) + 3) + 4 <= size.height {
                let fc = stackHeight(cardHeight: h, rows: 4) <= size.height ? 1 : (stackHeight(cardHeight: h, rows: 2) <= size.height ? 2 : 0)
                if fc > 0, blockWidth(cardWidth: w, columns: columns, gap: gap, side: side, foundationColumns: fc) + 2 * margin <= size.width {
                    return (w, fc)
                }
            }
            w -= 0.5
        }
        return (minCardWidth, 2)
    }
}

/// Abstände einer Spalte: verdeckt, offen und wie viele der tiefsten offenen Karten zum dichten Block werden
struct ColumnPlan {
    var down: CGFloat
    var open: CGFloat
    var collapsed = 0

    static let blockStep: CGFloat = 2.5
    /// So viele oberste offene Karten bleiben im Block-Fall voll sichtbar
    static let maxFull = 12

    /// - strict: Querformat (Mindestabstand ohne Ausnahme: `ruleStep`); sonst wird bis `minOpen` gestaucht
    static func make(downCount: Int, upCount: Int, cardHeight h: CGFloat, downStep: CGFloat, openBase: CGFloat, minOpen: CGFloat,
                     minDownStep: CGFloat, available: CGFloat, strict: Bool, ruleStep: CGFloat, unfolded: Bool) -> ColumnPlan {
        var down = h * downStep
        var open = openBase
        let nDown = CGFloat(downCount)
        let nOpen = CGFloat(max(upCount - 1, 0))
        guard nDown * down + nOpen * open > available else { return ColumnPlan(down: down, open: open) }
        let downMin = h * minDownStep
        if strict, !unfolded {
            if nOpen > 0 { open = max(ruleStep, (available - nDown * down) / nOpen) }
            if nDown * down + nOpen * open > available, nDown > 0 { down = max(downMin, (available - nOpen * open) / nDown) }
            if nDown * down + nOpen * open <= available { return ColumnPlan(down: down, open: open) }
            // Reicht es immer noch nicht: tiefere offene Karten werden ein dichter Block
            // Der Block hat mindestens 2 Karten; die obersten `full` Karten bleiben voll, der Abstand vom Block zur ersten vollen Karte zählt mit
            if upCount >= 3 {
                var full = min(maxFull, upCount - 2)
                while full > 1, nDown * downMin + CGFloat(upCount - full - 1) * blockStep + CGFloat(full) * ruleStep > available { full -= 1 }
                return ColumnPlan(down: downMin, open: ruleStep, collapsed: upCount - full)
            }
        }
        // Aufgeklappt (oder Hochformat): wie bisher stauchen, zuerst die offenen, dann die verdeckten.
        // Aufgeklappt darf es enger werden als sonst, damit die ganze Spalte ins Bild passt.
        down = h * downStep
        let floorOpen = unfolded ? CGFloat(6) : h * minOpen
        if nOpen > 0 { open = max(floorOpen, (available - nDown * down) / nOpen) }
        if nDown * down + nOpen * open > available, nDown > 0 { down = max(unfolded ? 2 : downMin, (available - nOpen * open) / nDown) }
        return ColumnPlan(down: down, open: open)
    }

    /// Obere Kante der i-ten offenen Karte, wenn die offenen Karten bei `y0` beginnen
    func y(ofUp i: Int, from y0: CGFloat) -> CGFloat {
        if i < collapsed { return y0 + CGFloat(i) * Self.blockStep }
        let start = collapsed > 0 ? y0 + CGFloat(collapsed - 1) * Self.blockStep + open : y0
        return start + CGFloat(i - collapsed) * open
    }
}
