// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Schwierigkeit: bestimmt Feldgröße und wie viele Kacheln von Anfang an fest sitzen.
enum Stufe: String, CaseIterable, Codable, Identifiable, Sendable {
    case leicht, mittel, schwer

    var id: String { rawValue }

    var spalten: Int {
        switch self { case .leicht: 5; case .mittel: 6; case .schwer: 7 }
    }
    var zeilen: Int {
        switch self { case .leicht: 7; case .mittel: 9; case .schwer: 11 }
    }
    var anzahl: Int { spalten * zeilen }
}

/// Ein Rätsel: Ein Farbverlauf zwischen vier Eckfarben ist in Kacheln zerlegt und gemischt.
/// `ziel[i]` ist die Farbe, die an Platz `i` gehört. `fest` sind Plätze, die schon stimmen und nicht bewegt werden.
struct Raetsel: Equatable, Codable, Sendable {
    let stufe: Stufe
    let seed: UInt64
    let ziel: [Farbton]
    let fest: Set<Int>
    /// `start[platz]` = Nummer der Kachel (= ihr Zielplatz), die dort anfangs liegt.
    let start: [Int]

    var spalten: Int { stufe.spalten }
    var zeilen: Int { stufe.zeilen }

    /// Erzeugt das Rätsel deterministisch aus Stufe und Seed.
    static func erzeugen(stufe: Stufe, seed: UInt64) -> Raetsel {
        var zufall = Zufall(seed: seed)
        let b = stufe.spalten, h = stufe.zeilen
        var ziel: [Farbton] = []
        // Eckfarben neu würfeln, bis Nachbarkacheln gut unterscheidbar sind (sonst wäre das Rätsel unlösbar zu erkennen).
        for _ in 0..<200 {
            let ecken = eckfarben(&zufall)
            ziel = verlauf(ecken, spalten: b, zeilen: h)
            if kleinsterNachbarabstand(ziel, spalten: b) >= mindestAbstand { break }
        }
        let fest = festePlaetze(stufe)
        var lose = (0..<stufe.anzahl).filter { !fest.contains($0) }
        var mischung = lose
        // Mischen, bis keine lose Kachel mehr an ihrem Platz liegt (damit das Rätsel nie „geschenkt“ ist).
        for _ in 0..<200 {
            mischung.shuffle(using: &zufall)
            if !zip(lose, mischung).contains(where: { $0 == $1 }) { break }
        }
        var start = Array(0..<stufe.anzahl)
        for (platz, kachel) in zip(lose, mischung) { start[platz] = kachel }
        lose.removeAll()
        return Raetsel(stufe: stufe, seed: seed, ziel: ziel, fest: fest, start: start)
    }

    static let mindestAbstand = 0.05

    static func verlauf(_ ecken: [Farbton], spalten b: Int, zeilen h: Int) -> [Farbton] {
        var ziel: [Farbton] = []
        for z in 0..<h {
            let y = Double(z) / Double(h - 1)
            let links = Farbton.mischung(ecken[0], ecken[2], y)
            let rechts = Farbton.mischung(ecken[1], ecken[3], y)
            for s in 0..<b {
                ziel.append(Farbton.mischung(links, rechts, Double(s) / Double(b - 1)))
            }
        }
        return ziel
    }

    static func kleinsterNachbarabstand(_ ziel: [Farbton], spalten b: Int) -> Double {
        var kleinster = Double.infinity
        for i in ziel.indices {
            if i % b < b - 1 { kleinster = min(kleinster, ziel[i].abstand(zu: ziel[i + 1])) }
            if i + b < ziel.count { kleinster = min(kleinster, ziel[i].abstand(zu: ziel[i + b])) }
        }
        return kleinster
    }

    /// Leicht: der ganze Rand sitzt fest. Mittel: die vier Ecken und die Randmitten. Schwer: nur die vier Ecken.
    static func festePlaetze(_ stufe: Stufe) -> Set<Int> {
        let b = stufe.spalten, h = stufe.zeilen
        var menge: Set<Int> = [0, b - 1, (h - 1) * b, h * b - 1]
        switch stufe {
        case .leicht:
            for s in 0..<b { menge.insert(s); menge.insert((h - 1) * b + s) }
            for z in 0..<h { menge.insert(z * b); menge.insert(z * b + b - 1) }
        case .mittel:
            menge.formUnion([b / 2, (h - 1) * b + b / 2, (h / 2) * b, (h / 2) * b + b - 1])
        case .schwer:
            break
        }
        return menge
    }

    /// Vier Eckfarben: gut verteilt auf dem Farbkreis, unterschiedlich hell, damit der Verlauf lesbar bleibt.
    private static func eckfarben(_ zufall: inout Zufall) -> [Farbton] {
        let start = zufall.kommazahl(0...1)
        let schritt = zufall.kommazahl(0.18...0.32)
        var farben: [Farbton] = []
        for i in 0..<4 {
            let winkel = start + Double(i) * schritt * (i.isMultiple(of: 2) ? 1 : 1.35)
            let sat = zufall.kommazahl(0.55...0.9)
            let hell = i == 3 ? zufall.kommazahl(0.45...0.65) : zufall.kommazahl(0.78...0.97)
            farben.append(Farbton(farbwinkel: winkel, saettigung: sat, helligkeit: hell))
        }
        return farben
    }
}
