// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Eine Partie. Reiner Wert, vollständig speicherbar. Die Minen werden erst beim ersten Aufdecken gelegt,
/// damit der erste Zug nie verliert (Feld und Umgebung bleiben frei) und das Brett ohne Raten lösbar ist.
public struct Spiel: Codable, Equatable, Sendable {
    public enum Status: String, Codable, Sendable { case bereit, laeuft, gewonnen, verloren }
    public enum Feld: UInt8, Codable, Sendable { case verdeckt, aufgedeckt, flagge }

    public let mass: Brettmass
    public let seed: UInt64
    /// Ohne Raten lösbares Brett erzeugen (empfohlen). Aus = reiner Zufall.
    public let fair: Bool
    public private(set) var minen: [Bool]
    public private(set) var felder: [Feld]
    public private(set) var status: Status = .bereit
    public private(set) var ausgeloest: Int? = nil
    public private(set) var hinweise = 0
    /// Gespielte Zeit in Sekunden; pflegt die Oberfläche (Hinweise kosten 10 s Strafzeit).
    public var dauer: TimeInterval = 0
    /// Feste Startposition (Tagesrätsel): wird sofort aufgedeckt, damit alle dasselbe Brett sehen.
    public let tagesStart: Int?

    /// 1.0 (M3): Die zweite Chance (einmal je Partie, nach einer Mine) wurde genutzt. Eine so gewonnene Partie zählt nicht als Bestzeit.
    public private(set) var zweiteChanceGenutzt = false
    /// 1.0 (M3): Brett vor dem letzten Zug, damit der Zug nach einer Mine zurückgenommen werden kann. Wird nicht gespeichert.
    private var vorZug: [Feld]? = nil
    /// N-024: Nach einer Mine zeigt das Brett die übrigen Minen erst, wenn der Spieler aufhört (`minenZeigen`). Bis dahin kann er die zweite Chance nehmen.
    /// Wird nicht gespeichert: Ein verlorenes Brett wird ohnehin nicht fortgesetzt.
    public private(set) var minenAufgedeckt = false

    public static let hinweisStrafe: TimeInterval = 10
    /// 1.0 (M3): Strafzeit für die zweite Chance
    public static let zweiteChanceStrafe: TimeInterval = 30

    private enum CodingKeys: String, CodingKey { case mass, seed, fair, minen, felder, status, ausgeloest, hinweise, dauer, tagesStart, zweiteChanceGenutzt }

    /// Pflichtfelder (Maße, Seed, Felder) müssen stimmen; alles Weitere bekommt bei fehlendem Wert einen Standard
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        mass = try c.decode(Brettmass.self, forKey: .mass)
        seed = try c.decode(UInt64.self, forKey: .seed)
        fair = (try? c.decodeIfPresent(Bool.self, forKey: .fair)) ?? true
        felder = try c.decode([Feld].self, forKey: .felder)
        minen = (try? c.decodeIfPresent([Bool].self, forKey: .minen)) ?? []
        guard felder.count == mass.felder, minen.isEmpty || minen.count == mass.felder else {
            throw DecodingError.dataCorruptedError(forKey: .felder, in: c, debugDescription: "Feldanzahl passt nicht zum Maß")
        }
        status = (try? c.decodeIfPresent(Status.self, forKey: .status)) ?? .bereit
        ausgeloest = (try? c.decodeIfPresent(Int.self, forKey: .ausgeloest)) ?? nil
        hinweise = (try? c.decodeIfPresent(Int.self, forKey: .hinweise)) ?? 0
        dauer = (try? c.decodeIfPresent(TimeInterval.self, forKey: .dauer)) ?? 0
        tagesStart = (try? c.decodeIfPresent(Int.self, forKey: .tagesStart)) ?? nil
        zweiteChanceGenutzt = (try? c.decodeIfPresent(Bool.self, forKey: .zweiteChanceGenutzt)) ?? false
    }

    public init(mass: Brettmass, seed: UInt64, fair: Bool = true, tagesStart: Int? = nil) {
        self.mass = mass; self.seed = seed; self.fair = fair; self.tagesStart = tagesStart
        minen = []
        felder = [Feld](repeating: .verdeckt, count: mass.felder)
        if let s = tagesStart { aufdecken(s) }
    }

    public init(stufe: Stufe, seed: UInt64, fair: Bool = true) {
        self.init(mass: stufe.mass, seed: seed, fair: fair)
    }

    /// Tagesrätsel: gleiches Brett für alle am selben Tag (Stufe mittel, Startfeld fest).
    public static func tagesraetsel(jahr: Int, monat: Int, tag: Int) -> Spiel {
        let seed = UInt64(jahr * 10_000 + monat * 100 + tag) &* 0x2545_F491_4F6C_DD1D
        let mass = Stufe.mittel.mass
        var z = SeedZufall(seed: seed)
        let start = Int.random(in: 0..<mass.felder, using: &z)
        return Spiel(mass: mass, seed: seed, fair: true, tagesStart: start)
    }

    /// Geteiltes Rätsel (D3): gleiche Stufe und gleicher Seed ergeben für alle dasselbe Brett, das Startfeld liegt fest (wie beim Tagesrätsel).
    public static func geteilt(stufe: Stufe, seed: UInt64, fair: Bool = true) -> Spiel {
        let mass = stufe.mass
        var z = SeedZufall(seed: seed)
        let start = Int.random(in: 0..<mass.felder, using: &z)
        return Spiel(mass: mass, seed: seed, fair: fair, tagesStart: start)
    }

    // MARK: Lesen

    public var istZuende: Bool { status == .gewonnen || status == .verloren }
    public var flaggen: Int { felder.reduce(0) { $0 + ($1 == .flagge ? 1 : 0) } }
    /// Restzähler wie auf einem Minenzähler: Minen minus gesetzte Fahnen (kann negativ sein).
    public var minenRest: Int { mass.minen - flaggen }
    public func feld(_ p: Position) -> Feld { felder[mass.index(p)] }
    public func istMine(_ p: Position) -> Bool { !minen.isEmpty && minen[mass.index(p)] }

    /// Zahl der Minen um das Feld (nur sinnvoll, wenn es aufgedeckt ist).
    public func zahl(_ p: Position) -> Int {
        guard !minen.isEmpty else { return 0 }
        return mass.nachbarn(mass.index(p)).reduce(0) { $0 + (minen[$1] ? 1 : 0) }
    }

    // MARK: Zuege

    public mutating func aufdecken(_ p: Position) { aufdecken(mass.index(p)) }

    mutating func aufdecken(_ i: Int) {
        guard !istZuende else { return }
        if felder[i] != .flagge { vorZug = (status == .laeuft) ? felder : nil }   // 1.0 (M3)
        switch felder[i] {
        case .flagge: return
        case .aufgedeckt: chord(i); oeffneRestWennAlleMinenMarkiert(); return
        case .verdeckt: break
        }
        if status == .bereit {
            legeMinen(sicher: i)
            status = .laeuft
        }
        flute(i)
        pruefeEnde()
        oeffneRestWennAlleMinenMarkiert()
    }

    public mutating func flaggeUmschalten(_ p: Position) {
        guard !istZuende else { return }
        let i = mass.index(p)
        switch felder[i] {
        case .verdeckt: felder[i] = .flagge
        case .flagge: felder[i] = .verdeckt
        case .aufgedeckt: break
        }
        oeffneRestWennAlleMinenMarkiert()
    }

    // MARK: Zweite Chance (1.0 M3)

    /// Nach einer Mine einmal je Partie möglich, solange der letzte Zug noch bekannt ist.
    public var zweiteChanceMoeglich: Bool { status == .verloren && !zweiteChanceGenutzt && vorZug != nil && !minenAufgedeckt }

    /// N-024: Ob das Brett die Lage aller Minen zeigen darf: nach einem Sieg, und nach einer Mine erst, wenn der Spieler aufhört
    /// (oder keine zweite Chance mehr hat). Wer noch weiterspielen kann, sieht sonst nur die getroffene Mine.
    public var minenSichtbar: Bool { status == .gewonnen || (status == .verloren && !zweiteChanceMoeglich) }

    /// N-024: „Aufhören“ nach einer Mine: Die übrigen Minen werden sichtbar, die zweite Chance ist damit vorbei.
    public mutating func minenZeigen() {
        guard status == .verloren else { return }
        minenAufgedeckt = true
    }

    /// Nimmt den Zug zurück, der die Mine ausgelöst hat. Die getroffene Mine bekommt eine Fahne, 30 s Strafzeit.
    /// Liefert wahr, wenn es geklappt hat.
    @discardableResult
    public mutating func zweiteChanceNehmen() -> Bool {
        guard zweiteChanceMoeglich, let alt = vorZug else { return false }
        let mine = ausgeloest
        felder = alt
        if let mine { felder[mine] = .flagge }
        status = .laeuft
        ausgeloest = nil
        zweiteChanceGenutzt = true
        vorZug = nil
        dauer += Spiel.zweiteChanceStrafe
        return true
    }

    // MARK: Rest öffnen (1.0 M3)

    /// Sind alle Minen richtig mit einer Fahne markiert (und keine falsche gesetzt), sind alle übrigen Felder sicher und öffnen sich von selbst.
    private mutating func oeffneRestWennAlleMinenMarkiert() {
        guard status == .laeuft, !minen.isEmpty else { return }
        for i in 0..<mass.felder where (felder[i] == .flagge) != minen[i] { return }
        for i in 0..<mass.felder where felder[i] == .verdeckt { felder[i] = .aufgedeckt }
        pruefeEnde()
    }

    /// Tippt der Spieler auf eine aufgedeckte Zahl mit genau so vielen Fahnen ringsum, öffnen sich alle übrigen Nachbarn.
    mutating func chord(_ i: Int) {
        guard status == .laeuft else { return }
        let zahl = self.zahl(mass.position(i))
        let nachbarn = mass.nachbarn(i)
        guard zahl > 0, nachbarn.filter({ felder[$0] == .flagge }).count == zahl else { return }
        for n in nachbarn where felder[n] == .verdeckt {
            flute(n)
            if status == .verloren { break }
        }
        pruefeEnde()
    }

    /// Ein Hinweis deckt ein Feld auf, das sich aus dem Sichtbaren sicher ergibt. Gibt es keins, passiert nichts.
    /// Liefert das aufgedeckte Feld.
    @discardableResult
    public mutating func hinweisGeben() -> Position? {
        guard status == .laeuft else { return nil }
        let offen = felder.map { $0 == .aufgedeckt }
        var zahlen = [Int](repeating: 0, count: mass.felder)
        for i in 0..<mass.felder where offen[i] { zahlen[i] = self.zahl(mass.position(i)) }
        let erg = Loeser.ableiten(mass: mass, zahl: zahlen, aufgedeckt: offen)
        guard let ziel = erg.sicher.filter({ felder[$0] != .aufgedeckt }).min() else { return nil }
        felder[ziel] = .verdeckt   // falsche Fahne darauf wird entfernt
        hinweise += 1
        dauer += Spiel.hinweisStrafe
        aufdecken(ziel)
        return mass.position(ziel)
    }

    /// RT-043: Eine Bestzeit zählt nur ohne zweite Chance und ohne benutzten Hinweis (wie in Sudoku und Kakuro).
    public var bestzeitMoeglich: Bool { !zweiteChanceGenutzt && hinweise == 0 }

    // MARK: Intern

    private mutating func flute(_ start: Int) {
        var stapel = [start]
        while let i = stapel.popLast() {
            guard felder[i] == .verdeckt else { continue }
            felder[i] = .aufgedeckt
            if minen[i] {
                status = .verloren
                ausgeloest = i
                return
            }
            if zahl(mass.position(i)) == 0 {
                stapel.append(contentsOf: mass.nachbarn(i).filter { felder[$0] == .verdeckt })
            }
        }
    }

    private mutating func pruefeEnde() {
        if status == .verloren { return }
        for i in 0..<mass.felder where !minen[i] && felder[i] != .aufgedeckt { return }
        status = .gewonnen
        for i in 0..<mass.felder where minen[i] { felder[i] = .flagge }
    }

    /// RT-006: Obergrenze der Versuche, ein ohne Raten lösbares Brett zu finden.
    static let maxVersuche = 5000

    private mutating func legeMinen(sicher: Int) {
        var sperre = Set(mass.nachbarn(sicher))
        sperre.insert(sicher)
        // Zu enges Brett: nur das angetippte Feld freihalten.
        if mass.felder - sperre.count < mass.minen { sperre = [sicher] }
        let kandidaten = (0..<mass.felder).filter { !sperre.contains($0) }
        var letzter: [Bool] = []
        // RT-006: „Ohne Raten“ soll gelten, solange es irgendein lösbares Brett gibt: Wir suchen bis `maxVersuche`
        // (früher 300, danach galt ein unlösbares Brett). Die Folge der Seeds bleibt gleich, bekannte Bretter ändern sich nicht.
        let versuche = fair ? Spiel.maxVersuche : 1
        for versuch in 0..<versuche {
            var z = SeedZufall(seed: seed &+ UInt64(versuch) &* 0x1000_0001)
            var m = [Bool](repeating: false, count: mass.felder)
            for i in kandidaten.shuffled(using: &z).prefix(mass.minen) { m[i] = true }
            letzter = m
            if !fair || Loeser.istOhneRatenLoesbar(mass: mass, minen: m, start: sicher) { break }
        }
        minen = letzter
    }
}
