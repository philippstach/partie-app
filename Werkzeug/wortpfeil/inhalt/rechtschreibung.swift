// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// Liest Wörter (eins pro Zeile) von stdin und gibt die aus, die die macOS-Rechtschreibprüfung (Deutsch) nicht kennt.
// Nur lokales Werkzeug für Referenz/inhalt.py – kommt nie in die App.
import AppKit

let pruefer = NSSpellChecker.shared
while let zeile = readLine() {
    let wort = zeile.trimmingCharacters(in: .whitespaces)
    if wort.isEmpty { continue }
    let treffer = pruefer.checkSpelling(of: wort, startingAt: 0, language: "de", wrap: false,
                                        inSpellDocumentWithTag: 0, wordCount: nil)
    if treffer.location != NSNotFound { print(wort) }
}
