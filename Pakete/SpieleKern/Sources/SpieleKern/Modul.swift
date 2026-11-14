// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas

public enum Gattung: String, CaseIterable, Sendable {
    case raetsel, wort, karten, brett, wuerfel, arcade
    public var name: LocalizedStringKey {
        switch self {
        case .raetsel: "Rätsel"
        case .wort: "Wort"
        case .karten: "Karten"
        case .brett: "Brett"
        case .wuerfel: "Würfel"
        case .arcade: "Arcade"
        }
    }
    /// Name als Text (für Suche und KI), in der Sprache des Geräts.
    public var anzeigeName: String {
        switch self {
        case .raetsel: String(localized: "Rätsel")
        case .wort: String(localized: "Wort")
        case .karten: String(localized: "Karten")
        case .brett: String(localized: "Brett")
        case .wuerfel: String(localized: "Würfel")
        case .arcade: String(localized: "Arcade")
        }
    }

    /// Farbe der Spielart (Startseite „Spieleabend“): jede Spielart eine Familienfarbe, damit die Farbe sagt, was man spielt.
    /// 08.11.: Wort = Grün (vorher Pink, zu nah an Rot der Karten), Würfel = Violett (vorher Indigo, zu nah an Blau der Rätsel).
    /// Designwechsel (09.11.): In Tinte und Salon kommt die Farbe aus der Palette des Designs (`DesignWerte.palette`).
    public var farbe: AkzentFarbeWert {
        if let p = Design.werte.palette?[designSpielart] { return AkzentFarbeWert(p) }
        return klarFarbe
    }

    /// Die Familienfarbe der Spielart im Design „Klar & Glas“, unabhängig vom gewählten Design
    /// (fester Wert für Widget-Daten und alles, was gespeichert wird).
    public var klarFarbe: AkzentFarbeWert {
        switch self {
        case .karten: .rot
        case .wuerfel: .violett
        case .brett: .tuerkis
        case .raetsel: .blau
        case .wort: .gruen
        case .arcade: .orange
        }
    }

    /// Dieselbe Spielart in der Design-Ebene des Baukastens (Palette je Design).
    public var designSpielart: Design.Spielart {
        switch self {
        case .karten: .karten
        case .wuerfel: .wuerfel
        case .brett: .brett
        case .raetsel: .raetsel
        case .wort: .wort
        case .arcade: .arcade
        }
    }

    /// SF-Symbol der Spielart, als zweites Merkmal neben der Farbe („Farben unterscheidbar“, G2).
    public var zeichen: String {
        switch self {
        case .karten: "suit.spade.fill"
        case .wuerfel: "dice.fill"
        case .brett: "checkerboard.rectangle"
        case .raetsel: "puzzlepiece.fill"
        case .wort: "textformat.abc"
        case .arcade: "gamecontroller.fill"
        }
    }

    /// Miniatur, wenn ein Spiel keine eigene nennt.
    public var miniatur: Miniatur {
        switch self {
        case .karten: .kartenfaecher
        case .wuerfel: .wuerfel
        case .brett: .brett
        case .raetsel: .zahlengitter
        case .wort: .buchstaben
        case .arcade: .ziegel
        }
    }
}

/// Was der Kern jedem Spiel gibt (Konzept 6.2).
@MainActor
public struct SpielUmgebung {
    public let spieler: SpielerVerzeichnis
    public let statistik: StatistikDienst
    public let wuerfelQuelle: WuerfelQuelle
    /// Zurück zur Sammlung (nil, wenn das Spiel das Standard-Spiel ist und die Sammlung über den Rundknopf erreicht wird).
    public let zurueck: @MainActor () -> Void
    public init(spieler: SpielerVerzeichnis, statistik: StatistikDienst, wuerfelQuelle: WuerfelQuelle, zurueck: @escaping @MainActor () -> Void) {
        self.spieler = spieler; self.statistik = statistik; self.wuerfelQuelle = wuerfelQuelle; self.zurueck = zurueck
    }
}

/// Die eine Schnittstelle zwischen Hülle und Spiel (Konzept 6.2).
@MainActor
public protocol SpielModul {
    var id: String { get }
    var name: String { get }
    var gattung: Gattung { get }
    var farbe: AkzentFarbeWert { get }
    var symbol: String { get }
    var spielerzahl: ClosedRange<Int> { get }
    /// Der Start des Spiels (sein eigener Wurzel-Bildschirm samt Neues-Spiel, Spiel, Ende).
    func start(_ umgebung: SpielUmgebung) -> AnyView
    /// Namen der Stufen in der Schreibweise der Sprachdatei, Index = gemeldete Kennzahl „stufe“ (`SpielEnde.kennzahlen`).
    /// Die Statistik-Seite zeigt damit die Bilanz je Stufe. Standard: die Stufen der Schwierigkeitsleiter (`Leiter.spiele`), sonst keine.
    var stufenNamen: [String] { get }
}

public extension SpielModul {
    var stufenNamen: [String] { Leiter.spiele.first { $0.id == id }?.stufen ?? [] }
}

/// Familienfarbe eines Spiels mit Kontrastwerten (gleiche Hex wie `AkzentFarbe`, DESIGN.md A.1).
public struct AkzentFarbeWert: Equatable, Sendable {
    public let flaeche: UInt32, textHell: UInt32, textDunkel: UInt32
    /// Designwechsel: eigene Fläche für die dunkle Darstellung und Schrift auf der Fläche (hell/dunkel).
    /// nil = wie bisher: dieselbe Fläche in hell und dunkel, weiße Schrift darauf.
    public let flaecheDunkel: UInt32?, aufFlaecheHell: UInt32?, aufFlaecheDunkel: UInt32?
    public init(flaeche: UInt32, textHell: UInt32, textDunkel: UInt32) {
        self.flaeche = flaeche; self.textHell = textHell; self.textDunkel = textDunkel
        flaecheDunkel = nil; aufFlaecheHell = nil; aufFlaecheDunkel = nil
    }
    /// Aus der Familienfarbe des Baukastens (eine Quelle für alle Hex-Werte, KlarGlas 2.10).
    public init(_ f: Familienfarbe) { self.init(flaeche: f.flaeche, textHell: f.textHell, textDunkel: f.textDunkel) }
    /// Aus der Spielart-Palette eines Designs (Tinte, Salon; KlarGlas 2.16).
    public init(_ p: SpielartFarben) {
        flaeche = p.flaecheHell; textHell = p.textHell; textDunkel = p.textDunkel
        flaecheDunkel = p.flaecheDunkel; aufFlaecheHell = p.aufFlaecheHell; aufFlaecheDunkel = p.aufFlaecheDunkel
    }
    public var color: Color { flaecheDunkel.map { Color(hell: flaeche, dunkel: $0) } ?? Color.familie(flaeche) }
    public var weich: Color { color.opacity(0.12) }
    /// Schrift auf der Fläche (bisher immer Weiß; in Tinte und Salon je Farbe und Darstellung festgelegt).
    public var aufFlaeche: Color { Color(hell: aufFlaecheHell ?? 0xFFFFFF, dunkel: aufFlaecheDunkel ?? 0xFFFFFF) }
    /// Fläche in der dunklen Darstellung (ohne eigenen Wert dieselbe wie hell).
    public var flaecheImDunkeln: UInt32 { flaecheDunkel ?? flaeche }

    public static let graphit = AkzentFarbeWert(.graphit)
    /// Hülle der Sammlung Partie (wie das Logo „Vier Kacheln“, Nachtrag 05.11.): Titel, Hauptknopf, Tischgrund.
    public static let nachtblau = AkzentFarbeWert(.nachtblau)
    public static let indigo = AkzentFarbeWert(.indigo)
    public static let braun = AkzentFarbeWert(.braun)
    public static let tuerkis = AkzentFarbeWert(.tuerkis)
    public static let schiefer = AkzentFarbeWert(.schiefer)
    public static let limette = AkzentFarbeWert(.limette)
    public static let blau = AkzentFarbeWert(.blau)
    public static let gruen = AkzentFarbeWert(.gruen)
    public static let rot = AkzentFarbeWert(.rot)
    public static let violett = AkzentFarbeWert(.violett)
    public static let pink = AkzentFarbeWert(.pink)
    public static let orange = AkzentFarbeWert(.orange)
}

public extension Color {
    init(hexWert h: UInt32) {
        self.init(.sRGB, red: Double((h >> 16) & 0xFF) / 255, green: Double((h >> 8) & 0xFF) / 255, blue: Double(h & 0xFF) / 255, opacity: 1)
    }
}

#if canImport(UIKit)
import UIKit
public extension AkzentFarbeWert {
    /// Kleiner Text in der Spielfarbe: hell/dunkel nach Darstellung (kontrastgeprüft, DESIGN.md A.1).
    /// Akzent für Schaltflächen und Text in einem Spiel: hell die dunklere Textstufe (weiße Schrift auf gefüllten Knöpfen ≥ 4,5:1,
    /// Text auf Weiß ≥ 4,5:1), dunkel die Flächenfarbe. Die reine Fläche (z. B. Orange) erreicht mit weißer Schrift nur 3,05:1.
    var kontrastTint: Color {
        // Palette (Tinte, Salon): im Dunkeln die Fläche, wenn sie als Text auf dem dunklen Seitengrund reicht, sonst die Textstufe.
        let dunkel: UInt32
        if let fd = flaecheDunkel, let grund = Design.werte.seitenGrund?.dunkel {
            dunkel = Kontrast.verhaeltnis(fd, grund) >= 4.5 ? fd : textDunkel
        } else {
            dunkel = flaeche
        }
        return Color(UIColor { t in
            let h = t.userInterfaceStyle == .dark ? dunkel : textHell
            return UIColor(red: CGFloat((h >> 16) & 0xFF) / 255, green: CGFloat((h >> 8) & 0xFF) / 255, blue: CGFloat(h & 0xFF) / 255, alpha: 1)  // design:spielinhalt
        })
    }

    var textFarbe: Color {
        Color(UIColor { t in
            let h = t.userInterfaceStyle == .dark ? textDunkel : textHell
            return UIColor(red: CGFloat((h >> 16) & 0xFF) / 255, green: CGFloat((h >> 8) & 0xFF) / 255, blue: CGFloat(h & 0xFF) / 255, alpha: 1)  // design:spielinhalt
        })
    }
}
#endif

#if canImport(UIKit)
public extension Array where Element == SpielTeilnehmer {
    /// „Gerät übergeben“-Bildschirme nur nötig, wenn mehr als ein Mensch am selben Gerät spielt.
    var mehrereMenschen: Bool { filter { !$0.computer }.count > 1 }
}
#endif
