// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas

// Designwechsel Stufe E: Widget-Ansichten für Tinte und Salon. „Klar & Glas“ bleibt in den Widgets, wie es war (der Aufrufer
// zeichnet dort den alten Code); diese Datei kennt nur die beiden neuen Designs. Reine SwiftUI-Ansichten ohne WidgetKit, damit
// sie auch in den Bildproben (Test/DesignBilder) gezeichnet werden können. Farben und Zahlen kommen aus `DesignWerte` des Baukastens
// (dieselbe Tabelle wie die App, keine zweite Stelle). Hintergrund setzt der Aufrufer (`containerBackground` im Widget, `background` im Bild).

struct WidgetStil {
    let art: DesignArt
    init(roh: String) { art = DesignArt(rawValue: roh) ?? .klar }
    init(_ art: DesignArt) { self.art = art }

    var werte: DesignWerte { DesignWerte.fuer(art) }
    var istSalon: Bool { art == .salon }

    /// Spielart eines Spiels (Kennung der Sammlung); unbekannte Kennungen fallen auf Karten (Terrakotta in Salon).
    static func spielart(id: String) -> Design.Spielart {
        switch id {
        case "yacht", "schocken", "10k", "maexchen", "chicago", "pokerwurf", "koenigsweg": .wuerfel
        case "sudoku", "minensuche", "kakuro", "schiebepuzzle", "irrgang", "farbflut", "farbraetsel": .raetsel
        case "viererreihe", "rauswurf", "muehle": .brett
        case "galgenmaennchen", "wortpfeil": .wort
        default: .karten
        }
    }

    func farben(_ id: String?) -> SpielartFarben? { werte.palette?[Self.spielart(id: id ?? "")] }

    /// Hintergrund der Kachel: Tinte Papier, Salon Farbfläche der Spielart (kleine Schrift darauf lesbar).
    func grund(id: String?) -> Color {
        if istSalon, let f = farben(id) { return f.flaecheFuerKleineSchrift }
        return werte.seitenGrund?.color ?? .clear
    }
    func schrift(id: String?) -> Color {
        if istSalon, let f = farben(id) { return f.aufFlaeche }
        return werte.schrift?.color ?? .primary
    }
    func schriftZweit(id: String?) -> Color {
        istSalon ? schrift(id: id).opacity(0.82) : (werte.schriftZweit?.color ?? .secondary)
    }
    func linie(id: String?) -> Color {
        istSalon ? schrift(id: id).opacity(0.35) : (werte.linieStark?.color ?? .primary)
    }
    /// Punkt in der Spielart-Farbe (Tinte); in Salon trägt die Fläche selbst die Farbe, der Punkt ist Schriftfarbe.
    func punkt(id: String?) -> Color { istSalon ? schrift(id: id) : (farben(id)?.flaeche ?? .primary) }
    var serif: Font.Design { .serif }
}

extension View {
    /// Schrift, Serife und Hintergrund einer Kachel. `container` entscheidet: im Widget `containerBackground`, im Bild `background`.
    @ViewBuilder func widgetKachel(_ stil: WidgetStil, id: String?, container: Bool = true, groesse: CGSize = CGSize(width: 158, height: 158)) -> some View {
        let v = self.foregroundStyle(stil.schrift(id: id)).fontDesign(.serif)
        if container { v.containerBackground(for: .widget) { stil.grund(id: id) } }
        else { v.padding(16).frame(width: groesse.width, height: groesse.height).background(stil.grund(id: id)).clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous)) }
    }
}

// MARK: Tagesrätsel eines Spiels

struct TagesKachel: View {
    let stil: WidgetStil
    let id: String
    let name: String
    let datum: Date
    let geloest: Bool
    let serie: Int
    let serieText: String
    var klein = true

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if stil.istSalon {
                Text("Tagesrätsel").textCase(.uppercase).font(.system(size: 10, weight: .semibold)).tracking(1.6).foregroundStyle(stil.schriftZweit(id: id))
                Spacer(minLength: 0)
                Text(verbatim: name).font(.system(size: klein ? 26 : 34, weight: .bold, design: .serif)).lineLimit(1).minimumScaleFactor(0.45)
                Text(geloest ? "Heute geschafft" : "Heute noch offen").font(.system(.subheadline, design: .serif)).italic()
                Text(verbatim: serieText).font(.caption).foregroundStyle(stil.schriftZweit(id: id))
            } else {
                HStack(spacing: 6) {
                    Circle().fill(stil.punkt(id: id)).frame(width: 8, height: 8)
                    Text(verbatim: name).font(.system(.headline, design: .serif)).lineLimit(1).minimumScaleFactor(0.6)
                    Spacer()
                    Text(datum.formatted(.dateTime.day().month(.abbreviated))).font(.caption).foregroundStyle(stil.schriftZweit(id: id))
                }
                Rectangle().fill(stil.linie(id: id)).frame(height: 1)
                Spacer(minLength: 0)
                Label { Text(geloest ? "Heute geschafft" : "Heute noch offen") } icon: { Image(systemName: geloest ? "checkmark.seal.fill" : "circle.dashed") }
                    .font(.system(.subheadline, design: .serif, weight: .semibold))
                Text(verbatim: serieText).font(.caption).foregroundStyle(stil.schriftZweit(id: id))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: Tagesübersicht

struct UebersichtKachelZeile: Identifiable {
    let id: String
    let name: String
    let geloest: Bool
    let serie: Int
}

struct UebersichtKachel: View {
    let stil: WidgetStil
    let zeilen: [UebersichtKachelZeile]
    var gross = false
    /// Link je Spiel; im Bild leer.
    var link: (String) -> URL? = { URL(string: "partie://spiel/\($0)") }

    private var erledigt: Int { zeilen.filter(\.geloest).count }
    private let kennung = "solitaer"   // Salon: Terrakotta (Karten) für die Übersicht

    var body: some View {
        VStack(alignment: .leading, spacing: gross ? 8 : 8) {
            HStack(alignment: .firstTextBaseline) {
                if stil.istSalon {
                    Text("Tagesrätsel").textCase(.uppercase).font(.system(size: 10, weight: .semibold)).tracking(1.6)
                } else {
                    Text("Tagesrätsel").font(.system(.headline, design: .serif))
                }
                Spacer()
                Text("\(erledigt) von \(zeilen.count)").font(.system(.title3, design: .serif, weight: .bold)).monospacedDigit()
            }
            Rectangle().fill(stil.linie(id: kennung)).frame(height: 1)
            if gross {
                ForEach(zeilen) { z in
                    zeile(z)
                }
            } else {
                let spalten = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)
                LazyVGrid(columns: spalten, alignment: .leading, spacing: 8) {
                    ForEach(zeilen) { z in
                        verlinkt(z) {
                            VStack(spacing: 3) {
                                Image(systemName: z.geloest ? "checkmark.circle.fill" : "circle").font(.title3.weight(.semibold))
                                    .foregroundStyle(z.geloest ? stil.punkt(id: z.id) : stil.schriftZweit(id: kennung))
                                Text(verbatim: z.name).font(.system(.caption2, design: .serif, weight: .semibold)).lineLimit(1).minimumScaleFactor(0.6)
                            }.frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
    }

    private func zeile(_ z: UebersichtKachelZeile) -> some View {
        verlinkt(z) {
            HStack(spacing: 10) {
                Image(systemName: z.geloest ? "checkmark.circle.fill" : "circle").font(.title3)
                    .foregroundStyle(z.geloest ? stil.punkt(id: z.id) : stil.schriftZweit(id: kennung))
                Text(verbatim: z.name).font(.system(.subheadline, design: .serif, weight: .semibold))
                Spacer()
                if z.serie > 0 { Label { Text(verbatim: "\(z.serie)") } icon: { Image(systemName: "flame.fill") }.font(.subheadline.weight(.semibold)) }
                Text(z.geloest ? "Geschafft" : "Offen").font(.caption).foregroundStyle(stil.schriftZweit(id: kennung)).frame(minWidth: 52, alignment: .trailing)
            }
        }
    }

    @ViewBuilder private func verlinkt<I: View>(_ z: UebersichtKachelZeile, @ViewBuilder _ inhalt: () -> I) -> some View {
        if let u = link(z.id) { Link(destination: u) { inhalt() } } else { inhalt() }
    }
}

// MARK: Weiterspielen

struct WeiterKachel: View {
    let stil: WidgetStil
    let id: String?
    let name: String?
    let wann: String
    var klein = true

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if stil.istSalon {
                Text("Weiterspielen").textCase(.uppercase).font(.system(size: 10, weight: .semibold)).tracking(1.6).foregroundStyle(stil.schriftZweit(id: id))
            } else {
                HStack(spacing: 6) {
                    Circle().fill(stil.punkt(id: id)).frame(width: 8, height: 8)
                    Text("Weiterspielen").font(.system(.subheadline, design: .serif, weight: .semibold))
                }
                Rectangle().fill(stil.linie(id: id)).frame(height: 1)
            }
            Spacer(minLength: 0)
            if let name {
                Text(verbatim: name).font(.system(size: klein ? 26 : 34, weight: .bold, design: .serif)).lineLimit(1).minimumScaleFactor(0.45)
                Text(verbatim: wann).font(.caption).foregroundStyle(stil.schriftZweit(id: id))
            } else {
                Text("Noch kein Spiel gespielt").font(.system(.headline, design: .serif))
                Text("Tippen für ein zufälliges Spiel").font(.caption).foregroundStyle(stil.schriftZweit(id: id))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: Bestleistung

struct RekordKachelZeile: Identifiable {
    let id: String
    let name: String
    let punkte: Int
}

struct RekordKachel: View {
    let stil: WidgetStil
    let rekorde: [RekordKachelZeile]
    let partien: Int
    let siege: Int
    var mittel = false

    private var erste: String? { rekorde.first?.id }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if stil.istSalon {
                Text("Bestleistung").textCase(.uppercase).font(.system(size: 10, weight: .semibold)).tracking(1.6).foregroundStyle(stil.schriftZweit(id: erste))
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "trophy.fill").font(.caption)
                    Text("Bestleistung").font(.system(.subheadline, design: .serif, weight: .semibold))
                }
                Rectangle().fill(stil.linie(id: erste)).frame(height: 1)
            }
            if mittel {
                if rekorde.isEmpty { Text("Noch keine Wertung").font(.subheadline) }
                ForEach(rekorde.prefix(3)) { r in
                    HStack {
                        Circle().fill(stil.punkt(id: r.id)).frame(width: 8, height: 8)
                        Text(verbatim: r.name).font(.system(.subheadline, design: .serif, weight: .semibold)).lineLimit(1)
                        Spacer()
                        Text(verbatim: "\(r.punkte)").font(.system(.title3, design: .serif, weight: .bold)).monospacedDigit()
                    }
                }
                Spacer(minLength: 0)
                if partien > 0 { Text("\(partien) Partien, \(siege) Siege").font(.caption).foregroundStyle(stil.schriftZweit(id: erste)) }
            } else {
                Spacer(minLength: 0)
                if let r = rekorde.first {
                    Text(verbatim: "\(r.punkte)").font(.system(size: 40, weight: .bold, design: .serif)).monospacedDigit().minimumScaleFactor(0.6)
                    Text(verbatim: r.name).font(.system(.subheadline, design: .serif, weight: .semibold)).lineLimit(1)
                } else { Text("Noch keine Wertung").font(.subheadline) }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
