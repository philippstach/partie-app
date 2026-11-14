// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import SpieleKern
import KlarGlas

/// Namensabgleich für Hall of Fame, Vorschläge und das Emoji-/Farb-Gedächtnis
/// (Doku/SPEC-1.0.1-B.md §2, Testfälle in Shared/spieler/namensabgleich.json).
nonisolated enum PlayerName {
    private static let german = Locale(identifier: "de_DE")

    /// Schlüssel einer Person: Rand weg, Leerraum innen (auch Tab, NBSP) zu einem Leerzeichen,
    /// klein geschrieben. Umlaute und Akzente bleiben unterschiedlich. Leer = kein bekannter Name.
    static func key(_ name: String) -> String {
        name.split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")
            .lowercased(with: german)
    }

    /// Dieselbe Person? Leere Namen sind niemand.
    static func same(_ a: String, _ b: String) -> Bool {
        let k = key(a)
        return !k.isEmpty && k == key(b)
    }

    /// Ersatzname für ein leer gelassenes Namensfeld (1.0: „Spieler N“, ab 1.0.1 „Person N“).
    static func placeholder(_ index: Int) -> String { String(localized: "Person \(index + 1)") }

    /// Platzhalter zählen nicht in Hall of Fame und Vorschlägen – sonst entstehen Phantom-Einträge.
    static func isPlaceholder(_ name: String) -> Bool {
        let parts = key(name).split(separator: " ")
        return parts.count == 2 && ["spieler", "person"].contains(parts[0]) && Int(parts[1]) != nil
    }

    /// Ein Name, den man sich merken darf
    static func isKnowable(_ name: String) -> Bool {
        !key(name).isEmpty && !isPlaceholder(name)
    }
}

/// Eine bekannte Person: zuletzt benutzte Schreibweise, Emoji und Farbe.
nonisolated struct KnownPlayer: Codable, Equatable, Sendable, Identifiable {
    var name: String
    var avatar: String
    /// `nil`, wenn nur aus der Statistik bekannt (dort fehlt die Farbe)
    var colorIndex: Int?
    var lastUsed: Date
    var games: Int

    var id: String { PlayerName.key(name) }
}

/// Lokale Liste der bekannten Personen (UserDefaults `tenk.knownPlayers.v1`).
nonisolated struct KnownPlayers: Codable, Equatable, Sendable {
    private(set) var byKey: [String: KnownPlayer] = [:]

    var all: [KnownPlayer] { byKey.values.sorted { $0.lastUsed > $1.lastUsed } }

    func lookup(_ name: String) -> KnownPlayer? {
        byKey[PlayerName.key(name)]
    }

    /// Beim Spielstart für alle Mitspielenden (Platzhalter nicht).
    mutating func record(_ players: [Player], at date: Date = Date()) {
        for p in players where !p.isComputer && PlayerName.isKnowable(p.name) {
            let k = PlayerName.key(p.name)
            let games = (byKey[k]?.games ?? 0) + 1
            byKey[k] = KnownPlayer(name: p.name, avatar: p.avatar, colorIndex: p.colorIndex, lastUsed: date, games: games)
        }
    }

    /// Personen aus dem gemeinsamen Verzeichnis der Sammlung ergänzen (nur neue, ohne Spielzahl).
    mutating func merge(shared: [(name: String, avatar: String, farbeHex: UInt32)]) {
        for s in shared where PlayerName.isKnowable(s.name) {
            // Farbe aus der Hülle: nächstliegende Farbe der 10k-Palette (W09, gleiche Farbe in jedem Spiel)
            let farbe = SpielerQuelle.naechsteFarbe(zu: s.farbeHex, in: Theme.playerHex)
            if byKey[PlayerName.key(s.name)] == nil {
                byKey[PlayerName.key(s.name)] = KnownPlayer(name: s.name, avatar: s.avatar, colorIndex: farbe, lastUsed: .distantPast, games: 0)
            } else if byKey[PlayerName.key(s.name)]?.colorIndex == nil {
                byKey[PlayerName.key(s.name)]?.colorIndex = farbe
            }
        }
    }

    /// Einmalig beim ersten Start mit 1.0.1: aus Statistik und gespeicherten Spielen befüllen.
    static func seeded(summaries: [GameSummary], games: [GameRecord]) -> KnownPlayers {
        var list = KnownPlayers()
        for s in summaries.sorted(by: { $0.date < $1.date }) {
            for e in s.players where PlayerName.isKnowable(e.name) {
                let k = PlayerName.key(e.name)
                let old = list.byKey[k]
                list.byKey[k] = KnownPlayer(name: e.name, avatar: e.avatar, colorIndex: old?.colorIndex,
                                            lastUsed: max(s.date, old?.lastUsed ?? .distantPast), games: (old?.games ?? 0) + 1)
            }
        }
        // Gespeicherte Spiele kennen auch die Farbe; Spiele, die schon in der Statistik stehen, nicht doppelt zählen
        let counted = Set(summaries.map(\.id))
        for r in games.sorted(by: { $0.updatedAt < $1.updatedAt }) {
            for p in r.state.players where PlayerName.isKnowable(p.name) {
                let k = PlayerName.key(p.name)
                let old = list.byKey[k]
                let newer = r.updatedAt >= (old?.lastUsed ?? .distantPast)
                list.byKey[k] = KnownPlayer(
                    name: newer ? p.name : old!.name,
                    avatar: newer ? p.avatar : old!.avatar,
                    colorIndex: newer ? p.colorIndex : (old?.colorIndex ?? p.colorIndex),
                    lastUsed: max(r.updatedAt, old?.lastUsed ?? .distantPast),
                    games: (old?.games ?? 0) + (counted.contains(r.id) ? 0 : 1))
            }
        }
        return list
    }

    mutating func remove(_ key: String) { byKey[key] = nil }

    mutating func removeAll() { byKey = [:] }

    /// Bis zu `limit` Vorschläge: Treffer am Anfang vor Treffern in der Mitte, dann zuletzt benutzt.
    /// Leere Eingabe = zuletzt benutzte. Schon im Spiel befindliche Personen nicht.
    func suggestions(for text: String, excluding names: [String], limit: Int = 5) -> [KnownPlayer] {
        let q = PlayerName.key(text)
        let taken = Set(names.map(PlayerName.key).filter { !$0.isEmpty })
        let candidates = all.filter { !taken.contains($0.id) && $0.id != q }
        guard !q.isEmpty else { return Array(candidates.prefix(limit)) }
        let starts = candidates.filter { $0.id.hasPrefix(q) || $0.id.split(separator: " ").contains { $0.hasPrefix(q) } }
        let inside = candidates.filter { $0.id.contains(q) && !starts.contains($0) }
        return Array((starts + inside).prefix(limit))
    }

    /// Übernimmt Name, Emoji und Farbe der bekannten Person. Ist die Farbe schon vergeben,
    /// kommt die nächste freie; das Emoji darf doppelt sein.
    static func apply(_ known: KnownPlayer, to player: Player, others: [Player], colorCount: Int) -> Player {
        var p = player
        p.name = known.name
        p.avatar = known.avatar
        let used = Set(others.map(\.colorIndex))
        let wanted = known.colorIndex ?? player.colorIndex
        if !used.contains(wanted) {
            p.colorIndex = wanted
        } else if let free = (0..<colorCount).map({ (wanted + $0) % colorCount }).first(where: { !used.contains($0) }) {
            p.colorIndex = free
        }
        return p
    }
}
