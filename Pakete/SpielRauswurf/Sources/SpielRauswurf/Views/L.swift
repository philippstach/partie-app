// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Übersetzter Text zu einem Schlüssel aus `Localizable.xcstrings` (Quelle: `Doku/TEXTE.md`).
/// `%@` für Namen, `%lld` für Zahlen.
func L(_ key: String, _ args: CVarArg...) -> String {
    let format = NSLocalizedString(key, comment: "")
    return args.isEmpty ? format : String(format: format, locale: Locale.current, arguments: args)
}
