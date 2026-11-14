// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import CoreGraphics

/// Wie zwei Spieler am Gerät sitzen (SPEZIFIKATION 17.2).
enum Sitzordnung: String, Codable, CaseIterable, Sendable {
    /// Beide unten, eine gemeinsame Anzeige (wie bisher).
    case nebeneinander
    /// Gerät hochkant und flach: Spieler 1 unten, Spieler 2 oben. Das Brett liegt um 90° gedreht, der Boden links.
    case gegenueber
    /// Gerät quer und flach: Spieler 1 links, Spieler 2 rechts. Das Brett steht normal im Querformat.
    case seitlich
}

enum Geraet: Sendable { case iPhone, iPad }

enum Ausrichtung: Sendable {
    case portrait, portraitUpsideDown, landscapeLeft, landscapeRight

    var istHoch: Bool { self == .portrait || self == .portraitUpsideDown }
    var istQuer: Bool { !istHoch }
}

struct Ausrichtungen: OptionSet, Sendable {
    let rawValue: Int
    static let portrait = Ausrichtungen(rawValue: 1)
    static let portraitUpsideDown = Ausrichtungen(rawValue: 2)
    static let landscapeLeft = Ausrichtungen(rawValue: 4)
    static let landscapeRight = Ausrichtungen(rawValue: 8)
    static let alle: Ausrichtungen = [.portrait, .portraitUpsideDown, .landscapeLeft, .landscapeRight]
    static let quer: Ausrichtungen = [.landscapeLeft, .landscapeRight]

    init(rawValue: Int) { self.rawValue = rawValue }

    init(_ ausrichtung: Ausrichtung) {
        switch ausrichtung {
        case .portrait: self = .portrait
        case .portraitUpsideDown: self = .portraitUpsideDown
        case .landscapeLeft: self = .landscapeLeft
        case .landscapeRight: self = .landscapeRight
        }
    }
}

/// Welche Ausrichtungen die Oberfläche gerade zulässt. `sitzordnung` ist nur während einer Partie zu zweit gesetzt, sonst `nil`.
/// Während der Partie bleibt die Lage fest (ein flach liegendes Gerät dreht sonst beim kleinsten Wackeln).
/// - iPhone: sonst nur Hochformat; „Seitlich“ nur Querformat.
/// - iPad: sonst alle vier; „Gegenüber“ in der aktuellen Hochformat-Lage, „Seitlich“ in der aktuellen Querformat-Lage.
func erlaubteAusrichtungen(geraet: Geraet, sitzordnung: Sitzordnung?, aktuell: Ausrichtung) -> Ausrichtungen {
    switch (geraet, sitzordnung) {
    case (.iPhone, .seitlich?), (.iPad, .seitlich?):
        return aktuell.istQuer ? Ausrichtungen(aktuell) : .quer
    case (.iPad, .gegenueber?):
        return aktuell.istHoch ? Ausrichtungen(aktuell) : .portrait
    case (.iPhone, _):
        return .portrait
    case (.iPad, _):
        return .alle
    }
}

/// Um wie viele Grad die Anzeigen des Spielers `amZug` (1 oder 2) gedreht werden, damit er sie richtig herum liest.
/// Nebeneinander: 0°. Gegenüber: Spieler 1 sitzt unten (0°), Spieler 2 oben (180°).
/// Seitlich: Spieler 1 links (+90°), Spieler 2 rechts (−90°).
func streifenDrehung(sitzordnung: Sitzordnung, amZug: Int) -> Double {
    switch sitzordnung {
    case .nebeneinander: 0
    case .gegenueber: amZug == 2 ? 180 : 0
    case .seitlich: amZug == 2 ? -90 : 90
    }
}

/// Um wie viele Grad das Brett gedreht liegt: nur „Gegenüber“ um 90° (Boden links), sonst 0°.
func brettDrehung(sitzordnung: Sitzordnung) -> Double { sitzordnung == .gegenueber ? 90 : 0 }

/// Welche Spalte (0…6) ein Berührpunkt trifft. `rahmen` ist das quadratische Brett auf dem Bildschirm (mit `rand`
/// rundherum), schon gedreht. Bei „Gegenüber“ liegt Spalte 0 oben und Spalte 6 unten, sonst Spalte 0 links.
func spalte(punkt: CGPoint, rahmen: CGRect, sitzordnung: Sitzordnung, rand: CGFloat = 8) -> Int {
    let kante = min(rahmen.width, rahmen.height)
    let zelle = (kante - 2 * rand) / CGFloat(Partie.spalten)
    guard zelle > 0 else { return 0 }
    let lage = sitzordnung == .gegenueber ? punkt.y - rahmen.minY : punkt.x - rahmen.minX
    return min(max(Int(((lage - rand) / zelle).rounded(.down)), 0), Partie.spalten - 1)
}
