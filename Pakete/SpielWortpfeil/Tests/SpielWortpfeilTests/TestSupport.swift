// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
@testable import SpielWortpfeil

/// Findet `Shared/` im Repo – relativ zu dieser Datei, nicht als Kopie.
enum Shared {
    static let root = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .appending(path: "Shared")

    static func json(_ path: String) -> Any {
        let data = try! Data(contentsOf: root.appending(path: path))
        return try! JSONSerialization.jsonObject(with: data)
    }

    static func puzzle(_ any: Any) -> Puzzle {
        let data = try! JSONSerialization.data(withJSONObject: any)
        return try! JSONDecoder().decode(Puzzle.self, from: data)
    }
}
