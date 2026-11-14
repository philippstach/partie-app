// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import SpieleKern
import KlarGlas

// MARK: Rauswurf-spezifisch

extension Theme {
    /// Farbe für Text in einer Spielerfarbe: im hellen Modus abgedunkelt, damit sie lesbar bleibt.
    static func textColor(hex: UInt32) -> Color { // design:spielinhalt
        Color.spielerText(hex: hex)
    }
}


/// Spieler-Abzeichen in der Farbe des Sitzes; die Farbe kommt aus dem gewählten `BrettTheme`, das Abzeichen selbst aus dem Kern.
struct AvatarBadge: View {
    let avatar: String
    /// Sitz 0…3 (Farbe aus dem `BrettTheme`)
    let sitz: Int
    var size: CGFloat = 36
    @Environment(\.brettTheme) private var theme

    var body: some View { AvatarAbzeichen(avatar: avatar, farbe: theme.farbe(sitz), groesse: size) }
}
