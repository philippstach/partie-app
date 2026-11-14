// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas

/// Brücke zum Spielerverzeichnis der Sammlung.
public enum Quelle10k {
    /// Spielerverzeichnis der Sammlung: lesen (Name, Avatar) und neue Namen melden; die Modul-Schicht setzt beides.
    nonisolated(unsafe) public static var lesen: () -> [(name: String, avatar: String, farbeHex: UInt32)] = { [] }
    nonisolated(unsafe) public static var melden: (([String]) -> Void)?
    /// Meldet beim Verlassen, ob eine Partie offen ist.
    nonisolated(unsafe) public static var offen: ((Bool) -> Void)?
}
