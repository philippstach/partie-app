// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI

// Klar & Glas – Tagesrätsel: Tagesschlüssel, Serie und der Monatskalender (Konzept 3.5 `TagesKalender`, 3.7 Widgets).
// Logik ohne UI (testbar auf dem Mac); die Kalender-Karte nur für iOS.

/// Ein Tag als Text „JJJJ-MM-TT“ im Kalender des Geräts. Damit speichern App und Widget gelöste Tage.
public enum Tagesschluessel {
    public static func text(_ datum: Date, kalender: Calendar = .current) -> String {
        let c = kalender.dateComponents([.year, .month, .day], from: datum)
        return String(format: "%04d-%02d-%02d", c.year ?? 1970, c.month ?? 1, c.day ?? 1)
    }

    public static func datum(_ text: String, kalender: Calendar = .current) -> Date? {
        let teile = text.split(separator: "-").compactMap { Int($0) }
        guard teile.count == 3 else { return nil }
        return kalender.date(from: DateComponents(year: teile[0], month: teile[1], day: teile[2]))
    }
}

/// Serie gelöster Tage.
public enum TagesSerie {
    /// Länge der Serie, die heute (oder innerhalb von `toleranz` Tagen davor) endet: zusammenhängende gelöste Tage,
    /// rückwärts gezählt vom jüngsten gelösten Tag, der höchstens `toleranz` Tage zurückliegt. Sonst 0.
    public static func laenge(geloest: Set<String>, heute: Date = .now, toleranz: Int = 1, kalender: Calendar = .current) -> Int {
        guard let anker = (0...max(0, toleranz)).lazy
            .compactMap({ kalender.date(byAdding: .day, value: -$0, to: heute) })
            .first(where: { geloest.contains(Tagesschluessel.text($0, kalender: kalender)) }) else { return 0 }
        var tag = anker, n = 0
        while geloest.contains(Tagesschluessel.text(tag, kalender: kalender)) {
            n += 1
            guard let vor = kalender.date(byAdding: .day, value: -1, to: tag) else { break }
            tag = vor
        }
        return n
    }

    /// Widget-Regel: Die gespeicherte Serie lebt, wenn der letzte gelöste Tag höchstens `toleranz` Tage zurückliegt; sonst 0.
    public static func lebend(serie: Int, letzterTag: String, heute: Date = .now, toleranz: Int = 1, kalender: Calendar = .current) -> Int {
        let lebt = (0...max(0, toleranz)).contains { versatz in
            guard let d = kalender.date(byAdding: .day, value: -versatz, to: heute) else { return false }
            return Tagesschluessel.text(d, kalender: kalender) == letzterTag
        }
        return lebt ? max(0, serie) : 0
    }

    /// Seriezeile für Karte und Widget: „Serie: 5 Tage“, „Serie: 1 Tag“ oder „Starte eine Serie“.
    public static func text(_ serie: Int) -> String {
        switch serie {
        case ..<1: String(localized: "Starte eine Serie", bundle: .module, comment: "Seriezeile ohne Serie")
        case 1: String(localized: "Serie: 1 Tag", bundle: .module, comment: "Seriezeile, ein Tag")
        default: String(localized: "Serie: \(serie) Tage", bundle: .module, comment: "Seriezeile, mehrere Tage")
        }
    }

    /// Die sieben Punkte der Tageskarte (Mo…So der laufenden Woche, `true` = gelöst).
    public static func woche(geloest: Set<String>, heute: Date = .now, kalender: Calendar = .current) -> [Bool] {
        var kal = kalender
        kal.firstWeekday = 2   // Montag, wie die Beschriftung der Tageskarte
        guard let start = kal.dateInterval(of: .weekOfYear, for: heute)?.start else { return Array(repeating: false, count: 7) }
        return (0..<7).map { i in
            guard let d = kal.date(byAdding: .day, value: i, to: start) else { return false }
            return geloest.contains(Tagesschluessel.text(d, kalender: kal))
        }
    }
}

#if canImport(UIKit)

/// Monatskalender des Tagesrätsels: Karte mit Monatswechsel, Wochentagen und Tagen; gelöst = Kreis in App-Farbe,
/// heute = Ring, Zukunft grau. `auswahl` macht vergangene Tage antippbar (ältere Rätsel nachholen).
public struct TagesKalender: View {
    @Binding var monat: Date
    let geloest: Set<String>
    let heute: Date
    let auswahl: ((Date) -> Void)?
    let kalender: Calendar
    /// 2.34 N-020: Tageskreise wachsen mit der Schrift (gedeckelt, damit sieben Spalten passen).
    @ScaledMetric(relativeTo: .subheadline) private var zellBasis: CGFloat = 36
    private var zellGroesse: CGFloat { min(zellBasis, 46) }

    public init(monat: Binding<Date>, geloest: Set<String>, heute: Date = .now, kalender: Calendar = .current,
                auswahl: ((Date) -> Void)? = nil) {
        _monat = monat; self.geloest = geloest; self.heute = heute; self.auswahl = auswahl
        var kal = kalender
        kal.firstWeekday = 2
        self.kalender = kal
    }

    private var monatsStart: Date { kalender.date(from: kalender.dateComponents([.year, .month], from: monat)) ?? monat }
    private var heuteStart: Date { kalender.startOfDay(for: heute) }
    private var vorwaertsErlaubt: Bool { monatsStart < (kalender.date(from: kalender.dateComponents([.year, .month], from: heute)) ?? heute) }

    private var tage: [Date?] {
        guard let bereich = kalender.range(of: .day, in: .month, for: monatsStart) else { return [] }
        let wochentag = kalender.component(.weekday, from: monatsStart)   // 1 = So … 7 = Sa
        let leer = (wochentag - kalender.firstWeekday + 7) % 7
        let echte: [Date?] = bereich.compactMap { kalender.date(byAdding: .day, value: $0 - 1, to: monatsStart) }
        return Array(repeating: nil, count: leer) + echte
    }

    private var kuerzel: [String] {
        var kal = kalender
        kal.locale = .current
        let s = kal.veryShortStandaloneWeekdaySymbols
        return (0..<7).map { s[($0 + kalender.firstWeekday - 1) % 7] }
    }

    public var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text(monatsStart, format: .dateTime.month(.wide).year())
                    .font(Design.ist(.klar) ? .headline : Design.Schrift.name).accessibilityAddTraits(.isHeader)
                Spacer()
                pfeil("chevron.left", Text("Vorheriger Monat", bundle: .module), aktiv: true) {
                    monat = kalender.date(byAdding: .month, value: -1, to: monatsStart) ?? monat
                }
                pfeil("chevron.right", Text("Nächster Monat", bundle: .module), aktiv: vorwaertsErlaubt) {
                    monat = kalender.date(byAdding: .month, value: 1, to: monatsStart) ?? monat
                }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Design.Abstand.xs), count: 7), spacing: 6) {
                ForEach(kuerzel.indices, id: \.self) { i in
                    Text(verbatim: kuerzel[i]).font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
                }
                ForEach(Array(tage.enumerated()), id: \.offset) { _, tag in
                    if let tag { zelle(tag) } else { Color.clear.frame(height: zellGroesse) }
                }
            }
        }
        .card()
    }

    private func pfeil(_ symbol: String, _ beschriftung: Text, aktiv: Bool, aktion: @escaping () -> Void) -> some View {
        Button(action: aktion) {
            Image(systemName: symbol).font(.body.weight(.semibold))
                .foregroundStyle(aktiv ? Color.accentText : Color.schriftBlass)
                .frame(width: Theme.tapSize - 8, height: Theme.tapSize)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .disabled(!aktiv)
        .accessibilityLabel(beschriftung)
    }

    @ViewBuilder
    private func zelle(_ tag: Date) -> some View {
        let schluessel = Tagesschluessel.text(tag, kalender: kalender)
        let istGeloest = geloest.contains(schluessel)
        let istHeute = kalender.isDate(tag, inSameDayAs: heute)
        let zukunft = tag > heuteStart && !istHeute
        let nummer = kalender.component(.day, from: tag)
        let kern = ZStack {
            if istGeloest {
                Circle().fill(Color.appFlaeche)
            } else if istHeute {
                Circle().strokeBorder(Color.appFlaeche, lineWidth: 1.5)
            }
            Text(verbatim: "\(nummer)")
                .font(Design.Schrift.zahl(.subheadline).weight(istGeloest || istHeute ? .bold : .regular).monospacedDigit())
                .foregroundStyle(istGeloest ? Color.onAccent : (zukunft ? Color.schriftBlass : Color.schrift))
        }
        .frame(width: zellGroesse, height: zellGroesse)
        .accessibilityLabel(Text(tag, format: .dateTime.day().month(.wide)))
        .accessibilityValue(istGeloest ? Text("gelöst", bundle: .module) : (istHeute ? Text("heute", bundle: .module) : Text(verbatim: "")))
        if let auswahl, !zukunft {
            Button { auswahl(tag) } label: { kern.frame(maxWidth: .infinity).frame(minHeight: Theme.tapSize).contentShape(.rect) }
                .buttonStyle(.plain)
        } else {
            kern.frame(maxWidth: .infinity)
        }
    }
}

#endif
