// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Ort einer Karte oder eines Stapels – gleich für alle Spielvarianten.
enum Pile: Hashable {
    case stock
    case waste
    case foundation(Int)
    case column(Int)
    case cell(Int)
}

/// Ein Zug – gleich für alle Spielvarianten. `.draw` = Stapel antippen.
enum Move: Hashable {
    case draw
    case move(from: Pile, to: Pile, count: Int)
}
