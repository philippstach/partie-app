// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI

// Designwechsel (KlarGlas 2.17): alle Werte eines Designs an einer Stelle. Drei feste Instanzen: `klar` (das bisherige
// Aussehen, liefert exakt die heutigen Zahlen), `tinte`, `salon`. Hex-Werte der neuen Designs stehen NUR hier
// (und für das Widget ein zweites Mal in `Widget/Geteilt/WidgetDesign.swift`, per Test verglichen).

/// Ein Farbwert für die helle und die dunkle Darstellung.
public struct FarbPaar: Equatable, Sendable {
    public let hell: UInt32
    public let dunkel: UInt32
    public init(_ hell: UInt32, _ dunkel: UInt32) { self.hell = hell; self.dunkel = dunkel }
    /// Derselbe Wert in hell und dunkel.
    public init(_ beide: UInt32) { self.hell = beide; self.dunkel = beide }
    public var color: Color { Color(hell: hell, dunkel: dunkel) }
}

/// Farben einer Spielart in einem Design: Fläche, Schrift auf der Fläche und Textfarbe, je hell und dunkel.
public struct SpielartFarben: Equatable, Sendable {
    public let flaecheHell: UInt32, aufFlaecheHell: UInt32, textHell: UInt32
    public let flaecheDunkel: UInt32, aufFlaecheDunkel: UInt32, textDunkel: UInt32

    public init(_ flaecheHell: UInt32, _ aufFlaecheHell: UInt32, _ textHell: UInt32,
                _ flaecheDunkel: UInt32, _ aufFlaecheDunkel: UInt32, _ textDunkel: UInt32) {
        self.flaecheHell = flaecheHell; self.aufFlaecheHell = aufFlaecheHell; self.textHell = textHell
        self.flaecheDunkel = flaecheDunkel; self.aufFlaecheDunkel = aufFlaecheDunkel; self.textDunkel = textDunkel
    }

    /// Farbfläche (Farbblock, Knopf, Punkt, Streifen).
    public var flaeche: Color { Color(hell: flaecheHell, dunkel: flaecheDunkel) }
    /// Schrift auf der Fläche, ab 17 pt halbfett (Paar ≥ 3:1).
    public var aufFlaeche: Color { Color(hell: aufFlaecheHell, dunkel: aufFlaecheDunkel) }
    /// Kleiner Text in der Spielart-Farbe auf Seiten- und Kartengrund (≥ 4,5:1).
    public var text: Color { Color(hell: textHell, dunkel: textDunkel) }
    /// Fläche, auf der auch kleine Schrift (Labels 11 pt) lesbar ist: wo das Paar unter 4,5:1 liegt, so wenig wie nötig
    /// abgedunkelt bzw. aufgehellt (Regel „kleine Schrift auf Fläche“ des Auftrags).
    public var flaecheFuerKleineSchrift: Color {
        Color(hell: Kontrast.angepasst(flaeche: flaecheHell, schrift: aufFlaecheHell),
              dunkel: Kontrast.angepasst(flaeche: flaecheDunkel, schrift: aufFlaecheDunkel))
    }
}

public extension Design {
    /// Farben der Spieler-Seite (Salon: Senf mit Espresso-Schrift); nil in klar und Tinte.
    static var spielerSeite: (flaeche: Color, schrift: Color)? {
        werte.spielerSeite.map { (Color(hex: $0.flaeche), Color(hex: $0.schrift)) }
    }

    /// Die sechs Spielarten der Sammlung (wie `Gattung` in SpieleKern, hier ohne Abhängigkeit dorthin).
    enum Spielart: String, CaseIterable, Sendable { case karten, wuerfel, brett, raetsel, wort, arcade }

    /// Farben der laufenden Spielart im gewählten Design; nil in `klar` oder außerhalb eines Spiels.
    static var spielFarben: SpielartFarben? {
        guard let s = KlarGlasHaken.spielart?() else { return nil }
        return werte.palette?[s]
    }
}

/// Farben der Spielkarten eines Designs (Tinte, Salon). Das Papier bleibt auch im Dunkeln hell, deshalb sind Rot und
/// Schwarz in beiden Darstellungen dieselben Werte.
public struct KartenWerte: Equatable, Sendable {
    public let papier: FarbPaar
    public let rot: FarbPaar
    public let schwarz: FarbPaar
    public init(papier: FarbPaar, rot: FarbPaar, schwarz: FarbPaar) { self.papier = papier; self.rot = rot; self.schwarz = schwarz }
}

/// Farben der Würfel eines Designs (Tinte, Salon): Fläche und Augen, frei und gehalten; Rand nur in Tinte.
public struct WuerfelWerte: Equatable, Sendable {
    public let flaeche: FarbPaar
    public let auge: FarbPaar
    public let gehalten: FarbPaar
    public let augeGehalten: FarbPaar
    public let rand: FarbPaar?
    public init(flaeche: FarbPaar, auge: FarbPaar, gehalten: FarbPaar, augeGehalten: FarbPaar, rand: FarbPaar?) {
        self.flaeche = flaeche; self.auge = auge; self.gehalten = gehalten; self.augeGehalten = augeGehalten; self.rand = rand
    }
}

/// Alle Werte eines Designs. Farben mit `nil` bedeuten „Systemfarbe wie bisher“ (nur in `klar`).
public struct DesignWerte: Sendable {
    public let art: DesignArt

    // MARK: Farbrollen
    public let seitenGrund: FarbPaar?
    public let kartenGrund: FarbPaar?
    public let feldGrund: FarbPaar?
    public let linie: FarbPaar?
    public let linieStark: FarbPaar?
    public let schrift: FarbPaar?
    public let schriftZweit: FarbPaar?
    public let schriftBlass: FarbPaar?
    /// Fläche des Hauptknopfs; nil = App-Farbe.
    public let knopf: FarbPaar?
    /// Schrift auf dem Hauptknopf; nil = Weiß.
    public let schriftAufKnopf: FarbPaar?
    /// Flächenfarbe der Hülle (Tischgrund, Farbblock, Hauptknopf der Hülle).
    public let huelleFlaeche: FarbPaar
    /// Schrift auf der Hüllenfläche.
    public let aufHuelleFlaeche: FarbPaar
    /// Akzent der Hülle für Text, Symbole und Tint.
    public let huelleAkzent: FarbPaar
    /// Farben je Spielart; nil = Familienfarben wie bisher.
    public let palette: [Design.Spielart: SpielartFarben]?
    /// Seitenfarben besonderer Seiten (Salon): Sieger, Niederlage, Remis, Spieler. Fläche und Schrift darauf.
    public let siegerSeite: (flaeche: UInt32, schrift: UInt32)?
    public let niederlageSeite: (flaeche: UInt32, schrift: UInt32)?
    public let remisSeite: (flaeche: UInt32, schrift: UInt32)?
    public let spielerSeite: (flaeche: UInt32, schrift: UInt32)?
    /// Spielkarten und Würfel; nil = wie bisher (klar).
    public let karten: KartenWerte?
    public let wuerfel: WuerfelWerte?

    // MARK: Form
    public let eckeKlein: CGFloat
    public let eckeFeld: CGFloat
    public let eckeKarte: CGFloat
    public let eckeLeiste: CGFloat
    public let eckeSheet: CGFloat
    public let seitenRand: CGFloat
    /// Randstärke des Zweitknopfs (ohne Füllung); 0 = Glas.
    public let knopfRand: CGFloat
    /// Stärke der Linie unter Zeilen und Abschnitten.
    public let linienStaerke: CGFloat

    // MARK: Schrift
    public let serif: Bool
    public let titelGroesse: CGFloat
    public let titelGewicht: Font.Weight
    /// Laufweite des Titels in em (mal Schriftgröße).
    public let titelLaufweite: CGFloat
    public let schlagzeileGroesse: CGFloat
    public let schlagzeileGewicht: Font.Weight
    public let nameGroesse: CGFloat
    public let nameGewicht: Font.Weight
    public let nebenGroesse: CGFloat
    /// Sperrung des Abschnitts-Labels in em.
    public let labelSperrung: CGFloat
    public let zahlDesign: Font.Design

    public static func fuer(_ art: DesignArt) -> DesignWerte {
        switch art {
        case .klar: klar
        case .tinte: tinte
        case .salon: salon
        }
    }

    /// „Klar & Glas“: das bisherige Aussehen. Farbrollen sind die Systemfarben (nil), Zahlen wie in DESIGN.md A.4.
    public static let klar = DesignWerte(
        art: .klar,
        seitenGrund: nil, kartenGrund: nil, feldGrund: nil, linie: nil, linieStark: nil,
        schrift: nil, schriftZweit: nil, schriftBlass: nil, knopf: nil, schriftAufKnopf: nil,
        huelleFlaeche: FarbPaar(Familienfarbe.nachtblau.flaeche), aufHuelleFlaeche: FarbPaar(0xFFFFFF),
        huelleAkzent: FarbPaar(Design.Farbe.akzentHell, Design.Farbe.akzentDunkel),
        palette: nil, siegerSeite: nil, niederlageSeite: nil, remisSeite: nil, spielerSeite: nil, karten: nil, wuerfel: nil,
        eckeKlein: 8, eckeFeld: 12, eckeKarte: 20, eckeLeiste: 28, eckeSheet: 32, seitenRand: 16, knopfRand: 0, linienStaerke: 1,
        serif: false, titelGroesse: 56, titelGewicht: .bold, titelLaufweite: -0.03,
        schlagzeileGroesse: 34, schlagzeileGewicht: .bold, nameGroesse: 20, nameGewicht: .bold, nebenGroesse: 20,
        labelSperrung: 0, zahlDesign: .rounded)

    /// „Tinte“: Papier, Haarlinien, Serifen. Entwurf R2.
    public static let tinte = DesignWerte(
        art: .tinte,
        seitenGrund: FarbPaar(0xFBFBF8, 0x16171A), kartenGrund: FarbPaar(0xFFFFFF, 0x1F2125), feldGrund: FarbPaar(0xEEEEE8, 0x2A2C31),
        linie: FarbPaar(0xE3E3DE, 0x34363C), linieStark: FarbPaar(0x1B1B1F, 0xEDEDE8),
        schrift: FarbPaar(0x1B1B1F, 0xEDEDE8), schriftZweit: FarbPaar(0x63656D, 0xA3A5AD), schriftBlass: FarbPaar(0xB0B2BA, 0x5C5E66),
        knopf: FarbPaar(0x1B1B1F, 0xEDEDE8), schriftAufKnopf: FarbPaar(0xFBFBF8, 0x16171A),
        huelleFlaeche: FarbPaar(0x1B1B1F, 0xEDEDE8), aufHuelleFlaeche: FarbPaar(0xFBFBF8, 0x16171A),
        huelleAkzent: FarbPaar(0x1B1B1F, 0xEDEDE8),
        palette: [
            .karten: SpielartFarben(0xB3261E, 0xFFFFFF, 0xB3261E, 0xE0685E, 0x16171A, 0xF28B82),
            .wuerfel: SpielartFarben(0x3B3A9E, 0xFFFFFF, 0x3B3A9E, 0x8E8DF0, 0x16171A, 0xA9A8F5),
            .brett: SpielartFarben(0x0B6E62, 0xFFFFFF, 0x0B6E62, 0x3FB3A1, 0x16171A, 0x5FC7B6),
            .raetsel: SpielartFarben(0x1F5FC2, 0xFFFFFF, 0x1F5FC2, 0x6FA0F0, 0x16171A, 0x8AB4F8),
            .wort: SpielartFarben(0x9A2C6C, 0xFFFFFF, 0x9A2C6C, 0xD878B4, 0x16171A, 0xE591C6),
            .arcade: SpielartFarben(0xB24D14, 0xFFFFFF, 0xB24D14, 0xE89055, 0x16171A, 0xF2A36B),
        ],
        siegerSeite: nil, niederlageSeite: nil, remisSeite: nil, spielerSeite: nil,
        karten: KartenWerte(papier: FarbPaar(0xFFFFFF, 0xF4F4EF), rot: FarbPaar(0xB3261E), schwarz: FarbPaar(0x1B1B1F)),
        // Würfel: weiß mit Tinte-Rand, gehalten Tinte mit Papier-Augen; im Dunkeln dieselbe Zeichnung mit heller Tinte
        wuerfel: WuerfelWerte(flaeche: FarbPaar(0xFFFFFF, 0x1F2125), auge: FarbPaar(0x1B1B1F, 0xEDEDE8),
                              gehalten: FarbPaar(0x1B1B1F, 0xEDEDE8), augeGehalten: FarbPaar(0xFBFBF8, 0x16171A), rand: FarbPaar(0x1B1B1F, 0xEDEDE8)),
        eckeKlein: 4, eckeFeld: 4, eckeKarte: 0, eckeLeiste: 0, eckeSheet: 16, seitenRand: 20, knopfRand: 1.5, linienStaerke: 1,
        serif: true, titelGroesse: 46, titelGewicht: .medium, titelLaufweite: -0.02,
        schlagzeileGroesse: 54, schlagzeileGewicht: .medium, nameGroesse: 21, nameGewicht: .medium, nebenGroesse: 18,
        labelSperrung: 0.12, zahlDesign: .serif)

    /// „Salon“ (Salon D, Editorial): Creme-Papier, große Farbflächen. Entwürfe S4 (hell) und DD (dunkel).
    public static let salon = DesignWerte(
        art: .salon,
        seitenGrund: FarbPaar(0xF3EBDD, 0x1E1A17), kartenGrund: FarbPaar(0xFAF5EA, 0x2A2420), feldGrund: FarbPaar(0xEADFCB, 0x332C27),
        linie: FarbPaar(0xD9CDB8, 0x3A332D), linieStark: FarbPaar(0x1E1A17, 0xF3EBDD),
        schrift: FarbPaar(0x1E1A17, 0xF3EBDD), schriftZweit: FarbPaar(0x645A4D, 0xA89C8C), schriftBlass: FarbPaar(0xB8AA92, 0x6E6355),
        knopf: FarbPaar(0x1E1A17, 0xF3EBDD), schriftAufKnopf: FarbPaar(0xF3EBDD, 0x1E1A17),
        huelleFlaeche: FarbPaar(0xC8553D), aufHuelleFlaeche: FarbPaar(0xF3EBDD),
        huelleAkzent: FarbPaar(0x9E3E2A, 0xE88D78),
        palette: [
            .karten: SpielartFarben(0xC8553D, 0xF3EBDD, 0x9E3E2A, 0xD4654D, 0x1E1A17, 0xE88D78),
            .wuerfel: SpielartFarben(0x2C3E5C, 0xF3EBDD, 0x2C3E5C, 0x4A6690, 0xF3EBDD, 0x8FA6D9),
            .brett: SpielartFarben(0x6B7B3A, 0xF3EBDD, 0x525F2A, 0x7E8F47, 0x1E1A17, 0xA9B86E),
            .raetsel: SpielartFarben(0x2F6F73, 0xF3EBDD, 0x2A6468, 0x3F8A8F, 0x1E1A17, 0x6FB3B8),
            .wort: SpielartFarben(0xD9A441, 0x1E1A17, 0x7D570F, 0xD9A441, 0x1E1A17, 0xE3B75E),
            .arcade: SpielartFarben(0x7A2E3D, 0xF3EBDD, 0x7A2E3D, 0x96404F, 0xF3EBDD, 0xD98A98),
        ],
        siegerSeite: (0x7A2E3D, 0xF3EBDD), niederlageSeite: (0x1E1A17, 0xF3EBDD), remisSeite: (0x2C3E5C, 0xF3EBDD),
        spielerSeite: (0xD9A441, 0x1E1A17),
        karten: KartenWerte(papier: FarbPaar(0xFAF5EA, 0xEFE6D4), rot: FarbPaar(0xC8553D), schwarz: FarbPaar(0x1E1A17)),
        // Würfel: Creme ohne Rand mit Espresso-Augen, gehalten Espresso mit Creme-Augen; dunkel umgekehrt (Entwurf DD)
        wuerfel: WuerfelWerte(flaeche: FarbPaar(0xF3EBDD, 0x1E1A17), auge: FarbPaar(0x1E1A17, 0xF3EBDD),
                              gehalten: FarbPaar(0x1E1A17, 0xF3EBDD), augeGehalten: FarbPaar(0xF3EBDD, 0x1E1A17), rand: nil),
        eckeKlein: 2, eckeFeld: 2, eckeKarte: 0, eckeLeiste: 0, eckeSheet: 0, seitenRand: 22, knopfRand: 2, linienStaerke: 1,
        serif: true, titelGroesse: 72, titelGewicht: .bold, titelLaufweite: -0.03,
        schlagzeileGroesse: 84, schlagzeileGewicht: .bold, nameGroesse: 24, nameGewicht: .semibold, nebenGroesse: 20,
        labelSperrung: 0.14, zahlDesign: .serif)
}

/// Kontrast nach WCAG 2 (relative Leuchtdichte), für Tests und für Flächen mit kleiner Schrift.
public enum Kontrast {
    public static func leuchtdichte(_ hex: UInt32) -> Double {
        func kanal(_ shift: UInt32) -> Double {
            let v = Double((hex >> shift) & 0xFF) / 255
            return v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * kanal(16) + 0.7152 * kanal(8) + 0.0722 * kanal(0)
    }

    /// Kontrastverhältnis zweier Farben (1 … 21).
    public static func verhaeltnis(_ a: UInt32, _ b: UInt32) -> Double {
        let la = leuchtdichte(a), lb = leuchtdichte(b)
        return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)
    }

    /// Die Fläche so wenig wie nötig von der Schrift weg verschoben (abgedunkelt bei heller Schrift, aufgehellt bei dunkler),
    /// bis das Paar `ziel` erreicht. Reicht die Fläche schon, kommt sie unverändert zurück.
    public static func angepasst(flaeche: UInt32, schrift: UInt32, ziel: Double = 4.5) -> UInt32 {
        guard verhaeltnis(flaeche, schrift) < ziel else { return flaeche }
        let abdunkeln = leuchtdichte(schrift) > leuchtdichte(flaeche)
        var bester = flaeche
        for schritt in 1...100 {
            let anteil = Double(schritt) / 100
            func kanal(_ shift: UInt32) -> UInt32 {
                let v = Double((flaeche >> shift) & 0xFF)
                let neu = abdunkeln ? v * (1 - anteil) : v + (255 - v) * anteil
                return UInt32(max(0, min(255, neu.rounded())))
            }
            bester = (kanal(16) << 16) | (kanal(8) << 8) | kanal(0)
            if verhaeltnis(bester, schrift) >= ziel { break }
        }
        return bester
    }
}
