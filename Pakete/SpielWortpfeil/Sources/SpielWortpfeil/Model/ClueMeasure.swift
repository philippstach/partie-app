// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation
import CoreGraphics
#if canImport(UIKit)
import UIKit
typealias PlatformFont = UIFont
#else
import AppKit
typealias PlatformFont = NSFont
#endif

/// Satzlogik für Fragetexte in Fragefeldern – ohne SwiftUI, damit die App und das Mac-Werkzeug
/// `Tools/fragefeld_messen.swift` dieselbe Messung benutzen.
/// Deutsche Silbentrennung (weiche Trennstriche), schmale mittelstarke Schrift, Zeilenabstand −2,
/// größte Schrift, die passt, mindestens `minimum(split:)`. Wörter werden nie mitten im Wort getrennt.
enum ClueFit {
    static let minSize: CGFloat = 7
    private static let de = Locale(identifier: "de")
    private static let soft = "\u{00AD}"
    nonisolated(unsafe) private static var cache: [String: Result] = [:]
    private static let lock = NSLock()

    struct Result: Sendable {
        var text: String       // mit weichen Trennstrichen
        var size: CGFloat
        var lines: Int
        var fits: Bool         // false: auch bei Mindestgröße zu groß (wird mit „…“ gekürzt)
    }

    // MARK: Maße des Fragefelds

    /// Mindestschrift: 8 pt bei einer Frage im Feld, 7 pt bei zwei
    static func minimum(split: Bool) -> CGFloat { split ? 7 : 8 }

    /// Startgröße der Schrift im Feld (wird verkleinert, bis der Text passt)
    static func baseSize(cell: CGFloat) -> CGFloat { min(14, max(9, cell * 0.24)) }

    /// Platz für den Text: das Feld ohne die Zone des Pfeils (4,5 pt am Rand zur Wortseite) und ohne 1,2 pt Rand ringsum.
    /// `bottom` = Pfeil am unteren Rand (Frage nach unten), sonst am rechten Rand.
    static let arrowZone: CGFloat = 4.5
    static let margin: CGFloat = 1.2

    static func box(cell: CGFloat, bottom: Bool, split: Bool) -> CGSize {
        let w = cell - 2 * margin - (bottom ? 0 : arrowZone)
        var h = (split ? cell * 0.5 : cell) - 2 * margin
        if bottom { h -= arrowZone }
        return CGSize(width: max(8, w), height: max(8, h))
    }

    /// Fragetext für ein Feld der Größe `cell` einpassen
    static func fitField(_ text: String, cell: CGFloat, bottom: Bool, split: Bool) -> Result {
        let b = box(cell: cell, bottom: bottom, split: split)
        return fit(text, width: b.width, height: b.height, base: baseSize(cell: cell), minSize: minimum(split: split))
    }

    // MARK: Messung

    private static func font(_ size: CGFloat) -> PlatformFont {
        #if canImport(UIKit)
        return .systemFont(ofSize: size, weight: .medium, width: .condensed)
        #else
        let base = NSFont.systemFont(ofSize: size, weight: .medium)
        let desc = base.fontDescriptor.addingAttributes([.traits: [NSFontDescriptor.TraitKey.width: -0.2]])
        return NSFont(descriptor: desc, size: size) ?? base
        #endif
    }

    private static func lineHeight(_ f: PlatformFont) -> CGFloat { f.ascender - f.descender + f.leading }

    /// Fügt weiche Trennstriche an deutschen Silbengrenzen ein
    static func hyphenated(_ text: String) -> String {
        guard CFStringIsHyphenationAvailableForLocale(de as CFLocale) else { return text }
        return text.split(separator: " ", omittingEmptySubsequences: false).map { word -> String in
            let w = String(word)
            guard w.count > 5 else { return w }
            let ns = w as NSString
            // Trennstellen: die Rückgabewerte „letzte Trennstelle vor Index i“
            var points = Set<Int>()
            for i in 0...ns.length {
                let p = CFStringGetHyphenationLocationBeforeIndex(w as CFString, i, CFRange(location: 0, length: ns.length), 0, de as CFLocale, nil)
                if p >= 2, p <= ns.length - 2 { points.insert(p) }
            }
            var out = ""
            for i in 0..<ns.length {
                if points.contains(i) { out += soft }
                out += ns.substring(with: NSRange(location: i, length: 1))
            }
            return out
        }.joined(separator: " ")
    }

    /// Größte Schrift (0,5-pt-Schritte) von `base` abwärts, bei der der Text in `width × height` passt
    static func fit(_ text: String, width: CGFloat, height: CGFloat, base: CGFloat, minSize: CGFloat = ClueFit.minSize) -> Result {
        let key = "\(minSize)|\(text)|\(Int(width * 2))|\(Int(height * 2))|\(Int(base * 2))"
        lock.lock(); let cached = cache[key]; lock.unlock()
        if let cached { return cached }
        let h = hyphenated(text)
        let top = max(base, minSize)
        // Passt eine Größe, passen auch alle kleineren: Halbierungssuche über die 0,5-pt-Stufen
        let steps = Int(((top - minSize) * 2).rounded(.down))
        var result: Result?
        if let lines = measure(h, size: minSize, width: width, height: height) {
            var lo = 0, hi = steps          // Stufe 0 = minSize passt
            var best = (size: minSize, lines: lines)
            while lo <= hi {
                let mid = (lo + hi) / 2
                let size = minSize + CGFloat(mid) * 0.5
                if let l = measure(h, size: size, width: width, height: height) { best = (size, l); lo = mid + 1 } else { hi = mid - 1 }
            }
            result = Result(text: h, size: best.size, lines: best.lines, fits: true)
        }
        let r = result ?? Result(text: h, size: minSize, lines: max(1, Int(height / lineHeight(font(minSize)))), fits: false)
        lock.lock(); cache[key] = r; lock.unlock()
        return r
    }

    /// Zeilenzahl, wenn der Text passt (kein Wortteil breiter als die Zeile, Höhe reicht), sonst nil
    private static func measure(_ text: String, size: CGFloat, width: CGFloat, height: CGFloat) -> Int? {
        let f = font(size)
        let hyphen = ("-" as NSString).size(withAttributes: [.font: f]).width
        for word in text.split(separator: " ") {
            let parts = word.components(separatedBy: soft)
            for (i, part) in parts.enumerated() {
                let w = (part as NSString).size(withAttributes: [.font: f]).width + (i < parts.count - 1 ? hyphen : 0)
                if w > width { return nil }
            }
        }
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        style.lineBreakMode = .byWordWrapping
        style.lineSpacing = -2   // wie im Fragefeld (.lineSpacing(-2))
        let rect = (text as NSString).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin], attributes: [.font: f, .paragraphStyle: style], context: nil)
        guard ceil(rect.height) <= height else { return nil }
        return max(1, Int((rect.height / lineHeight(f)).rounded()))
    }
}
