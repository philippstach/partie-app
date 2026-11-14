// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// W2 Technik-Training: feste Übungen aus `Shared/uebungen.json` (6 je Technik, von leicht nach schwer).
/// Eine Übung ist ein Feld mit Notizen (= Kandidaten des Logik-Lösers) und einem Zielschritt.
struct ExerciseStep: Codable, Equatable, Sendable {
    struct Place: Codable, Equatable, Sendable { let zelle: Int; let ziffer: Int }
    struct Strike: Codable, Equatable, Sendable { let zelle: Int; let ziffern: [Int] }

    let technik: String
    let muster: [Int]
    let ziffern: [Int]
    var setzen: Place?
    var streichen: [Strike]?
    var einheit: Int?
    /// Nur Färben: Zellen der Farbe 0
    var farbe0: [Int]?

    enum CodingKeys: String, CodingKey {
        case technik, muster, ziffern, setzen, streichen, einheit
        case farbe0 = "farbe_0"
    }
}

struct Exercise: Codable, Equatable, Sendable {
    let nr: Int
    let stufe: Int
    let feld: String
    let kandidaten: [String]
    let loesung: String
    let schritt: ExerciseStep

    var values: [UInt8] { feld.map { UInt8(String($0)) ?? 0 } }
    var solution: [UInt8] { loesung.map { UInt8(String($0)) ?? 0 } }
    /// Notizen je Zelle als Maske
    var masks: [UInt16] { kandidaten.map { $0.reduce(UInt16(0)) { $0 | Mask.bit(Int(String($1))!) } } }
    var board: LogicBoard { LogicBoard(grid: values, candidates: masks) }

    /// Der Zielschritt, wie der Logik-Löser ihn von diesem Stand aus findet
    var step: LogicStep? { board.nextStep(maxLevel: 4) }

    func puzzle(for technique: Technique) -> Puzzle {
        let difficulty: Difficulty = switch technique.level {
        case 1: .easy
        case 2: .medium
        case 3: .hard
        default: .expert
        }
        return Puzzle(givens: values, solution: solution, difficulty: difficulty, seed: UInt64(nr))
    }

    /// Ist der Zielschritt erledigt? Zahl setzen: die Ziffer steht in der Zielzelle. Streichen: alle Ziel-Notizen sind weg.
    func isDone(on board: Board) -> Bool {
        if let place = schritt.setzen { return Int(board.cells[place.zelle].value) == place.ziffer }
        guard let strikes = schritt.streichen, !strikes.isEmpty else { return false }
        return strikes.allSatisfy { strike in
            let cell = board.cells[strike.zelle]
            return strike.ziffern.allSatisfy { cell.notes & Mask.bit($0) == 0 }
        }
    }
}

/// Verweis auf eine Übung in einem laufenden Spiel (wird mit dem Spielstand gespeichert).
struct ExerciseRef: Codable, Equatable, Sendable {
    var technique: Int
    var number: Int
}

enum Exercises {
    private struct File: Codable {
        struct Series: Codable { let technik: String; let uebungen: [Exercise] }
        let reihen: [Series]
    }

    /// Nur Debug-Builds ohne App (Paket-Tests): Ordner der Umgebungsvariable PARTIE_PARTIEN, in Release immer `nil`.
    private static var testURL: URL? {
        #if DEBUG
        for ordner in (ProcessInfo.processInfo.environment["PARTIE_PARTIEN"] ?? "").split(separator: ":") {
            let url = URL(fileURLWithPath: String(ordner)).appending(path: "uebungen.json")
            if FileManager.default.fileExists(atPath: url.path) { return url }
        }
        #endif
        return nil
    }

    /// Alle Übungen je Technik, aus dem Bundle geladen
    static let all: [Technique: [Exercise]] = {
        guard let url = Bundle.main.url(forResource: "uebungen", withExtension: "json") ?? testURL,
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(File.self, from: data) else { return [:] }
        var result = [Technique: [Exercise]]()
        for series in file.reihen {
            if let technique = Technique.allCases.first(where: { String(describing: $0) == series.technik }) {
                result[technique] = series.uebungen.sorted { $0.nr < $1.nr }
            }
        }
        return result
    }()

    static func series(for technique: Technique) -> [Exercise] { all[technique] ?? [] }

    static func exercise(_ technique: Technique, _ number: Int) -> Exercise? {
        series(for: technique).first { $0.nr == number }
    }

    static func exercise(for ref: ExerciseRef) -> Exercise? {
        Technique(rawValue: ref.technique).flatMap { exercise($0, ref.number) }
    }
}
