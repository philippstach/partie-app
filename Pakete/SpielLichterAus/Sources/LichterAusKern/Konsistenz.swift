// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

extension LichterAus {
    /// Stimmen Feldgröße und Lampenzahl überein? (Schutz vor beschädigten oder veralteten Spielständen)
    public var istKonsistent: Bool { (2...9).contains(n) && an.count == n * n && zuege >= 0 }
}
