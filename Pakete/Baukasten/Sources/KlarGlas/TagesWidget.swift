// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
#if canImport(WidgetKit)
import WidgetKit

// Klar & Glas – Tagesrätsel-Widget für alle Apps mit Tagesaufgabe (Konzept 3.7). Ersetzt die Kopien aus WidgetVorlage.swift.
// Die App schreibt Serie und letzten gelösten Tag in die App Group (`TagesWidgetSpeicher.schreibe`); das Widget liest nur.
// Einbau in der Widget-Erweiterung (eine Datei, siehe _Gemeinsam/Widget/WidgetVorlage.swift.txt):
//   struct SudokuTagesWidget: Widget { var body: some WidgetConfiguration { TagesWidgetKonfiguration(…).widget } }

/// Alles, was das Widget über die App wissen muss.
public struct TagesWidgetKonfiguration: Sendable {
    /// App Group, z. B. „group.de.philippstach.spiele“
    public let gruppe: String
    /// Schlüssel-Präfix in der App Group, z. B. „sudoku“ → „sudoku.serie“, „sudoku.letzterTag“; auch Widget-Kennung
    public let praefix: String
    /// Kurzname oben links im Widget („Sudoku“, „Wortpfeil“); bei langen Namen den Kurznamen nehmen
    public let titel: String
    /// Name in der Widget-Galerie („Sudoku Tagesrätsel“)
    public let galerieName: String
    /// App-Farbe als Fläche (Mockup-Hex)
    public let farbeHex: UInt32
    /// Tage, die der letzte gelöste Tag zurückliegen darf, damit die Serie lebt (Sudoku: 2 wegen Ruhetag)
    public let toleranz: Int

    public init(gruppe: String, praefix: String, titel: String, galerieName: String, farbeHex: UInt32, toleranz: Int = 1) {
        self.gruppe = gruppe; self.praefix = praefix; self.titel = titel; self.galerieName = galerieName
        self.farbeHex = farbeHex; self.toleranz = toleranz
    }

    public var kennung: String { praefix + ".tagesraetsel" }
    var serieSchluessel: String { praefix + ".serie" }
    var letzterTagSchluessel: String { praefix + ".letzterTag" }
}

/// App-Seite: nach jedem gelösten Tagesrätsel (und beim Start) aufrufen. Schreibt in die App Group und lädt das Widget neu.
public enum TagesWidgetSpeicher {
    public static func schreibe(_ konfig: TagesWidgetKonfiguration, serie: Int, letzterTag: Date?, kalender: Calendar = .current) {
        let d = UserDefaults(suiteName: konfig.gruppe)
        d?.set(serie, forKey: konfig.serieSchluessel)
        d?.set(letzterTag.map { Tagesschluessel.text($0, kalender: kalender) } ?? "", forKey: konfig.letzterTagSchluessel)
        WidgetCenter.shared.reloadTimelines(ofKind: konfig.kennung)
    }
}

public struct TagesWidgetEintrag: TimelineEntry {
    public let date: Date
    public let serie: Int
    public let heuteGeloest: Bool

    public init(date: Date, serie: Int, heuteGeloest: Bool) {
        self.date = date; self.serie = serie; self.heuteGeloest = heuteGeloest
    }
}

public struct TagesWidgetProvider: TimelineProvider {
    let konfig: TagesWidgetKonfiguration

    public init(konfig: TagesWidgetKonfiguration) { self.konfig = konfig }

    public func placeholder(in context: Context) -> TagesWidgetEintrag { TagesWidgetEintrag(date: .now, serie: 3, heuteGeloest: false) }

    public func getSnapshot(in context: Context, completion: @escaping (TagesWidgetEintrag) -> Void) { completion(lesen()) }

    public func getTimeline(in context: Context, completion: @escaping (Timeline<TagesWidgetEintrag>) -> Void) {
        // Nächster Kalendertag (nicht +24 h: an Tagen der Zeitumstellung hat der Tag 23 oder 25 Stunden)
        let beginn = Calendar.current.startOfDay(for: .now)
        let morgen = (Calendar.current.date(byAdding: .day, value: 1, to: beginn) ?? beginn.addingTimeInterval(24 * 3600)).addingTimeInterval(60)
        completion(Timeline(entries: [lesen()], policy: .after(morgen)))
    }

    func lesen() -> TagesWidgetEintrag {
        let d = UserDefaults(suiteName: konfig.gruppe)
        let serie = d?.integer(forKey: konfig.serieSchluessel) ?? 0
        let letzter = d?.string(forKey: konfig.letzterTagSchluessel) ?? ""
        let heute = Tagesschluessel.text(.now)
        return TagesWidgetEintrag(date: .now,
                                  serie: TagesSerie.lebend(serie: serie, letzterTag: letzter, toleranz: konfig.toleranz),
                                  heuteGeloest: letzter == heute)
    }
}

/// Ansicht klein und mittel: App-Farbe als Fläche, weißer Text, oben Kurzname + Datum, unten Stand und Serie.
public struct TagesWidgetAnsicht: View {
    let eintrag: TagesWidgetEintrag
    let konfig: TagesWidgetKonfiguration
    @Environment(\.widgetFamily) private var familie

    public init(eintrag: TagesWidgetEintrag, konfig: TagesWidgetKonfiguration) {
        self.eintrag = eintrag; self.konfig = konfig
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(verbatim: konfig.titel).font(.headline.weight(.bold)).lineLimit(1).minimumScaleFactor(0.6)
                Spacer()
                Text(eintrag.date.formatted(.dateTime.day().month(.abbreviated))).font(.caption).opacity(0.85)
            }
            Spacer(minLength: 0)
            if eintrag.heuteGeloest {
                Label { Text("Heute geschafft", bundle: .module) } icon: { Image(systemName: "checkmark.seal.fill") }
                    .font(.subheadline.weight(.semibold))
            } else {
                Label { Text("Heute noch offen", bundle: .module) } icon: { Image(systemName: "circle.dashed") }
                    .font(.subheadline.weight(.semibold))
            }
            if eintrag.serie > 0 {
                Label { Text(verbatim: TagesSerie.text(eintrag.serie)) } icon: { Image(systemName: "flame.fill") }
                    .font(familie == .systemSmall ? .caption : .subheadline)
            } else {
                Text(verbatim: TagesSerie.text(0)).font(familie == .systemSmall ? .caption : .subheadline).opacity(0.9)
            }
        }
        .foregroundStyle(.white)
        .containerBackground(for: .widget) { Color(hex: konfig.farbeHex) }
    }
}

public extension TagesWidgetKonfiguration {
    /// Die fertige Widget-Konfiguration für `var body: some WidgetConfiguration` der Erweiterung.
    var widget: some WidgetConfiguration {
        StaticConfiguration(kind: kennung, provider: TagesWidgetProvider(konfig: self)) { eintrag in
            TagesWidgetAnsicht(eintrag: eintrag, konfig: self)
        }
        .configurationDisplayName(Text(verbatim: galerieName))
        .description(Text("Zeigt, ob das heutige Rätsel gelöst ist, und deine Serie.", bundle: .module))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#endif
