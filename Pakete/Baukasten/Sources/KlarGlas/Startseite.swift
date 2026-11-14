// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI

// Klar & Glas – Bausteine der Startseite (Handbuch Teil B, Konzept 3.4 „Start“).
// Reihenfolge auf dem Start: StartTitel → WeiterspielenKarte → TagesKarte → Spielmodi (AuswahlZeile, höchstens vier)
// → StatistikZeile → unten EIN Hauptknopf „Neues Spiel“. Apps binden ein und bauen nichts nach.

/// „Guten Morgen/Tag/Abend“ nach Tageszeit. Ohne Namen nur die Anrede (Beschluss E2: Apps rufen ohne Namen auf).
public enum Gruss {
    public static func text(name: String? = nil, datum: Date = .now, kalender: Calendar = .current) -> String {
        let stunde = kalender.component(.hour, from: datum)
        let anrede: String
        switch stunde {
        case 5..<11: anrede = String(localized: "Guten Morgen", bundle: .module, comment: "Gruß vormittags")
        case 11..<18: anrede = String(localized: "Guten Tag", bundle: .module, comment: "Gruß tagsüber")
        default: anrede = String(localized: "Guten Abend", bundle: .module, comment: "Gruß abends")
        }
        guard let name, !name.isEmpty else { return anrede }
        return "\(anrede), \(name)"
    }
}

#if canImport(UIKit)

/// Großer, linksbündiger App-Titel in der App-Farbe mit Gruß darunter. Immer oberstes Element der Startseite.
/// `StartTitel("Sudoku")` zeigt den Gruß nach Tageszeit ohne Namen (E2).
public struct StartTitel: View {
    /// klar: die Titelgröße (56 pt mal Regler) mit Dynamic Type skaliert, wie bisher.
    @ScaledMetric(relativeTo: .largeTitle) private var groesse = DesignWerte.klar.titelGroesse * CGFloat(Design.Regler.schrift)
    /// Tinte und Salon: nur der Faktor, damit die Größe dem gewählten Design folgt.
    @ScaledMetric(relativeTo: .largeTitle) private var faktor: CGFloat = 1
    @Environment(\.startTitelFarbe) private var titelFarbe
    @Environment(\.designArt) private var art
    let titel: Text
    let untertitel: Text
    /// 2.30 (F-AWS-K-038): Ein langes Einzelwort (z. B. „Galgenmännchen“) bleibt auch im Salon einzeilig und wird verkleinert,
    /// statt mitten im Wort umzubrechen. Vorgabe false (bis zu zwei Zeilen).
    var einzeilig = false

    /// Titel in einer Zeile halten (Salon verkleinert statt zu brechen). Für Titel aus einem einzigen langen Wort.
    public func einzeilig(_ an: Bool = true) -> StartTitel {
        var kopie = self; kopie.einzeilig = an; return kopie
    }

    public init(_ titel: LocalizedStringKey) {
        self.titel = Text(titel)
        self.untertitel = Text(verbatim: Gruss.text())
    }

    public init(_ titel: LocalizedStringKey, gruss: String) {
        self.titel = Text(titel)
        self.untertitel = Text(verbatim: gruss)
    }

    public init(_ titel: LocalizedStringKey, untertitel: LocalizedStringKey) {
        self.titel = Text(titel)
        self.untertitel = Text(untertitel)
    }

    /// Mit fertigen Texten (2.17), z. B. einem Spielnamen, der nicht übersetzt wird.
    public init(titel: Text, untertitel: Text) {
        self.titel = titel
        self.untertitel = untertitel
    }

    /// 2.5 (Wunsch 12): Der Titel wächst mit der Schriftgröße nur bis etwa xxxLarge (×1,25), sonst füllt er bei
    /// Bedienungshilfen-Größen die ganze Breite und schrumpft auf die Hälfte.
    private var titelGroesse: CGFloat {
        art == .klar ? min(groesse, Theme.titelGroesse * 1.25) : min(faktor, 1.25) * Theme.titelGroesse
    }

    public var body: some View {
        switch art {
        case .klar:
            VStack(alignment: .leading, spacing: Design.Abstand.xs) {
                titel
                    .font(.system(size: titelGroesse, weight: .bold))
                    .tracking(-0.03 * titelGroesse)
                    .foregroundStyle(titelFarbe ?? Color.appFlaeche)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .accessibilityAddTraits(.isHeader)
                untertitel
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        case .tinte:
            // New York 46 medium, Laufweite −0,02 em; Nebenzeile kursiv grau
            VStack(alignment: .leading, spacing: 6) {
                titel
                    .font(Design.Schrift.titelSchrift(titelGroesse))
                    .tracking(Design.Schrift.titelLaufweite(titelGroesse))
                    .foregroundStyle(titelFarbe ?? Color.schrift)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .accessibilityAddTraits(.isHeader)
                untertitel
                    .font(Design.Schrift.neben)
                    .foregroundStyle(titelFarbe?.opacity(0.85) ?? Color.schriftZweit)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        case .salon:
            // New York 72 fett, Laufweite −0,03 em, enge Zeilen, bis zwei Zeilen; Nebenzeile leicht kursiv
            VStack(alignment: .leading, spacing: 10) {
                titel
                    .font(Design.Schrift.titelSchrift(titelGroesse).leading(.tight))
                    .tracking(Design.Schrift.titelLaufweite(titelGroesse))
                    .lineSpacing(-titelGroesse * 0.08)
                    .foregroundStyle(titelFarbe ?? Color.schrift)
                    .minimumScaleFactor(0.45)
                    .lineLimit(einzeilig ? 1 : 2)
                    .accessibilityAddTraits(.isHeader)
                untertitel
                    .font(Design.Schrift.neben)
                    .foregroundStyle(titelFarbe?.opacity(0.9) ?? Color.schriftZweit)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

/// Farbe des `StartTitel`, wenn nicht die App-Farbe gilt (Sammlung „Spieleabend“: Weiß auf dunklem Grund).
public struct StartTitelFarbeKey: EnvironmentKey { public static let defaultValue: Color? = nil }
public extension EnvironmentValues {
    var startTitelFarbe: Color? { get { self[StartTitelFarbeKey.self] } set { self[StartTitelFarbeKey.self] = newValue } }
}

/// Kartenkopf: Titel links (fett), Zusatz rechts (grau). Baustein der Start-Karten.
public struct KartenKopf: View {
    let titel: Text
    let zusatz: Text?

    public init(_ titel: LocalizedStringKey, zusatz: String? = nil) {
        self.titel = Text(titel)
        self.zusatz = zusatz.map { Text(verbatim: $0) }
    }

    public init(titel: Text, zusatz: Text? = nil) {
        self.titel = titel
        self.zusatz = zusatz
    }

    @Environment(\.designArt) private var art

    public var body: some View {
        if art == .klar { klar } else { label }
    }

    /// Tinte: Label-Rolle mit Tinte-Linie darunter, Zusatz rechts. Salon: Label-Rolle, Zusatz rechts.
    private var label: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                titel.designLabel().accessibilityAddTraits(.isHeader)
                Spacer(minLength: 8)
                zusatz?.font(.footnote).foregroundStyle(Color.schriftZweit).lineLimit(1)
            }
            if art == .tinte { ZeilenLinie(stark: true) }
        }
    }

    private var klar: some View {
        // Passt der Zusatz nicht neben den Titel (große Schrift, lange Sprache), steht er darunter
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline) {
                titel.font(.headline).lineLimit(1).accessibilityAddTraits(.isHeader)
                Spacer(minLength: 8)
                zusatz?.font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
            }
            VStack(alignment: .leading, spacing: 2) {
                titel.font(.headline).accessibilityAddTraits(.isHeader)
                zusatz?.font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }
}

/// Weiterspielen-Karte: Titel, Zeit/Stand rechts, Untertitel, optional Fortschrittsbalken (0…1).
/// Mit `verwerfen` erscheint rechts oben ein Menü „…“ mit „Partie verwerfen“; die Rückfrage (E6) ist eingebaut.
public struct WeiterspielenKarte: View {
    let stand: Text
    let zeit: String?
    let beschreibung: String
    let fortschritt: Double?
    let verwerfen: (() -> Void)?
    let aktion: () -> Void
    @State private var rueckfrage = false

    public init(_ stand: LocalizedStringKey? = nil, zeit: String? = nil, beschreibung: String,
                fortschritt: Double? = nil, verwerfen: (() -> Void)? = nil, aktion: @escaping () -> Void) {
        self.stand = stand.map { Text($0) } ?? Text("Weiterspielen", bundle: .module)
        self.zeit = zeit; self.beschreibung = beschreibung
        self.fortschritt = fortschritt; self.verwerfen = verwerfen; self.aktion = aktion
    }

    @Environment(\.designArt) private var art

    private func zeitText(_ zeit: String) -> some View {
        Text(verbatim: zeit)
            .font(Design.Schrift.zahl(.subheadline).weight(.semibold).monospacedDigit())
            .foregroundStyle(.secondary)
    }

    /// Tinte und Salon: Listenzeile. Links der Name (Beschreibung) in Serifenschrift, rechts Stand und Zeit, darunter der
    /// Fortschritt als 2-pt-Linie.
    private var zeile: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: Design.Abstand.m) {
                Text(verbatim: beschreibung).font(Design.Schrift.name).foregroundStyle(Color.schrift)
                    .lineLimit(2).minimumScaleFactor(0.7)
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 1) {
                    stand.font(.footnote.weight(.semibold)).lineLimit(1).accessibilityAddTraits(.isHeader)
                    if let zeit { Text(verbatim: zeit).font(.footnote.monospacedDigit()) }
                }
                .foregroundStyle(Color.schriftZweit)
                if verwerfen != nil { Color.clear.frame(width: 28, height: 1) }   // Platz für das Menü
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        // Mit Fortschritt ist der 2-pt-Balken die Linie der Zeile, sonst die Haarlinie
        .overlay(alignment: .bottom) { if let fortschritt { Fortschrittsbalken(wert: fortschritt) } else { ZeilenLinie() } }
    }

    public var body: some View {
        Group { if art == .klar { klar.card() } else { zeile } }
        .kartenAktion(aktion)
        .overlay(alignment: art == .klar ? .topTrailing : .trailing) {
            if let verwerfen {
                Menu {
                    Button(role: .destructive) { rueckfrage = true } label: {
                        Label { Text("Partie verwerfen", bundle: .module) } icon: { Image(systemName: "trash") }
                    }
                } label: {
                    Image(systemName: art == .klar ? "ellipsis.circle" : "ellipsis")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: Theme.tapSize, height: Theme.tapSize)
                        .contentShape(.rect)
                }
                .accessibilityLabel(Text("Weitere Aktionen", bundle: .module))
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)   // Wunsch 6: Menü wächst nicht über den Titel
                .padding(.top, art == .klar ? 4 : 0).padding(.trailing, art == .klar ? 4 : -8)
                .spielSpeicherRueckfrage($rueckfrage, verwerfen: verwerfen)
            }
        }
    }

    private var klar: some View {
        VStack(alignment: .leading, spacing: 6) {
            // N-19: Bei großer Schrift Titel und Zeit untereinander statt „Weiterspie-/len“ neben der Zeit
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline) {
                    stand.font(.headline).lineLimit(1).fixedSize(horizontal: true, vertical: false).accessibilityAddTraits(.isHeader)
                    Spacer(minLength: 8)
                    if let zeit { zeitText(zeit) }
                    if verwerfen != nil { Color.clear.frame(width: 28, height: 1) }   // Platz für das Menü
                }
                VStack(alignment: .leading, spacing: 2) {
                    stand.font(.headline).lineLimit(1).minimumScaleFactor(0.6).accessibilityAddTraits(.isHeader)   // 2.2: kein „Weiterspie-len“
                    if let zeit { zeitText(zeit) }
                }
                .padding(.trailing, verwerfen != nil ? 36 : 0)   // Wunsch 6: Platz für das Menü auch bei großer Schrift
            }
            Text(verbatim: beschreibung).font(.subheadline).foregroundStyle(.secondary)
            if let fortschritt {
                Fortschrittsbalken(wert: fortschritt).padding(.top, 4)
            }
        }
    }
}

public struct Fortschrittsbalken: View {
    let wert: Double

    @Environment(\.designArt) private var art

    public init(wert: Double) { self.wert = wert }

    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                if art == .klar {
                    Capsule().fill(Color.accentSoft)
                    Capsule().fill(Color.appFlaeche)
                        .frame(width: geo.size.width * min(max(wert, 0), 1))
                } else {
                    // Tinte und Salon: Balken als 2-pt-Linie
                    Rectangle().fill(Color.linie)
                    Rectangle().fill(Color.accentText)
                        .frame(width: geo.size.width * min(max(wert, 0), 1))
                }
            }
        }
        .frame(height: art == .klar ? 6 : 2)
        .accessibilityElement()
        .accessibilityValue(Text(wert, format: .percent.precision(.fractionLength(0))))
    }
}

/// Tages-/Serien-Karte: Titel, Datum, sieben Wochentags-Punkte (gefüllt = erledigt), Seriezeile.
public struct TagesKarte: View {
    let titel: LocalizedStringKey
    let datum: String
    /// Sieben Einträge Mo…So; `true` = erledigt.
    let woche: [Bool]
    let serie: String
    let aktion: () -> Void

    public init(titel: LocalizedStringKey, datum: String, woche: [Bool], serie: String, aktion: @escaping () -> Void) {
        self.titel = titel; self.datum = datum; self.woche = woche; self.serie = serie; self.aktion = aktion
    }

    private let kuerzel: [String] = {
        var kal = Calendar.current
        kal.locale = .current
        return kal.shortStandaloneWeekdaySymbols   // F-AWS-K-012/P-012/M-012: Mo Di Mi … statt M D M D F S S
    }()

    @Environment(\.designArt) private var art

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            KartenKopf(titel, zusatz: datum)
            HStack {
                ForEach(0..<7, id: \.self) { i in
                    VStack(spacing: Design.Abstand.xs) {
                        let erledigt = woche.indices.contains(i) && woche[i]
                        Circle()
                            .fill(erledigt ? (art == .klar ? Color.appFlaeche : Color.accentText) : (art == .klar ? Color.accentSoft : Color.clear))
                            .overlay { if art != .klar, !erledigt { Circle().strokeBorder(Color.linieStark, lineWidth: 1) } }
                            .frame(width: 22, height: 22)
                        Text(verbatim: kuerzel[(i + 1) % 7]).font(.caption2).foregroundStyle(.secondary).lineLimit(1).minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("\(woche.filter { $0 }.count) von 7 Tagen erledigt", bundle: .module))
            Text(verbatim: serie).font(.subheadline).foregroundStyle(.secondary)
        }
        .card()
        .kartenAktion(aktion)
    }
}

/// Auswahl-Zeile (Spielmodi auf dem Start, Solitär-Spielauswahl): Symbolkachel 44 pt, Titel, Untertitel, Pfeil.
/// `laeuft`: Rand in App-Farbe (laufendes Spiel; einzige erlaubte Rahmen-Ausnahme, Konzept 3.3). Optional `zusatz`
/// (z. B. Auswahl 1 Karte | 3 Karten) unter der Zeile – nur wenn das Mockup es zeigt, sonst nicht benutzen.
public struct AuswahlZeile<Zusatz: View>: View {
    let symbol: String
    let titel: LocalizedStringKey
    let untertitel: LocalizedStringKey
    var laeuft = false
    let aktion: () -> Void
    let zusatz: Zusatz

    public init(symbol: String, titel: LocalizedStringKey, untertitel: LocalizedStringKey, laeuft: Bool = false,
                aktion: @escaping () -> Void, @ViewBuilder zusatz: () -> Zusatz) {
        self.symbol = symbol; self.titel = titel; self.untertitel = untertitel; self.laeuft = laeuft
        self.aktion = aktion; self.zusatz = zusatz()
    }

    @Environment(\.designArt) private var art

    public var body: some View {
        if art == .klar { klar } else { zeile }
    }

    /// Tinte und Salon: Listenzeile mit Serifennamen, Untertitel klein, rechts Pfeil; läuft = Punkt in der Akzentfarbe.
    private var zeile: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: Design.Abstand.m) {
                if laeuft { Circle().fill(Color.accentText).frame(width: 10, height: 10).accessibilityHidden(true) }
                VStack(alignment: .leading, spacing: 2) {
                    Text(titel).font(Design.Schrift.name).foregroundStyle(Color.schrift)
                    Text(untertitel).font(.footnote).foregroundStyle(Color.schriftZweit)
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Text(verbatim: art == .salon ? "→" : "›").font(.title3).foregroundStyle(Color.schriftZweit).accessibilityHidden(true)
            }
            zusatz
        }
        .card()
        .kartenAktion(aktion)
    }

    private var klar: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: Design.Abstand.m) {
                Image(systemName: symbol)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(laeuft ? Color.appFlaeche : Color.primary)
                    .frame(width: 44, height: 44)
                    .background(laeuft ? Color.accentSoft : Color.feldGrund, in: .rect(cornerRadius: 11))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(titel).font(.headline)
                    // 2.8 (Wunsch 16): Untertitel wächst nur bis xxxLarge; bei AXXXL wurden Wörter getrennt („Par-tie“)
                    Text(untertitel).font(.subheadline).foregroundStyle(.secondary)
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right").font(.body.weight(.semibold))
                    .foregroundStyle(Color(.tertiaryLabel)).accessibilityHidden(true)
            }
            zusatz
        }
        .card()
        .overlay { if laeuft { RoundedRectangle(cornerRadius: Theme.cardRadius).strokeBorder(Color.appFlaeche, lineWidth: 2) } }
        .kartenAktion(aktion)
    }
}

public extension AuswahlZeile where Zusatz == EmptyView {
    init(symbol: String, titel: LocalizedStringKey, untertitel: LocalizedStringKey, laeuft: Bool = false, aktion: @escaping () -> Void) {
        self.init(symbol: symbol, titel: titel, untertitel: untertitel, laeuft: laeuft, aktion: aktion, zusatz: { EmptyView() })
    }
}

/// Statistik-Zeile (und jede andere „Gehe zu“-Karte): fetter Titel, Pfeil rechts. Auf dem Start ohne Zahlen (Q9);
/// `werte` nur dort, wo das Mockup Kennzahlen zeigt.
public struct StatistikZeile: View {
    public struct Wert: Identifiable {
        public let zahl: String
        public let name: LocalizedStringKey
        public var id: String { "\(zahl)|\(name)" }
        public init(zahl: String, name: LocalizedStringKey) { self.zahl = zahl; self.name = name }
    }

    let titel: LocalizedStringKey
    var werte: [Wert] = []
    let aktion: () -> Void

    public init(titel: LocalizedStringKey, werte: [Wert] = [], aktion: @escaping () -> Void) {
        self.titel = titel; self.werte = werte; self.aktion = aktion
    }

    @Environment(\.designArt) private var art

    public var body: some View {
        if art == .klar { klar } else { zeilen }
    }

    /// Tinte: Abschnitts-Label, darunter je Wert eine Zeile (Label links, Zahl in Serifenschrift rechts).
    /// Salon: dieselben Zeilen mit großen Zahlen. Ohne Werte eine einzelne Zeile mit Pfeil.
    private var zeilen: some View {
        VStack(alignment: .leading, spacing: 0) {
            if werte.isEmpty {
                DesignZeile {
                    HStack {
                        Text(titel).font(Design.Schrift.name).foregroundStyle(Color.schrift).accessibilityAddTraits(.isHeader)
                        Spacer(minLength: 8)
                        Text(verbatim: art == .salon ? "→" : "›").font(.title3).foregroundStyle(Color.schriftZweit).accessibilityHidden(true)
                    }
                }
            } else {
                SectionLabel(text: Text(titel))
                    .padding(.bottom, art == .salon ? 6 : 0)
                ForEach(werte) { w in
                    DesignWertZeile(label: Text(w.name), wert: Text(verbatim: w.zahl))
                }
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .kartenAktion(aktion)
    }

    private var klar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 10) {
                Text(titel).font(.headline).accessibilityAddTraits(.isHeader)
                if !werte.isEmpty {
                    HStack(alignment: .top) {
                        ForEach(werte) { w in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(verbatim: w.zahl)
                                    .font(Design.Schrift.zahl(.title2).weight(.bold).monospacedDigit())
                                Text(w.name).font(.caption).foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "chevron.right").font(.body.weight(.semibold))
                .foregroundStyle(Color(.tertiaryLabel)).accessibilityHidden(true)
        }
        .card()
        .kartenAktion(aktion)
    }
}

#endif
