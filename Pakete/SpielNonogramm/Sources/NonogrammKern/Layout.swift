// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Platzrechnung für das Nonogramm-Raster bei großer Schrift. Reine Zahlen, damit ein Test sie festhalten kann.
public enum NonogrammLayout {
    /// Breite des Rasters samt Hinweisspalte auf einem Gerät der Breite `geraet` (Seitenrand 16, Kartenrand 6, Innenrand 4).
    public static func rasterBreite(geraet: Double) -> Double { geraet - 2 * 16 - 2 * 6 - 2 * 4 }
    /// Grundbreite der Hinweisspalte bei normaler Schrift.
    public static func hinweisBreite(n: Int) -> Double { n >= 15 ? 60 : n >= 12 ? 52 : n >= 10 ? 36 : 44 }
    /// Breite eines Rasterfelds (Abstand 2 zwischen den Spalten) bei Hinweisspalten-Faktor `skala`.
    public static func feldBreite(n: Int, geraet: Double, skala: Double) -> Double {
        (rasterBreite(geraet: geraet) - hinweisBreite(n: n) * skala - 2 * Double(n)) / Double(n)
    }
    /// Größte Schriftskalierung für die Hinweiszahlen. Je größer das Raster, desto kleiner: Bei 12 × 12 und mehr wäre eine
    /// zweistellige Spaltenzahl sonst breiter als das Feld darunter (auf iPhone SE / mini mit 320 pt Breite).
    public static func skalaGrenze(n: Int) -> Double { n >= 15 ? 1.0 : n >= 12 ? 1.1 : n >= 10 ? 1.25 : 1.3 }
    /// Breite einer zweistelligen Ziffernfolge in der Spaltenschrift (11 pt Grundgröße, Ziffernbreite etwa 0,6 em).
    public static func zweistelligBreite(skala: Double) -> Double { 2 * 0.6 * 11 * skala }
    /// Kleinster Faktor, auf den eine lange Hinweiszeile schrumpfen darf (`minimumScaleFactor`).
    public static let kleinsterSchrumpf: Double = 0.5
    /// Zeichen (Ziffern und Leerzeichen) der längsten Zeilen- oder Spaltenhinweise eines Rasters. Höchstens `n`: Jede Zahl braucht mindestens so viele Felder wie Ziffern, jede Lücke ein Feld.
    public static func zeichen(_ hinweise: [Int]) -> Int { hinweise.map { String($0).count }.reduce(0, +) + max(0, hinweise.count - 1) }
    /// Breite der Hinweiszeile bei Schriftgröße 12 · `skala`, nachdem sie auf den kleinsten Faktor geschrumpft ist.
    public static func geschrumpfteBreite(zeichen: Int, skala: Double) -> Double { Double(zeichen) * 0.6 * 12 * skala * kleinsterSchrumpf }
}
