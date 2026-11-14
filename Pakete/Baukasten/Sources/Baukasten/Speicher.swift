// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Kleiner Schlüssel-Wert-Speicher. `UserDefaults` erfüllt ihn, Tests nehmen ein Wörterbuch.
public protocol WerteSpeicher: AnyObject {
    func object(forKey key: String) -> Any?
    func set(_ value: Any?, forKey key: String)
}

extension UserDefaults: WerteSpeicher {}

/// Speicher im Arbeitsspeicher (Tests, Vorschau).
public final class FluechtigerSpeicher: WerteSpeicher {
    private var daten: [String: Any] = [:]
    public init() {}
    public func object(forKey key: String) -> Any? { daten[key] }
    public func set(_ value: Any?, forKey key: String) { daten[key] = value }
}
