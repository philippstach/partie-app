// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Liest die gemeinsamen Testfälle direkt aus dem Repo (`Shared/regeltests`), nicht aus einer Kopie.
enum Fixtures {
    static let root = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()  // GalgenmaennchenTests
        .deletingLastPathComponent()  // iOS
        .deletingLastPathComponent()  // Repo

    static func load<T: Decodable>(_ name: String, as type: T.Type = T.self) throws -> T {
        let url = root.appending(path: "Shared/regeltests/\(name).json")
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(T.self, from: Data(contentsOf: url))
    }
}
