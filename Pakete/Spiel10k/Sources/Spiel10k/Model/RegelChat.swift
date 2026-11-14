// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import SpieleKern
#if canImport(FoundationModels)
import FoundationModels
#endif

/// Regel-Chat von 10k auf dem Gerüst aus SpieleKern (KI-2). Gerüst (Status, Sitzung, Motor, Zahlen-Wächter,
/// Apple-Modell) liegt in `SpieleKern/RegelChat`; hier bleibt, was nur 10k hat: Regeln, Rechen-Tools,
/// Direktantworten, Fakten zur Frage. Die Anweisungen und der Prompt sind wortgleich zu vorher.
/// Punkte rechnet nie das Modell, sondern `RegelTools`. Alles Apple-Spezifische hinter `#available(iOS 26, *)`.

nonisolated extension RegelChatStatus {
    /// Philipps Regel (06.10.): Besteht der Chat die Abnahme (≥ 38/40, 0 falsche Zahlen, greedy und
    /// 2 Sampling-Läufe), wird hier `false` gesetzt – dann ist er ohne Schalter sichtbar.
    static let experimentell = false

    /// 10k prüft nur das Modell (nicht die App-Sprache) – wie vor dem Umzug.
    static var zehnk: RegelChatStatus { aktuell(nurDeutscheApp: false) }

    /// Knopf in Regeln und im Spiel zeigen?
    static func sichtbar(experimente: Bool) -> Bool {
        zehnk != .hidden && (!experimentell || experimente)
    }
}

/// Das Regelwissen von 10k für das Gerüst. Die Abschnitte stehen absichtlich nicht im Prompt (wie vorher):
/// Das Modell holt sie bei Bedarf über das Werkzeug `regel_nachschlagen`; für den Zahlen-Wächter zählen sie mit.
nonisolated struct ZehnkRegelWissen: RegelWissen {
    let rules: GameRules
    /// Aus einem laufenden Spiel geöffnet (Beispielfragen zum Wurf statt zu den Grundregeln)
    let imSpiel: Bool
    init(rules: GameRules, imSpiel: Bool = false) { self.rules = rules; self.imSpiel = imSpiel }

    let spielID = "10k"
    let name = "Zehntausend"   // Fund 77: Anzeigename (Chat-Text „Stell eine Frage zu …“), nicht die Kurzform
    var abschnitte: [RegelAbschnitt] { [] }
    /// Blatt 12: drei Beispielfragen auf dem leeren Chat-Blatt
    var beispielfragen: [String] {
        imSpiel
            ? ["Was zählt mein Wurf?", "Was bringen drei Einsen?", "Wie funktioniert Übernehmen?"]
            : ["Was bringen drei Einsen?", "Was ist eine Niete?", "Wie funktioniert Übernehmen?"]
    }
    var chatGrenzen: RegelChatGrenzen { ZehnkRegelChat.grenzen }
    /// 10k prüft nur das Modell, nicht die App-Sprache (wie vor dem Umzug)
    var nurDeutscheApp: Bool { false }
    /// Das Modell mit den vier Rechen-Werkzeugen; im Simulator mit Startargument die Attrappe
    func sprachmodell() -> (any RegelChatSprachmodell)? {
        if RegelChatUmgebung.attrappeAngefordert { return RegelChatUmgebung.attrappe() }
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *) { return ZehnkRegelChat.modell(rules) }
        #endif
        return nil
    }
    var eigeneAnweisungen: String? { Self.anweisungen }
    var aktiveRegeln: String { RegelZusammenfassung.text(rules) }
    var begriffe: String { RegelChatWissen.begriffe }
    var beispiele: String { RegelChatWissen.beispiele(rules) }
    var waechterQuellen: [String] { RulesText.sections(for: rules).map { "\($0.0) \($0.1)" } }
    func direktAntwort(auf frage: String) -> String? { RegelChatDirekt.antwort(for: frage, rules: rules) }
    func zusatz(zu frage: String) -> String? { RegelChatKontext.zusatz(for: frage, rules: rules) }
    func ersatzAntwort(auf frage: String) -> String? { RegelChatKontext.regelAntwort(for: frage, rules: rules) }

    static let anweisungen = """
    Du bist die Regelhilfe der App „10k – Würfelspiel“ (Zehntausend).
    Du beantwortest nur Fragen zu den Regeln von 10k in dieser App.
    Grundlage sind ausschließlich die AKTUELLEN REGELN unten und das Tool
    regel_nachschlagen. Andere Würfelspiele und Varianten aus dem Internet
    gelten hier nicht. Erfinde keine Regeln. Was nicht in den Regeln steht,
    gibt es in diesem Spiel nicht.

    Punkte rechnest du nie selbst. Für jede Punktzahl rufst du ein Tool auf:
    wertung_berechnen, beste_auswahl oder zug_berechnen. Nenne die Zahl, die
    das Tool liefert, und erkläre sie kurz.

    Antworte auf Deutsch, in der Du-Form, freundlich und kurz: höchstens vier
    Sätze. Schreib Zahlen immer als Ziffern (5, nicht „fünf“). Steht in den
    FAKTEN ein ERGEBNIS, antworte mit genau dieser Punktzahl in einem Satz und
    nenne keine anderen Punktzahlen. Sprich alle Spielenden an, ohne Geschlecht („wer würfelt“, „die
    nächste Person“).

    Bist du unsicher oder fehlt eine Angabe (zum Beispiel, ob alle Würfel
    geworfen wurden), sag das offen und frag nach.

    Geht es nicht um 10k-Regeln, sag freundlich, dass du nur Fragen zu den
    Regeln von 10k beantwortest.
    """
}

/// Das Regelwissen von 10k für den `SpielRahmen` („Frag nach den Regeln“ in Menü und auf der Regelseite) mit den
/// zuletzt gespeicherten Regeln der Partie.
nonisolated public enum ZehnKRegelAuskunft {
    public static func wissen() -> any RegelWissen {
        ZehnkRegelWissen(rules: NeuAblage.regeln())   // T-Fund 8: die Regeln liegen in der Suite von 10k-neu, nicht in `.standard`
    }
}

/// Grenzen wie vorher: kein Abschnittsauswahl-Kürzen, Prompt bis 8000 Zeichen (Test: Anweisungen < 8000).
nonisolated enum ZehnkRegelChat {
    static let grenzen = RegelChatGrenzen(maxZeichenGesamt: 8000)
    /// Wörter, die den Inhaltsfilter auslösen können, mit neutralerem Ersatz (zweiter Versuch)
    static let weichmacher = ["Strafe": "Punktabzug"]
}

#if canImport(FoundationModels)

// MARK: - Tools

@available(iOS 26.0, *)
nonisolated struct WertungTool: Tool {
    let name = "wertung_berechnen"
    let description = "Berechnet die Punkte für Würfel, die aus EINEM Wurf rausgelegt werden."
    let rules: GameRules

    @Generable
    struct Arguments {
        @Guide(description: "Augen der rausgelegten Würfel, jeweils 1 bis 6")
        var wuerfel: [Int]
        @Guide(description: "true, wenn in diesem Wurf alle Würfel gleichzeitig geworfen wurden")
        var alleGeworfen: Bool
        @Guide(description: "true, wenn es der erste Wurf nach einer Übernahme ist")
        var nachUebernahme: Bool
    }

    func call(arguments: Arguments) async throws -> String {
        RegelTools.wertung(arguments.wuerfel, alleGeworfen: arguments.alleGeworfen,
                           nachUebernahme: arguments.nachUebernahme, rules: rules)
    }
}

@available(iOS 26.0, *)
nonisolated struct BesteAuswahlTool: Tool {
    let name = "beste_auswahl"
    let description = "Zeigt für einen ganzen Wurf, welche Würfel am meisten Punkte bringen, oder ob es eine Niete ist."
    let rules: GameRules

    @Generable
    struct Arguments {
        @Guide(description: "Augen aller geworfenen Würfel, jeweils 1 bis 6")
        var wuerfel: [Int]
        @Guide(description: "true, wenn alle Würfel gleichzeitig geworfen wurden")
        var alleGeworfen: Bool
        @Guide(description: "true, wenn es der erste Wurf nach einer Übernahme ist")
        var nachUebernahme: Bool
    }

    func call(arguments: Arguments) async throws -> String {
        RegelTools.besteAuswahl(arguments.wuerfel, alleGeworfen: arguments.alleGeworfen,
                                nachUebernahme: arguments.nachUebernahme, rules: rules)
    }
}

@available(iOS 26.0, *)
nonisolated struct ZugTool: Tool {
    let name = "zug_berechnen"
    let description = "Rechnet einen ganzen Zug zusammen: mehrere Würfe und übernommene Punkte."
    let rules: GameRules

    @Generable
    struct Wurf {
        @Guide(description: "Augen der in diesem Wurf rausgelegten Würfel")
        var wuerfel: [Int]
    }

    @Generable
    struct Arguments {
        @Guide(description: "Je Wurf die rausgelegten Würfel, in der Reihenfolge der Würfe")
        var wuerfe: [Wurf]
        @Guide(description: "Übernommene Punkte, sonst 0")
        var uebernommenePunkte: Int
        @Guide(description: "true, wenn der erste Wurf direkt nach einer Übernahme war")
        var erstesWurfNachUebernahme: Bool
    }

    func call(arguments: Arguments) async throws -> String {
        RegelTools.zug(arguments.wuerfe.map(\.wuerfel), uebernommenePunkte: arguments.uebernommenePunkte,
                       erstesWurfNachUebernahme: arguments.erstesWurfNachUebernahme, rules: rules)
    }
}

@available(iOS 26.0, *)
nonisolated struct RegelTool: Tool {
    let name = "regel_nachschlagen"
    let description = "Liefert den genauen Regeltext zu einem Thema."
    let rules: GameRules

    @Generable
    struct Arguments {
        @Guide(description: "Thema", .anyOf(RegelTools.themen))
        var thema: String
    }

    func call(arguments: Arguments) async throws -> String {
        RegelTools.nachschlagen(arguments.thema, rules: rules)
    }
}

@available(iOS 26.0, macOS 26.0, *)
nonisolated extension ZehnkRegelChat {
    static func werkzeuge(_ rules: GameRules) -> [any Tool] {
        [WertungTool(rules: rules), BesteAuswahlTool(rules: rules), ZugTool(rules: rules), RegelTool(rules: rules)]
    }

    /// Das Apple-Modell mit den vier Werkzeugen von 10k
    static func modell(_ rules: GameRules) -> AppleSprachmodell {
        AppleSprachmodell(werkzeuge: werkzeuge(rules), weichmacher: weichmacher)
    }

    @MainActor
    static func sitzung(rules: GameRules, zug: String?) -> RegelChatSitzung {
        RegelChatSitzung(wissen: ZehnkRegelWissen(rules: rules, imSpiel: zug != nil), modell: modell(rules), zug: zug, grenzen: grenzen)
    }
}

#endif
