// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// design:spielinhalt-datei (Spielerfarben und Avatare sind Spielinhalt, DESIGN.md 3.6)
import SwiftUI
import KlarGlas
import SpieleKern

extension Theme {
    /// Spielerfarben = Familienfarben (wie das Spielerverzeichnis der Sammlung; kein Gold).
    private static let playerHex: [UInt32] = Familienfarbe.spieler.map(\.flaeche)

    static let playerColors: [Color] = playerHex.map { Color.familie($0) }
    static let maxPlayers = 6

    static func color(_ index: Int) -> Color { playerColors[index % playerColors.count] }

    /// Spielerfarbe für Text: im hellen Modus abgedunkelt, damit sie lesbar bleibt.
    static func textColor(_ index: Int) -> Color {
        let hex = playerHex[index % playerHex.count]
        return Color.spielerText(hex: hex)
    }

}
