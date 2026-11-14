// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Die 15 Abzeichen (SPEZIFIKATION-EXTRAS §5). Nur Abzeichen, keine Freischaltungen, alles lokal.
enum Achievement: String, CaseIterable, Identifiable {
    case ersterSieg, alleFuenf, ohneZurueck, ohneTipp, blitz, dreiKarten, schwer, spinne4, freecellFlink, kette10, serie5, serie10, hundert, krone, goldpokal
    var id: String { rawValue }

    var title: String {
        switch self {
        case .ersterSieg: String(localized: "Erster Sieg")
        case .alleFuenf: String(localized: "Alle Spiele")
        case .ohneZurueck: String(localized: "Ohne Netz")
        case .ohneTipp: String(localized: "Auf eigene Faust")
        case .blitz: String(localized: "Blitz")
        case .dreiKarten: String(localized: "Drei auf einmal")
        case .schwer: String(localized: "Harte Nuss")
        case .spinne4: String(localized: "Vier Farben")
        case .freecellFlink: String(localized: "Flinke Zellen")
        case .kette10: String(localized: "Lange Kette")
        case .serie5: String(localized: "Serie 5")
        case .serie10: String(localized: "Serie 10")
        case .hundert: String(localized: "Hundert")
        case .krone: String(localized: "Gekrönt")
        case .goldpokal: String(localized: "Goldpokal")
        }
    }

    /// Bedingung als Satzteil: „gewinnen ohne Rückgängig“
    var condition: String {
        switch self {
        case .ersterSieg: String(localized: "irgendeine Partie gewinnen")
        case .alleFuenf: String(localized: "jedes Spiel der App mindestens einmal gewinnen")
        case .ohneZurueck: String(localized: "gewinnen ohne Rückgängig")
        case .ohneTipp: String(localized: "gewinnen ohne Tipp")
        case .blitz: String(localized: "Klondike in unter 3:00 gewinnen")
        case .dreiKarten: String(localized: "Klondike mit 3 Karten gewinnen")
        case .schwer: String(localized: "eine Partie der Stufe Schwer gewinnen")
        case .spinne4: String(localized: "Spider mit 4 Farben gewinnen")
        case .freecellFlink: String(localized: "FreeCell in unter 5:00 gewinnen")
        case .kette10: String(localized: "bei TriPeaks eine Kette von 10 Karten erreichen")
        case .serie5: String(localized: "5 Siege in Folge in einem Spiel")
        case .serie10: String(localized: "10 Siege in Folge in einem Spiel")
        case .hundert: String(localized: "100 Siege insgesamt")
        case .krone: String(localized: "die erste Krone im Tagesspiel holen")
        case .goldpokal: String(localized: "einen Monatspokal in Gold holen")
        }
    }

    var symbol: String {
        switch self {
        case .ersterSieg: "flag.checkered"
        case .alleFuenf: "star.circle"
        case .ohneZurueck: "lock.shield"
        case .ohneTipp: "lightbulb.slash"
        case .blitz: "bolt.fill"
        case .dreiKarten: "rectangle.stack"
        case .schwer: "flame.fill"
        case .spinne4: "circle.grid.cross"
        case .freecellFlink: "timer"
        case .kette10: "link"
        case .serie5: "5.circle"
        case .serie10: "10.circle"
        case .hundert: "rosette"
        case .krone: "crown.fill"
        case .goldpokal: "trophy.fill"
        }
    }
}

/// Was passiert ist; Aufgeben und „Lösung ansehen“ erzeugen nie ein Ereignis.
enum AchievementEvent {
    /// Sieg einer Partie (Spiel, Modus, Zeit, Rückgängig/Tipp benutzt). Die Statistik enthält den Sieg schon.
    case win(DealInfo, seconds: TimeInterval, undoUsed: Bool, hintUsed: Bool)
    /// TriPeaks: Kette erreicht (sofort, auch ohne Sieg)
    case chain(Int)
    /// Krone im Tagesspiel geholt
    case crown
    /// Monatspokal erreicht
    case cup(Cup)
}

enum Achievements {
    static let blitzSeconds: TimeInterval = 180
    static let freecellSeconds: TimeInterval = 300

    /// Reine Funktion: welche Abzeichen bringt das Ereignis zusätzlich? `data` ist die Statistik NACH dem Ereignis,
    /// `bisher` die schon vergebenen Abzeichen (nie doppelt). Reihenfolge wie `Achievement.allCases`.
    static func newAchievements(_ event: AchievementEvent, data: StatsData, earned bisher: Set<String>) -> [Achievement] {
        var hit = Set<Achievement>()
        switch event {
        case let .win(deal, seconds, undoUsed, hintUsed):
            hit.insert(.ersterSieg)
            if !undoUsed { hit.insert(.ohneZurueck) }
            if !hintUsed { hit.insert(.ohneTipp) }
            let kind = deal.mode.kind
            if kind == .klondike, seconds < blitzSeconds { hit.insert(.blitz) }
            if deal.mode == .klondike(3) { hit.insert(.dreiKarten) }
            if deal.kind != .random, DealCatalog.shared.level(mode: deal.mode, seed: deal.seed) == 3 { hit.insert(.schwer) }
            if deal.mode == .spider(4) { hit.insert(.spinne4) }
            if kind == .freecell, seconds < freecellSeconds { hit.insert(.freecellFlink) }
            let streak = data[deal.mode].streak
            if streak >= 5 { hit.insert(.serie5) }
            if streak >= 10 { hit.insert(.serie10) }
            hit.formUnion(derivable(data))
        case let .chain(n):
            if n >= 10 { hit.insert(.kette10) }
        case .crown:
            hit.insert(.krone)
        case let .cup(cup):
            if cup == .gold { hit.insert(.goldpokal) }
        }
        return Achievement.allCases.filter { hit.contains($0) && !bisher.contains($0.rawValue) }
    }

    /// Was sich allein aus der Statistik ableiten lässt (auch fürs stille Nachholen beim ersten Start)
    static func derivable(_ data: StatsData) -> Set<Achievement> {
        var out = Set<Achievement>()
        let total = data.modes.values.reduce(0) { $0 + $1.won }
        if total >= 1 { out.insert(.ersterSieg) }
        if total >= 100 { out.insert(.hundert) }
        let kindsWon = Set(GameKind.allCases.filter { kind in data.modes.contains { $0.key.hasPrefix(kind.rawValue) && $0.value.won > 0 } })
        if kindsWon.count == GameKind.allCases.count { out.insert(.alleFuenf) }
        if (data.modes[GameMode.klondike(3).key]?.won ?? 0) > 0 { out.insert(.dreiKarten) }
        if (data.modes[GameMode.spider(4).key]?.won ?? 0) > 0 { out.insert(.spinne4) }
        let best = data.modes.values.map(\.bestStreak).max() ?? 0
        if best >= 5 { out.insert(.serie5) }
        if best >= 10 { out.insert(.serie10) }
        if data.daily.values.contains(where: { !$0.crowned.isEmpty }) { out.insert(.krone) }
        return out
    }
}
