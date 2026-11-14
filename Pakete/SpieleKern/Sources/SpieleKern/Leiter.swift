// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// D4 „Schwierigkeitsleiter“: Die Stufen eines Rätselspiels schalten sich nacheinander frei.
/// Stufe 0 ist immer offen; Stufe n+1 öffnet sich nach `siegeNoetig` Siegen ohne Tipp auf Stufe n.
/// Im Kindermodus und mit dem Schalter „Alle Stufen offen“ ist nichts gesperrt (kein Frust, kein Zwang).
/// Reine Zählung auf dem Gerät in `UserDefaults`; Tagesrätsel zählen nicht und sind nie gesperrt.
public enum Leiter {
    public static let siegeNoetig = 3
    /// Schalter in den Einstellungen; gleiche Schreibweise wie die anderen Schlüssel der Hülle.
    public static let alleOffenKey = "leiterAlleOffen"
    public static let kinderKey = "kinderModus"

    /// Spiele mit Leiter: Kennung, Anzeigename, Stufennamen (in Schreibweise der Sprachdatei).
    public static let spiele: [(id: String, name: String, stufen: [String])] = [
        ("lichteraus", "Lichter aus", ["Leicht", "Mittel", "Schwer"]),
        ("farbflut", "Farbfüller", ["Leicht", "Normal", "Schwer"]),
        ("farbcode", "Farbcode", ["Leicht", "Normal", "Schwer"]),
        ("bruecken", "Brücken", ["Leicht", "Mittel", "Schwer", "Experte"]),
        ("ungleichung", "Ungleichung", ["Mit Starthilfe", "Schwer"]),
        ("sudoku", "Sudoku", ["Leicht", "Mittel", "Schwer", "Experte"]),
        ("minensuche", "Minensuche", ["Leicht", "Mittel", "Schwer"]),
        ("nonogramm", "Nonogramm", ["5 × 5", "8 × 8", "10 × 10", "12 × 12", "15 × 15"]),
        ("kakuro", "Kakuro", ["5 × 5", "6 × 6", "7 × 7"]),
    ]

    /// T-6: Die App sagt, welche Spiele es in dieser Fassung gibt (Standard: alle). Die Übersicht zeigt nur diese; die Zähler der übrigen bleiben erhalten.
    @MainActor public static var istSichtbar: (String) -> Bool = { _ in true }

    static func key(_ spiel: String, _ stufe: Int) -> String { "partie.leiter.\(spiel).\(stufe)" }

    public static func alleOffen(_ d: UserDefaults = .standard) -> Bool { d.bool(forKey: alleOffenKey) || d.bool(forKey: kinderKey) }

    /// Gezählte Siege auf dieser Stufe (ohne Tipp).
    public static func siege(_ spiel: String, stufe: Int, _ d: UserDefaults = .standard) -> Int { d.integer(forKey: key(spiel, stufe)) }

    /// Zählt einen Sieg. Mit Tipp, im Tagesrätsel oder bei Stufen unter 0 zählt nichts. Gibt die neue Zahl zurück.
    @discardableResult
    public static func sieg(_ spiel: String, stufe: Int, mitTipp: Bool = false, tages: Bool = false, _ d: UserDefaults = .standard) -> Int {
        guard stufe >= 0, !mitTipp, !tages else { return siege(spiel, stufe: max(stufe, 0), d) }
        let n = siege(spiel, stufe: stufe, d) + 1
        d.set(n, forKey: key(spiel, stufe)); return n
    }

    public static func offen(_ spiel: String, stufe: Int, _ d: UserDefaults = .standard) -> Bool {
        stufe <= 0 || alleOffen(d) || siege(spiel, stufe: stufe - 1, d) >= siegeNoetig
    }

    /// Noch nötige Siege auf der Vorstufe, bis `stufe` aufgeht (0, wenn offen).
    public static func fehlend(_ spiel: String, stufe: Int, _ d: UserDefaults = .standard) -> Int {
        offen(spiel, stufe: stufe, d) ? 0 : max(0, siegeNoetig - siege(spiel, stufe: stufe - 1, d))
    }

    /// Die höchste offene Stufe unter `anzahl` Stufen.
    public static func hoechste(_ spiel: String, anzahl: Int, _ d: UserDefaults = .standard) -> Int {
        (0..<max(anzahl, 1)).last { offen(spiel, stufe: $0, d) } ?? 0
    }

    /// Eine gespeicherte Wahl, die inzwischen gesperrt ist (z. B. nach Zurücksetzen), fällt auf die höchste offene Stufe zurück.
    public static func begrenzt(_ spiel: String, stufe: Int, anzahl: Int, _ d: UserDefaults = .standard) -> Int {
        offen(spiel, stufe: stufe, d) ? stufe : hoechste(spiel, anzahl: anzahl, d)
    }

    public static func zuruecksetzen(_ spiel: String, anzahl: Int, _ d: UserDefaults = .standard) {
        for s in 0..<anzahl { d.removeObject(forKey: key(spiel, s)) }
    }
}
