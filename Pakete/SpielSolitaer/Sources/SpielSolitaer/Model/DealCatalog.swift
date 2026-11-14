// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

private final class BundleToken {}

/// Bundle mit den Partie-Listen. Im App-Bundle liegen sie flach; ohne App (Paket-Tests in Debug) darf
/// die Umgebungsvariable PARTIE_PARTIEN auf den Ordner `Shared/partien` zeigen.
func partienBundle(_ token: AnyClass = BundleToken.self) -> Bundle {
    // Erst das App-Bundle (auch Host der gehosteten Tests): Wird das Paket als eigenes dynamisches Framework gebaut
    // (App und Test-Ziel binden es beide ein), zeigt `Bundle(for:)` auf das Framework, in dem die Listen nicht liegen.
    if Bundle.main.url(forResource: "ziehen1", withExtension: "json") != nil { return Bundle.main }
    let standard = Bundle(for: token)
    #if DEBUG
    if standard.url(forResource: "ziehen1", withExtension: "json") == nil,
       let pfad = ProcessInfo.processInfo.environment["PARTIE_PARTIEN"], let b = Bundle(path: pfad) { return b }
    #endif
    return standard
}

/// Die geprüft lösbaren Partien (`Shared/partien/ziehen1.json`, `ziehen3.json`, als Datei-Referenz im Bundle)
/// und das Tagesspiel.
struct DealCatalog {
    static let dailyEpoch = (year: 2026, month: 1, day: 1)
    static let recentLimit = 200

    private(set) var seeds: [Int: [UInt64]]
    /// Spider: lösbare Partien mit 1 und 2 Farben (4 Farben: vorerst nur Zufall)
    private(set) var spiderSeeds: [Int: [UInt64]]
    /// Pyramid: lösbare Partien
    private(set) var pyramidSeeds: [UInt64] = []
    /// TriPeaks: lösbare Partien
    private(set) var tripeaksSeeds: [UInt64] = []
    /// Golf: lösbare Partien
    private(set) var golfSeeds: [UInt64] = []
    /// Yukon: lösbare Partien
    private(set) var yukonSeeds: [UInt64] = []
    /// Lösungslänge je Partie (Züge der gefundenen Lösung) – für das Tagesziel „in höchstens … Zügen“
    private(set) var solutionLengths: [String: [UInt64: Int]] = [:]
    /// Schwierigkeit je Partie: 1 leicht, 2 mittel, 3 schwer (je ein Drittel, nach dem Tipp-Spieler bewertet)
    private(set) var levels: [String: [UInt64: Int]] = [:]

    init(seeds1: [UInt64], seeds3: [UInt64], spider1: [UInt64] = [], spider2: [UInt64] = [], pyramid: [UInt64] = [], tripeaks: [UInt64] = [], golf: [UInt64] = [], yukon: [UInt64] = [],
         solutionLengths: [String: [UInt64: Int]] = [:], levels: [String: [UInt64: Int]] = [:]) {
        seeds = [1: seeds1, 3: seeds3]
        spiderSeeds = [1: spider1, 2: spider2]
        pyramidSeeds = pyramid
        tripeaksSeeds = tripeaks
        golfSeeds = golf
        yukonSeeds = yukon
        self.solutionLengths = solutionLengths
        self.levels = levels
    }

    static let shared = DealCatalog.load()

    static func load(bundle: Bundle = partienBundle()) -> DealCatalog {
        var lengths: [String: [UInt64: Int]] = [:]
        var levels: [String: [UInt64: Int]] = [:]
        func read(_ name: String) -> [UInt64] {
            guard let url = bundle.url(forResource: name, withExtension: "json"),
                  let data = try? Data(contentsOf: url),
                  let file = try? JSONDecoder().decode(File.self, from: data) else { return [] }
            lengths[name] = Dictionary(file.partien.compactMap { e in e.loesung.map { (e.seed, $0) } }, uniquingKeysWith: { a, _ in a })
            levels[name] = Dictionary(file.partien.compactMap { e in e.stufe.map { (e.seed, $0) } }, uniquingKeysWith: { a, _ in a })
            return file.partien.map(\.seed)
        }
        let list1 = read("ziehen1"), list3 = read("ziehen3"), s1 = read("spider1"), s2 = read("spider2"), pyr = read("pyramid"), tri = read("tripeaks"), gol = read("golf"), yuk = read("yukon")
        return DealCatalog(seeds1: list1, seeds3: list3, spider1: s1, spider2: s2, pyramid: pyr, tripeaks: tri, golf: gol, yukon: yuk, solutionLengths: lengths, levels: levels)
    }

    private struct File: Decodable {
        struct Entry: Decodable { let seed: UInt64; let loesung: Int?; let stufe: Int? }
        let partien: [Entry]
    }

    func seeds(draw: Int) -> [UInt64] { seeds[draw == 3 ? 3 : 1] ?? [] }

    /// Lösbare Partien eines Modus; leer = nur Zufall (Spider 4 Farben, FreeCell hat Nummern)
    func seeds(for mode: GameMode) -> [UInt64] {
        switch mode.kind {
        case .klondike: seeds(draw: mode.option)
        case .spider: spiderSeeds[mode.option] ?? []
        case .freecell: []
        case .pyramid: pyramidSeeds
        case .tripeaks: tripeaksSeeds
        case .golf: golfSeeds
        case .yukon: yukonSeeds
        }
    }

    // MARK: Partie per Nummer

    /// Nummer einer Partie: Platz in der Liste + 1 (je Liste eigene Nummern), bei FreeCell die Microsoft-Nummer; nil = nicht in der Liste
    func number(mode: GameMode, seed: UInt64) -> Int? {
        if mode.kind == .freecell { return seed >= 1 && seed <= UInt64(FreeCellRules.maxNumber) ? Int(seed) : nil }
        return seeds(for: mode).firstIndex(of: seed).map { $0 + 1 }
    }

    /// Größte Nummer eines Modus; nil = keine Nummern (Spider mit 4 Farben: nur Zufall)
    func maxNumber(mode: GameMode) -> Int? {
        if mode.kind == .freecell { return FreeCellRules.maxNumber }
        let n = seeds(for: mode).count
        return n > 0 ? n : nil
    }

    /// Partie zu einer eingegebenen Nummer; nil = ungültig (außerhalb 1…N, bei FreeCell auch die unlösbare 11982)
    func seed(mode: GameMode, number: Int) -> UInt64? {
        guard let max = maxNumber(mode: mode), number >= 1, number <= max else { return nil }
        if mode.kind == .freecell { return FreeCellRules.unsolvable.contains(number) ? nil : UInt64(number) }
        return seeds(for: mode)[number - 1]
    }

    /// Zufällige lösbare Partie; möglichst keine der zuletzt gespielten.
    func pick(draw: Int, recent: [UInt64], using rng: inout some RandomNumberGenerator) -> UInt64? {
        pick(mode: .klondike(draw), recent: recent, using: &rng)
    }

    /// Name der Liste im Bundle (`ziehen1`, `ziehen3`, `spider1`, `spider2`); nil = keine Liste (Spider 4 Farben, FreeCell)
    func listName(for mode: GameMode) -> String? {
        switch mode.kind {
        case .klondike: mode.option == 3 ? "ziehen3" : "ziehen1"
        case .spider: [1, 2].contains(mode.option) ? "spider\(mode.option)" : nil
        case .freecell: nil
        case .pyramid: "pyramid"
        case .tripeaks: "tripeaks"
        case .golf: "golf"
        case .yukon: "yukon"
        }
    }

    /// Hat der Modus Schwierigkeitsstufen (nur Modi mit Partie-Liste)?
    func hasLevels(_ mode: GameMode) -> Bool { listName(for: mode).map { levels[$0]?.isEmpty == false } ?? false }

    /// Stufe (1 leicht … 3 schwer) einer Partie; nil, wenn der Modus keine Liste hat
    func level(mode: GameMode, seed: UInt64) -> Int? { listName(for: mode).flatMap { levels[$0]?[seed] } }

    /// Lösbare Partien einer Stufe (0 = gemischt = alle) in der Reihenfolge der Liste
    func seeds(for mode: GameMode, level: Int) -> [UInt64] {
        let all = seeds(for: mode)
        guard level != 0, let name = listName(for: mode), let map = levels[name] else { return all }
        return all.filter { map[$0] == level }
    }

    func pick(mode: GameMode, level: Int = 0, recent: [UInt64], using rng: inout some RandomNumberGenerator) -> UInt64? {
        if mode.kind == .freecell {
            // Microsoft-Nummern 1…32000 ohne 11982 (unlösbar), möglichst keine der letzten 200
            let blocked = Set(recent.suffix(Self.recentLimit))
            for _ in 0..<100 {
                let n = UInt64.random(in: 1...UInt64(FreeCellRules.maxNumber), using: &rng)
                if !FreeCellRules.unsolvable.contains(Int(n)), !blocked.contains(n) { return n }
            }
            return 1
        }
        var all = seeds(for: mode, level: level)
        if all.isEmpty { all = seeds(for: mode) }          // Stufe leer (z. B. kleine Liste): alle Partien
        guard !all.isEmpty else { return nil }
        let blocked = Set(recent.suffix(Self.recentLimit))
        let free = all.filter { !blocked.contains($0) }
        return (free.isEmpty ? all : free).randomElement(using: &rng)
    }

    /// Lösungslänge der Tagesspiel-Partie (Klondike: ziehen1, Spider: spider2)
    func solutionLength(kind: GameKind, seed: UInt64) -> Int? {
        solutionLengths[kind == .spider ? "spider2" : kind == .pyramid ? "pyramid" : kind == .tripeaks ? "tripeaks" : kind == .golf ? "golf" : kind == .yukon ? "yukon" : "ziehen1"]?[seed]
    }

    // MARK: Tagesspiel

    /// Tage seit dem 01.01.2026 (negativ davor)
    static func daysSinceEpoch(year: Int, month: Int, day: Int, calendar: Calendar = .solitaer) -> Int {
        var cal = calendar
        cal.timeZone = calendar.timeZone
        let start = cal.date(from: DateComponents(year: dailyEpoch.year, month: dailyEpoch.month, day: dailyEpoch.day))!
        let date = cal.date(from: DateComponents(year: year, month: month, day: day))!
        return cal.dateComponents([.day], from: start, to: date).day!
    }

    /// Seed des Tagesspiels: Klondike ziehen1, Spider spider2 (immer 2 Farben): partien[(Tage seit 01.01.2026) mod Anzahl], Rest nie negativ.
    func dailySeed(daysSinceEpoch t: Int, kind: GameKind = .klondike) -> UInt64? {
        if kind == .freecell { return UInt64(FreeCellRules.dailyNumber(days: t)) }
        let list = kind == .spider ? seeds(for: .spider(2)) : kind == .pyramid ? pyramidSeeds : kind == .tripeaks ? tripeaksSeeds : kind == .golf ? golfSeeds : kind == .yukon ? yukonSeeds : seeds(draw: 1)
        guard !list.isEmpty else { return nil }
        return list[((t % list.count) + list.count) % list.count]
    }

    func dailySeed(for date: Date, kind: GameKind = .klondike, calendar: Calendar = .solitaer) -> UInt64? {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return dailySeed(daysSinceEpoch: Self.daysSinceEpoch(year: c.year!, month: c.month!, day: c.day!, calendar: calendar), kind: kind)
    }

    // MARK: Tagesspiel in drei Stufen (Klondike 1 Karte, Spider 2 Farben)

    /// Spiele, die zusätzlich zum „Gemischten“ ein leichtes und ein schweres Tagesspiel haben
    static func hasDailyLevels(_ kind: GameKind) -> Bool { kind == .klondike || kind == .spider }

    /// Leicht (1) oder Schwer (3): Partie = Liste der Stufe in Listenreihenfolge [Tage mod Länge]. Gemischt (nil) ist das bisherige Tagesspiel.
    func dailySeed(daysSinceEpoch t: Int, kind: GameKind, level: Int?) -> UInt64? {
        guard let level, Self.hasDailyLevels(kind) else { return dailySeed(daysSinceEpoch: t, kind: kind) }
        let teil = seeds(for: kind == .spider ? .spider(2) : .klondike(1), level: level)
        guard !teil.isEmpty else { return nil }
        return teil[((t % teil.count) + teil.count) % teil.count]
    }

    func dailySeed(for date: Date, kind: GameKind, level: Int?, calendar: Calendar = .solitaer) -> UInt64? {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return dailySeed(daysSinceEpoch: Self.daysSinceEpoch(year: c.year!, month: c.month!, day: c.day!, calendar: calendar), kind: kind, level: level)
    }
}
