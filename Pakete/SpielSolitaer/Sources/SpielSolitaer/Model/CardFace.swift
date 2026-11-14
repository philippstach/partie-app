// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

extension CardFace {
    var rankText: String {
        switch rank {
        case 1: String(localized: "A", comment: "Kürzel Ass auf der Karte")
        case 11: String(localized: "B", comment: "Kürzel Bube auf der Karte (Englisch: J)")
        case 12: String(localized: "D", comment: "Kürzel Dame auf der Karte (Englisch: Q)")
        case 13: String(localized: "K", comment: "Kürzel König auf der Karte")
        default: String(rank)
        }
    }

    var rankName: String {
        switch rank {
        case 1: String(localized: "Ass")
        case 11: String(localized: "Bube")
        case 12: String(localized: "Dame")
        case 13: String(localized: "König")
        default: String(rank)
        }
    }

    /// Für VoiceOver
    var spokenName: String { "\(suit.name) \(rankName)" }
}
