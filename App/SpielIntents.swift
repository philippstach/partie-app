// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import AppIntents
import SwiftUI
import SpieleKern

/// Ein Spiel der Sammlung als Siri-/Kurzbefehle-Objekt (E1). Die ID ist die Spiel-ID aus `SpielKatalog` und bleibt über Starts stabil.
struct SpielEntitaet: AppEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Spiel"
    static let defaultQuery = SpielAbfrage()

    let id: String
    let name: String
    /// Spielart („Würfelspiel“ …) als Untertitel und Symbol des Spiels, für Siri-Vorschläge, Kurzbefehle und Spotlight.
    let untertitel: String
    let symbol: String
    /// Für den Spotlight-Eintrag (iOS 18): Kurzbeschreibung und Suchwörter, schon beim Anlegen berechnet.
    let beschreibung: String
    let suchwoerter: [String]

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", subtitle: "\(untertitel)", image: .init(systemName: symbol))
    }

    @MainActor
    init?(id: String) {
        guard let m = SpielKatalog.modul(id) else { return nil }
        self.init(modul: m)
    }

    @MainActor
    init(modul: any SpielModul) {
        id = modul.id; name = modul.name; untertitel = modul.gattung.anzeigeName; symbol = modul.symbol
        let inhalt = SpielSpotlight.inhalt(modul)
        beschreibung = inhalt.beschreibung; suchwoerter = inhalt.suchwoerter
    }
}

struct SpielAbfrage: EntityStringQuery {
    @MainActor
    func entities(for identifiers: [String]) async throws -> [SpielEntitaet] {
        identifiers.compactMap { SpielEntitaet(id: $0) }
    }

    @MainActor
    func entities(matching string: String) async throws -> [SpielEntitaet] {
        SpielSuchtext.treffer(string, in: SpielKatalog.sichtbar.filter { Modi.erlaubt($0.id) }).map { SpielEntitaet(modul: $0) }
    }

    @MainActor
    func suggestedEntities() async throws -> [SpielEntitaet] {
        SpielKatalog.sichtbar.filter { Modi.erlaubt($0.id) }.map { SpielEntitaet(modul: $0) }   // Kinder-Modus: gesperrte Spiele nicht vorschlagen
    }
}

/// KI-8: Siri und Kurzbefehle finden ein Spiel auch über Stichworte und Namen in anderen Sprachen
/// („Vier gewinnt“ → Viererreihe, „Kniffel“ → Yacht), nicht nur über den Namen.
enum SpielSuchtext {
    static func glatt(_ s: String) -> String {
        s.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current).trimmingCharacters(in: .whitespaces)
    }

    /// Wörter, unter denen ein Spiel gefunden wird: Name, Spielart, Stichworte, übersetzte Namen.
    @MainActor
    static func woerter(_ m: any SpielModul) -> [String] {
        [m.name, m.gattung.anzeigeName] + SpielMetadaten.info(m.id).stichworte + SpielMetadaten.uebersetzt(m.id, gattung: m.gattung)
    }

    /// Treffer in der Reihenfolge: Name beginnt mit dem Text, Name enthält ihn, Stichwort enthält ihn.
    @MainActor
    static func treffer(_ text: String, in module: [any SpielModul]) -> [any SpielModul] {
        let t = glatt(text)
        guard !t.isEmpty else { return module }
        var stufe: [(Int, Int, any SpielModul)] = []
        for (i, m) in module.enumerated() {
            let name = glatt(m.name)
            if name.hasPrefix(t) { stufe.append((0, i, m)) }
            else if name.contains(t) { stufe.append((1, i, m)) }
            else if woerter(m).contains(where: { glatt($0).contains(t) }) { stufe.append((2, i, m)) }
        }
        return stufe.sorted { ($0.0, $0.1) < ($1.0, $1.1) }.map { $0.2 }
    }
}

/// Antwort von Siri und Kurzbefehlen, wenn der Kinder-Modus das Spiel sperrt.
struct KinderModusGesperrt: Error, CustomLocalizedStringResourceConvertible {
    var localizedStringResource: LocalizedStringResource { "Dieses Spiel ist im Kinder-Modus gesperrt. Gib es in den Einstellungen unter „Modi“ frei." }
}

extension Modi {
    /// Wirft `KinderModusGesperrt`, wenn das Spiel im Kinder-Modus nicht geöffnet werden darf.
    static func pruefeOeffnen(_ id: String, kinder: Bool = Modi.kinder, gesperrt: Set<String> = Modi.gesperrt) throws {
        if !erlaubt(id, kinder: kinder, gesperrt: gesperrt) { throw KinderModusGesperrt() }
    }
}

/// „Spiele <Spiel> in Partie“: öffnet das Spiel direkt auf seiner Startseite.
struct SpielOeffnenIntent: AppIntent {
    static let title: LocalizedStringResource = "Spiel öffnen"
    static let description = IntentDescription("Öffnet ein Spiel der Sammlung.")
    static let openAppWhenRun = true

    @Parameter(title: "Spiel") var spiel: SpielEntitaet

    @MainActor
    func perform() async throws -> some IntentResult {
        try Modi.pruefeOeffnen(spiel.id)
        AktionsPost.oeffnen(spiel.id)
        return .result()
    }
}

/// „Zufälliges Spiel in Partie“: wählt ein Spiel aus der Sammlung.
struct ZufallsSpielIntent: AppIntent {
    static let title: LocalizedStringResource = "Zufälliges Spiel"
    static let description = IntentDescription("Öffnet ein zufällig gewähltes Spiel.")
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        if let m = SpielKatalog.sichtbar.randomElement() { AktionsPost.oeffnen(m.id) }
        return .result()
    }
}

/// „Letztes Spiel in Partie“: setzt dort fort, wo zuletzt gespielt wurde.
struct LetztesSpielIntent: AppIntent {
    static let title: LocalizedStringResource = "Zuletzt gespieltes Spiel"
    static let description = IntentDescription("Öffnet das Spiel, das du zuletzt gespielt hast.")
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        if let id = UserDefaults.standard.string(forKey: "zuletztGespielt"), SpielKatalog.modul(id) != nil {
            try Modi.pruefeOeffnen(id)
            AktionsPost.oeffnen(id)
        }
        return .result()
    }
}

/// KI-8: Was Siri oder ein Kurzbefehl für „Neue Partie“ aus den Angaben macht. Reine Rechnung, damit sie sich prüfen lässt.
enum NeuePartieWunsch {
    /// Spiele der Version 1.0, die Computergegner kennen (Stand: `computerErlaubt: true` im SpielRahmen des Spiels).
    /// Die Hülle prüft beim Start noch einmal selbst; diese Liste dient nur der ehrlichen Antwort von Siri.
    static let computerSpiele: Set<String> = Set([
        "maumau", "schwimmen", "elferraus", "romme", "mogeln", "siebzehnundvier", "herzensjagd", "yacht", "schocken", "10k",
        "maexchen", "chicago", "pokerwurf", "koenigsweg", "viererreihe", "rauswurf", "muehle",
    ].map(SpielKatalog.kennung))

    enum Hinweis: Equatable {
        case keinComputer          // das Spiel kennt keine Computergegner
        case einzelspiel           // das Spiel ist ein Einzelspiel; Zahlen werden nicht gebraucht
        case gekuerzt              // mehr Plätze gewünscht, als das Spiel hat
    }

    /// `spielerzahl`: Grenzen des Spiels; `computerErlaubt`: kennt das Spiel Computergegner.
    static func pruefen(menschen: Int?, computer: Int?, spielerzahl: ClosedRange<Int>, computerErlaubt: Bool) -> (wunsch: StartWunsch, hinweis: Hinweis?) {
        let m = menschen.map { max(1, $0) }
        let c = max(0, computer ?? 0)
        if spielerzahl.upperBound == 1 {
            return (StartWunsch(), (m ?? 1) > 1 || c > 0 ? .einzelspiel : nil)
        }
        if c > 0 && !computerErlaubt { return (StartWunsch(menschen: m, computer: 0), .keinComputer) }
        let summe = (m ?? (c > 0 ? 1 : 0)) + c
        return (StartWunsch(menschen: m, computer: c), summe > spielerzahl.upperBound ? .gekuerzt : nil)
    }
}

/// Gemeinsamer Ablauf von „Neue Partie“ und „… gegen den Computer“.
@MainActor
enum NeuePartieStarter {
    static func starten(_ spiel: SpielEntitaet, menschen: Int?, computer: Int?) throws -> IntentDialog {
        try Modi.pruefeOeffnen(spiel.id)
        guard let modul = SpielKatalog.modul(spiel.id) else { return IntentDialog("Dieses Spiel gibt es nicht.") }
        let kennung = SpielKatalog.kennung(modul.id)
        let (wunsch, hinweis) = NeuePartieWunsch.pruefen(menschen: menschen, computer: computer, spielerzahl: modul.spielerzahl,
                                                         computerErlaubt: NeuePartieWunsch.computerSpiele.contains(kennung))
        StartWunschPost.merken(kennung, wunsch)
        AktionsPost.oeffnen(modul.id)
        switch hinweis {
        case .keinComputer: return IntentDialog("\(modul.name) hat keinen Computergegner. Ich starte ohne.")
        case .einzelspiel: return IntentDialog("\(modul.name) spielst du allein. Ich starte eine neue Partie.")
        case .gekuerzt: return IntentDialog("So viele Plätze hat \(modul.name) nicht. Ich starte mit der größtmöglichen Runde.")
        case nil: return IntentDialog("Ich starte eine neue Partie \(modul.name).")
        }
    }
}

/// „Neue Partie <Spiel> in Partie“: startet gleich eine frische Partie, auf Wunsch mit Spielerzahl und Computergegnern.
/// Läuft schon eine Partie des Spiels, fragt die App wie bei „Neu starten“, bevor sie verworfen wird.
struct NeuePartieIntent: AppIntent {
    static let title: LocalizedStringResource = "Neue Partie"
    static let description = IntentDescription("Startet eine neue Partie eines Spiels, auf Wunsch mit Spielerzahl und Computergegnern.")
    static let openAppWhenRun = true

    @Parameter(title: "Spiel") var spiel: SpielEntitaet
    @Parameter(title: "Menschen", description: "Wie viele Menschen mitspielen.")
    var menschen: Int?
    @Parameter(title: "Computer", description: "Wie viele Computergegner mitspielen.")
    var computer: Int?

    static var parameterSummary: some ParameterSummary {
        Summary("Neue Partie \(\.$spiel)") {
            \.$menschen
            \.$computer
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        .result(dialog: try NeuePartieStarter.starten(spiel, menschen: menschen, computer: computer))
    }
}

/// „<Spiel> gegen den Computer in Partie“: neue Partie, ein Mensch gegen einen Computer.
struct GegenComputerIntent: AppIntent {
    static let title: LocalizedStringResource = "Gegen den Computer"
    static let description = IntentDescription("Startet eine neue Partie gegen den Computer.")
    static let openAppWhenRun = true

    @Parameter(title: "Spiel") var spiel: SpielEntitaet

    static var parameterSummary: some ParameterSummary { Summary("\(\.$spiel) gegen den Computer") }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        .result(dialog: try NeuePartieStarter.starten(spiel, menschen: 1, computer: 1))
    }
}

/// „Tagesrätsel in Partie“: öffnet das nächste Tagesrätsel, das heute noch offen ist.
struct TagesraetselIntent: AppIntent {
    static let title: LocalizedStringResource = "Tagesrätsel"
    static let description = IntentDescription("Öffnet das nächste Tagesrätsel, das du heute noch nicht gelöst hast.")
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        if let id = WidgetAbgleich.naechstesTagesraetsel() {
            try Modi.pruefeOeffnen(id)
            AktionsPost.oeffnen(id)
        }
        return .result()
    }
}

struct PartieKurzbefehle: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: SpielOeffnenIntent(),
                    phrases: ["Spiele \(\.$spiel) in \(.applicationName)", "Öffne \(\.$spiel) in \(.applicationName)", "Play \(\.$spiel) in \(.applicationName)",
                              "Jugar a \(\.$spiel) en \(.applicationName)", "Jouer à \(\.$spiel) dans \(.applicationName)"],
                    shortTitle: "Spiel öffnen", systemImageName: "gamecontroller")
        AppShortcut(intent: NeuePartieIntent(),
                    phrases: ["Neue Partie \(\.$spiel) in \(.applicationName)", "Starte eine neue Partie \(\.$spiel) in \(.applicationName)",
                              "New game of \(\.$spiel) in \(.applicationName)", "Nueva partida de \(\.$spiel) en \(.applicationName)",
                              "Nouvelle partie de \(\.$spiel) dans \(.applicationName)"],
                    shortTitle: "Neue Partie", systemImageName: "plus.circle")
        AppShortcut(intent: GegenComputerIntent(),
                    phrases: ["\(\.$spiel) gegen den Computer in \(.applicationName)", "\(\.$spiel) against the computer in \(.applicationName)",
                              "\(\.$spiel) contra el ordenador en \(.applicationName)", "\(\.$spiel) contre l’ordinateur dans \(.applicationName)"],
                    shortTitle: "Gegen den Computer", systemImageName: "cpu")
        AppShortcut(intent: TagesraetselIntent(),
                    phrases: ["Tagesrätsel in \(.applicationName)", "Daily puzzle in \(.applicationName)",
                              "Acertijo del día en \(.applicationName)", "Énigme du jour dans \(.applicationName)"],
                    shortTitle: "Tagesrätsel", systemImageName: "calendar")
        AppShortcut(intent: ZufallsSpielIntent(),
                    phrases: ["Zufälliges Spiel in \(.applicationName)", "Überrasch mich in \(.applicationName)", "Random game in \(.applicationName)",
                              "Juego aleatorio en \(.applicationName)", "Jeu au hasard dans \(.applicationName)"],
                    shortTitle: "Zufälliges Spiel", systemImageName: "dice")
        AppShortcut(intent: LetztesSpielIntent(),
                    phrases: ["Letztes Spiel in \(.applicationName)", "Weiterspielen in \(.applicationName)", "Resume \(.applicationName)",
                              "Continuar en \(.applicationName)", "Reprendre dans \(.applicationName)"],
                    shortTitle: "Weiterspielen", systemImageName: "play.circle")
    }
}
