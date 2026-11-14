// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern
import UIKit

/// Aufbau einer Seite nach der Fenstergröße, nicht nach dem Gerät (SPEZIFIKATION → iPad).
/// Ein iPad im schmalen Split View oder kleinen Stage-Manager-Fenster bekommt das iPhone-Layout.
nonisolated enum SpielLayout: Equatable, Sendable {
    case kompakt, breitHoch, breitQuer

    /// Unter dieser Breite gilt immer `kompakt`
    static let kompaktUnter: CGFloat = 700
    /// Querformat erst ab dieser Breite
    static let querAb: CGFloat = 1000

    static func entscheide(breite: CGFloat, hoehe: CGFloat, sizeClass: UserInterfaceSizeClass?,
                           grosseSchrift: Bool = false) -> SpielLayout {
        if sizeClass == .compact || breite < kompaktUnter { return .kompakt }
        // Bedienungshilfen-Schriftgrößen: Spalten würden zu schmal, also untereinander
        if grosseSchrift { return .breitHoch }
        return breite > hoehe && breite >= querAb ? .breitQuer : .breitHoch
    }

    var breit: Bool { self != .kompakt }
}

