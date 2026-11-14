// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Rätselschreibweise: ein Großbuchstabe A–Z pro Feld (Ä→AE, Ö→OE, Ü→UE, ß→SS, Akzente weg).
enum Normalizer {
    private static let replacements: [String: String] = ["Ä": "AE", "Ö": "OE", "Ü": "UE", "ß": "SS", "ẞ": "SS"]

    static func normalize(_ text: String) -> String {
        var out = ""
        for scalar in text.unicodeScalars {
            let s = String(scalar)
            if s == "ß" || s == "ẞ" { out += "SS"; continue }
            let upper = s.uppercased()
            if let r = replacements[upper] { out += r; continue }
            // Akzente erst nach der Umlaut-Ersetzung entfernen
            if let base = upper.decomposedStringWithCanonicalMapping.unicodeScalars.first,
               base.value >= 65, base.value <= 90 {
                out.unicodeScalars.append(base)
            }
        }
        return out
    }
}
