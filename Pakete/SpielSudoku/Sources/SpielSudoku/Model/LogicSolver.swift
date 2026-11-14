// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Lösungstechniken, wie ein Mensch sie benutzt. `level` ist die Schwierigkeitsstufe,
/// ab der die Technik nötig wird (1 = Leicht … 3 = Schwer). Stufe 4 (Experte) gibt es nur für Tipps: Die Einstufung
/// (`Rating`) nutzt weiter nur Stufe 1–3.
enum Technique: Int, Codable, CaseIterable {
    case nakedSingle, hiddenSingle
    case pointing, claiming, nakedPair, hiddenPair
    case nakedTriple, hiddenTriple, xWing
    /// Nur für Tipps auf Experte (Stufe 4)
    case swordfish, xyWing, simpleColoring

    var level: Int {
        switch self {
        case .nakedSingle, .hiddenSingle: 1
        case .pointing, .claiming, .nakedPair, .hiddenPair: 2
        case .nakedTriple, .hiddenTriple, .xWing: 3
        case .swordfish, .xyWing, .simpleColoring: 4
        }
    }

    var title: String {
        switch self {
        case .nakedSingle: String(localized: "Einzige Möglichkeit")
        case .hiddenSingle: String(localized: "Einzige Stelle")
        case .pointing: String(localized: "Zeigendes Paar")
        case .claiming: String(localized: "Beanspruchte Linie")
        case .nakedPair: String(localized: "Nacktes Paar")
        case .hiddenPair: String(localized: "Verstecktes Paar")
        case .nakedTriple: String(localized: "Nacktes Tripel")
        case .hiddenTriple: String(localized: "Verstecktes Tripel")
        case .xWing: "X-Wing"
        case .swordfish: String(localized: "Schwertfisch")
        case .xyWing: String(localized: "XY-Flügel")
        case .simpleColoring: String(localized: "Färben")
        }
    }
}

/// Ein Lösungsschritt des Logik-Lösers: entweder eine Zahl setzen oder Kandidaten streichen.
struct LogicStep: Equatable {
    let technique: Technique
    /// Nur bei Einzelschritten: Zelle und Ziffer
    var placement: (cell: Int, digit: Int)?
    /// Zu streichende Kandidaten: Zelle und Ziffern-Maske
    var eliminations: [(cell: Int, mask: UInt16)] = []
    /// Die Zellen, die das Muster bilden
    var pattern: [Int] = []
    /// Beteiligte Ziffern
    var digits: UInt16 = 0
    /// Einheit (0–8 Zeile, 9–17 Spalte, 18–26 Box), falls sinnvoll
    var unit: Int?
    /// Nur Färben: die Zellen der Farbe 0 (für die Anzeige); die übrigen Musterzellen haben Farbe 1
    var color0: [Int] = []

    static func == (a: LogicStep, b: LogicStep) -> Bool {
        a.technique == b.technique && a.placement?.cell == b.placement?.cell
            && a.placement?.digit == b.placement?.digit && a.pattern == b.pattern && a.digits == b.digits
    }

    /// „Zeile 3“, „Spalte 5“, „Box 4“ (Boxen zählen wie beim Lesen: links oben = 1)
    static func unitName(_ unit: Int) -> String {
        switch unit {
        case 0..<9: String(localized: "Zeile \(unit + 1)")
        case 9..<18: String(localized: "Spalte \(unit - 9 + 1)")
        default: String(localized: "Box \(unit - 18 + 1)")
        }
    }

    static func cellName(_ i: Int) -> String { String(localized: "Zeile \(i / 9 + 1), Spalte \(i % 9 + 1)") }

    /// Erklärung für Tipps, ohne die Lösung zu verraten (`reveal: false`) oder mit ihr.
    func explanation(reveal: Bool) -> String {
        let digitList = ListFormatter.localizedString(byJoining: Mask.digits(digits).map(String.init))
        let place = placement
        switch technique {
        case .nakedSingle:
            if reveal, let place { return String(localized: "In \(Self.cellName(place.cell)) passt nur noch die \(place.digit).") }
            return String(localized: "Eine Zelle hat nur noch eine mögliche Zahl.")
        case .hiddenSingle:
            if reveal, let place, let unit {
                return String(localized: "In \(Self.unitName(unit)) passt die \(place.digit) nur in \(Self.cellName(place.cell)).")
            }
            if let unit { return String(localized: "In \(Self.unitName(unit)) passt eine Zahl nur an eine einzige Stelle.") }
            return String(localized: "Eine Zahl passt in ihrer Einheit nur an eine Stelle.")
        case .pointing:
            return String(localized: "In einer Box liegt die \(digitList) nur auf einer Linie. Sie fällt aus dem Rest der Linie.")
        case .claiming:
            return String(localized: "In einer Linie liegt die \(digitList) nur in einer Box. Sie fällt aus dem Rest der Box.")
        case .nakedPair, .nakedTriple:
            return String(localized: "Mehrere Zellen teilen sich dieselben Zahlen (\(digitList)). Die Zahlen fallen bei den anderen raus.")
        case .hiddenPair, .hiddenTriple:
            return String(localized: "Die Zahlen \(digitList) passen nur in dieselben Zellen. Dort fallen alle anderen Zahlen raus.")
        case .xWing:
            return String(localized: "Ein X-Wing für die \(digitList): Die Zahl liegt in zwei Linien nur in denselben zwei Kreuzungen.")
        case .swordfish:
            return String(localized: "Ein Schwertfisch für die \(digitList): Die Zahl liegt in drei Linien nur in denselben drei Kreuzungslinien. Sie fällt dort aus allen anderen Zellen.")
        case .xyWing:
            return String(localized: "Ein XY-Flügel: Drei Zellen mit je zwei Möglichkeiten. Die \(digitList) fällt aus jeder Zelle, die beide Zangen sehen.")
        case .simpleColoring:
            return String(localized: "Färben für die \(digitList): Eine Kette aus gefüllten und umrandeten Zellen. Nur eine der beiden Gruppen stimmt. Zellen, die beide sehen, verlieren die Zahl.")
        }
    }
}

/// Löst ein Sudoku mit menschlichen Techniken, Schritt für Schritt.
/// Dient zum Einstufen der Schwierigkeit und für Tipps.
struct LogicBoard {
    private(set) var values: [UInt8]
    private(set) var candidates: [UInt16]

    init(grid: [UInt8]) {
        values = grid
        candidates = [UInt16](repeating: 0, count: 81)
        var used = [UInt16](repeating: 0, count: 27)
        for i in 0..<81 where grid[i] != 0 {
            let bit = Mask.bit(Int(grid[i]))
            for u in Units.units(of: i) { used[u] |= bit }
        }
        for i in 0..<81 where grid[i] == 0 {
            let u = Units.units(of: i)
            candidates[i] = ~(used[u[0]] | used[u[1]] | used[u[2]]) & Mask.all
        }
    }

    /// Ein Feld mit schon gestrichenen Kandidaten (für die Beispiele der Technik-Sammlung)
    init(grid: [UInt8], candidates: [UInt16]) {
        values = grid
        self.candidates = candidates
    }

    var isSolved: Bool { !values.contains(0) }

    /// Der Widerspruch „Zelle ohne Kandidaten“ – bei eindeutigen Rätseln nie der Fall.
    var isContradiction: Bool { (0..<81).contains { values[$0] == 0 && candidates[$0] == 0 } }

    mutating func apply(_ step: LogicStep) {
        if let p = step.placement {
            values[p.cell] = UInt8(p.digit)
            candidates[p.cell] = 0
            let bit = Mask.bit(p.digit)
            for peer in Units.peers[p.cell] { candidates[peer] &= ~bit }
        }
        for e in step.eliminations { candidates[e.cell] &= ~e.mask }
    }

    /// Der einfachste Schritt, der weiterhilft (Reihenfolge: leichte Techniken zuerst).
    /// `maxLevel` begrenzt die erlaubten Techniken.
    func nextStep(maxLevel: Int = 3) -> LogicStep? {
        if let s = nakedSingle() { return s }
        if let s = hiddenSingle() { return s }
        guard maxLevel >= 2 else { return nil }
        if let s = pointingClaiming() { return s }
        if let s = nakedSubset(2) { return s }
        if let s = hiddenSubset(2) { return s }
        guard maxLevel >= 3 else { return nil }
        if let s = nakedSubset(3) { return s }
        if let s = hiddenSubset(3) { return s }
        if let s = xWing() { return s }
        guard maxLevel >= 4 else { return nil }
        if let s = swordfish() { return s }
        if let s = xyWing() { return s }
        if let s = simpleColoring() { return s }
        return nil
    }

    // MARK: Einzelne Zahlen

    private func nakedSingle() -> LogicStep? {
        for i in 0..<81 where candidates[i].nonzeroBitCount == 1 {
            let d = Mask.digits(candidates[i])[0]
            return LogicStep(technique: .nakedSingle, placement: (i, d), pattern: [i], digits: Mask.bit(d))
        }
        return nil
    }

    private func hiddenSingle() -> LogicStep? {
        for (u, cells) in Units.all.enumerated() {
            for d in 1...9 {
                let bit = Mask.bit(d)
                var found = -1
                var n = 0
                for c in cells where candidates[c] & bit != 0 {
                    found = c; n += 1
                    if n > 1 { break }
                }
                if n == 1 {
                    return LogicStep(technique: .hiddenSingle, placement: (found, d), pattern: [found], digits: bit, unit: u)
                }
            }
        }
        return nil
    }

    // MARK: Zeigen und Beanspruchen

    private func pointingClaiming() -> LogicStep? {
        // Zeigend: Ziffer in einer Box nur auf einer Linie
        for b in 0..<9 {
            let box = Units.boxes[b]
            for d in 1...9 {
                let bit = Mask.bit(d)
                let cells = box.filter { candidates[$0] & bit != 0 }
                guard cells.count >= 2 else { continue }
                for line in [cells.map(Units.row), cells.map(Units.col)].enumerated() {
                    guard Set(line.element).count == 1 else { continue }
                    let lineCells = line.offset == 0 ? Units.rows[line.element[0]] : Units.cols[line.element[0]]
                    let elim = lineCells.filter { Units.box($0) != b && candidates[$0] & bit != 0 }
                    if !elim.isEmpty {
                        return LogicStep(technique: .pointing, eliminations: elim.map { ($0, bit) },
                                         pattern: cells, digits: bit, unit: 18 + b)
                    }
                }
            }
        }
        // Beanspruchend: Ziffer in einer Linie nur in einer Box
        for (u, cells) in Units.all[0..<18].enumerated() {
            for d in 1...9 {
                let bit = Mask.bit(d)
                let with = cells.filter { candidates[$0] & bit != 0 }
                guard with.count >= 2, Set(with.map(Units.box)).count == 1 else { continue }
                let b = Units.box(with[0])
                let elim = Units.boxes[b].filter { !cells.contains($0) && candidates[$0] & bit != 0 }
                if !elim.isEmpty {
                    return LogicStep(technique: .claiming, eliminations: elim.map { ($0, bit) },
                                     pattern: with, digits: bit, unit: u)
                }
            }
        }
        return nil
    }

    // MARK: Paare und Tripel

    private func nakedSubset(_ n: Int) -> LogicStep? {
        for (u, unit) in Units.all.enumerated() {
            let cells = unit.filter { (2...n).contains(candidates[$0].nonzeroBitCount) }
            guard cells.count >= n else { continue }
            for combo in combinations(cells.count, n) {
                let chosen = combo.map { cells[$0] }
                let union = chosen.reduce(UInt16(0)) { $0 | candidates[$1] }
                guard union.nonzeroBitCount == n else { continue }
                let elim = unit.filter { !chosen.contains($0) && candidates[$0] & union != 0 }
                if !elim.isEmpty {
                    return LogicStep(technique: n == 2 ? .nakedPair : .nakedTriple,
                                     eliminations: elim.map { ($0, candidates[$0] & union) },
                                     pattern: chosen, digits: union, unit: u)
                }
            }
        }
        return nil
    }

    private func hiddenSubset(_ n: Int) -> LogicStep? {
        for (u, unit) in Units.all.enumerated() {
            // Ziffern, die in der Einheit noch 2…n-mal vorkommen
            var cellsOf = [Int: [Int]]()
            for d in 1...9 {
                let cells = unit.filter { candidates[$0] & Mask.bit(d) != 0 }
                if (2...n).contains(cells.count) { cellsOf[d] = cells }
            }
            let digits = cellsOf.keys.sorted()
            guard digits.count >= n else { continue }
            for combo in combinations(digits.count, n) {
                let chosen = combo.map { digits[$0] }
                let cells = Set(chosen.flatMap { cellsOf[$0]! })
                guard cells.count == n else { continue }
                let keep = chosen.reduce(UInt16(0)) { $0 | Mask.bit($1) }
                let elim = cells.sorted().filter { candidates[$0] & ~keep != 0 }
                if !elim.isEmpty {
                    return LogicStep(technique: n == 2 ? .hiddenPair : .hiddenTriple,
                                     eliminations: elim.map { ($0, candidates[$0] & ~keep) },
                                     pattern: cells.sorted(), digits: keep, unit: u)
                }
            }
        }
        return nil
    }

    // MARK: X-Wing

    private func xWing() -> LogicStep? {
        for d in 1...9 {
            let bit = Mask.bit(d)
            for byRows in [true, false] {
                // Linien, in denen die Ziffer genau zwei Plätze hat
                var pairs = [(line: Int, a: Int, b: Int)]()
                for line in 0..<9 {
                    let cells = (byRows ? Units.rows[line] : Units.cols[line]).filter { candidates[$0] & bit != 0 }
                    if cells.count == 2 {
                        let pos = cells.map { byRows ? Units.col($0) : Units.row($0) }
                        pairs.append((line, pos[0], pos[1]))
                    }
                }
                guard pairs.count >= 2 else { continue }
                for i in 0..<pairs.count {
                    for j in (i + 1)..<pairs.count where pairs[i].a == pairs[j].a && pairs[i].b == pairs[j].b {
                        let lines = [pairs[i].line, pairs[j].line]
                        let crossings = [pairs[i].a, pairs[i].b]
                        var elim = [Int]()
                        for cross in crossings {
                            let cells = byRows ? Units.cols[cross] : Units.rows[cross]
                            for c in cells {
                                let line = byRows ? Units.row(c) : Units.col(c)
                                if !lines.contains(line) && candidates[c] & bit != 0 { elim.append(c) }
                            }
                        }
                        if !elim.isEmpty {
                            let pattern = lines.flatMap { line in
                                crossings.map { byRows ? line * 9 + $0 : $0 * 9 + line }
                            }
                            return LogicStep(technique: .xWing, eliminations: elim.map { ($0, bit) },
                                             pattern: pattern, digits: bit)
                        }
                    }
                }
            }
        }
        return nil
    }

    /// Alle n-elementigen Auswahlen aus 0..<count (aufsteigend).
    private func combinations(_ count: Int, _ n: Int) -> [[Int]] {
        guard count >= n else { return [] }
        if n == 2 {
            return (0..<count).flatMap { a in ((a + 1)..<count).map { [a, $0] } }
        }
        return (0..<count).flatMap { a in
            ((a + 1)..<count).flatMap { b in ((b + 1)..<count).map { [a, b, $0] } }
        }
    }
}

// MARK: Stufe 4 (nur Tipps auf Experte): Suche genau wie `Referenz/sudoku.py`

extension LogicBoard {
    /// Wie X-Wing mit drei Linien: Ziffer d steht in drei Zeilen (Spalten) nur in 2–3 Zellen, die zusammen in genau drei
    /// Spalten (Zeilen) liegen. Dann fällt d dort in allen anderen Zeilen (Spalten) weg.
    func swordfish() -> LogicStep? {
        for d in 1...9 {
            let bit = Mask.bit(d)
            for byRows in [true, false] {
                var lines = [(line: Int, cells: [Int])]()
                for line in 0..<9 {
                    let cells = (byRows ? Units.rows[line] : Units.cols[line]).filter { candidates[$0] & bit != 0 }
                    if (2...3).contains(cells.count) { lines.append((line, cells)) }
                }
                guard lines.count >= 3 else { continue }
                for i in 0..<lines.count {
                    for j in (i + 1)..<lines.count {
                        for k in (j + 1)..<lines.count {
                            let chosen = [lines[i], lines[j], lines[k]]
                            let base = chosen.map(\.line)
                            let cells = chosen.flatMap(\.cells).sorted()
                            let crossings = Set(cells.map { byRows ? Units.col($0) : Units.row($0) })
                            guard crossings.count == 3 else { continue }
                            var elim = [Int]()
                            for c in 0..<81 {
                                let line = byRows ? Units.row(c) : Units.col(c)
                                let cross = byRows ? Units.col(c) : Units.row(c)
                                if crossings.contains(cross), !base.contains(line), candidates[c] & bit != 0 { elim.append(c) }
                            }
                            if !elim.isEmpty {
                                return LogicStep(technique: .swordfish, eliminations: elim.map { ($0, bit) }, pattern: cells, digits: bit)
                            }
                        }
                    }
                }
            }
        }
        return nil
    }

    /// Angelzelle mit genau {x, y}; eine Zange sieht die Angel und hat {x, z}, die andere {y, z}. Dann fällt z aus allen
    /// Zellen, die beide Zangen sehen.
    func xyWing() -> LogicStep? {
        for pivot in 0..<81 {
            let pm = candidates[pivot]
            guard pm.nonzeroBitCount == 2 else { continue }
            let wings = Units.peers[pivot].filter { candidates[$0].nonzeroBitCount == 2 && (candidates[$0] & pm).nonzeroBitCount == 1 }
            for (i, a) in wings.enumerated() {
                let z = candidates[a] & ~pm
                let rest = pm & ~candidates[a]
                for b in wings[(i + 1)...] where candidates[b] == (rest | z) {
                    let seenB = Set(Units.peers[b])
                    let elim = Units.peers[a].filter { seenB.contains($0) && $0 != pivot && candidates[$0] & z != 0 }
                    if !elim.isEmpty {
                        return LogicStep(technique: .xyWing, eliminations: elim.map { ($0, z) }, pattern: [pivot, a, b],
                                         digits: z)
                    }
                }
            }
        }
        return nil
    }

    /// Einfache Färbung: Ketten aus „starken Verbindungen“ (Einheiten, in denen d nur zweimal vorkommt), abwechselnd in
    /// zwei Farben; genau eine Farbe ist wahr. Widerspricht sich eine Farbe, fällt d aus all ihren Zellen; sonst verliert
    /// jede Zelle, die beide Farben sieht, die Ziffer. Nur Ketten ab 4 Zellen.
    func simpleColoring() -> LogicStep? {
        for d in 1...9 {
            let bit = Mask.bit(d)
            var links = [Int: Set<Int>]()
            for unit in Units.all {
                let cells = unit.filter { candidates[$0] & bit != 0 }
                if cells.count == 2 {
                    links[cells[0], default: []].insert(cells[1])
                    links[cells[1], default: []].insert(cells[0])
                }
            }
            var seen = Set<Int>()
            for start in links.keys.sorted() where !seen.contains(start) {
                var color = [start: 0]
                var queue = [start]
                while !queue.isEmpty {
                    let c = queue.removeFirst()
                    for n in (links[c] ?? []).sorted() where color[n] == nil {
                        color[n] = 1 - color[c]!
                        queue.append(n)
                    }
                }
                seen.formUnion(color.keys)
                guard color.count >= 4 else { continue }
                let chain = color.keys.sorted()
                for f in 0...1 {
                    let same = chain.filter { color[$0] == f }
                    var contradiction = false
                    for x in 0..<same.count {
                        for y in (x + 1)..<same.count where Units.peers[same[x]].contains(same[y]) { contradiction = true }
                    }
                    if contradiction {
                        return LogicStep(technique: .simpleColoring, eliminations: same.map { ($0, bit) }, pattern: chain, digits: bit,
                                         color0: chain.filter { color[$0] == 0 })
                    }
                }
                var elim = [Int]()
                for c in 0..<81 where color[c] == nil && candidates[c] & bit != 0 {
                    if Set(Units.peers[c].compactMap { color[$0] }) == [0, 1] { elim.append(c) }
                }
                if !elim.isEmpty {
                    return LogicStep(technique: .simpleColoring, eliminations: elim.map { ($0, bit) }, pattern: chain, digits: bit,
                                     color0: chain.filter { color[$0] == 0 })
                }
            }
        }
        return nil
    }
}

/// Einstufung eines Rätsels durch den Logik-Löser.
enum Rating {
    /// F7: Löst der Logik-Löser das Feld mit Techniken bis `maxLevel` vollständig, ohne Raten? (Schrittgrenze wie beim Tipp)
    static func isSolvableByLogic(_ grid: [UInt8], maxLevel: Int) -> Bool {
        var board = LogicBoard(grid: grid)
        for _ in 0..<400 {
            if board.isSolved { return true }
            guard let step = board.nextStep(maxLevel: maxLevel) else { return false }
            board.apply(step)
        }
        return board.isSolved
    }

    /// 1 = Leicht, 2 = Mittel, 3 = Schwer, 4 = Experte (mit den bekannten Techniken nicht lösbar).
    /// Bricht ab, sobald `cap` überschritten würde, und meldet dann `cap + 1`.
    static func level(of grid: [UInt8], cap: Int = 3) -> Int {
        var board = LogicBoard(grid: grid)
        var hardest = 1
        // F11: Schrittgrenze wie beim Tipp (ein Feld hat höchstens 81 Zahlen und einige hundert Streich-Schritte)
        for _ in 0..<400 {
            if board.isSolved { return hardest }
            guard let step = board.nextStep(maxLevel: 3) else { return 4 }
            hardest = max(hardest, step.technique.level)
            if hardest > cap { return cap + 1 }
            board.apply(step)
        }
        return board.isSolved ? hardest : 4
    }
}
