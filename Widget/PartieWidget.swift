// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import WidgetKit
import SwiftUI
import KlarGlas

// Widgets der Sammlung Partie (Build 4): Tagesrätsel je Spiel, Tagesübersicht, Weiterspielen, Bestleistungen.
// Aussehen und Serienregel der Tagesrätsel kommen aus dem Baukasten (KlarGlas: TagesWidget), die Daten aus der App Group
// group.de.philippstach.spiele (`PartieGeteilt`). Tippen öffnet das Spiel über partie://spiel/<id>.

private let hülle: UInt32 = Familienfarbe.nachtblau.flaeche   // Nachtblau, Hülle der Sammlung

// MARK: Tagesrätsel je Spiel (kleine und mittlere Fläche, wie in den Einzel-Apps)

func spielTagesWidget(_ info: TagesSpielInfo) -> some WidgetConfiguration {
    let konfig = TagesWidgetKonfiguration(gruppe: PartieGeteilt.gruppe, praefix: info.praefix, titel: info.name,
                                          galerieName: info.name, farbeHex: info.farbeHex, toleranz: info.toleranz)
    return StaticConfiguration(kind: "partie.\(info.id).tagesraetsel", provider: TagesWidgetProvider(konfig: konfig)) { eintrag in
        TagesSpielAnsicht(info: info, konfig: konfig, eintrag: eintrag)
            .widgetURL(URL(string: "partie://spiel/\(info.id)"))
    }
    .configurationDisplayName(Text(verbatim: info.name))
    .description("Zeigt, ob das heutige Rätsel gelöst ist, und deine Serie.")
    .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline])
}

/// Klein und mittel: Ansicht aus dem Baukasten. Sperrbildschirm: eigene schlichte Ansichten (Gauge, Text).
struct TagesSpielAnsicht: View {
    let info: TagesSpielInfo
    let konfig: TagesWidgetKonfiguration
    let eintrag: TagesWidgetEintrag
    @Environment(\.widgetFamily) private var familie

    var body: some View {
        switch familie {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 0) {
                    Image(systemName: eintrag.heuteGeloest ? "checkmark.seal.fill" : "circle.dashed").font(.title3)
                    if eintrag.serie > 0 { Text(verbatim: "\(eintrag.serie)").font(.caption2.bold()) }
                }
            }
            .containerBackground(for: .widget) { Color.clear }
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: info.name).font(.headline).widgetAccentable()
                Text(eintrag.heuteGeloest ? "Heute geschafft" : "Heute noch offen")
                Text(verbatim: TagesSerie.text(eintrag.serie)).font(.caption)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .containerBackground(for: .widget) { Color.clear }
        case .accessoryInline:
            Label { Text(verbatim: "\(info.name): ") + Text(eintrag.heuteGeloest ? "Heute geschafft" : "Heute noch offen") }
                icon: { Image(systemName: eintrag.heuteGeloest ? "checkmark.seal" : "circle.dashed") }
                .containerBackground(for: .widget) { Color.clear }
        default:
            let stil = WidgetStil(roh: PartieGeteilt.design())
            if stil.art == .klar { TagesWidgetAnsicht(eintrag: eintrag, konfig: konfig) }
            else {
                TagesKachel(stil: stil, id: info.id, name: info.name, datum: eintrag.date, geloest: eintrag.heuteGeloest, serie: eintrag.serie,
                            serieText: TagesSerie.text(eintrag.serie), klein: familie == .systemSmall)
                    .widgetKachel(stil, id: info.id)
            }
        }
    }
}

private func info(_ id: String) -> TagesSpielInfo { TagesSpielInfo.alle.first { $0.id == id }! }

struct MinensucheTagesWidget: Widget { var body: some WidgetConfiguration { spielTagesWidget(info("minensuche")) } }
struct SudokuTagesWidget: Widget { var body: some WidgetConfiguration { spielTagesWidget(info("sudoku")) } }
struct SolitaerTagesWidget: Widget { var body: some WidgetConfiguration { spielTagesWidget(info("solitaer")) } }
struct ViererreiheTagesWidget: Widget { var body: some WidgetConfiguration { spielTagesWidget(info("viererreihe")) } }
struct GalgenTagesWidget: Widget { var body: some WidgetConfiguration { spielTagesWidget(info("galgenmaennchen")) } }
struct WortpfeilTagesWidget: Widget { var body: some WidgetConfiguration { spielTagesWidget(info("wortpfeil")) } }
struct FarbraetselTagesWidget: Widget { var body: some WidgetConfiguration { spielTagesWidget(info("farbraetsel")) } }

// MARK: Tagesübersicht (alle Tagesrätsel auf einen Blick, auch für den Sperrbildschirm)

struct UebersichtZeile: Identifiable {
    let info: TagesSpielInfo
    let serie: Int
    let geloest: Bool
    var id: String { info.id }
}

struct UebersichtEintrag: TimelineEntry {
    let date: Date
    let zeilen: [UebersichtZeile]
    var erledigt: Int { zeilen.filter(\.geloest).count }
    /// Erstes noch offenes Tagesrätsel (Ziel beim Tippen).
    var naechstes: TagesSpielInfo? { zeilen.first { !$0.geloest }?.info }
}

struct UebersichtProvider: TimelineProvider {
    func placeholder(in context: Context) -> UebersichtEintrag {
        UebersichtEintrag(date: .now, zeilen: TagesSpielInfo.alle.enumerated().map { UebersichtZeile(info: $1, serie: $0 % 3, geloest: $0 % 2 == 0) })
    }
    func getSnapshot(in context: Context, completion: @escaping (UebersichtEintrag) -> Void) { completion(lesen()) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<UebersichtEintrag>) -> Void) {
        completion(Timeline(entries: [lesen()], policy: .after(naechsterTag())))
    }
    private func lesen() -> UebersichtEintrag {
        let heute = Tagesschluessel.text(.now)
        let zeilen = TagesSpielInfo.alle.map { i -> UebersichtZeile in
            let t = PartieGeteilt.tag(praefix: i.praefix)
            return UebersichtZeile(info: i, serie: TagesSerie.lebend(serie: t.serie, letzterTag: t.letzterTag, toleranz: i.toleranz), geloest: t.letzterTag == heute)
        }
        return UebersichtEintrag(date: .now, zeilen: zeilen)
    }
}

/// Beginn des nächsten Kalendertags (kurz nach Mitternacht), nicht +24 h wegen der Zeitumstellung.
func naechsterTag() -> Date {
    let beginn = Calendar.current.startOfDay(for: .now)
    return (Calendar.current.date(byAdding: .day, value: 1, to: beginn) ?? beginn.addingTimeInterval(24 * 3600)).addingTimeInterval(60)
}

struct UebersichtAnsicht: View {
    let eintrag: UebersichtEintrag
    @Environment(\.widgetFamily) private var familie

    private var ziel: URL? {
        if let n = eintrag.naechstes { return URL(string: "partie://spiel/\(n.id)") }
        return URL(string: "partie://")
    }

    var body: some View {
        switch familie {
        case .accessoryCircular:
            Gauge(value: Double(eintrag.erledigt), in: 0...Double(max(1, eintrag.zeilen.count))) {
                Image(systemName: "calendar")
            } currentValueLabel: {
                Text(verbatim: "\(eintrag.erledigt)")
            }
            .gaugeStyle(.accessoryCircular)
            .widgetURL(ziel)
            .containerBackground(for: .widget) { Color.clear }
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Text("Tagesrätsel").font(.headline).widgetAccentable()
                Text("\(eintrag.erledigt) von \(eintrag.zeilen.count) geschafft")
                Gauge(value: Double(eintrag.erledigt), in: 0...Double(max(1, eintrag.zeilen.count))) { EmptyView() }
                    .gaugeStyle(.accessoryLinear)
            }
            .widgetURL(ziel)
            .containerBackground(for: .widget) { Color.clear }
        case .accessoryInline:
            Label("Tagesrätsel: \(eintrag.erledigt) von \(eintrag.zeilen.count)", systemImage: "calendar")
                .widgetURL(ziel)
                .containerBackground(for: .widget) { Color.clear }
        case .systemLarge:
            if stil.art == .klar { gross } else { neu(gross: true) }
        default:
            if stil.art == .klar { mittel } else { neu(gross: false) }
        }
    }

    private var stil: WidgetStil { WidgetStil(roh: PartieGeteilt.design()) }

    /// Tinte und Salon (Designwechsel E): Ansicht aus `WidgetAnsichten.swift`.
    private func neu(gross: Bool) -> some View {
        UebersichtKachel(stil: stil, zeilen: eintrag.zeilen.map { UebersichtKachelZeile(id: $0.info.id, name: $0.info.name, geloest: $0.geloest, serie: $0.serie) }, gross: gross)
            .widgetKachel(stil, id: "solitaer")
    }

    private var kopf: some View {
        HStack {
            Text("Tagesrätsel").font(.headline.weight(.bold))
            Spacer()
            Text("\(eintrag.erledigt) von \(eintrag.zeilen.count)").font(.subheadline.weight(.semibold)).opacity(0.9)
        }
    }

    private var mittel: some View {
        VStack(alignment: .leading, spacing: 10) {
            kopf
            let spalten = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)
            LazyVGrid(columns: spalten, spacing: 8) {
                ForEach(eintrag.zeilen) { z in
                    Link(destination: URL(string: "partie://spiel/\(z.info.id)")!) {
                        VStack(spacing: 3) {
                            Image(systemName: z.geloest ? "checkmark.circle.fill" : "circle")
                                .font(.title3.weight(.semibold))
                            Text(verbatim: z.info.name).font(.caption2.weight(.semibold)).lineLimit(1).minimumScaleFactor(0.6)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 8)
                        .background(Color.familie(z.info.farbeHex).opacity(z.geloest ? 1 : 0.55), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
            }
        }
        .foregroundStyle(.white)
        .containerBackground(for: .widget) { Color.familie(hülle) }
    }

    private var gross: some View {
        VStack(alignment: .leading, spacing: 8) {
            kopf
            ForEach(eintrag.zeilen) { z in
                Link(destination: URL(string: "partie://spiel/\(z.info.id)")!) {
                    HStack(spacing: 10) {
                        Image(systemName: z.geloest ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(Color.familie(z.info.farbeHex)).font(.title3)
                            .frame(width: 26, height: 26).background(.white, in: Circle())
                        Text(verbatim: z.info.name).font(.subheadline.weight(.semibold))
                        Spacer()
                        if z.serie > 0 {
                            Label { Text(verbatim: "\(z.serie)") } icon: { Image(systemName: "flame.fill") }.font(.subheadline.weight(.semibold))
                        }
                        Text(z.geloest ? "Geschafft" : "Offen").font(.caption).opacity(0.85).frame(minWidth: 52, alignment: .trailing)
                    }
                }
            }
        }
        .foregroundStyle(.white)
        .containerBackground(for: .widget) { Color.familie(hülle) }
    }
}

struct UebersichtWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "partie.uebersicht", provider: UebersichtProvider()) { UebersichtAnsicht(eintrag: $0) }
            .configurationDisplayName("Tagesrätsel-Übersicht")
            .description("Alle Tagesrätsel auf einen Blick; Tippen öffnet das nächste offene.")
            .supportedFamilies([.systemMedium, .systemLarge, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

// MARK: Weiterspielen (zuletzt gespieltes Spiel)

struct WeiterEintrag: TimelineEntry {
    let date: Date
    let zuletzt: PartieGeteilt.Zuletzt?
}

struct WeiterProvider: TimelineProvider {
    func placeholder(in context: Context) -> WeiterEintrag {
        WeiterEintrag(date: .now, zuletzt: .init(id: "sudoku", name: "Sudoku", farbeHex: Familienfarbe.blau.flaeche, datum: .now))
    }
    func getSnapshot(in context: Context, completion: @escaping (WeiterEintrag) -> Void) { completion(WeiterEintrag(date: .now, zuletzt: PartieGeteilt.zuletzt())) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<WeiterEintrag>) -> Void) {
        // stündlich neu, damit „vor 3 Stunden“ stimmt; die App lädt außerdem bei jedem Spielwechsel neu
        completion(Timeline(entries: [WeiterEintrag(date: .now, zuletzt: PartieGeteilt.zuletzt())], policy: .after(.now.addingTimeInterval(3600))))
    }
}

struct WeiterAnsicht: View {
    let eintrag: WeiterEintrag
    @Environment(\.widgetFamily) private var familie

    private var ziel: URL? {
        eintrag.zuletzt.flatMap { URL(string: "partie://spiel/\($0.id)") } ?? URL(string: "partie://zufall")
    }
    private var wann: String {
        guard let z = eintrag.zuletzt else { return "" }
        return RelativeDateTimeFormatter().localizedString(for: z.datum, relativeTo: .now)
    }

    var body: some View {
        Group {
            switch familie {
            case .accessoryCircular:
                ZStack { AccessoryWidgetBackground(); Image(systemName: "play.fill").font(.title2) }
            case .accessoryInline:
                Label { if let z = eintrag.zuletzt { Text("Weiter: \(z.name)") } else { Text("Spiel wählen") } } icon: { Image(systemName: "play.circle") }
            case .accessoryRectangular:
                VStack(alignment: .leading, spacing: 2) {
                    Text("Weiterspielen").font(.headline).widgetAccentable()
                    if let z = eintrag.zuletzt { Text(verbatim: z.name); Text(verbatim: wann).font(.caption) } else { Text("Zufälliges Spiel") }
                }
            default:
                if stil.art != .klar {
                    WeiterKachel(stil: stil, id: eintrag.zuletzt?.id, name: eintrag.zuletzt?.name, wann: wann, klein: familie == .systemSmall)
                } else {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Weiterspielen", systemImage: "play.circle.fill").font(.subheadline.weight(.semibold)).opacity(0.9)
                    Spacer(minLength: 0)
                    if let z = eintrag.zuletzt {
                        Text(verbatim: z.name).font(familie == .systemSmall ? .title2.bold() : .largeTitle.bold()).lineLimit(1).minimumScaleFactor(0.6)
                        Text(verbatim: wann).font(.caption).opacity(0.85)
                    } else {
                        Text("Noch kein Spiel gespielt").font(.headline)
                        Text("Tippen für ein zufälliges Spiel").font(.caption).opacity(0.85)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(.white)
                }
            }
        }
        .widgetURL(ziel)
        .containerBackground(for: .widget) {
            if familie.rawValue >= WidgetFamily.accessoryCircular.rawValue { Color.clear }
            else if stil.art != .klar { stil.grund(id: eintrag.zuletzt?.id) }
            else { Color.familie(eintrag.zuletzt?.farbeHex ?? hülle) }
        }
        .modifier(WeiterSchrift(stil: stil, id: eintrag.zuletzt?.id, aktiv: familie.rawValue < WidgetFamily.accessoryCircular.rawValue))
    }
    private var stil: WidgetStil { WidgetStil(roh: PartieGeteilt.design()) }
}

/// Schriftfarbe und Serife der Weiterspielen-Kachel in Tinte und Salon (klar und Sperrbildschirm bleiben, wie sie waren).
struct WeiterSchrift: ViewModifier {
    let stil: WidgetStil
    let id: String?
    let aktiv: Bool
    func body(content: Content) -> some View {
        if aktiv && stil.art != .klar { content.foregroundStyle(stil.schrift(id: id)).fontDesign(.serif) } else { content }
    }
}

struct WeiterWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "partie.weiter", provider: WeiterProvider()) { WeiterAnsicht(eintrag: $0) }
            .configurationDisplayName("Weiterspielen")
            .description("Öffnet das Spiel, das du zuletzt gespielt hast.")
            .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

// MARK: Bestleistungen

struct RekordEintrag: TimelineEntry {
    let date: Date
    let rekorde: [PartieGeteilt.Rekord]
    let summen: PartieGeteilt.Summen
}

struct RekordProvider: TimelineProvider {
    func placeholder(in context: Context) -> RekordEintrag {
        RekordEintrag(date: .now, rekorde: [.init(id: "steinfall", name: "Steinfall", farbeHex: Familienfarbe.orange.flaeche, punkte: 1240, datum: .now)], summen: .init(partien: 12, siege: 7))
    }
    func getSnapshot(in context: Context, completion: @escaping (RekordEintrag) -> Void) { completion(lesen()) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<RekordEintrag>) -> Void) {
        completion(Timeline(entries: [lesen()], policy: .never))   // die App lädt nach jeder Partie neu
    }
    private func lesen() -> RekordEintrag { RekordEintrag(date: .now, rekorde: PartieGeteilt.rekorde(), summen: PartieGeteilt.summen()) }
}

struct RekordAnsicht: View {
    let eintrag: RekordEintrag
    @Environment(\.widgetFamily) private var familie

    var body: some View {
        switch familie {
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Text("Bestleistung").font(.headline).widgetAccentable()
                if let r = eintrag.rekorde.first { Text(verbatim: r.name); Text(verbatim: "\(r.punkte)").font(.title3.bold()) } else { Text("Noch keine Wertung") }
            }
            .containerBackground(for: .widget) { Color.clear }
        case .accessoryInline:
            Label { if let r = eintrag.rekorde.first { Text(verbatim: "\(r.name): \(r.punkte)") } else { Text("Bestleistung") } } icon: { Image(systemName: "trophy") }
                .containerBackground(for: .widget) { Color.clear }
        case .systemMedium where stil.art != .klar:
            RekordKachel(stil: stil, rekorde: eintrag.rekorde.map { RekordKachelZeile(id: $0.id, name: $0.name, punkte: $0.punkte) },
                         partien: eintrag.summen.partien, siege: eintrag.summen.siege, mittel: true)
                .widgetKachel(stil, id: eintrag.rekorde.first?.id)
        case .systemMedium:
            VStack(alignment: .leading, spacing: 6) {
                kopf
                if eintrag.rekorde.isEmpty { leer } else {
                    ForEach(eintrag.rekorde.prefix(3), id: \.id) { r in
                        Link(destination: URL(string: "partie://spiel/\(r.id)")!) {
                            HStack {
                                Circle().fill(Color.familie(r.farbeHex)).frame(width: 10, height: 10).overlay(Circle().stroke(.white.opacity(0.8), lineWidth: 1))
                                Text(verbatim: r.name).font(.subheadline.weight(.semibold)).lineLimit(1)
                                Spacer()
                                Text(verbatim: "\(r.punkte)").font(.title3.bold().monospacedDigit())
                            }
                        }
                    }
                }
                Spacer(minLength: 0)
                if eintrag.summen.partien > 0 {
                    Text("\(eintrag.summen.partien) Partien, \(eintrag.summen.siege) Siege").font(.caption).opacity(0.85)
                }
            }
            .foregroundStyle(.white)
            .containerBackground(for: .widget) { Color.familie(hülle) }
        case _ where stil.art != .klar:
            RekordKachel(stil: stil, rekorde: eintrag.rekorde.map { RekordKachelZeile(id: $0.id, name: $0.name, punkte: $0.punkte) },
                         partien: eintrag.summen.partien, siege: eintrag.summen.siege)
                .widgetURL(URL(string: eintrag.rekorde.first.map { "partie://spiel/\($0.id)" } ?? "partie://zufall"))
                .widgetKachel(stil, id: eintrag.rekorde.first?.id)
        default:
            let r = eintrag.rekorde.first
            VStack(alignment: .leading, spacing: 4) {
                kopf
                Spacer(minLength: 0)
                if let r {
                    Text(verbatim: "\(r.punkte)").font(.system(.largeTitle, design: .rounded).weight(.bold).monospacedDigit()).minimumScaleFactor(0.6)
                    Text(verbatim: r.name).font(.subheadline.weight(.semibold)).lineLimit(1)
                } else { leer }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(.white)
            .widgetURL(URL(string: r.map { "partie://spiel/\($0.id)" } ?? "partie://zufall"))
            .containerBackground(for: .widget) { Color.familie(r?.farbeHex ?? hülle) }
        }
    }

    private var stil: WidgetStil { WidgetStil(roh: PartieGeteilt.design()) }

    private var kopf: some View {
        Label("Bestleistung", systemImage: "trophy.fill").font(.subheadline.weight(.semibold)).opacity(0.9)
    }
    private var leer: some View {
        Text("Noch keine Wertung").font(.subheadline)
    }
}

struct RekordWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "partie.bestleistung", provider: RekordProvider()) { RekordAnsicht(eintrag: $0) }
            .configurationDisplayName("Bestleistung")
            .description("Deine zuletzt erzielte Höchstpunktzahl in den Spielen mit Wertung.")
            .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryInline])
    }
}

@main
struct PartieWidgetBundle: WidgetBundle {
    var body: some Widget {
        UebersichtWidget()
        WeiterWidget()
        RekordWidget()
        MinensucheTagesWidget()
        SudokuTagesWidget()
        SolitaerTagesWidget()
        ViererreiheTagesWidget()
        GalgenTagesWidget()
        WortpfeilTagesWidget()
        FarbraetselTagesWidget()
        if #available(iOS 16.2, *) { PartieAktivitaetWidget() }
        if #available(iOS 18.0, *) {
            ZufallsSteuerung()
            WeiterSteuerung()
            TagesraetselSteuerung()
        }
    }
}

extension Color {
    /// Mockup-Hexwert als Farbe (der Baukasten hält sein `init(hex:)` intern).
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }
}
