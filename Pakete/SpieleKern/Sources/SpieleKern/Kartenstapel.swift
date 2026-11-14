// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Gemischter Kartenstapel mit Ziehen, Ablegen und Neumischen der Ablage (Mau-Mau, Farbwechsel, Stufenstapel, Rommé …).
public struct Kartenstapel<Karte: Sendable>: Sendable {
    public private(set) var vorrat: [Karte]
    public private(set) var ablage: [Karte] = []

    public init(_ karten: [Karte]) { vorrat = karten }
    public init<G: RandomNumberGenerator>(_ karten: [Karte], gemischt g: inout G) { vorrat = karten.shuffled(using: &g) }

    public var anzahl: Int { vorrat.count }
    public var istLeer: Bool { vorrat.isEmpty && ablage.count <= 1 }
    public var oben: Karte? { ablage.last }

    public mutating func mischen<G: RandomNumberGenerator>(mit g: inout G) { vorrat.shuffle(using: &g) }

    /// Oberste Karte ziehen. Ist der Vorrat leer, wird die Ablage (außer der obersten Karte) neu gemischt.
    public mutating func ziehen<G: RandomNumberGenerator>(mit g: inout G) -> Karte? {
        if vorrat.isEmpty, ablage.count > 1 {
            let top = ablage.removeLast()
            vorrat = ablage.shuffled(using: &g); ablage = [top]
        }
        return vorrat.popLast()
    }
    public mutating func ziehen() -> Karte? { var g = SystemRandomNumberGenerator(); return ziehen(mit: &g) }

    public mutating func ablegen(_ k: Karte) { ablage.append(k) }
}

/// Standard-Skatblatt mit 52 Karten (Kreuz, Pik, Herz, Karo; 2 … Ass).
public struct SkatKarte: Hashable, Sendable, Codable {
    public enum Farbe: Int, CaseIterable, Sendable, Codable { case kreuz, pik, herz, karo
        public var symbol: String { ["♣", "♠", "♥", "♦"][rawValue] }
        public var rot: Bool { self == .herz || self == .karo }
    }
    public let farbe: Farbe
    public let wert: Int          // 2…10, 11 = Bube, 12 = Dame, 13 = König, 14 = Ass
    public init(_ farbe: Farbe, _ wert: Int) { self.farbe = farbe; self.wert = wert }

    /// Rang als Text: 2 … 10, B, D, K, A.
    public var rang: String { wert > 10 ? ["B", "D", "K", "A"][wert - 11] : String(wert) }
    /// Für VoiceOver: „Herz Dame“.
    public var sprechname: String {
        Kartensprache.name(rang: rang, symbol: farbe.symbol)
    }
    public var kurz: String { (wert > 10 ? ["B", "D", "K", "A"][wert - 11] : String(wert)) + farbe.symbol }
    public static var blatt: [SkatKarte] { Farbe.allCases.flatMap { f in (2...14).map { SkatKarte(f, $0) } } }
}

/// Speichern und Fortsetzen: ein Stapel ist codierbar, sobald seine Karten es sind.
extension Kartenstapel: Codable where Karte: Codable {}
