// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import CoreGraphics

/// Regel-Typen der Solitär-Varianten ohne Oberfläche (früher in GameStore.swift, dort mit SwiftUI): damit die Regeln mit `swift test` laufen.

/// Art der Partie: lösbar, zufällig oder Tagesspiel.
enum DealKind: String, Codable { case solvable, random, daily }

/// Wie sich Karten nach der nächsten Zustandsänderung bewegen (Federwerte siehe DESIGN „Töne und Haptik“)
enum MoveStyle { case normal, drop, undo, finish, draw, recycle, complete }

/// Was die Regeln aus den Einstellungen lesen (die App-Einstellungen `AppPreferences` erfüllen das Protokoll).
protocol SolitaireRegelOptionen {
    /// Klondike-Punkte: 0 Standard · 1 Vegas · 2 Vegas fortlaufend · 3 Aus
    var klondikeScoring: Int { get }
}

/// Was gegeben wurde: Modus, Seed, Art (lösbar/zufällig/Tagesspiel).
struct DealInfo: Codable, Equatable {
    var seed: UInt64
    var mode: GameMode
    var kind: DealKind
    /// Nur beim Tagesspiel: der Tag als „2026-10-04“
    var day: String?
    /// Nur beim Tagesspiel Leicht (1) oder Schwer (3); nil = Gemischt (das Tagesspiel mit Ziel, Krone und Pokal)
    var dailyLevel: Int?

    init(seed: UInt64, mode: GameMode, kind: DealKind, day: String? = nil, dailyLevel: Int? = nil) {
        self.seed = seed; self.mode = mode; self.kind = kind; self.day = day; self.dailyLevel = dailyLevel
    }

    /// Klondike: Zieh-Art 1 oder 3
    init(seed: UInt64, draw: Int, kind: DealKind, day: String? = nil) {
        self.init(seed: seed, mode: .klondike(draw), kind: kind, day: day)
    }

    /// Option des Modus (Klondike: Zieh-Art)
    var draw: Int { mode.option }

    // Alte Spielstände kennen nur `draw` (= Klondike): fehlende Felder → Standardwert
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Key.self)
        seed = try c.decodeIfPresent(UInt64.self, forKey: .seed) ?? 1
        if let m = try c.decodeIfPresent(GameMode.self, forKey: .mode) {
            mode = m
        } else {
            mode = .klondike(try c.decodeIfPresent(Int.self, forKey: .draw) ?? 1)
        }
        kind = try c.decodeIfPresent(DealKind.self, forKey: .kind) ?? .random
        day = try c.decodeIfPresent(String.self, forKey: .day)
        dailyLevel = try c.decodeIfPresent(Int.self, forKey: .dailyLevel)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: Key.self)
        try c.encode(seed, forKey: .seed)
        try c.encode(mode, forKey: .mode)
        try c.encode(kind, forKey: .kind)
        try c.encodeIfPresent(day, forKey: .day)
        try c.encodeIfPresent(dailyLevel, forKey: .dailyLevel)
    }
    private enum Key: String, CodingKey { case seed, mode, draw, kind, day, dailyLevel }

    /// Nummer der Partie: Platz in der Liste + 1 (FreeCell: Microsoft-Nummer); bei Zufall die letzten 6 Ziffern des Seeds
    var number: String {
        if kind == .random { return String(String(seed).suffix(6)) }
        return DealCatalog.shared.number(mode: mode, seed: seed).map(String.init) ?? String(seed)
    }

    /// Lässt sich diese Partie über „Partie wählen…“ wieder aufrufen (und damit teilen)?
    var isNumbered: Bool { kind != .random && DealCatalog.shared.number(mode: mode, seed: seed) != nil }
}

/// Eine Spalte, deren tiefere offene Karten zu einem dichten Block zusammengeschoben sind (nur Querformat)
struct CollapsedBlock: Equatable {
    var column: Int
    var frame: CGRect
    var count: Int
}

/// Lebenslauf einer Partie – daran hängen Statistik, Serie, Tagesspiel und Rekorde.
enum GameEvent {
    /// erster Zug einer Partie
    case started(DealInfo)
    /// `score` ist nil bei Spielen ohne Punkte (FreeCell)
    case won(DealInfo, moves: Int, score: Int?, seconds: TimeInterval, undoUsed: Bool = false, hintUsed: Bool = false)
    /// angefangene Partie verlassen (Neu, Neustart, Tagesspiel)
    case abandoned(DealInfo)
    /// TriPeaks: die Kette hat eine neue Länge erreicht (nur ab 10 gemeldet)
    case chain(DealInfo, Int)
    /// Vegas fortlaufend: so viele Vegas-Punkte gehen in den Vegas-Stand (am Ende der Partie, vor Sieg/Verlust)
    case account(DealInfo, Int)
}
