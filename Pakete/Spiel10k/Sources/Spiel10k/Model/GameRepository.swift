// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Ablage für Spielstände. Der `GameStore` kennt nur dieses Protokoll –
/// ein späterer Cloud-Sync kann als weitere Implementierung andocken.
protocol GameRepository {
    func loadAll() -> [GameRecord]
    func save(_ record: GameRecord) throws
    func delete(id: UUID) throws
}

/// Dateiformat eines gespeicherten Spiels, mit Versionsnummer.
nonisolated struct StoredGame: Codable, Sendable {
    /// Bei inkompatiblen Formatänderungen erhöhen und in `FileGameRepository.decode` migrieren.
    static let currentVersion = 1

    var version: Int
    var record: GameRecord
}

/// Speichert jedes Spiel als eigene JSON-Datei in Application Support/Games.
final class FileGameRepository: GameRepository {
    let directory: URL

    init(directory: URL = FileGameRepository.defaultDirectory) {
        self.directory = directory
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    static var defaultDirectory: URL {
        URL.applicationSupportDirectory.appending(path: "Games", directoryHint: .isDirectory)
    }

    private func url(for id: UUID) -> URL {
        directory.appending(path: "\(id.uuidString).json")
    }

    func loadAll() -> [GameRecord] {
        let files = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        return files
            .filter { $0.pathExtension == "json" }
            .compactMap { try? Data(contentsOf: $0) }
            .compactMap(Self.decode)
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    func save(_ record: GameRecord) throws {
        let data = try Self.encoder.encode(StoredGame(version: StoredGame.currentVersion, record: record))
        try data.write(to: url(for: record.id), options: .atomic)
    }

    func delete(id: UUID) throws {
        let file = url(for: id)
        if FileManager.default.fileExists(atPath: file.path()) {
            try FileManager.default.removeItem(at: file)
        }
    }

    static func decode(_ data: Data) -> GameRecord? {
        guard let stored = try? decoder.decode(StoredGame.self, from: data) else { return nil }
        // Dateien aus einer neueren App-Version nicht anfassen.
        guard stored.version <= StoredGame.currentVersion else { return nil }
        // Beschädigte Stände überspringen statt später abzustürzen (die Datei bleibt liegen).
        guard stored.record.state.isConsistent else { return nil }
        return stored.record
    }

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
}

/// Übernimmt den Spielstand der ersten App-Version (ein Spiel in UserDefaults).
enum LegacyMigration {
    static let legacyKey = "tenk.game.v1"

    static func run(defaults: UserDefaults, repository: GameRepository) {
        guard let data = defaults.data(forKey: legacyKey) else { return }
        guard let state = try? JSONDecoder().decode(GameState.self, from: data), state.isConsistent else { return }
        let now = Date()
        do {
            try repository.save(GameRecord(id: UUID(), name: nil, createdAt: now, updatedAt: now, state: state))
            defaults.removeObject(forKey: legacyKey)
        } catch {
            // Beim nächsten Start erneut versuchen – der alte Stand bleibt erhalten.
        }
    }
}
