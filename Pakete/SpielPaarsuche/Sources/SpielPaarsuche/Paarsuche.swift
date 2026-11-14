// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import SpielHilfen
import PaarsucheKern

@MainActor
public struct PaarsucheModul: SpielModul {
    public init() {}
    public let id = "paarsuche"
    public let name = "Paarsuche"
    public let gattung = Gattung.karten
    public let farbe = AkzentFarbeWert.pink
    public let symbol = "square.on.square"
    public let spielerzahl = 1...4
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(SpielRahmen(id: id, name: name, untertitel: "Finde alle Paare", farbe: farbe, spieler: 1...4, computerErlaubt: true,
                            regeln: "Alle Karten liegen verdeckt. Wer an der Reihe ist, deckt zwei Karten auf. Zeigen beide dasselbe Bild, bekommt er das Paar und darf gleich noch einmal. Wenn nicht, werden sie wieder umgedreht, und der nächste Spieler ist dran. Merke dir, wo was liegt! Wer am Ende die meisten Paare hat, gewinnt. Allein spielst du auf wenige Züge: Je weniger Versuche du brauchst, desto besser. Vor dem Start wählst du Größe und Motive.",
                            einzelText: "Ein Spieler: Wie wenige Züge brauchst du?",
                            umgebung: umgebung) { teilnehmer, ende, abbrechen in
            PaarsucheSpiel(teilnehmer: teilnehmer, ende: ende, abbrechen: abbrechen)
        }.mitZiel("Finde möglichst viele Paare. Wer am Ende die meisten hat, gewinnt; allein brauchst du wenige Versuche.").mitAnleitung(Self.anleitung))
    }
}

enum PaarThema: String, CaseIterable, Identifiable {
    case tiere, wetter, dinge
    var id: String { rawValue }
    var titel: LocalizedStringKey { switch self { case .tiere: "Tiere"; case .wetter: "Wetter"; case .dinge: "Dinge" } }
    var symbole: [String] {
        switch self {
        case .tiere: TierMotive.symbole
        case .wetter: ["sun.max.fill", "cloud.rain.fill", "snowflake", "wind", "bolt.fill", "moon.stars.fill", "cloud.fog.fill", "rainbow", "tornado", "flame.fill", "drop.fill", "thermometer.sun.fill", "sparkles", "cloud.sun.fill", "umbrella.fill"]
        case .dinge: ["key.fill", "bell.fill", "gift.fill", "lightbulb.fill", "camera.fill", "book.fill", "hammer.fill", "scissors", "paperplane.fill", "cup.and.saucer.fill", "bicycle", "airplane", "car.fill", "sailboat.fill", "tram.fill"]
        }
    }
}

private let motivFarben = TierMotive.farben

/// Deutsche Namen der Bild-Motive für die Sprachausgabe (statt der SF-Symbol-Namen).
private let motivNamen: [String: LocalizedStringKey] = [
    "tortoise.fill": "Schildkröte", "hare.fill": "Hase", "bird.fill": "Vogel", "fish.fill": "Fisch", "ant.fill": "Ameise", "ladybug.fill": "Marienkäfer", "pawprint.fill": "Pfotenabdruck", "leaf.fill": "Blatt", "cat.fill": "Katze", "dog.fill": "Hund", "lizard.fill": "Eidechse", "teddybear.fill": "Teddybär", "tree.fill": "Baum", "carrot.fill": "Karotte", "fossil.shell.fill": "Fossil", "sun.max.fill": "Sonne", "cloud.rain.fill": "Regenwolke", "snowflake": "Schneeflocke", "wind": "Wind", "bolt.fill": "Blitz", "moon.stars.fill": "Mond und Sterne", "cloud.fog.fill": "Nebel", "rainbow": "Regenbogen", "tornado": "Wirbelsturm", "flame.fill": "Flamme", "drop.fill": "Tropfen", "thermometer.sun.fill": "Thermometer", "sparkles": "Funkeln", "cloud.sun.fill": "Sonne und Wolke", "umbrella.fill": "Regenschirm", "key.fill": "Schlüssel", "bell.fill": "Glocke", "gift.fill": "Geschenk", "lightbulb.fill": "Glühbirne", "camera.fill": "Kamera", "book.fill": "Buch", "hammer.fill": "Hammer", "scissors": "Schere", "paperplane.fill": "Papierflieger", "cup.and.saucer.fill": "Tasse", "bicycle": "Fahrrad", "airplane": "Flugzeug", "car.fill": "Auto", "sailboat.fill": "Segelboot", "tram.fill": "Straßenbahn"
]
private func motivName(_ symbol: String) -> Text { motivNamen[symbol].map { Text($0) } ?? Text(verbatim: symbol) }

struct PaarsucheSpiel: View {
    @Environment(\.accessibilityReduceMotion) private var bewegungReduziert
    let teilnehmer: [SpielTeilnehmer]
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    @State private var paare = 8
    @State private var thema = PaarThema.tiere
    @State private var spiel: Paarsuche?
    @State private var zufall = SystemRandomNumberGenerator()
    @State private var beschaeftigt = false
    @State private var gemeldet = false

    @State private var stufe = ComputerStufe.gespeichert("paarsuche")
    /// Wie zuverlässig sich der Computer Gesehenes merkt.
    private var staerke: Double { switch stufe { case .leicht: 0.4; case .mittel: 0.7; case .schwer: 0.92 } }

    var body: some View {
        Group {
            if let s = spiel { brett(s) } else { auswahl }
        }
        .background(Color.seitenGrund)
        .fortsetzbar("paarsuche", $spiel)
        .weicheAnimation(bei: spiel)
        .spielHaptik(zug: spiel, erfolg: (spiel?.vorbei ?? false))
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
    }

    private var auswahl: some View {
        VStack(spacing: Theme.kartenAbstand) {
            SpielKopf(mitte: "Paarsuche", linksAktion: abbrechen) { Color.clear.frame(width: 44, height: 44) }
            VStack(alignment: .leading, spacing: 14) {
                Text("Größe").font(.headline)
                Picker("Größe", selection: $paare) {
                    Text("Klein (12)").tag(6); Text("Mittel (16)").tag(8); Text("Groß (20)").tag(10); Text("Riesig (30)").tag(15)
                }.pickerStyle(.segmented)
                if teilnehmer.contains(where: \.computer) { ComputerStufePicker(spiel: "paarsuche", stufe: $stufe).pickerStyle(.segmented) }
                Text("Motive").font(.headline)
                Picker("Motive", selection: $thema) { ForEach(PaarThema.allCases) { Text($0.titel).tag($0) } }.pickerStyle(.segmented)
                HStack(spacing: 10) {
                    ForEach(Array(thema.symbole.prefix(5).enumerated()), id: \.offset) { i, s in
                        Image(systemName: s).font(.title2).foregroundStyle(motivFarben[i]).frame(maxWidth: .infinity)
                    }
                }.padding(.vertical, 8)
            }.padding(Theme.seitenRand)
            Spacer()
            Button("Los geht’s") {
                var g = SystemRandomNumberGenerator()
                spiel = Paarsuche(paare: paare, spieler: teilnehmer.count, mit: &g); gemeldet = false
                weiter()
            }.buttonStyle(HauptKnopfStil()).padding(.horizontal, Theme.seitenRand).padding(.bottom, 8)
        }
    }

    private func brett(_ s: Paarsuche) -> some View {
        let spalten = s.karten.count <= 12 ? 3 : (s.karten.count <= 20 ? 4 : 5)
        return VStack(spacing: Theme.kartenAbstand) {
            SpielKopf(mitte: teilnehmer.count == 1 ? "\(s.zuege) Züge" : "\(s.paareGefunden)/\(s.karten.count / 2) Paare", linksAktion: abbrechen) {
                RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                    Button("Neu beginnen", systemImage: "arrow.counterclockwise") { spiel = nil; beschaeftigt = false }
                    Button("Spiel beenden", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
                }
            }
            if teilnehmer.count > 1 {
                HStack(spacing: Design.Abstand.s) {
                    ForEach(teilnehmer.indices, id: \.self) { i in
                        VStack(spacing: 2) {
                            Text(verbatim: teilnehmer[i].name).font(.footnote).lineLimit(1).minimumScaleFactor(0.7)
                            Text(verbatim: "\(s.punkte[i])").font(.title3.weight(.semibold))
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(Text(verbatim: teilnehmer[i].name))
                        .accessibilityValue(Text("\(s.punkte[i]) Paare"))
                        .frame(maxWidth: .infinity).padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: Design.Ecke.feld).fill(i == s.amZug ? Color.appFlaeche.opacity(0.25) : Color.kartenGrund))
                    }
                }.padding(.horizontal, Theme.seitenRand)
            }
            GeometryReader { g in
                let abstand: CGFloat = 8
                let breite = (g.size.width - abstand * CGFloat(spalten - 1)) / CGFloat(spalten)
                let zeilen = (s.karten.count + spalten - 1) / spalten
                let hoehe = min(breite * 1.15, (g.size.height - abstand * CGFloat(zeilen - 1)) / CGFloat(zeilen))
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(breite), spacing: abstand), count: spalten), spacing: abstand) {
                    ForEach(s.karten.indices, id: \.self) { i in
                        kartenAnsicht(s, i).frame(width: breite, height: hoehe)
                            .onTapGesture { tippe(i) }
                    }
                }.frame(maxWidth: .infinity)
            }.padding(.horizontal, Theme.seitenRand)
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private func kartenAnsicht(_ s: Paarsuche, _ i: Int) -> some View {
        let k = s.karten[i]
        let aufgedeckt = k.gefunden || s.offen.contains(i)
        ZStack {
            RoundedRectangle(cornerRadius: Design.Ecke.feld).fill(Color.appFlaeche.gradient)
                .overlay(Image(systemName: "questionmark").font(.title3.weight(.bold)).foregroundStyle(.white.opacity(0.7)))
                .opacity(aufgedeckt ? 0 : 1)
            RoundedRectangle(cornerRadius: Design.Ecke.feld).fill(Color.kartenGrund)
                .overlay(RoundedRectangle(cornerRadius: Design.Ecke.feld).stroke(k.gefunden ? Color.appFlaeche : .clear, lineWidth: 2))
                .overlay(Image(systemName: thema.symbole[k.motiv % thema.symbole.count]).font(.title).foregroundStyle(motivFarben[k.motiv % motivFarben.count]))
                .opacity(aufgedeckt ? (k.gefunden ? 0.55 : 1) : 0)
        }
        .rotation3DEffect(.degrees(aufgedeckt ? 0 : 180), axis: (x: 0, y: 1, z: 0))
        .animation(bewegungReduziert ? nil : .easeInOut(duration: 0.25), value: aufgedeckt)   // G3
        .accessibilityLabel(aufgedeckt ? motivName(thema.symbole[k.motiv % thema.symbole.count]) : Text("Verdeckte Karte"))
    }

    private var amZugIstComputer: Bool { spiel.map { teilnehmer[$0.amZug].computer } ?? false }

    private func tippe(_ i: Int) {
        guard !beschaeftigt, !amZugIstComputer, spiel?.decke(i) == true else { return }
        if spiel?.zweiOffen == true { Task { await klaere() } }
    }

    private func klaere() async {
        beschaeftigt = true
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        spiel?.aufloesen()
        beschaeftigt = false
        weiter()
    }

    /// Prüft Ende und lässt gegebenenfalls den Computer ziehen.
    private func weiter() {
        guard let s = spiel else { return }
        if s.vorbei { abschluss(s); return }
        guard teilnehmer[s.amZug].computer, !beschaeftigt else { return }
        Task {
            beschaeftigt = true
            try? await Task.sleep(nanoseconds: 700_000_000)
            guard spiel != nil else { return }
            spiel?.vergiss(staerke: staerke + 0.2, mit: &zufall)
            if let a = spiel?.computerWahl(staerke: staerke, mit: &zufall) { spiel?.decke(a) }
            try? await Task.sleep(nanoseconds: 700_000_000)
            if let b = spiel?.computerWahl(staerke: staerke, mit: &zufall) { spiel?.decke(b) }
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            spiel?.aufloesen()
            beschaeftigt = false
            weiter()
        }
    }

    private func abschluss(_ s: Paarsuche) {
        guard !gemeldet else { return }
        gemeldet = true
        let rang = s.rangfolge
        let plaetze = rang.enumerated().map { (n, i) in rang.firstIndex { s.punkte[$0] == s.punkte[i] }! + 0 * n }
        Task {
            try? await Task.sleep(nanoseconds: 600_000_000)
            ende(SpielEnde(reihenfolge: rang.map { teilnehmer[$0].name },
                           punkte: teilnehmer.count == 1 ? ["\(s.zuege) Züge"] : rang.map { "\(s.punkte[$0])" },
                           plaetze: teilnehmer.count == 1 ? nil : plaetze.map { $0 + 1 },
                           info: teilnehmer.count == 1 ? String(localized: "Alle Paare in \(s.zuege) Zügen") : nil))
        }
    }
}
#endif
