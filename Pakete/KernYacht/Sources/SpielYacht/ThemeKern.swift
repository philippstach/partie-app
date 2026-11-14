// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import KlarGlas

/// Nur im Regelkern-Paket: die Teile von `Views/Theme.swift`, die Modell und Tests brauchen (ohne Oberfläche).
extension Theme {
    static let avatars = ["😎", "🤠", "🧠", "👑", "🦁", "🐯", "🦊", "🐺", "🦄", "🐲", "👾", "🤖",
                          "🎩", "🧙", "🥷", "👻", "🎭", "🍀", "⚡", "🔥", "💎", "🌙", "🌈", "🎯"]
    static func maxPlayers(regular: Bool) -> Int { regular ? 8 : 6 }
}
