// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import CoreGraphics
import Foundation

/// Misst, wie stark sich das Kamerabild zwischen zwei Auswertungen verändert hat (Wackeln oder bewegte Würfel).
/// Arbeitet auf kleinen Graubildern (Werte 0…255) und ist ohne Kamera testbar.
public struct RuheMesser: Sendable {
    private var vorher: [UInt8]?
    public init() {}

    /// Mittlere Abweichung zum vorigen Bild, 0 (gleich) bis 1 (völlig anders). Beim ersten Bild: 1 (noch nichts zum Vergleichen).
    public mutating func bewegung(_ miniatur: [UInt8]) -> Double {
        defer { vorher = miniatur }
        guard let v = vorher, v.count == miniatur.count, !v.isEmpty else { return 1 }
        var summe = 0
        for i in v.indices { summe += abs(Int(v[i]) - Int(miniatur[i])) }
        return Double(summe) / Double(v.count) / 255
    }

    public mutating func zuruecksetzen() { vorher = nil }
}

/// Aus der Bewegung wird „ruhig“ oder „wackelt“: ruhig erst nach `noetig` ruhigen Auswertungen in Folge, wackelt sofort.
public struct RuheFilter: Sendable {
    /// Mittlere Bildabweichung, ab der das Bild als bewegt gilt (Handschwankung liegt darunter, echtes Wackeln deutlich darüber).
    public var schwelle: Double
    public var noetig: Int
    public private(set) var ruhig = false
    private var folge = 0

    public init(schwelle: Double = 0.03, noetig: Int = 2) { self.schwelle = schwelle; self.noetig = noetig }

    @discardableResult
    public mutating func beobachte(bewegung: Double) -> Bool {
        if bewegung > schwelle { folge = 0; ruhig = false } else { folge += 1; if folge >= noetig { ruhig = true } }
        return ruhig
    }

    public mutating func zuruecksetzen() { folge = 0; ruhig = false }
}

extension RuheMesser {
    /// Verkleinertes Graubild (24 × 42) für den Bildvergleich.
    public static func miniatur(_ bild: CGImage) -> [UInt8] {
        let w = 24, h = 42
        var roh = [UInt8](repeating: 0, count: w * h)
        roh.withUnsafeMutableBytes { p in
            guard let ctx = CGContext(data: p.baseAddress, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w,
                                      space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue) else { return }
            ctx.interpolationQuality = .high
            ctx.draw(bild, in: CGRect(x: 0, y: 0, width: w, height: h))
        }
        return roh
    }
}
