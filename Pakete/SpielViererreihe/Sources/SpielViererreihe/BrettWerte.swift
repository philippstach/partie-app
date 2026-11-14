// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import UIKit
import KlarGlas

/// Die Brett-Tabelle der neuen Viererreihe: alle Maße und Farben des Bretts je Design an einer Stelle.
/// `klar` liefert die bisherigen Werte (Darstellung unverändert); Tinte und Salon die überarbeiteten.
struct BrettWerte {
    let art: DesignArt
    let dunkel: Bool
    /// „Transparenz reduzieren“ ist an: dann bleibt das bisherige deckende Brett (kein Glas).
    var transparenzReduziert: Bool = false

    /// Glasplatte (Tinte und Salon, solange die Transparenz nicht reduziert ist).
    /// K-032: Tinte bleibt Papierstil (kein Glas); nur Salon bekommt die Glasplatte.
    var glas: Bool { art == .salon && !transparenzReduziert }
    var gestanzt: Bool { art != .klar }
    /// Eckenradius des Bretts: Klar wie die Karten, sonst 8.
    var radius: CGFloat { gestanzt ? 8 : Theme.cardRadius }
    /// Anteil der Zellenkante, den Loch und Stein einnehmen (Klar: Loch 86 %, Stein 82 %).
    var lochAnteil: CGFloat { gestanzt ? 0.78 : 0.86 }
    var steinAnteil: CGFloat { gestanzt ? 0.78 : 0.82 }
    /// Innenabstand eines Lochs zur Zellkante.
    func lochAbstand(_ kante: CGFloat) -> CGFloat { kante * (1 - lochAnteil) / 2 }
    func steinAbstand(_ kante: CGFloat) -> CGFloat { kante * (1 - steinAnteil) / 2 }
    /// Sockelstreifen unter dem Brett (nur Salon).
    var sockel: CGFloat { art == .salon && !glas ? 8 : 0 }
    /// Ring im Loch bzw. im Stein.
    static let lochRing: CGFloat = 2
    static let tintenLinie: CGFloat = 1.5
    static let steinRing: CGFloat = 2
    static let lochDunkler: Double = 0.30
    static let steinDunkler: Double = 0.20
    /// Salon dunkel: Anteil der Spielart-Farbe in der Brettfläche (Rest Seitengrund).
    static let salonDunkelAnteil: Double = 0.60

    /// Brettfläche.
    var flaeche: Color {
        switch art {
        case .klar: Color.appFlaeche.opacity(dunkel ? 0.62 : 0.28)   // M-022: im Dunkeln deckender, sonst verschwindet das Brett auf Schwarz
        case .tinte: Color.feldGrund
        case .salon: dunkel ? Self.mischen(Color.appFlaeche, Color.seitenGrund, anteilA: Self.salonDunkelAnteil) : Color.appFlaeche
        }
    }
    /// Das Loch.
    var loch: Color { art == .klar ? (dunkel ? Color.black.opacity(0.85) : Color(.systemBackground).opacity(0.9)) : Color.seitenGrund }
    /// Brettfarbe, um 30 % abgedunkelt (Lochring und Sockel in Salon).
    var brettDunkel: Color { Self.abdunkeln(flaeche, Self.lochDunkler) }
    /// Linie von Rahmen und Lochring.
    var lochLinie: Color { art == .tinte ? Color.linieStark : brettDunkel }
    var lochLinieBreite: CGFloat { art == .tinte ? Self.tintenLinie : Self.lochRing }

    // MARK: Farbrechnung

    static func aufhellen(_ c: Color, _ anteil: Double) -> Color {
        Color(UIColor { trait in
            let u = UIColor(c).resolvedColor(with: trait)
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            u.getRed(&r, green: &g, blue: &b, alpha: &a)
            let t = CGFloat(anteil)
            return UIColor(red: r + (1 - r) * t, green: g + (1 - g) * t, blue: b + (1 - b) * t, alpha: a)
        })
    }

    static func abdunkeln(_ c: Color, _ anteil: Double) -> Color {
        Color(UIColor { trait in
            let u = UIColor(c).resolvedColor(with: trait)
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            u.getRed(&r, green: &g, blue: &b, alpha: &a)
            let f = 1 - anteil
            return UIColor(red: r * f, green: g * f, blue: b * f, alpha: a)
        })
    }

    static func mischen(_ a: Color, _ b: Color, anteilA: Double) -> Color {
        Color(UIColor { trait in
            var xr: CGFloat = 0, xg: CGFloat = 0, xb: CGFloat = 0, xa: CGFloat = 0
            var yr: CGFloat = 0, yg: CGFloat = 0, yb: CGFloat = 0, ya: CGFloat = 0
            UIColor(a).resolvedColor(with: trait).getRed(&xr, green: &xg, blue: &xb, alpha: &xa)
            UIColor(b).resolvedColor(with: trait).getRed(&yr, green: &yg, blue: &yb, alpha: &ya)
            let t = CGFloat(anteilA)
            return UIColor(red: xr * t + yr * (1 - t), green: xg * t + yg * (1 - t), blue: xb * t + yb * (1 - t), alpha: 1)
        })
    }
}

/// Tabelle „Glas“: alle Zahlen der geschliffenen Glasplatte (Tinte und Salon). Der View enthält keine eigenen Werte.
enum Glas {
    static let radius: CGFloat = 14
    /// Leeres Loch: Seitengrund plus Schwarz.
    static let lochSchwarz: Double = 0.06
    /// Füllung, Deckkraft von links oben nach rechts unten.
    static func fuellung(dunkel: Bool) -> (von: Double, nach: Double) { dunkel ? (0.58, 0.34) : (0.62, 0.42) }
    /// Glasfarbe in dunkel: Aufhellung Richtung Weiß (gegen den trüben Eindruck).
    static func glasAufhellung(dunkel: Bool) -> Double { dunkel ? 0.20 : 0 }
    /// Lichtstreifen: Anteil der Brettbreite, Neigung in Grad, Lage der Mitte (Anteil der Breite), Deckkraft.
    static let streifenBreite: CGFloat = 0.45
    static let streifenWinkel: Double = 20
    static let streifenLage: CGFloat = 0.40
    static func streifenDeckkraft(dunkel: Bool) -> Double { dunkel ? 0.08 : 0.14 }
    /// Querverlauf des Streifens (durchsichtig, Weiß, durchsichtig): Stützpunkte.
    static let streifenStuetzen: [CGFloat] = [0, 0.5, 1]
    /// Schliffkante außen (Kontur) und Facettenlinie.
    static let kanteBreite: CGFloat = 1.5
    static let kanteOben: Double = 0.75, kanteMitte: Double = 0.10, kanteUnten: Double = 0.18
    static let facetteBreite: CGFloat = 1, facetteAbstand: CGFloat = 2.5, facetteDeckkraft: Double = 0.18
    /// Lochkanten (eingeschnitten): oben Schwarz, unten Weiß.
    static let lochRand: CGFloat = 1.5
    static let lochRandOben: Double = 0.28, lochRandUnten: Double = 0.45
    /// Schatten unter dem Brett.
    static func schatten(dunkel: Bool) -> (deckkraft: Double, radius: CGFloat, y: CGFloat) { dunkel ? (0.5, 12, 6) : (0.25, 10, 6) }
    /// Glaslinse: Lichtpunkt des Verlaufs, Aufhellung innen, Abdunklung außen, Ausdehnung (Anteil des Durchmessers).
    static let linseMitte = UnitPoint(x: 0.35, y: 0.30)
    static let linseHeller: Double = 0.25, linseDunkler: Double = 0.15, linseRadius: CGFloat = 0.8
    static let glanzBreite: CGFloat = 0.38, glanzHoehe: CGFloat = 0.22, glanzDeckkraft: Double = 0.35, glanzWeich: CGFloat = 1.5
    static let glanzLinks: CGFloat = 0.17, glanzOben: CGFloat = 0.12
    static let linsenRand: CGFloat = 1, linsenRandOben: Double = 0.35
}
#endif
