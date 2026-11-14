// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import KlarGlas
import SwiftUI
import SpieleKern

// App-spezifische Hilfen (nicht Teil der gemeinsamen Vorlage).


extension Font {
    /// Zahlen und Buchstaben immer `.rounded`
    static func rounded(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        .system(style, design: KlarGlasDesign.zahlDesign, weight: weight)
    }
}

extension Category {
    var symbol: String {
        switch self {
        case .animals: "pawprint.fill"
        case .food: "fork.knife"
        case .countries: "globe.europe.africa.fill"
        case .sports: "figure.run"
        case .nature: "leaf.fill"
        case .home: "house.fill"
        case .transport: "car.fill"
        case .music: "music.note"
        }
    }
}

extension Difficulty {
    var key: LocalizedStringKey {
        switch self {
        case .easy: "Leicht"
        case .medium: "Mittel"
        case .hard: "Schwer"
        }
    }

    var title: LocalizedStringResource {
        switch self {
        case .easy: "Leicht"
        case .medium: "Mittel"
        case .hard: "Schwer"
        }
    }
}
#endif
