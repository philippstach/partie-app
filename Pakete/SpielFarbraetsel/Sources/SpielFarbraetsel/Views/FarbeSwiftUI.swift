// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern

extension Color {
    init(_ ton: Farbton) {
        self.init(red: ton.rot, green: ton.gruen, blue: ton.blau)
    }
}

// Zeitformat kommt aus KlarGlas (Q16): `Zeitformat.text(_:)` nimmt Sekunden als Double.
#endif
