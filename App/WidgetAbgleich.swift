// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import WidgetKit
import SpieleKern
import KlarGlas

/// Schreibt Stand der App für Widgets und Steuerelemente in die App Group (zuletzt gespielt, Bestleistungen, Summen)
/// und lädt die betroffenen Zeitleisten neu. Die Tagesrätsel-Serien schreiben die Spiele selbst.
@MainActor
enum WidgetAbgleich {
    static func zuletzt(_ id: String) {
        guard let m = SpielKatalog.modul(id) else { return }
        let neu = PartieGeteilt.Zuletzt(id: m.id, name: m.name, farbeHex: m.gattung.klarFarbe.flaeche, datum: .now)
        if PartieGeteilt.zuletztSchreiben(neu) {
            WidgetCenter.shared.reloadTimelines(ofKind: "partie.weiter")
            if #available(iOS 18.0, *) { ControlCenter.shared.reloadControls(ofKind: "de.philippstach.partie.steuerung.weiter") }
        }
    }

    /// Kinder-Modus an die Widgets weitergeben: gesperrte Spiele verschwinden aus „Zuletzt gespielt“ und den Bestleistungen.
    static func kinderModusAbgleichen(kinder: Bool = Modi.kinder, gesperrt: Set<String> = Modi.gesperrt) {
        if PartieGeteilt.gesperrtSchreiben(kinder ? gesperrt : []) {
            WidgetCenter.shared.reloadTimelines(ofKind: "partie.weiter")
            WidgetCenter.shared.reloadTimelines(ofKind: "partie.bestleistung")
            if #available(iOS 18.0, *) { ControlCenter.shared.reloadControls(ofKind: "de.philippstach.partie.steuerung.weiter") }
        }
    }

    /// Nach einer gemeldeten Partie: Bestleistung des Spiels und Gesamtzahlen übernehmen.
    static func partie(_ statistik: StatistikDienst, spiel: String, ich: UUID?) {
        var geaendert = false
        if let punkte = statistik.rekord(spiel: spiel) {
            let m = SpielKatalog.modul(spiel)
            let neu = PartieGeteilt.Rekord(id: spiel, name: m?.name ?? spiel, farbeHex: m?.gattung.klarFarbe.flaeche ?? Familienfarbe.nachtblau.flaeche, punkte: punkte, datum: .now)
            geaendert = PartieGeteilt.rekordSchreiben(neu) || geaendert
        }
        let s = statistik.summe(ich: ich)
        geaendert = PartieGeteilt.summenSchreiben(.init(partien: s.partien, siege: s.siege)) || geaendert
        if geaendert { WidgetCenter.shared.reloadTimelines(ofKind: "partie.bestleistung") }
    }

    /// Designwechsel: die Auswahl in die App Group spiegeln (das Widget liest sie dort) und alle Zeitleisten neu laden.
    static func designAbgleichen(_ art: DesignArt = Design.art) {
        if PartieGeteilt.designSchreiben(art.rawValue) { WidgetCenter.shared.reloadAllTimelines() }
    }

    /// Erstes Tagesrätsel, das heute noch offen ist (für `partie://tagesraetsel`); sonst eines zufällig.
    static func naechstesTagesraetsel(erlaubt: (String) -> Bool = { Modi.erlaubt($0) }) -> String? {
        let heute = Tagesschluessel.text(.now)
        let moegliche = TagesSpielInfo.alle.filter { erlaubt($0.id) }   // Kinder-Modus: keine gesperrten Spiele
        let offen = moegliche.first { PartieGeteilt.tag(praefix: $0.praefix).letzterTag != heute && SpielKatalog.modul($0.id) != nil }
        return (offen ?? moegliche.randomElement())?.id
    }
}
