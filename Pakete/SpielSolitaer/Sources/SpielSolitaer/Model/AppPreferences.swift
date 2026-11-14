// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation
import Observation
import UIKit

/// Einstellungen (Standardwerte siehe Doku/SPEZIFIKATION.md). Gespeichert in UserDefaults.
@Observable
final class AppPreferences: SolitaireRegelOptionen {
    private let defaults: UserDefaults

    var drawCount: Int { didSet { save(drawCount, "drawCount") } }
    /// Spider: 1, 2 oder 4 Farben
    var spiderColors: Int { didSet { save(spiderColors, "spiderColors") } }
    /// Klondike-Punkte: 0 Standard · 1 Vegas · 2 Vegas fortlaufend · 3 Aus
    var klondikeScoring: Int { didSet { save(klondikeScoring, "klondikeScoring") } }
    /// Kartengröße: false Normal, true Groß
    var largeCards: Bool { didSet { save(largeCards, "largeCards") } }
    var solvableDeals: Bool { didSet { save(solvableDeals, "solvableDeals") } }
    /// Schwierigkeit der lösbaren Partien: 0 gemischt, 1 leicht, 2 mittel, 3 schwer
    var difficulty: Int { didSet { save(difficulty, "difficulty") } }
    /// Karten ablegen: true = Automatisch (sichere Karten wandern von selbst nach oben), false = Selbst (Standard).
    /// Ein gespeicherter Wert heißt: bewusst gewählt (der Schalter wird nur beim Ändern geschrieben).
    var autoFoundation: Bool { didSet { save(autoFoundation, "autoFoundation") } }
    /// Bestandsnutzer, die den alten Schalter nie bewusst geändert haben (kein gespeicherter Wert): einmaliger Hinweis „Neu: Karten legst du jetzt selbst ab“
    private(set) var autoPlaceNoticePending: Bool
    var showTime: Bool { didSet { save(showTime, "showTime") } }
    var showMoves: Bool { didSet { save(showMoves, "showMoves") } }
    var showScore: Bool { didSet { save(showScore, "showScore") } }
    var leftHanded: Bool { didSet { save(leftHanded, "leftHanded") } }
    var fourColor: Bool { didSet { save(fourColor, "fourColor") } }
    /// Aussehen (Einstellungen → Aussehen): Tisch und Kartenrücken
    var tableStyle: TableStyle { didSet { save(tableStyle.rawValue, "tableStyle") } }
    /// Eigenes Foto als Tisch (nil, wenn keines gespeichert ist); wird aus dem App-Ordner geladen
    private(set) var tablePhoto: UIImage?
    /// „Automatisch nach Jahreszeit“: überschreibt die Tischwahl, solange es an ist
    var autoSeason: Bool { didSet { save(autoSeason, "autoSeason") } }
    /// Der Tisch, der gerade gezeigt wird (Jahreszeit oder gewählter Tisch)
    func activeTable(on date: Date = .now) -> TableStyle { autoSeason ? TableStyle.season(for: date) : tableStyle }
    var activeTable: TableStyle { activeTable() }
    var cardBack: CardBackStyle { didSet { save(cardBack.rawValue, "cardBack") } }
    /// Zuletzt gespielter Modus (`mode.key`); die App startet direkt dort
    var lastModeKey: String { didSet { defaults.set(lastModeKey, forKey: "lastModeKey") } }
    /// Modus, den „Neues Spiel“ startet (Klondike: die gewählte Zieh-Art)
    var klondikeMode: GameMode { .klondike(drawCount) }
    var spiderMode: GameMode { .spider(spiderColors) }
    /// Erstspieler-Hinweise, die schon gezeigt wurden (jeder genau einmal im Leben der App)
    /// Willkommens-Karte beim allerersten Start schon gesehen?
    var welcomeSeen: Bool { didSet { save(welcomeSeen, "welcomeSeen") } }
    var seenHints: Set<String> { didSet { defaults.set(Array(seenHints), forKey: "seenHints") } }
    /// Erste Nutzung (beim ersten Start gespeichert, fehlt sie → jetzt); Grundlage der Bewertungsabfrage
    let firstUse: Date
    /// Der einmalige Hinweis auf den Haus-Knopf (erster Start) wurde gezeigt
    var homeHintShown: Bool { didSet { defaults.set(homeHintShown, forKey: "homeHintShown") } }
    /// App-Version, bei der zuletzt die Bewertung angefragt wurde (höchstens einmal je Version)
    private(set) var lastReviewVersion: String?

    /// Ordner des Tischfotos (Tests nehmen einen eigenen)
    private let photoFolder: URL

    init(defaults: UserDefaults = .standard, photoFolder: URL = AppModel.standardFolder) {
        self.defaults = defaults
        self.photoFolder = photoFolder
        func bool(_ key: String, _ standard: Bool) -> Bool { defaults.object(forKey: key) as? Bool ?? standard }
        drawCount = defaults.object(forKey: "drawCount") as? Int == 3 ? 3 : 1
        spiderColors = [1, 2, 4].contains(defaults.object(forKey: "spiderColors") as? Int ?? 2) ? defaults.object(forKey: "spiderColors") as? Int ?? 2 : 2
        difficulty = (0...3).contains(defaults.object(forKey: "difficulty") as? Int ?? 0) ? defaults.object(forKey: "difficulty") as? Int ?? 0 : 0
        klondikeScoring = (0...3).contains(defaults.object(forKey: "klondikeScoring") as? Int ?? 0) ? defaults.object(forKey: "klondikeScoring") as? Int ?? 0 : 0
        largeCards = bool("largeCards", false)
        solvableDeals = bool("solvableDeals", true)
        autoFoundation = bool("autoFoundation", false)          // Standard seit Build 6: Selbst
        showTime = bool("showTime", true)
        showMoves = bool("showMoves", true)
        showScore = bool("showScore", true)
        leftHanded = bool("leftHanded", false)
        fourColor = bool("fourColor", false)
        // Fehlende oder unbekannte Werte → Standard; wer früher „Filz“ gewählt hatte, behält Filz
        let photo = PhotoTable.load(in: photoFolder)
        var style = defaults.string(forKey: "tableStyle").flatMap(TableStyle.init(rawValue:))
            ?? (bool("feltTable", false) ? .felt : .linen)
        if style == .photo, photo == nil { style = .linen }       // Foto-Tisch ohne Foto (Datei fehlt) → Leinen
        tableStyle = style
        autoSeason = bool("autoSeason", false)
        tablePhoto = photo
        cardBack = defaults.string(forKey: "cardBack").flatMap(CardBackStyle.init(rawValue:)) ?? .gold
        lastModeKey = defaults.string(forKey: "lastModeKey") ?? GameMode.klondike(1).key
        // Wer die App schon benutzt (Erstspieler-Hinweise oder letzter Modus gespeichert), bekommt die Willkommens-Karte nicht mehr
        let seen = defaults.object(forKey: "welcomeSeen") as? Bool ?? (defaults.object(forKey: "lastModeKey") != nil)
        welcomeSeen = seen
        // Hinweis nur für Bestandsnutzer (Willkommen schon gesehen), die „Automatisch ablegen“ nie bewusst geändert haben, und nur einmal
        autoPlaceNoticePending = seen && defaults.object(forKey: "autoFoundation") == nil && !defaults.bool(forKey: "autoPlaceNoticeShown")
        seenHints = Set(defaults.stringArray(forKey: "seenHints") ?? [])
        homeHintShown = defaults.bool(forKey: "homeHintShown")
        if let t = defaults.object(forKey: "firstUse") as? Double { firstUse = Date(timeIntervalSince1970: t) }
        else { firstUse = .now; defaults.set(firstUse.timeIntervalSince1970, forKey: "firstUse") }
        lastReviewVersion = defaults.string(forKey: "lastReviewVersion")
    }

    /// Neues Tischfoto aus Bilddaten: verkleinern, weichzeichnen, abdunkeln, speichern und als Tisch wählen. false = Foto nicht lesbar.
    @discardableResult
    func setTablePhoto(data: Data) -> Bool {
        guard PhotoTable.save(data, in: photoFolder), let image = PhotoTable.load(in: photoFolder) else { return false }
        tablePhoto = image
        tableStyle = .photo
        return true
    }

    /// Wie `setTablePhoto`, aber das Verarbeiten läuft außerhalb des Haupt-Threads (große Fotos blockieren die Oberfläche nicht)
    func setTablePhotoInBackground(data: Data) async -> Bool {
        let folder = photoFolder
        let saved = await Task.detached(priority: .userInitiated) { PhotoTable.save(data, in: folder) }.value
        guard saved, let image = PhotoTable.load(in: folder) else { return false }
        tablePhoto = image
        tableStyle = .photo
        return true
    }

    /// Auswahl „Karten ablegen“ (erster Start, Hinweis, Einstellungen): speichert den Wert als bewusst gewählt
    func choosePlacing(automatic: Bool) {
        autoFoundation = automatic
        autoPlaceNoticePending = false
        defaults.set(true, forKey: "autoPlaceNoticeShown")
    }

    /// Die Bewertung wurde bei dieser App-Version angefragt
    func markReviewAsked(version: String) {
        lastReviewVersion = version
        defaults.set(version, forKey: "lastReviewVersion")
    }

    /// Der Hinweis wurde gezeigt: er kommt nie wieder (auch wenn die App vorher beendet wird)
    func markAutoPlaceNoticeShown() { defaults.set(true, forKey: "autoPlaceNoticeShown") }

    func removeTablePhoto() {
        PhotoTable.remove(in: photoFolder)
        tablePhoto = nil
        if tableStyle == .photo { tableStyle = .linen }
    }

    private func save(_ value: Any, _ key: String) { defaults.set(value, forKey: key) }
}
