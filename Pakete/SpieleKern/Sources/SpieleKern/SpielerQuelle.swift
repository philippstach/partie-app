// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Brücke für Spiele, die ihre eigene Liste „Bekannte Spieler“ führen: lesen aus dem gemeinsamen Verzeichnis, melden neue Namen dorthin.
public enum SpielerQuelle {
    /// Abbild des Verzeichnisses (Menschen, zuletzt gespielte zuerst); die Hülle hält es aktuell.
    nonisolated(unsafe) public static var bekannt: [(name: String, avatar: String, farbeHex: UInt32)] = []

    /// Index der Farbe in `palette`, die der Hüllenfarbe `hex` am nächsten kommt (einfacher RGB-Abstand). So trägt Anna in jedem
    /// Spiel „ihre“ Farbe, auch wenn das Spiel eine eigene Spielerpalette hat.
    public static func naechsteFarbe(zu hex: UInt32, in palette: [UInt32]) -> Int {
        guard !palette.isEmpty else { return 0 }
        func rgb(_ h: UInt32) -> (Int, Int, Int) { (Int((h >> 16) & 0xFF), Int((h >> 8) & 0xFF), Int(h & 0xFF)) }
        let (r, g, b) = rgb(hex)
        return palette.indices.min { i, j in
            let a = rgb(palette[i]), c = rgb(palette[j])
            return (a.0 - r) * (a.0 - r) + (a.1 - g) * (a.1 - g) + (a.2 - b) * (a.2 - b) < (c.0 - r) * (c.0 - r) + (c.1 - g) * (c.1 - g) + (c.2 - b) * (c.2 - b)
        } ?? 0
    }

    /// Farbe eines bekannten Spielers (Hülle), falls er im Verzeichnis steht.
    public static func farbeHex(fuer name: String) -> UInt32? {
        bekannt.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }?.farbeHex
    }
    nonisolated(unsafe) public static var anmelden: (@MainActor ([String]) -> Void)?

    /// Namen, die ein Spiel nur technisch als Spieler setzt (z. B. „Tageswürfel“ im Solo-Modus); sie kommen nie ins Verzeichnis (Fund S1-010). Kleingeschrieben.
    nonisolated(unsafe) public static var technischeNamen: Set<String> = ["tageswürfel", "daily dice", "dado diario", "dé du jour"]

    /// Das Spiel meldet Namen menschlicher Mitspieler (beim Start einer Partie).
    public static func menschen(_ namen: [String]) {
        let n = namen.filter { name in
            let k = name.trimmingCharacters(in: .whitespaces).lowercased()
            return !k.isEmpty && !technischeNamen.contains(k)
        }
        guard !n.isEmpty else { return }
        Task { @MainActor in anmelden?(n) }
    }
}
