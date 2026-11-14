// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// KI-1 (Regel-Chat im Baukasten): Das Wissen eines Spiels über seine Regeln, in Abschnitten.
/// Der Regel-Chat antwortet nur aus diesem Wissen. Jedes Spiel liefert später eine Datei
/// `RegelWissen.swift` mit `static let regelWissen: RegelWissen` (Text-Pakete KI-T1 bis T7).

/// Ein Abschnitt der Regeln (je etwa 80 bis 200 Wörter). Der Chat nimmt je Frage nur die passenden Abschnitte
/// in den Prompt, weil das Modell höchstens 4096 Token je Sitzung fasst.
public struct RegelAbschnitt: Sendable, Equatable {
    public let titel: String
    public let text: String
    /// Umgangssprachliche Wörter, bei denen dieser Abschnitt passt (zum Beispiel „Zonk“ beim Abschnitt „Niete“).
    public let stichwoerter: [String]

    public init(titel: String, text: String, stichwoerter: [String] = []) {
        self.titel = titel
        self.text = text
        self.stichwoerter = stichwoerter
    }
}

public protocol RegelWissen: Sendable {
    /// Kennung des Spiels (wie in `Startauswahl.grundIDs`)
    var spielID: String { get }
    /// Name des Spiels, wie ihn Spieler lesen
    var name: String { get }
    /// Die Regeln in Abschnitten
    var abschnitte: [RegelAbschnitt] { get }
    /// Kurze Zusammenfassung der **eingestellten** Variante (nur die aktive, keine Alternativen)
    var aktiveRegeln: String { get }
    /// Umgangssprachliche Begriffe („Zonk = Niete“); leer, wenn es keine gibt
    var begriffe: String { get }
    /// Vorgerechnete Beispiele (Frage und Antwort); leer, wenn es keine gibt
    var beispiele: String { get }
    /// Spielspezifische Zusatzzeilen für die Anweisungen (zum Beispiel Hinweis auf Rechen-Werkzeuge); leer = keine
    var zusatzAnweisungen: String { get }
    /// Eigene Anweisungen statt des allgemeinen Gerüsts (für Spiele mit Werkzeugen, zum Beispiel 10k). Ist das
    /// gesetzt, kommen `aktiveRegeln`, `begriffe`, `beispiele` und die Fakten wortgleich in den Prompt (sie tragen
    /// dann ihre Überschriften selbst).
    var eigeneAnweisungen: String? { get }
    /// Weitere Texte, aus deren Zahlen eine Antwort schöpfen darf (Zahlen-Wächter), auch wenn sie nicht im Prompt stehen
    var waechterQuellen: [String] { get }
    /// Antwort aus dem Regeltext ohne Modell, wenn das Modell scheitert oder der Wächter eingreift; `nil` = allgemeiner Rückfall
    func ersatzAntwort(auf frage: String) -> String?
    /// Antwort ohne Sprachmodell (Rechenfragen, feste Fakten); `nil` = das Modell soll antworten
    func direktAntwort(auf frage: String) -> String?
    /// Fakten, die Swift zur Frage berechnet hat; sie landen verbindlich im Prompt. `nil` = keine
    func zusatz(zu frage: String) -> String?
    /// Drei Beispielfragen für das leere Chat-Blatt (KI-3); leer = keine Beispiele
    var beispielfragen: [String] { get }
    /// Eigenes Sprachmodell des Spiels (zum Beispiel mit Rechen-Werkzeugen wie in 10k); `nil` = Apples Modell ohne Werkzeuge
    func sprachmodell() -> (any RegelChatSprachmodell)?
    /// Grenzen für den Prompt; Standard, wenn das Spiel nichts anderes braucht
    var chatGrenzen: RegelChatGrenzen { get }
    /// `true` (Standard): Der Chat erscheint nur bei deutscher App-Sprache. 10k prüft nur das Modell (`false`).
    var nurDeutscheApp: Bool { get }
}

public extension RegelWissen {
    var aktiveRegeln: String { "" }
    var begriffe: String { "" }
    var beispiele: String { "" }
    var zusatzAnweisungen: String { "" }
    var eigeneAnweisungen: String? { nil }
    var waechterQuellen: [String] { [] }
    func ersatzAntwort(auf frage: String) -> String? { nil }
    func direktAntwort(auf frage: String) -> String? { nil }
    func zusatz(zu frage: String) -> String? { nil }
    var beispielfragen: [String] { [] }
    func sprachmodell() -> (any RegelChatSprachmodell)? { nil }
    var chatGrenzen: RegelChatGrenzen { .standard }
    var nurDeutscheApp: Bool { true }
}

/// Einfache Umsetzung für Spiele ohne eigene Rechenlogik (und für Tests).
public struct RegelWissenEinfach: RegelWissen {
    public let spielID: String
    public let name: String
    public let abschnitte: [RegelAbschnitt]
    public let aktiveRegeln: String
    public let begriffe: String
    public let beispiele: String
    public let zusatzAnweisungen: String
    public let beispielfragen: [String]
    private let direkt: (@Sendable (String) -> String?)?
    private let fakten: (@Sendable (String) -> String?)?

    public init(spielID: String, name: String, abschnitte: [RegelAbschnitt], aktiveRegeln: String = "",
                begriffe: String = "", beispiele: String = "", zusatzAnweisungen: String = "",
                beispielfragen: [String] = [],
                direkt: (@Sendable (String) -> String?)? = nil,
                fakten: (@Sendable (String) -> String?)? = nil) {
        self.spielID = spielID
        self.name = name
        self.abschnitte = abschnitte
        self.aktiveRegeln = aktiveRegeln
        self.begriffe = begriffe
        self.beispiele = beispiele
        self.zusatzAnweisungen = zusatzAnweisungen
        self.beispielfragen = beispielfragen
        self.direkt = direkt
        self.fakten = fakten
    }

    public func direktAntwort(auf frage: String) -> String? { direkt?(frage) }
    public func zusatz(zu frage: String) -> String? { fakten?(frage) }
}

/// Liest die Regeltexte der Text-Pakete (`plan/ki-regeltexte/<id>.md`): alles ab der ersten Zeile `## ` ist Regeltext,
/// je `## Titel` ein Abschnitt. Eine Zeile `Stichwörter: a, b, c` im Abschnitt (optional) wird nicht Teil des Texts,
/// sondern zu `stichwoerter`. Kopf (Quellen, Optionen) vor dem ersten `## ` wird ignoriert.
public enum RegelWissenMarkdown {
    public static func abschnitte(aus markdown: String) -> [RegelAbschnitt] {
        var ergebnis: [RegelAbschnitt] = []
        var titel: String?
        var zeilen: [String] = []
        var stich: [String] = []

        func abschliessen() {
            if let titel {
                let text = zeilen.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
                ergebnis.append(RegelAbschnitt(titel: titel, text: text, stichwoerter: stich))
            }
            zeilen = []
            stich = []
        }

        for zeile in markdown.components(separatedBy: "\n") {
            if zeile.hasPrefix("## ") {
                abschliessen()
                titel = String(zeile.dropFirst(3)).trimmingCharacters(in: .whitespaces)
            } else if titel != nil {
                if zeile.hasPrefix("Stichwörter:") {
                    stich += zeile.dropFirst("Stichwörter:".count).split(separator: ",")
                        .map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                } else {
                    zeilen.append(zeile)
                }
            }
        }
        abschliessen()
        return ergebnis
    }
}
