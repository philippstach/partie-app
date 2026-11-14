// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Standard-Avatare zur Unterscheidung der Spieler (vorher je eine Kopie in Rauswurf, Schocken und Viererreihe).
public enum Avatare {
    public static let alle = ["😎", "🤠", "🧠", "👑", "🦁", "🐯", "🦊", "🐺", "🦄", "🐲", "👾", "🤖",
                              "🎩", "🧙", "🥷", "👻", "🎭", "🍀", "⚡", "🔥", "💎", "🌙", "🌈", "🎯"]
    public static func standard(_ index: Int) -> String { alle[index % alle.count] }
}
