// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import Spiel10k

/// D13: flaches Aktions-JSON mit `type`, wie in Doku/MEHRSPIELER-PLAN.md §5.
struct GameActionCodingTests {
    private func json(_ action: GameAction) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        return String(decoding: try encoder.encode(action), as: UTF8.self)
    }

    private func decode(_ json: String) throws -> GameAction {
        try JSONDecoder().decode(GameAction.self, from: Data(json.utf8))
    }

    nonisolated static let cases: [(GameAction, String)] = [
        (.roll(keep: []), #"{"keep":[],"type":"roll"}"#),
        (.roll(keep: [0, 2]), #"{"keep":[0,2],"type":"roll"}"#),
        (.enterThrow(keep: [0], dice: [3, 3, 6, 2]), #"{"dice":[3,3,6,2],"keep":[0],"type":"enterThrow"}"#),
        (.bank(keep: [1]), #"{"keep":[1],"type":"bank"}"#),
        (.layOut(dice: [1, 1], bank: false), #"{"bank":false,"dice":[1,1],"type":"layOut"}"#),
        (.layOut(dice: [5], bank: true), #"{"bank":true,"dice":[5],"type":"layOut"}"#),
        (.acceptOffer, #"{"type":"acceptOffer"}"#),
        (.declineOffer, #"{"type":"declineOffer"}"#),
        (.points(450), #"{"points":450,"type":"points"}"#),
        (.points(450, leaveOpen: 2), #"{"leaveOpen":2,"points":450,"type":"points"}"#),
        (.noPoints, #"{"type":"noPoints"}"#),
        (.undo, #"{"type":"undo"}"#),
    ]

    @Test(arguments: cases)
    func encodesFlat(_ action: GameAction, _ expected: String) throws {
        #expect(try json(action) == expected)
    }

    @Test(arguments: cases)
    func roundTrip(_ action: GameAction, _ expected: String) throws {
        #expect(try decode(expected) == action)
        #expect(try decode(try json(action)) == action)
    }

    @Test func layOutBankDefaultsToFalse() throws {
        #expect(try decode(#"{"type":"layOut","dice":[1,1]}"#) == .layOut(dice: [1, 1], bank: false))
        #expect(throws: DecodingError.self) { try decode(#"{"type":"layOut"}"#) }
    }

    @Test func missingKeepMeansEmpty() throws {
        #expect(try decode(#"{"type":"roll"}"#) == .roll(keep: []))
        #expect(try decode(#"{"type":"bank"}"#) == .bank(keep: []))
    }

    @Test func rejectsUnknownOrIncomplete() {
        #expect(throws: DecodingError.self) { try decode(#"{"type":"cheat"}"#) }
        #expect(throws: DecodingError.self) { try decode(#"{"type":"points"}"#) }
        #expect(throws: DecodingError.self) { try decode(#"{"type":"enterThrow","keep":[0]}"#) }
        #expect(throws: DecodingError.self) { try decode(#"{"points":{"_0":450}}"#) }
    }
}
