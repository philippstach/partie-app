// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// design:spielinhalt-datei – Kartenvorderseiten und Tinte (Spielmaterial); Pokale aus der Familienfarbe
import SwiftUI
import KlarGlas
import SpieleKern

// App-spezifische Ergänzungen zu Theme (Kern: KlarGlas.swift)
extension Theme {
    /// Kartenformat: Höhe = Breite × 1,4
    static let cardAspect: CGFloat = 1.4

    static func dynamic(_ light: UInt32, _ dark: UInt32, lightAlpha: Double = 1, darkAlpha: Double = 1) -> Color {
        Color(uiColor: UIColor { t in
            let dunkel = t.userInterfaceStyle == .dark
            let hex = dunkel ? dark : light
            return UIColor(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
                           blue: CGFloat(hex & 0xFF) / 255, alpha: dunkel ? darkAlpha : lightAlpha)
        })
    }

    // Tisch
    // (Tische und Rücken: Themes.swift)

    // Karten (die Vorderseite bleibt in beiden Modi hell)
    // Designwechsel D.2: Tinte und Salon nehmen Papier, Rand, Schwarz und Rot vom gemeinsamen Kartenstil (SpieleKern.KartenStil); klar wie bisher.
    private static let cardFaceKlar = dynamic(0xFFFFFF, 0xE9E5DC)
    private static let cardEdgeKlar = dynamic(0x000000, 0x000000, lightAlpha: 0.12, darkAlpha: 0.35)
    private static let inkKlar = Color(hex: 0x1B1B1F)
    private static let inkRedKlar = dynamic(0xC3262E, 0xB8222A)
    static var cardFace: Color { KartenStil.ist(.klar) ? cardFaceKlar : KartenStil.aktuell.papier }
    static var cardEdge: Color { KartenStil.ist(.klar) ? cardEdgeKlar : (KartenStil.aktuell.rand ?? .clear) }
    static var cardEdgeWidth: CGFloat { KartenStil.ist(.klar) ? 0.5 : KartenStil.aktuell.randStaerke }
    /// Eckenradius einer Karte der Breite `width` (klar 9 % der Breite, Tinte 4, Salon 3).
    static func cardRadius(_ width: CGFloat) -> CGFloat { KartenStil.ist(.klar) ? width * 0.09 : KartenStil.aktuell.ecke(breite: width) }
    static var ink: Color { KartenStil.ist(.klar) ? inkKlar : KartenStil.aktuell.schwarz }
    /// Gold der Bildkarten (Innenrahmen, Krone, Pik-Ass-Ring)
    static let cardGold = Color(hex: 0xB08A2E)
    static var inkRed: Color { KartenStil.ist(.klar) ? inkRedKlar : KartenStil.aktuell.rot }
    static let inkBlue = dynamic(0x1F5FBF, 0x1C55AA)
    static let inkGreen = dynamic(0x2E7D32, 0x2A6F2E)

    // Grüner Rücken (Muster und Rand)
    static let backPattern = dynamic(0xFFFFFF, 0xFFFFFF, lightAlpha: 0.32, darkAlpha: 0.22)
    static let backBorder = Color.white

    // Pokale aus der Familienfarbe (kein Gold, Konzept 3.3): Erster Orange, Zweiter Schiefer-Text, Dritter Braun
    static let bronze = Familienfarbe.braun.color
    static let silver = Color.familie(Familienfarbe.schiefer.textDunkel)
    static let cupGold = Familienfarbe.orange.color

    static func ink(for suit: Suit, fourColor: Bool) -> Color {
        switch suit {
        case .spades: ink
        case .hearts: inkRed
        case .diamonds: fourColor ? inkBlue : inkRed
        case .clubs: fourColor ? inkGreen : ink
        }
    }
}

extension Suit {
    var symbolName: String {
        switch self {
        case .spades: "suit.spade.fill"
        case .hearts: "suit.heart.fill"
        case .diamonds: "suit.diamond.fill"
        case .clubs: "suit.club.fill"
        }
    }
}

extension Color {
    /// App-Farbe ausdrücklich aus dem Asset `AccentColor` (hell + dunkel). `Color.accentColor` lieferte auf dem Spieltisch das System-Blau.
    static var appFarbe: Color { Color.appFlaeche }
}
