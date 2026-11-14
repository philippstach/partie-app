// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import SpielHilfen
import StufenstapelKern

@MainActor
public struct StufenstapelModul: SpielModul {
    public init() {}
    public let id = "stufenstapel"
    public let name = "Stufenstapel"
    public let gattung = Gattung.karten
    public let farbe = AkzentFarbeWert.limette
    public let symbol = "square.stack.3d.up.fill"
    public let spielerzahl = 2...4
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(SpielRahmen(id: id, name: name, untertitel: "Dein Vorrat muss weg", farbe: farbe, spieler: 2...4, computerErlaubt: true,
                            regeln: "Jeder hat einen Vorrat von 15 Karten, von dem nur die oberste Karte sichtbar ist, dazu fünf Handkarten und drei eigene Ablagen. Wer als Erster seinen Vorrat leer hat, gewinnt. In der Mitte liegen vier Bau-Stapel. Auf einen leeren Stapel kommt die 1, darauf die 2, dann die 3 und so weiter bis zur 10; ein Stapel mit der 10 wird abgeräumt. Der Stern ersetzt jede Zahl. Du darfst so viele Karten bauen, wie du kannst: aus dem Vorrat, aus der Hand oder von der Spitze deiner Ablagen. Hast du keine Handkarte mehr, bekommst du fünf neue. Dein Zug endet, wenn du eine Handkarte auf eine deiner drei Ablagen legst. Tippe zuerst eine Karte an, dann den Stapel, auf den sie soll.",
                            umgebung: umgebung) { teilnehmer, ende, abbrechen in
            StufenstapelSpiel(teilnehmer: teilnehmer, ende: ende, abbrechen: abbrechen)
        }.mitZiel("Baue die Stapel von 1 bis 10 und leere als Erster deinen Vorrat. Wer das schafft, gewinnt.").mitAnleitung(Self.anleitung))
    }
}

private let stufenFarben: [Color] = [.gray, Color(red: 0.80, green: 0.14, blue: 0.22), Color(red: 0.90, green: 0.45, blue: 0.08), Color(red: 0.88, green: 0.68, blue: 0.05), Color(red: 0.30, green: 0.65, blue: 0.20), Color(red: 0.10, green: 0.60, blue: 0.55), Color(red: 0.14, green: 0.45, blue: 0.82), Color(red: 0.30, green: 0.30, blue: 0.80), Color(red: 0.55, green: 0.25, blue: 0.75), Color(red: 0.80, green: 0.25, blue: 0.55), Color(red: 0.20, green: 0.20, blue: 0.25)]

struct StufenKarte: View {
    let wert: Int?
    var gewaehlt = false
    var zaehler: Int?
    var body: some View {
        ZStack {
            if let w = wert {
                RoundedRectangle(cornerRadius: 9).fill(stufenFarben[w])
                    .overlay(w == 0 ? Image(systemName: "star.fill").font(.title2).foregroundStyle(.yellow) : nil)
                    .overlay(w > 0 ? Text(verbatim: "\(w)").font(.system(.title, design: Design.zahlDesign).weight(.bold)).foregroundStyle(.white) : nil)
            } else {
                RoundedRectangle(cornerRadius: 9).strokeBorder(.secondary.opacity(0.5), style: StrokeStyle(lineWidth: 1.5, dash: [4]))
            }
        }
        .overlay(RoundedRectangle(cornerRadius: 9).stroke(gewaehlt ? Color.primary : .white.opacity(wert == nil ? 0 : 0.8), lineWidth: gewaehlt ? 3.5 : 2))
        .overlay(alignment: .topTrailing) {
            if let z = zaehler, z > 1 { Text(verbatim: "\(z)").font(.caption2.bold()).padding(3).background(Circle().fill(.black.opacity(0.6))).foregroundStyle(.white).offset(x: 5, y: -5) }
        }
        .frame(width: 52, height: 76)
        .contentShape(Rectangle())
        .accessibilityLabel(wert.map { $0 == 0 ? Text("Stern") : Text(verbatim: "\($0)") } ?? Text("Leer"))
    }
}

struct StufenstapelSpiel: View {
    let teilnehmer: [SpielTeilnehmer]
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    @State private var spiel: Stufenstapel
    @State private var zufall = SystemRandomNumberGenerator()
    @State private var stufe = ComputerStufe.gespeichert("stufenstapel")
    private var fehler: Double { switch stufe { case .leicht: 0.4; case .mittel: 0.12; case .schwer: 0 } }
    @State private var gewaehlt: Stufenstapel.Quelle?
    @State private var tippZiel: (bau: Int?, ablage: Int?) = (nil, nil)   // F4: Ziel des Vorschlags
    @State private var tippText: String?
    @State private var gemeldet = false
    @State private var schritte = 0

    init(teilnehmer: [SpielTeilnehmer], ende: @escaping (SpielEnde) -> Void, abbrechen: @escaping () -> Void) {
        self.teilnehmer = teilnehmer; self.ende = ende; self.abbrechen = abbrechen
        var g = SystemRandomNumberGenerator()
        _spiel = State(initialValue: Stufenstapel(spieler: teilnehmer.count, mit: &g))
    }

    private var menschen: [Int] { teilnehmer.menschen }
    private var amZugComputer: Bool { teilnehmer[spiel.amZug].computer }
    private var sicht: Int { amZugComputer ? (menschen.first ?? 0) : spiel.amZug }
    private var kannHandeln: Bool { spiel.gewinner == nil && !amZugComputer }

    var body: some View {
        ZStack {
            Color.seitenGrund.ignoresSafeArea()
            VStack(spacing: Theme.kartenAbstand) {
                SpielKopf(mitte: spiel.gewinner == nil ? String(localized: "\(teilnehmer[spiel.amZug].name) ist dran") : String(localized: "Spielende"), linksAktion: abbrechen) {
                    RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                        if teilnehmer.contains(where: \.computer) { ComputerStufePicker(spiel: "stufenstapel", stufe: $stufe) }
                        Button("Spiel beenden", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
                    }
                }
                gegner
                Spacer(minLength: 0)
                HStack(spacing: 10) {
                    ForEach(0..<4, id: \.self) { b in
                        Button { tippZiel = (nil, nil); tippeBau(b) } label: {
                            StufenKarte(wert: spiel.bau[b] == 0 ? nil : spiel.bau[b], zaehler: nil)
                        }.buttonStyle(.plain)
                        .accessibilityLabel(Text("Bau-Stapel \(b + 1)"))
                        .accessibilityValue(spiel.bau[b] == 0 ? Text("Leer") : Text(verbatim: "\(spiel.bau[b])"))
                    }
                }
                Text("Nächste Zahl: \(spiel.bau.map { String($0 + 1) }.joined(separator: " · "))").font(.footnote).foregroundStyle(.secondary)
                Spacer(minLength: 0)
                eigene
            }
        }
        .uebergabeSeite(teilnehmer: teilnehmer, amZug: spiel.amZug, aktiv: spiel.gewinner == nil)
        .fortsetzbar("stufenstapel", $spiel)
        .weicheAnimation(bei: spiel)
        .spielHaptik(zug: spiel, erfolg: (spiel.gewinner != nil))
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .task(id: "\(spiel.amZug)-\(schritte)") {
            guard spiel.gewinner == nil, amZugComputer else { return }
            try? await Task.sleep(nanoseconds: 800_000_000)
            guard !Task.isCancelled else { return }
            spiel.computerSchritt(fehler: fehler, mit: &zufall); schritte += 1
            pruefe()
        }
    }

    private var gegner: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Design.Abstand.s) {
                ForEach(teilnehmer.indices.filter { $0 != sicht }, id: \.self) { i in
                    VStack(spacing: Design.Abstand.xs) {
                        Text(verbatim: teilnehmer[i].name).font(.footnote).lineLimit(1).minimumScaleFactor(0.7)
                        HStack(spacing: Design.Abstand.xs) {
                            StufenKarte(wert: spiel.vorrat[i].last, zaehler: spiel.vorrat[i].count).scaleEffect(0.6).frame(width: 32, height: 46)
                            ForEach(0..<3, id: \.self) { a in StufenKarte(wert: spiel.ablage[i][a].last, zaehler: spiel.ablage[i][a].count).scaleEffect(0.45).frame(width: 24, height: 34) }
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text(verbatim: teilnehmer[i].name))
                    .accessibilityValue(Text("Vorrat \(spiel.vorrat[i].count)"))
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: Design.Ecke.feld).fill(i == spiel.amZug ? Color.appFlaeche.opacity(0.25) : Color.kartenGrund))
                }
            }.padding(.horizontal, Theme.seitenRand)
        }
    }

    private var eigene: some View {
        VStack(spacing: 10) {
            HStack(alignment: .top, spacing: 14) {
                VStack(spacing: 2) {
                    Button { waehle(.vorrat) } label: { StufenKarte(wert: spiel.vorrat[sicht].last, gewaehlt: gewaehlt == .vorrat && sicht == spiel.amZug, zaehler: spiel.vorrat[sicht].count) }.buttonStyle(.plain)
                        .accessibilityLabel(Text("Vorrat \(spiel.vorrat[sicht].count)"))
                        .accessibilityValue(spiel.vorrat[sicht].last.map { $0 == 0 ? Text("Stern") : Text(verbatim: "\($0)") } ?? Text("Leer"))
                    Text("Vorrat \(spiel.vorrat[sicht].count)").font(.caption2).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                ForEach(0..<3, id: \.self) { a in
                    VStack(spacing: 2) {
                        Button { tippZiel = (nil, nil); tippeAblage(a) } label: {
                            StufenKarte(wert: spiel.ablage[sicht][a].last, gewaehlt: gewaehlt == .ablage(a) && sicht == spiel.amZug, zaehler: spiel.ablage[sicht][a].count)
                                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.yellow, lineWidth: 4).opacity(tippZiel.ablage == a ? 1 : 0))
                        }.buttonStyle(.plain)
                        .accessibilityLabel(Text("Ablage \(a + 1)"))
                        .accessibilityValue(spiel.ablage[sicht][a].last.map { $0 == 0 ? Text("Stern") : Text(verbatim: "\($0)") } ?? Text("Leer"))
                        Text("Ablage").font(.caption2).foregroundStyle(.secondary).accessibilityHidden(true)
                    }
                }
            }.padding(.horizontal, Theme.seitenRand)
            HStack(spacing: 6) {
                ForEach(spiel.hand[sicht].indices, id: \.self) { i in
                    Button { waehle(.hand(i)) } label: { StufenKarte(wert: spiel.hand[sicht][i], gewaehlt: gewaehlt == .hand(i) && sicht == spiel.amZug) }.buttonStyle(.plain)
                }
            }
            HStack(spacing: Design.Abstand.m) {
                Text(tippText ?? hinweis).font(.footnote).foregroundStyle(.secondary).lineLimit(2).multilineTextAlignment(.leading).frame(minHeight: 36, alignment: .topLeading)   // zwei Zeilen reserviert, damit der Text nicht springt
                if kannHandeln, sicht == spiel.amZug {
                    Button { tipp() } label: { Label("Tipp", systemImage: "lightbulb") }.nebenKnopf().dynamicTypeSize(...DynamicTypeSize.xxxLarge)   // F4
                        .accessibilityHint(Text("Wählt die vorgeschlagene Karte aus und nennt das Ziel."))
                }
            }
        }.padding(.bottom, 8)
    }

    private var hinweis: String {
        guard kannHandeln else { return " " }
        if gewaehlt == nil { return String(localized: "Tippe eine Karte an.") }
        if case .hand = gewaehlt { return String(localized: "Dann einen Bau-Stapel – oder eine Ablage, um den Zug zu beenden.") }
        return String(localized: "Dann einen Bau-Stapel.")
    }

    /// F4: Vorschlag des Kerns – Quelle vorwählen, Ziel gelb markieren, Text (auch für VoiceOver).
    private func tipp() {
        guard let v = spiel.vorschlag() else { return }
        func name(_ q: Stufenstapel.Quelle) -> String {
            switch q {
            case .vorrat: return String(localized: "die Vorratskarte")
            case .hand(let i): return String(localized: "Handkarte \(i + 1) (\(spiel.hand[spiel.amZug][i] == Stufenstapel.stern ? String(localized: "Stern") : "\(spiel.hand[spiel.amZug][i])"))")
            case .ablage(let a): return String(localized: "die oberste Karte von Ablage \(a + 1)")
            }
        }
        switch v {
        case .bauen(let q, let b): gewaehlt = q; tippZiel = (b, nil); tippText = String(localized: "Tipp: \(name(q)) auf Bau-Stapel \(b + 1) legen.")
        case .ablegen(let i, let a): gewaehlt = .hand(i); tippZiel = (nil, a); tippText = String(localized: "Tipp: Nichts passt – \(name(.hand(i))) auf Ablage \(a + 1) legen.")
        }
        UIAccessibility.post(notification: .announcement, argument: tippText)
    }

    private func waehle(_ q: Stufenstapel.Quelle) {
        guard kannHandeln, sicht == spiel.amZug else { return }
        if spiel.wert(q) == nil { return }
        gewaehlt = gewaehlt == q ? nil : q
    }

    private func tippeBau(_ b: Int) {
        guard kannHandeln, let q = gewaehlt else { return }
        if spiel.baue(q, auf: b, mit: &zufall) { gewaehlt = nil; tippText = nil; schritte += 1; pruefe() }
    }

    private func tippeAblage(_ a: Int) {
        guard kannHandeln else { return }
        if case .hand(let i) = gewaehlt {
            if spiel.lege(handKarte: i, auf: a, mit: &zufall) { gewaehlt = nil; tippText = nil; schritte += 1; pruefe() }
        } else { waehle(.ablage(a)) }
    }

    private func pruefe() {
        if let w = spiel.gewinner, !gemeldet {
            gemeldet = true
            let rang = teilnehmer.indices.sorted { a, b in a == w ? true : (b == w ? false : spiel.vorrat[a].count < spiel.vorrat[b].count) }
            Task {
                try? await Task.sleep(nanoseconds: 700_000_000)
                ende(SpielEnde(reihenfolge: rang.map { teilnehmer[$0].name }, punkte: rang.map { String(localized: "Vorrat: \(spiel.vorrat[$0].count)") },
                               info: String(localized: "\(teilnehmer[w].name) hat den Vorrat geleert")))
            }
            return
        }
    }
}
#endif
