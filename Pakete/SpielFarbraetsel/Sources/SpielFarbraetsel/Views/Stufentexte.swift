// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI

extension Stufe {
    var name: LocalizedStringResource {
        switch self {
        case .leicht: "Leicht"
        case .mittel: "Mittel"
        case .schwer: "Schwer"
        }
    }

    var beschreibung: LocalizedStringKey {
        switch self {
        case .leicht: "Der Rand steht schon. Gut zum Einstieg."
        case .mittel: "Nur Ecken und Randmitten stehen fest."
        case .schwer: "Nur die vier Ecken sind vorgegeben."
        }
    }
}
#endif
