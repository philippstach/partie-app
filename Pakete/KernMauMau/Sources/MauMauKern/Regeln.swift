// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Karte des Skatblatts. Farbe 0 Kreuz, 1 Pik, 2 Herz, 3 Karo; Wert 7…10, 11 Bube, 12 Dame, 13 König, 14 Ass.
public struct NKarte: Hashable, Sendable, Codable {
    public let farbe: Int
    public let wert: Int
    public init(_ f: Int, _ w: Int) { farbe = f; wert = w }
    public static let blatt: [NKarte] = (0..<4).flatMap { f in (7...14).map { NKarte(f, $0) } }
    public static let farbSymbole = ["♣", "♠", "♥", "♦"]
    public static let farbNamen = ["Kreuz", "Pik", "Herz", "Karo"]
    public var symbol: String { Self.farbSymbole[farbe] }
    public var name: String { ["7", "8", "9", "10", "B", "D", "K", "A"][wert - 7] }
    /// Augen für die Wertung am Rundenende: Bube 20, Ass 11, Dame und König 10, Zahlen ihre Augen.
    public var augen: Int {
        switch wert { case 11: 20; case 14: 11; case 12, 13: 10; default: wert }
    }
}

/// Was die „Aussetzen“-Karte ist.
public enum Aussetzen: Int, Sendable, Codable, CaseIterable {
    case keine = 0, acht = 8, ass = 14
}

/// Frei kombinierbare Hausregeln. Jedes Feld ist ein eigener Schalter; die `vorlage…`-Werte sind nur Schnellwahlen.
public struct NRegeln: Equatable, Sendable, Codable {
    /// Karten auf die Hand: 5, 6 oder 7.
    public var startkarten = 5
    /// 7 lässt den Nächsten zwei Karten ziehen (stapelbar).
    public var siebenZiehen = true
    public var aussetzen = Aussetzen.acht
    /// Der Bube darf als letzte Karte gelegt werden.
    public var bubeAlsSchluss = true
    /// Ein Bube darf auf einen Buben (und auf einen gewünschten Farbwechsel durch einen Buben) gelegt werden.
    public var bubeAufBube = true
    /// Die 9 wechselt die Spielrichtung (wirkt ab drei Spielern).
    public var neunRichtung = false
    /// Wer die vorletzte Karte legt, muss „Mau“ sagen; sonst gibt es eine Strafkarte.
    public var maueSagen = false
    /// Eine gezogene Karte darf gleich gelegt werden, wenn sie passt.
    public var sofortLegen = false
    /// Mehrere Runden bis zu einer Zielsumme; wer sie zuerst erreicht, verliert.
    public var mehrrunden = false
    public var zielPunkte = 100

    public init() {}
    public init(startkarten: Int = 5, siebenZiehen: Bool = true, aussetzen: Aussetzen = .acht, bubeAlsSchluss: Bool = true, bubeAufBube: Bool = true,
                neunRichtung: Bool = false, maueSagen: Bool = false, sofortLegen: Bool = false, mehrrunden: Bool = false, zielPunkte: Int = 100) {
        self.startkarten = min(7, max(5, startkarten)); self.siebenZiehen = siebenZiehen; self.aussetzen = aussetzen; self.bubeAlsSchluss = bubeAlsSchluss
        self.bubeAufBube = bubeAufBube; self.neunRichtung = neunRichtung; self.maueSagen = maueSagen; self.sofortLegen = sofortLegen
        self.mehrrunden = mehrrunden; self.zielPunkte = zielPunkte
    }

    public static let standard = NRegeln()
    public static let ass = NRegeln(aussetzen: .ass)
    public static let sieben = NRegeln(startkarten: 7)
    public static let schlicht = NRegeln(siebenZiehen: false, aussetzen: .keine)
    public static let streng = NRegeln(bubeAlsSchluss: false, bubeAufBube: false)
    /// „Wild“: 9 wechselt die Richtung, gezogene Karten dürfen gleich gelegt werden, „Mau“ ist Pflicht.
    public static let wild = NRegeln(neunRichtung: true, maueSagen: true, sofortLegen: true)

    /// Wert der Aussetzen-Karte oder 0.
    public var aussetzenWert: Int { aussetzen.rawValue }

    /// Zwei Blätter (64 Karten) gibt es ab fünf Spielern.
    public static func blaetter(spieler: Int) -> Int { spieler >= 5 ? 2 : 1 }
}
