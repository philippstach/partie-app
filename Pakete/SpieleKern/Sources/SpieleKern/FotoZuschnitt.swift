// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import CoreGraphics

/// Rechnung für den Foto-Zuschnitt (ohne Oberfläche, damit testbar): Das Bild füllt zunächst den quadratischen Ausschnitt
/// (Seite `kasten`), der Zoom (>= 1) vergrößert, der Versatz verschiebt. Der Ausschnitt verlässt nie das Bild.
public struct FotoZuschnitt: Equatable, Sendable {
    public let bild: CGSize
    public let kasten: CGFloat
    public static let hoechsterZoom: CGFloat = 6

    public init?(bild: CGSize, kasten: CGFloat) {
        guard bild.width > 0, bild.height > 0, kasten > 0 else { return nil }
        self.bild = bild; self.kasten = kasten
    }

    /// Maßstab Kasten-Punkte je Bildpixel bei Zoom 1 (kürzere Seite füllt den Kasten).
    public var grundMassstab: CGFloat { kasten / min(bild.width, bild.height) }

    public static func zoomBegrenzen(_ z: CGFloat) -> CGFloat { min(max(z, 1), hoechsterZoom) }

    /// Größe des Bildes im Kasten bei diesem Zoom.
    public func anzeigeGroesse(zoom: CGFloat) -> CGSize {
        let m = grundMassstab * Self.zoomBegrenzen(zoom)
        return CGSize(width: bild.width * m, height: bild.height * m)
    }

    /// Begrenzt den Versatz (Bildmitte relativ zur Kastenmitte) so, dass der Kasten vollständig vom Bild bedeckt bleibt.
    public func versatzBegrenzen(_ v: CGSize, zoom: CGFloat) -> CGSize {
        let g = anzeigeGroesse(zoom: zoom)
        let mx = (g.width - kasten) / 2, my = (g.height - kasten) / 2
        return CGSize(width: min(max(v.width, -mx), mx), height: min(max(v.height, -my), my))
    }

    /// Ausschnitt in Bildpixeln (immer quadratisch und innerhalb des Bildes).
    public func quelle(zoom: CGFloat, versatz: CGSize) -> CGRect {
        let z = Self.zoomBegrenzen(zoom)
        let v = versatzBegrenzen(versatz, zoom: z)
        let m = grundMassstab * z
        let seite = kasten / m
        let x = (bild.width - seite) / 2 - v.width / m
        let y = (bild.height - seite) / 2 - v.height / m
        return CGRect(x: min(max(x, 0), bild.width - seite), y: min(max(y, 0), bild.height - seite), width: seite, height: seite)
    }
}
