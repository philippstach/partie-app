// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

// Designwechsel C.5: Bausteine der Einführung (erster Start) für die Designs Tinte und Salon.
// `EinfuehrungSeiten` behält Ablauf, Texte und Zustand; hier steht nur der Aufbau einer Seite.
// Tinte: wie eine Buchseite (Seitenzahl kursiv, Titel linksbündig, Symbol als feine Strichzeichnung).
// Salon: obere Hälfte ein Farbblock in einer Palettenfarbe mit römischer Ziffer und Schlagzeile, das Symbol groß in Creme
// an der Blockkante; der Text darunter auf Creme.

/// Römische Ziffern der Seiten (Salon).
private let einfuehrungRoemisch = ["I", "II", "III", "IV", "V", "VI"]

/// Kopf einer Einführungsseite in Tinte oder Salon. Steht als erstes Element in der Seite.
/// Tinte: Seitenzahl kursiv, Symbol als feine Strichzeichnung, Titel linksbündig, Text, Tinte-Linie.
/// Salon: Farbblock in einer Palettenfarbe (je Seite eine andere) mit römischer Ziffer und Schlagzeile, das Symbol groß in Creme
/// an der Blockkante; der Text darunter auf Creme. `rand`: waagerechter Innenrand des umgebenden Stapels, über den der Block hinausreicht.
struct EinfuehrungKopfNeu: View {
    /// 0-basiert
    let nummer: Int
    let anzahl: Int
    let symbol: String?
    let titel: LocalizedStringKey
    let text: LocalizedStringKey
    var rand: CGFloat = 0
    @Environment(\.designArt) private var art

    var body: some View {
        if art == .salon { salon } else { tinte }
    }

    private var tinte: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(verbatim: "\(nummer + 1) / \(anzahl)")
                .font(Design.Schrift.serif(18, relativ: .body, kursiv: true)).foregroundStyle(Color.schriftZweit)
                .accessibilityLabel(Text("Seite \(nummer + 1) von \(anzahl)"))
            if let symbol {
                Image(systemName: symbol).font(.system(size: 64, weight: .ultraLight)).foregroundStyle(Color.schrift)
                    .padding(.top, 24).accessibilityHidden(true)
            }
            Text(titel)
                .font(Design.Schrift.serif(40, gewicht: .medium, relativ: .largeTitle, hoechstens: 1.2)).tracking(-0.8)
                .foregroundStyle(Color.schrift).fixedSize(horizontal: false, vertical: true)
                .padding(.top, 22).accessibilityAddTraits(.isHeader)
            Text(text).font(.body).foregroundStyle(Color.schriftZweit).fixedSize(horizontal: false, vertical: true)
                .padding(.top, 10).padding(.bottom, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .linieUnten(stark: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Farbe des Blocks: je Seite eine andere Palettenfarbe (Terrakotta, Nachtblau, Oliv, Petrol).
    private var block: (flaeche: Color, schrift: Color) { Self.blockFarben(nummer: nummer) }

    /// Farben des Blocks einer Seite (auch für die Kopfleiste darüber, damit kein Streifen zwischen Leiste und Block bleibt).
    static func blockFarben(nummer: Int) -> (flaeche: Color, schrift: Color) {
        let folge: [Design.Spielart] = [.karten, .wuerfel, .brett, .raetsel]
        if let f = Design.werte.palette?[folge[nummer % folge.count]] { return (f.flaecheFuerKleineSchrift, f.aufFlaeche) }
        return (Color.hinweisFlaecheHuelle, Design.werte.aufHuelleFlaeche.color)
    }

    /// „I / IV“: römische Seitenzahl, damit das Label lesbar ist (eine einzelne „I“ sah wie ein verirrter Strich aus).
    private var seitenLabel: String {
        let z = einfuehrungRoemisch
        return "\(z[nummer % z.count]) / \(z[(max(anzahl, 1) - 1) % z.count])"
    }

    private func kantenSymbol(_ symbol: String, _ farbe: Color) -> some View {
        Image(systemName: symbol).font(.system(size: 84, weight: .bold)).foregroundStyle(farbe)
            .padding(.trailing, Theme.seitenRand).offset(y: 30).accessibilityHidden(true)
    }

    private var salon: some View {
        let b = block
        return VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                Text(verbatim: seitenLabel).designLabel(b.schrift).opacity(0.9)
                    .accessibilityLabel(Text("Seite \(nummer + 1) von \(anzahl)"))
                Text(titel)
                    .font(Design.Schrift.serif(48, gewicht: .bold, relativ: .largeTitle, hoechstens: 1.15).leading(.tight)).tracking(-1.4)
                    .lineLimit(3).minimumScaleFactor(0.5).fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 10).padding(.trailing, symbol == nil ? 0 : 40).accessibilityAddTraits(.isHeader)
            }
            .foregroundStyle(b.schrift)
            .padding(.horizontal, Theme.seitenRand).padding(.top, 24).padding(.bottom, symbol == nil ? 28 : 72)
            .frame(maxWidth: .infinity, minHeight: symbol == nil ? 190 : 250, alignment: .topLeading)
            .background(b.flaeche)
            // Symbol groß an der Blockkante: der Teil auf dem Block in der Grundfarbe der Seite, der überstehende Teil in der Schriftfarbe
            .overlay(alignment: .bottomTrailing) { if let symbol { kantenSymbol(symbol, Color.seitenGrund) } }
            .clipped()
            .background(alignment: .bottomTrailing) { if let symbol { kantenSymbol(symbol, Color.schrift) } }
            .padding(.horizontal, -rand)
            .zIndex(1)
            Text(text).font(Design.Schrift.serif(19, gewicht: .light, relativ: .body)).foregroundStyle(Color.schrift)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, symbol == nil ? 20 : 44)
        }
    }
}

/// Punktzeile der Seitenanzeige in Tinte und Salon (ersetzt dort die Punkte des `TabView`).
struct EinfuehrungPunkte: View {
    let seite: Int
    let anzahl: Int
    @Environment(\.designArt) private var art
    @Environment(\.accessibilityReduceMotion) private var weniger

    var body: some View {
        HStack(spacing: Design.Abstand.s) {
            ForEach(0..<anzahl, id: \.self) { i in
                if art == .salon {
                    Rectangle().fill(i == seite ? Color.schrift : Color.linie).frame(width: i == seite ? 28 : 14, height: 3)
                } else {
                    Circle().fill(i == seite ? Color.schrift : Color.clear).frame(width: 8, height: 8)
                        .overlay { Circle().strokeBorder(Color.schrift, lineWidth: 1) }
                }
            }
        }
        .animation(weniger ? nil : .smooth, value: seite)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Seite \(seite + 1) von \(anzahl)"))
    }
}

/// Liste der Spielarten für die Seite „Für jeden etwas“ in Tinte (Zeilen mit Tintenpunkt) und Salon (Zeilen mit Farbstreifen).
struct EinfuehrungSpielarten: View {
    @Environment(\.designArt) private var art

    var body: some View {
        VStack(spacing: 0) {
            // nur Spielarten, zu denen es sichtbare Spiele gibt
            ForEach(SpielZeilen.spielarten.filter { g in SpielKatalog.sichtbar.contains { $0.gattung == g } }, id: \.self) { g in
                HStack(spacing: art == .salon ? 16 : Design.Abstand.m) {
                    if art == .salon { g.farbe.color.frame(width: 14) } else { Circle().fill(g.farbe.color).frame(width: 10, height: 10) }
                    Text(g.name).font(Design.Schrift.name).foregroundStyle(Color.schrift)
                    Spacer(minLength: 0)
                }
                .frame(minHeight: 46)
                .linieUnten()
                .accessibilityElement(children: .combine)
            }
        }
    }
}

/// Kachel eines Spiels auf der Favoriten-Seite in Tinte und Salon: Rand statt Farbfläche, gewählt deutlich markiert.
struct EinfuehrungFavoritKachel: View {
    let modul: any SpielModul
    /// Anzeigename (ohne „(neu)“)
    let name: String
    let an: Bool
    @Environment(\.designArt) private var art

    var body: some View {
        let farbe = modul.gattung.farbe
        VStack(spacing: Design.Abstand.xs) {
            Image(systemName: EinfuehrungSymbol.name(modul.symbol)).font(.title2).frame(height: 32)
            Text(verbatim: name).font(.caption).lineLimit(2).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 80).padding(6)
        .foregroundStyle(an && art == .salon ? farbe.aufFlaeche : Color.schrift)
        .background(an && art == .salon ? farbe.color : Color.clear)
        .overlay { Rectangle().strokeBorder(an ? (art == .salon ? Color.clear : Color.linieStark) : Color.linie, lineWidth: an ? 2 : 1) }
        .overlay(alignment: .topLeading) { if art == .tinte { Circle().fill(farbe.color).frame(width: 8, height: 8).padding(7) } }
        .overlay(alignment: .topTrailing) {
            if an { Image(systemName: "checkmark").font(.caption.weight(.bold)).padding(6) }
        }
        .contentShape(.rect)
    }
}

/// P-018: Gibt es ein Symbol auf diesem iOS nicht (Mäxchen: „questionmark.dice.fill“ erst ab neueren Fassungen), bliebe die Kachel leer; dann ein Würfel, den es immer gibt.
enum EinfuehrungSymbol {
    static func name(_ symbol: String) -> String {
        UIImage(systemName: symbol) == nil ? "die.face.2.fill" : symbol
    }
}
