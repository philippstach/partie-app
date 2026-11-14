// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

enum Strategie: String, Codable, CaseIterable {
    case mensch, einfach, gut
}

/// Wogegen der Computer spielt: `ref` = schlechtestes Ergebnis der Runde bisher (nil = Vorleger).
struct Ziel: Hashable {
    var ref: Ergebnis?
    var position: Int
}

/// Alles, was der Computer vor einer Entscheidung weiß.
struct Lage {
    var draussen: [Int]
    var wurf: [Int]
    var wuerfe: Int
    var maxWuerfe: Int
    var ziel: Ziel
    var optionen: Optionen
}

/// Entscheidung „stehen“ oder „weiter“ für die Computer-Spieler (SPEZIFIKATION Abschnitt 6).
/// Rein rechnend, ohne Zustand außer Zwischenspeichern. Darf auf einem Hintergrund-Task laufen.
struct Computer {
    private static let ausgaenge: [[([Int], Double)]] = (0...3).map { n in
        guard n > 0 else { return [] }
        var zaehler: [[Int]: Int] = [:]
        var wuerfe = [[Int]()]
        for _ in 0..<n { wuerfe = wuerfe.flatMap { w in (1...6).map { w + [$0] } } }
        for w in wuerfe { zaehler[w.sorted(), default: 0] += 1 }
        let gesamt = Double(wuerfe.count)
        return zaehler.sorted { $0.key.lexicographicallyPrecedes($1.key) }.map { ($0.key, Double($0.value) / gesamt) }
    }

    private static let eps = 1e-9

    static func entscheide(_ strategie: Strategie, _ lage: Lage) -> Aktion {
        switch strategie {
        case .gut: Computer.entscheideGut(lage)
        case .einfach, .mensch: Computer.entscheideEinfach(lage)
        }
    }

    // MARK: Einfach

    static func entscheideEinfach(_ l: Lage) -> Aktion {
        let draussen = l.draussen.sorted()
        let wurf = l.wurf.sorted()
        if l.wuerfe >= l.maxWuerfe { return .stehen }
        let w = werte(draussen + wurf, ausEinemWurf: draussen.isEmpty, optionen: l.optionen)
        if let ref = l.ziel.ref {
            if istBesser(Ergebnis(wertung: w, wuerfe: l.wuerfe, position: l.ziel.position), ref) { return .stehen }
        } else if w.art != .zahl || w.hoehe >= 650 {
            return .stehen
        }
        var einsen = wurf.filter { $0 == 1 }
        let u = l.optionen.sechsenUmdrehen ? maxUmdrehen(wurf) : 0
        while !einsen.isEmpty && 3 - draussen.count - einsen.count - u < 1 { einsen.removeLast() }
        if weiterErlaubt(draussen: draussen, wurf: wurf, wuerfe: l.wuerfe, maxWuerfe: l.maxWuerfe,
                         herauslegen: einsen, umdrehen: u, optionen: l.optionen) {
            return .weiter(herauslegen: einsen, umdrehen: u)
        }
        return .weiter(herauslegen: einsen, umdrehen: 0)
    }

    // MARK: Gut

    /// Perzentil: Anteil der 216 Würfe aus einem Wurf, die schlechter sind, plus halber Anteil der gleichen.
    static func perzentil(_ s: Schluessel, optionen: Optionen) -> Double {
        var schlechter = 0, gleich = 0
        for w in ausgaenge[3] {
            let k = werte(w.0, ausEinemWurf: true, optionen: optionen).schluessel
            let n = Int((w.1 * 216).rounded())
            if k < s { schlechter += n } else if k == s { gleich += n }
        }
        return Double(2 * schlechter + gleich) / Double(2 * 216)
    }

    /// Erwarteter Nutzen jeder Aktion; Index 0 = stehen, danach `moeglicheZuege` in fester Reihenfolge.
    static func bewerteGut(_ l: Lage) -> [(aktion: Aktion, nutzen: Double)] {
        let rechner = GutRechner(lage: l)
        let draussen = l.draussen.sorted()
        let wurf = l.wurf.sorted()
        var erg: [(Aktion, Double)] = [(.stehen, rechner.nutzen(draussen, wurf, l.wuerfe))]
        for z in moeglicheZuege(draussen: draussen, wurf: wurf, wuerfe: l.wuerfe, maxWuerfe: l.maxWuerfe, optionen: l.optionen) {
            erg.append((.weiter(herauslegen: z.herauslegen, umdrehen: z.umdrehen),
                        rechner.erwartung(draussen, wurf, l.wuerfe, z)))
        }
        return erg
    }

    static func entscheideGut(_ l: Lage) -> Aktion {
        var beste = Aktion.stehen
        var besterWert: Double?
        for (aktion, wert) in bewerteGut(l) where besterWert == nil || wert > besterWert! + eps {
            beste = aktion
            besterWert = wert
        }
        return beste
    }

    private final class GutRechner {
        struct Key: Hashable { let draussen: [Int]; let wurf: [Int]; let wuerfe: Int }

        let lage: Lage
        var cache: [Key: Double] = [:]
        var perzentile: [Schluessel: Double] = [:]

        init(lage: Lage) { self.lage = lage }

        func nutzen(_ draussen: [Int], _ wurf: [Int], _ wuerfe: Int) -> Double {
            let w = werte(draussen + wurf, ausEinemWurf: draussen.isEmpty, optionen: lage.optionen)
            return nutzen(w, wuerfe)
        }

        func nutzen(_ w: Wertung, _ wuerfe: Int) -> Double {
            guard let ref = lage.ziel.ref else {
                if let p = perzentile[w.schluessel] { return p }
                let p = Computer.perzentil(w.schluessel, optionen: lage.optionen)
                perzentile[w.schluessel] = p
                return p
            }
            return istBesser(Ergebnis(wertung: w, wuerfe: wuerfe, position: lage.ziel.position), ref) ? 1 : 0
        }

        func wert(_ draussen: [Int], _ wurf: [Int], _ wuerfe: Int) -> Double {
            let key = Key(draussen: draussen, wurf: wurf, wuerfe: wuerfe)
            if let v = cache[key] { return v }
            var best = nutzen(draussen, wurf, wuerfe)
            for z in moeglicheZuege(draussen: draussen, wurf: wurf, wuerfe: wuerfe,
                                    maxWuerfe: lage.maxWuerfe, optionen: lage.optionen) {
                best = max(best, erwartung(draussen, wurf, wuerfe, z))
            }
            cache[key] = best
            return best
        }

        func erwartung(_ draussen: [Int], _ wurf: [Int], _ wuerfe: Int, _ z: Zugwahl) -> Double {
            let neu = (draussen + z.herauslegen + Array(repeating: 1, count: z.umdrehen)).sorted()
            var summe = 0.0
            for (t, p) in Computer.ausgaenge[3 - neu.count] {
                summe += p * wert(neu, t, wuerfe + 1)
            }
            return summe
        }
    }
}
