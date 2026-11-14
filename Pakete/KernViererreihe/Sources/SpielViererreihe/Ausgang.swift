// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Ausgang einer Partie aus Sicht des Menschen.
enum Ausgang: Equatable, Sendable {
    case sieg, niederlage, unentschieden
}

extension Ausgang: Codable {
    private var text: String {
        switch self {
        case .sieg: "sieg"
        case .niederlage: "niederlage"
        case .unentschieden: "unentschieden"
        }
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        switch try c.decode(String.self) {
        case "sieg": self = .sieg
        case "niederlage": self = .niederlage
        default: self = .unentschieden
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(text)
    }
}
