// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Regeln für Game Center (1.0): Welche Partie landet in welcher Bestenliste, welche Erfolge gibt es und wie weit ist jeder.
/// Reine Logik ohne Game Kit, damit sie ohne Gerät und Simulator getestet werden kann. Die Hülle schickt die Ergebnisse weiter.
public enum GameCenterRegeln {

    // MARK: Bestenlisten

    public struct Bestenliste: Equatable, Sendable {
        public enum Art: Sendable { case zeit, punkte }
        /// Kennung in App Store Connect (nie ändern, nachdem sie dort angelegt ist).
        public let id: String
        public let art: Art
        /// Spiel-IDs aus dem Katalog, die in diese Liste melden.
        public let spiele: [String]
        public let titelDE: String
        public let titelEN: String
    }

    /// Passend zu den 25 Startspielen: Rätsel nach Zeit, Würfelspiele nach Punkten. Brett- und Kartenspiele gegeneinander haben keine Liste.
    public static let bestenlisten: [Bestenliste] = [
        .init(id: "partie.zeit.sudoku", art: .zeit, spiele: ["sudoku", "sudoku-neu"], titelDE: "Sudoku: Schnellste Zeit", titelEN: "Sudoku: Fastest time"),
        .init(id: "partie.zeit.minensuche", art: .zeit, spiele: ["minensuche"], titelDE: "Minensuche: Schnellste Zeit", titelEN: "Minesweeper: Fastest time"),
        .init(id: "partie.zeit.kakuro", art: .zeit, spiele: ["kakuro"], titelDE: "Kakuro: Schnellste Zeit", titelEN: "Kakuro: Fastest time"),
        .init(id: "partie.zeit.schiebepuzzle", art: .zeit, spiele: ["schiebepuzzle"], titelDE: "Schiebepuzzle: Schnellste Zeit", titelEN: "Sliding puzzle: Fastest time"),
        .init(id: "partie.zeit.irrgang", art: .zeit, spiele: ["irrgang"], titelDE: "Irrgang: Schnellste Zeit", titelEN: "Maze: Fastest time"),
        .init(id: "partie.punkte.yacht", art: .punkte, spiele: ["yacht", "yacht-neu"], titelDE: "Yacht: Höchste Punktzahl", titelEN: "Yacht: High score"),
        .init(id: "partie.punkte.10k", art: .punkte, spiele: ["10k", "10k-neu"], titelDE: "10k: Höchste Punktzahl", titelEN: "10k: High score"),
        .init(id: "partie.punkte.chicago", art: .punkte, spiele: ["chicago"], titelDE: "Chicago: Höchste Punktzahl", titelEN: "Chicago: High score"),
        .init(id: "partie.punkte.pokerwurf", art: .punkte, spiele: ["pokerwurf"], titelDE: "Pokerwurf: Höchste Punktzahl", titelEN: "Poker dice: High score"),
    ]

    public struct Meldung: Equatable, Sendable {
        public let bestenliste: String
        public let wert: Int
    }

    /// Kürzeste Zeit, die als Bestenlisten-Eintrag zählt (Schutz vor Fehlbuchungen).
    public static let mindestZeit = 5

    /// Was eine beendete Partie in die Bestenlisten schickt (höchstens ein Eintrag).
    /// Zeit: nur gewonnene Einzelpartien. Punkte: die Punkte von „Ich“, bei Einzelspielen die des einzigen Teilnehmers.
    public static func meldung(fuer e: PartieErgebnis, ich: UUID?) -> Meldung? {
        guard let liste = bestenlisten.first(where: { $0.spiele.contains(e.spiel) }) else { return nil }
        switch liste.art {
        case .zeit:
            guard e.teilnehmer.count == 1, e.teilnehmer[0].platz == 1 else { return nil }
            let s = Kennzahl.ganz(e.dauer.rounded())
            return s >= mindestZeit ? Meldung(bestenliste: liste.id, wert: s) : nil
        case .punkte:
            let eigene: PartieErgebnis.Teilnehmer?
            if let ich, let t = e.teilnehmer.first(where: { $0.spielerID == ich }) { eigene = t }
            else if e.teilnehmer.count == 1 { eigene = e.teilnehmer[0] }
            else { eigene = nil }
            guard let p = eigene?.punkte, p > 0 else { return nil }
            return Meldung(bestenliste: liste.id, wert: p)
        }
    }

    // MARK: Erfolge

    public struct Erfolg: Equatable, Sendable {
        public let id: String
        public let titelDE: String
        public let titelEN: String
        public let beschreibungDE: String
        public let beschreibungEN: String
        public let punkte: Int
    }

    /// Erfolge für die ganze Sammlung. Summe der Punkte: 200 (Apple erlaubt höchstens 1000).
    public static let erfolge: [Erfolg] = [
        .init(id: "partie.erfolg.erstePartie", titelDE: "Erste Partie", titelEN: "First game", beschreibungDE: "Spiele eine Partie zu Ende.", beschreibungEN: "Finish a game.", punkte: 10),
        .init(id: "partie.erfolg.ersterSieg", titelDE: "Erster Sieg", titelEN: "First win", beschreibungDE: "Gewinne eine Partie.", beschreibungEN: "Win a game.", punkte: 10),
        .init(id: "partie.erfolg.zehnSiege", titelDE: "Zehn Siege", titelEN: "Ten wins", beschreibungDE: "Gewinne zehn Partien.", beschreibungEN: "Win ten games.", punkte: 20),
        .init(id: "partie.erfolg.fuenfzigPartien", titelDE: "Fünfzig Partien", titelEN: "Fifty games", beschreibungDE: "Spiele fünfzig Partien.", beschreibungEN: "Play fifty games.", punkte: 20),
        .init(id: "partie.erfolg.hundertPartien", titelDE: "Hundert Partien", titelEN: "A hundred games", beschreibungDE: "Spiele hundert Partien.", beschreibungEN: "Play a hundred games.", punkte: 30),
        .init(id: "partie.erfolg.zehnSpiele", titelDE: "Zehn Spiele ausprobiert", titelEN: "Ten games tried", beschreibungDE: "Spiele zehn verschiedene Spiele.", beschreibungEN: "Play ten different games.", punkte: 20),
        .init(id: "partie.erfolg.alleArten", titelDE: "Alle Arten gespielt", titelEN: "All kinds played", beschreibungDE: "Spiele Rätsel, Wort, Karten, Brett und Würfel.", beschreibungEN: "Play puzzle, word, card, board and dice games.", punkte: 30),
        .init(id: "partie.erfolg.weltreise", titelDE: "Weltreise", titelEN: "World tour", beschreibungDE: "Spiele Spiele aus fünf Ländern.", beschreibungEN: "Play games from five countries.", punkte: 20),
        .init(id: "partie.erfolg.tagesSerie", titelDE: "Sieben Tage in Folge", titelEN: "Seven days in a row", beschreibungDE: "Schaffe die Tagesaufgabe sieben Tage hintereinander.", beschreibungEN: "Complete the daily challenge seven days in a row.", punkte: 30),
        .init(id: "partie.erfolg.spielerrunde", titelDE: "Spielerrunde", titelEN: "Game night", beschreibungDE: "Spiele eine Partie mit mindestens drei Mitspielern.", beschreibungEN: "Play a game with at least three players.", punkte: 10),
    ]

    /// Angaben, die die Hülle zu einem Spiel kennt.
    public struct Spielangaben: Sendable {
        public let gattung: String?
        public let land: String?
        public init(gattung: String?, land: String?) { self.gattung = gattung; self.land = land }
    }

    /// Wie weit jeder Erfolg ist (0 bis 100) für die Partien von „Ich“. Partien anderer Personen zählen nicht.
    /// `tagesSerie`: Tage in Folge mit geschaffter Tagesaufgabe. `angaben`: Gattung („raetsel“ …) und Land je Spiel-ID.
    public static func fortschritt(ereignisse: [PartieErgebnis], ich: UUID?, tagesSerie: Int, angaben: (String) -> Spielangaben) -> [String: Double] {
        // Partien von „Ich“: ohne Zuordnung (alte Partien) zählen alle, wie in der Statistik.
        let meine = ereignisse.filter { e in
            guard let ich else { return true }
            return e.teilnehmer.contains { $0.spielerID == ich } || !e.teilnehmer.contains { $0.spielerID != nil }
        }.filter { !$0.istAbbruch }
        func gewonnen(_ e: PartieErgebnis) -> Bool {
            guard !e.istRemis else { return false }
            if let ich, e.teilnehmer.contains(where: { $0.spielerID == ich }) { return e.teilnehmer.contains { $0.platz == 1 && $0.spielerID == ich } }
            return e.teilnehmer.count == 1 && e.teilnehmer[0].platz == 1
        }
        let partien = meine.count
        let siege = meine.filter(gewonnen).count
        let spiele = Set(meine.map(\.spiel))
        let gattungen = Set(spiele.compactMap { angaben($0).gattung }).intersection(["raetsel", "wort", "karten", "brett", "wuerfel"])
        let laender = Set(spiele.compactMap { angaben($0).land }.filter { !$0.isEmpty })
        let runde = meine.contains { $0.teilnehmer.count >= 3 }

        func anteil(_ ist: Int, _ ziel: Int) -> Double { min(100, Double(ist) / Double(ziel) * 100) }
        return [
            "partie.erfolg.erstePartie": anteil(partien, 1),
            "partie.erfolg.ersterSieg": anteil(siege, 1),
            "partie.erfolg.zehnSiege": anteil(siege, 10),
            "partie.erfolg.fuenfzigPartien": anteil(partien, 50),
            "partie.erfolg.hundertPartien": anteil(partien, 100),
            "partie.erfolg.zehnSpiele": anteil(spiele.count, 10),
            "partie.erfolg.alleArten": anteil(gattungen.count, 5),
            "partie.erfolg.weltreise": anteil(laender.count, 5),
            "partie.erfolg.tagesSerie": anteil(tagesSerie, 7),
            "partie.erfolg.spielerrunde": runde ? 100 : 0,
        ]
    }
}
