// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

extension Theme {
    static let avatars = ["😎", "🤠", "🧠", "👑", "🦁", "🐯", "🦊", "🐺", "🦄", "🐲", "👾", "🤖",
                          "🎩", "🧙", "🥷", "👻", "🎭", "🍀", "⚡", "🔥", "💎", "🌙", "🌈", "🎯"]

    static let playerHex: [UInt32] = [ // design:spielinhalt (Spielerfarben)
        0xFF8A5B, 0x5B9FD9, 0x4FBF7A, 0xE06666, 0xA66BD9, 0xE89A4F, 0x3FBFBF, 0xE0669E,
    ]

    static let playerColors: [Color] = playerHex.map { Color(hex: $0) } // design:spielinhalt
    /// Höchstzahl der Spieler: auf dem iPhone 6 (jede Spalte im Blatt bleibt gut lesbar), auf dem iPad 8.
    static func maxPlayers(regular: Bool) -> Int { regular ? 8 : 6 }

    static func color(_ index: Int) -> Color { playerColors[index % playerColors.count] }

    /// Spielerfarbe für Text: im hellen Modus abgedunkelt, damit sie lesbar bleibt.
    static func textColor(_ index: Int) -> Color {
        let hex = playerHex[index % playerHex.count]
        return Color.spielerText(hex: hex)
    }

    static func points(_ value: Int) -> String {
        value.formatted(.number)
    }

}

extension Player {
    var color: Color { Theme.color(colorIndex) }
    var textColor: Color { Theme.textColor(colorIndex) }
}
