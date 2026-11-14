// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Himmelsleiter: Würfeln und mit der Figur zum Feld 100 ziehen. Leitern bringen nach oben, Wolkenrutschen nach unten.
/// Eigene Regeln: Eine 6 gibt einen Extrawurf (dreimal hintereinander ist Schluss), und das Ziel muss nicht genau getroffen werden.
public struct Himmelsleiter: Equatable, Sendable, Codable {
    public static let ziel = 100
    /// Start → Ziel
    public static let leitern: [Int: Int] = [4: 27, 13: 33, 20: 41, 31: 54, 42: 63, 52: 71, 64: 85, 77: 96]
    public static let rutschen: [Int: Int] = [29: 9, 38: 16, 47: 26, 58: 37, 69: 48, 83: 61, 91: 72, 98: 79]

    public private(set) var positionen: [Int]       // 0 = vor dem Brett
    public private(set) var amZug = 0
    public private(set) var sieger: Int?
    public private(set) var letzterWurf = 0
    public private(set) var meldung = ""
    private var sechser = 0
    public let spieler: Int

    public init(spieler: Int) { self.spieler = max(2, min(4, spieler)); positionen = Array(repeating: 0, count: self.spieler) }

    /// Würfelt und zieht (der Wurf kommt von außen, damit die Würfelquelle austauschbar bleibt).
    public mutating func zug(wurf: Int) {
        guard sieger == nil, (1...6).contains(wurf) else { return }
        letzterWurf = wurf; meldung = ""
        sechser = wurf == 6 ? sechser + 1 : 0
        if sechser == 3 { meldung = "Dreimal die Sechs – ausgesetzt"; sechser = 0; weiter(); return }
        var p = positionen[amZug] + wurf
        if p >= Himmelsleiter.ziel { positionen[amZug] = Himmelsleiter.ziel; sieger = amZug; return }
        if let l = Himmelsleiter.leitern[p] { p = l; meldung = "Leiter hinauf!" }
        else if let r = Himmelsleiter.rutschen[p] { p = r; meldung = "Wolkenrutsche hinab!" }
        positionen[amZug] = p
        if wurf == 6 { meldung += meldung.isEmpty ? "Extrawurf" : " · Extrawurf"; return }
        weiter()
    }

    private mutating func weiter() { amZug = (amZug + 1) % spieler }

    /// Koordinaten eines Feldes im Schlangenmuster (Feld 1 unten links), Spalte/Zeile 0…9, Zeile 0 oben.
    public static func koordinate(_ feld: Int) -> (spalte: Int, zeile: Int) {
        let i = feld - 1; let reihe = i / 10; let sp = i % 10
        return (reihe % 2 == 0 ? sp : 9 - sp, 9 - reihe)
    }
}
