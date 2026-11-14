// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import UIKit

public extension Color {
    /// Lesbare Textfarbe zu einer Spielerfarbe: im dunklen Modus die Farbe selbst, im hellen Modus abgedunkelt.
    /// (Vorher je Spiel eine eigene Kopie in `Theme.textColor`.)
    static func spielerText(hex: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            let f: CGFloat = traits.userInterfaceStyle == .dark ? 1 : 0.62
            return UIColor(
                red: CGFloat((hex >> 16) & 0xFF) / 255 * f,
                green: CGFloat((hex >> 8) & 0xFF) / 255 * f,
                blue: CGFloat(hex & 0xFF) / 255 * f,
                alpha: 1
            )
        })
    }
}
#endif
