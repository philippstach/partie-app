// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// design:spielinhalt-datei – Farbwerte des Kreuzworträtsels (Gitter, Felder, Akzent)
import Foundation

/// Die Farbwerte des Kreuzworträtsels an einer Stelle, je hell und dunkel. Ohne SwiftUI, damit Tests den Kontrast nachrechnen.
enum KwFarbe {
    struct Paar: Sendable { let hell: UInt32; let dunkel: UInt32 }

    /// Design-Akzent der Sammlung (wie `Design.Farbe.akzentHell`/`akzentDunkel`)
    static let akzent = Paar(hell: 0x1658D8, dunkel: 0x6FA8FF)
    static let aufAkzent = Paar(hell: 0xFFFFFF, dunkel: 0x0A1730)
    /// Große Heldenkarte der Startseite (Rätsel des Tages) und die Schrift darauf
    static let held = Paar(hell: 0x1658D8, dunkel: 0x1D3566)
    static let aufHeld = Paar(hell: 0xFFFFFF, dunkel: 0xFFFFFF)
    static let feldLeer = Paar(hell: 0xFFFFFF, dunkel: 0x1C1C1E)
    static let feldFrage = Paar(hell: 0xE4ECFB, dunkel: 0x1B2A47)
    static let feldSperre = Paar(hell: 0xD5D9E0, dunkel: 0x34343A)
    static let frageTinte = Paar(hell: 0x0F2350, dunkel: 0xE3ECFF)
    static let fehler = Paar(hell: 0xC4201D, dunkel: 0xFF6F64)
    static let linie = Paar(hell: 0x9AA3B2, dunkel: 0x4A4F5A)
    /// Seitengrund und Karten des Systems (zum Nachrechnen)
    static let papier = Paar(hell: 0xF2F2F7, dunkel: 0x000000)
    static let karte = Paar(hell: 0xFFFFFF, dunkel: 0x1C1C1E)

    /// Deckkraft der Markierungen im Buchstabenfeld
    static let wortMarkierung = (hell: 0.14, dunkel: 0.22)
    static let cursorMarkierung = (hell: 0.32, dunkel: 0.42)
    /// Bleistift-Buchstaben: heller als Tinte, aber lesbar
    static let bleistift = 0.62

    /// WCAG-Leuchtdichte und Kontrastverhältnis
    static func leuchtdichte(_ hex: UInt32) -> Double {
        func kanal(_ s: UInt32) -> Double {
            let v = Double((hex >> s) & 0xFF) / 255
            return v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * kanal(16) + 0.7152 * kanal(8) + 0.0722 * kanal(0)
    }

    static func kontrast(_ a: UInt32, _ b: UInt32) -> Double {
        let (h, d) = (max(leuchtdichte(a), leuchtdichte(b)), min(leuchtdichte(a), leuchtdichte(b)))
        return (h + 0.05) / (d + 0.05)
    }

    /// Farbe `oben` mit Deckkraft über `unten` gemischt
    static func gemischt(_ oben: UInt32, ueber unten: UInt32, deckkraft: Double) -> UInt32 {
        func k(_ s: UInt32) -> UInt32 {
            let o = Double((oben >> s) & 0xFF), u = Double((unten >> s) & 0xFF)
            return UInt32((o * deckkraft + u * (1 - deckkraft)).rounded()) << s
        }
        return k(16) | k(8) | k(0)
    }
}
