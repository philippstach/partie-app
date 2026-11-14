// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import SpieleKern
import MauMauKern

/// KI-6 (Vorbereitung, ohne Oberfläche): bildet die Hausregeln `NRegeln` auf das Varianten-Gerüst (SpieleKern, KI-5) ab.
/// Das Modell wählt nur Vorlage und Schalter; gesetzt wird erst nach der Bestätigung. Eingabefeld und Knöpfe kommen später (Blatt vom Design-Chat).
/// Die Vorlagen stammen aus den `NRegeln`-Schnellwahlen, damit Regelblatt und Ansage dieselben Werte benutzen.
public final class MauMauVarianten: SpielVarianten {
    public private(set) var regeln: NRegeln
    private let beiAenderung: (NRegeln) -> Void
    private let istAenderbar: () -> Bool

    /// - Parameters:
    ///   - regeln: aktueller Stand (im Spiel: gemerkte Hausregeln `RegelSpeicher.gespeichert`).
    ///   - aenderbar: `false` nach dem ersten Zug.
    ///   - beiAenderung: wird nach `anwenden` mit den neuen Regeln gerufen (Aufrufer sichert sie, zum Beispiel über `RegelSpeicher.sichern`).
    public init(regeln: NRegeln, aenderbar: @escaping () -> Bool = { true }, beiAenderung: @escaping (NRegeln) -> Void) {
        self.regeln = regeln; self.istAenderbar = aenderbar; self.beiAenderung = beiAenderung
    }

    public var aenderbar: Bool { istAenderbar() }

    // MARK: Schema

    /// Werte einer Schnellwahl ohne die Runden-Optionen (die Schnellwahl im Regelblatt lässt Runden und Zielsumme auch unverändert).
    static func werte(_ r: NRegeln) -> [String: VariantenWert] {
        var w = lesen(r); w["mehrrunden"] = nil; w["ziel_punkte"] = nil; return w
    }

    public static let schema = VariantenSchema(
        spielID: "maumau-neu",   // = MauMauModul.kennung (Modul.swift ist UIKit-gebunden, darum hier als Text)
        spielName: "Mau-Mau",
        optionen: [
            VariantenOption(id: "start_karten", titel: "Karten auf der Hand", hinweis: "Wie viele Karten jede Person zu Beginn bekommt.",
                            art: .zahl(von: 5, bis: 7), standard: .zahl(5), stichworte: ["Karten", "Handkarten", "austeilen"]),
            VariantenOption(id: "sieben_ziehen", titel: "7 lässt ziehen", hinweis: "Wer eine 7 legt, lässt die nächste Person zwei Karten ziehen; Siebenen lassen sich stapeln.",
                            art: .schalter, standard: .an(true), stichworte: ["Sieben", "ziehen", "zwei Karten", "stapeln"]),
            VariantenOption(id: "aussetzen", titel: "Aussetzen", hinweis: "Welche Karte die nächste Person aussetzen lässt: die 8, das Ass oder keine.",
                            art: .auswahl([VariantenAuswahlEintrag(id: "acht", titel: "Mit der 8"), VariantenAuswahlEintrag(id: "ass", titel: "Mit dem Ass"),
                                           VariantenAuswahlEintrag(id: "keine", titel: "Niemand setzt aus")]),
                            standard: .auswahl("acht"), stichworte: ["Acht", "Ass", "aussetzen", "aussetzer"]),
            VariantenOption(id: "bube_als_schluss", titel: "Bube darf die letzte Karte sein", hinweis: "Ist es erlaubt, mit einem Buben zu gewinnen?",
                            art: .schalter, standard: .an(true), stichworte: ["Bube", "Schluss", "letzte Karte", "Bauer"]),
            VariantenOption(id: "bube_auf_bube", titel: "Bube auf Bube erlaubt", hinweis: "Ein Bube darf auf einen Buben gelegt werden.",
                            art: .schalter, standard: .an(true), stichworte: ["Bube", "Bauer", "Wunsch"]),
            VariantenOption(id: "neun_richtung", titel: "9 wechselt die Richtung", hinweis: "Die 9 dreht die Spielrichtung um (ab drei Personen).",
                            art: .schalter, standard: .an(false), stichworte: ["Neun", "Richtung", "drehen", "Richtungswechsel"]),
            VariantenOption(id: "mau_sagen", titel: "„Mau“ sagen", hinweis: "Wer die vorletzte Karte legt, muss „Mau“ sagen, sonst gibt es eine Strafkarte.",
                            art: .schalter, standard: .an(false), stichworte: ["Mau", "Strafkarte", "vorletzte Karte", "ansagen"]),
            VariantenOption(id: "sofort_legen", titel: "Gezogene Karte gleich legen", hinweis: "Eine gezogene Karte darf sofort gelegt werden, wenn sie passt.",
                            art: .schalter, standard: .an(false), stichworte: ["ziehen", "sofort", "gleich legen"]),
            VariantenOption(id: "mehrrunden", titel: "Mehrere Runden mit Punkten", hinweis: "Mehrere Runden bis zu einer Zielsumme; wer sie zuerst erreicht, verliert.",
                            art: .schalter, standard: .an(false), stichworte: ["Runden", "Punkte", "Zielsumme", "mehrere Runden"]),
            VariantenOption(id: "ziel_punkte", titel: "Spielende bei", hinweis: "Zielsumme in Punkten; gilt nur bei mehreren Runden.",
                            art: .zahl(von: 50, bis: 150, schritt: 50), standard: .zahl(100), stichworte: ["Zielsumme", "Punkte", "bis 100", "Spielende"]),
        ],
        vorlagen: [
            VariantenVorlage(id: "standard", titel: "Standard", hinweis: "7 zieht, 8 setzt aus.", werte: werte(.standard), stichworte: ["normal", "klassisch"]),
            VariantenVorlage(id: "ass", titel: "Ass setzt aus", hinweis: "Statt der 8 setzt das Ass aus.", werte: werte(.ass), stichworte: ["Ass"]),
            VariantenVorlage(id: "sieben", titel: "Sieben Karten auf die Hand", hinweis: "Jede Person bekommt sieben Karten.", werte: werte(.sieben), stichworte: ["sieben Karten"]),
            VariantenVorlage(id: "schlicht", titel: "Schlicht", hinweis: "Ohne 7 und 8: keine Sonderkarten zum Ziehen oder Aussetzen.", werte: werte(.schlicht), stichworte: ["einfach", "für Kinder", "ohne Sonderkarten"]),
            VariantenVorlage(id: "streng", titel: "Streng", hinweis: "Der Bube darf nicht zuletzt gelegt werden und nicht auf einen Buben.", werte: werte(.streng), stichworte: ["Turnier", "strenge Regeln"]),
            VariantenVorlage(id: "wild", titel: "Wild", hinweis: "9 dreht die Richtung, gezogene Karten dürfen gleich gelegt werden, „Mau“ ist Pflicht.", werte: werte(.wild), stichworte: ["wild", "Hausregeln", "chaotisch"]),
        ]
    )

    public var schema: VariantenSchema { Self.schema }

    // MARK: Lesen und Anwenden

    static func lesen(_ r: NRegeln) -> [String: VariantenWert] {
        [
            "start_karten": .zahl(r.startkarten),
            "sieben_ziehen": .an(r.siebenZiehen),
            "aussetzen": .auswahl(auswahlID(r.aussetzen)),
            "bube_als_schluss": .an(r.bubeAlsSchluss),
            "bube_auf_bube": .an(r.bubeAufBube),
            "neun_richtung": .an(r.neunRichtung),
            "mau_sagen": .an(r.maueSagen),
            "sofort_legen": .an(r.sofortLegen),
            "mehrrunden": .an(r.mehrrunden),
            "ziel_punkte": .zahl(r.zielPunkte),
        ]
    }

    static func auswahlID(_ a: Aussetzen) -> String {
        switch a { case .acht: "acht"; case .ass: "ass"; case .keine: "keine" }
    }

    /// Setzt gültige Werte in die Regeln ein. Unbekannte Schlüssel oder falsche Arten werden übersprungen.
    static func einsetzen(_ w: [String: VariantenWert], in start: NRegeln) -> NRegeln {
        var r = start
        for (k, v) in w {
            switch (k, v) {
            case let ("start_karten", .zahl(n)): r.startkarten = min(7, max(5, n))
            case let ("sieben_ziehen", .an(b)): r.siebenZiehen = b
            case let ("aussetzen", .auswahl(id)):
                switch id { case "acht": r.aussetzen = .acht; case "ass": r.aussetzen = .ass; case "keine": r.aussetzen = .keine; default: break }
            case let ("bube_als_schluss", .an(b)): r.bubeAlsSchluss = b
            case let ("bube_auf_bube", .an(b)): r.bubeAufBube = b
            case let ("neun_richtung", .an(b)): r.neunRichtung = b
            case let ("mau_sagen", .an(b)): r.maueSagen = b
            case let ("sofort_legen", .an(b)): r.sofortLegen = b
            case let ("mehrrunden", .an(b)): r.mehrrunden = b
            case let ("ziel_punkte", .zahl(n)): r.zielPunkte = n
            default: break
            }
        }
        return r
    }

    public func lesen() -> [String: VariantenWert] { Self.lesen(regeln) }

    public func anwenden(_ werte: [String: VariantenWert]) {
        guard aenderbar else { return }
        let neu = Self.einsetzen(werte, in: regeln)
        guard neu != regeln else { return }
        regeln = neu
        beiAenderung(neu)
    }
}
