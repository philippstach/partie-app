// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import StadtLandFlussKern

@MainActor
public struct StadtLandFlussModul: SpielModul {
    public init() {}
    public let id = "stadtlandfluss"
    public let name = "Stadt, Land, Fluss"
    public let gattung = Gattung.wort
    public let farbe = AkzentFarbeWert.pink
    public let symbol = "textformat.abc"
    public let spielerzahl = 1...8
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(SpielRahmen(id: id, name: name, untertitel: "Ein Buchstabe, sechs Begriffe", farbe: farbe, spieler: 1...8,
                            regeln: "Pro Runde wird ein Buchstabe gezogen. Jeder trägt der Reihe nach (Gerät weitergeben) zu jeder Kategorie ein Wort ein, das mit diesem Buchstaben beginnt. Danach prüft die Runde gemeinsam: Streicht Antworten, die nicht stimmen. Wertung je Kategorie: 10 Punkte, 5 Punkte bei gleicher Antwort mehrerer Spieler, 20 Punkte, wenn nur du eine gültige Antwort hast. Fünf Runden; die meisten Punkte gewinnen. Allein spielst du auf Punkte.",
                            umgebung: umgebung) { teilnehmer, ende, abbrechen in
            StadtLandFlussSpiel(teilnehmer: teilnehmer, ende: ende, abbrechen: abbrechen)
        }.mitZiel("Finde zu jedem Buchstaben passende Wörter für alle Kategorien und hole nach fünf Runden die meisten Punkte.").mitAnleitung(Self.anleitung))
    }
}

/// Gespeicherte Partie: Runde, Buchstabe, Antworten, Wertung, wer gerade dran ist.
extension StadtLandFlussStand {
    /// Sind alle Listen so lang, wie Kategorien und Spielerzahl es verlangen? Sonst würde das Fortsetzen außerhalb der Felder zugreifen.
    var istStimmig: Bool {
        let k = (kategorien ?? StadtLandFlussWertung.kategorien).count, sp = gesamt.count
        guard k >= StadtLandFlussWertung.mindestKategorien, sp >= 1, runde >= 1, aktuell >= 0, aktuell < sp, eingabe.count == k else { return false }
        return antworten.count == sp && gueltig.count == sp && antworten.allSatisfy { $0.count == k } && gueltig.allSatisfy { $0.count == k }
    }
}

struct StadtLandFlussStand: Codable {
    var kategorien: [String]?
    var runde: Int
    var buchstabe: String
    var benutzt: [String]
    var antworten: [[String]]
    var gueltig: [[Bool]]
    var aktuell: Int
    var eingabe: [String]
    var phase: StadtLandFlussSpiel.Phase
    var gesamt: [Int]
}

struct StadtLandFlussSpiel: View {
    let teilnehmer: [SpielTeilnehmer]
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    @State private var kat = StadtLandFlussWertung.auswahl(gespeichert: UserDefaults.standard.stringArray(forKey: "stadtlandfluss.kategorien"))
    private let runden = 5

    @State private var runde = 1
    @State private var buchstabe: Character = "A"
    @State private var benutzt: Set<Character> = []
    @State private var antworten: [[String]] = []
    @State private var gueltig: [[Bool]] = []
    @State private var aktuell = 0
    @State private var eingabe: [String]
    @State private var phase: Phase = .uebergabe
    @ScaledMetric(relativeTo: .largeTitle) private var buchstabeGroesse: CGFloat = 120
    @State private var gesamt: [Int]

    enum Phase: String, Codable { case uebergabe, eingabe, auswertung }

    init(teilnehmer: [SpielTeilnehmer], ende: @escaping (SpielEnde) -> Void, abbrechen: @escaping () -> Void) {
        self.teilnehmer = teilnehmer; self.ende = ende; self.abbrechen = abbrechen
        _eingabe = State(initialValue: Array(repeating: "", count: StadtLandFlussWertung.auswahl(gespeichert: UserDefaults.standard.stringArray(forKey: "stadtlandfluss.kategorien")).count))
        _gesamt = State(initialValue: Array(repeating: 0, count: teilnehmer.count))
    }

    var body: some View {
        VStack(spacing: Theme.kartenAbstand) {
            SpielKopf(mitte: "Runde \(runde) · \(String(buchstabe))", linksAktion: abbrechen) {
                RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                    if runde == 1, phase == .uebergabe, aktuell == 0 {
                        Section("Kategorien") {
                            ForEach(StadtLandFlussWertung.alleKategorien, id: \.self) { k in
                                Toggle(LocalizedStringKey(k), isOn: Binding(get: { kat.contains(k) }, set: { an in waehle(k, an) }))
                            }
                        }
                    }
                    Button("Spiel beenden", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
                }
            }
            switch phase {
            case .uebergabe: uebergabe
            case .eingabe: eingabeAnsicht
            case .auswertung: auswertung
            }
        }
        .background(Color.seitenGrund)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .spielHaptik(zug: phase, erfolg: phase == .auswertung)
        .fortsetzbar("stadtlandfluss", Binding(
            get: { StadtLandFlussStand(kategorien: kat, runde: runde, buchstabe: String(buchstabe), benutzt: benutzt.map(String.init), antworten: antworten, gueltig: gueltig, aktuell: aktuell, eingabe: eingabe, phase: phase, gesamt: gesamt) },
            set: { s in
                kat = s.kategorien ?? StadtLandFlussWertung.kategorien; runde = s.runde; buchstabe = s.buchstabe.first ?? "A"; benutzt = Set(s.benutzt.compactMap(\.first)); antworten = s.antworten; gueltig = s.gueltig
                aktuell = s.aktuell; eingabe = s.eingabe; phase = s.phase; gesamt = s.gesamt
            }),
            pruefen: { $0.istStimmig })
        .onAppear { if !SpielStand.vorhanden("stadtlandfluss") { neueRunde() } }
    }

    private var uebergabe: some View {
        VStack(spacing: Design.Abstand.m) {
            Spacer()
            Text(String(buchstabe)).font(.system(size: buchstabeGroesse, weight: .black, design: Design.zahlDesign)).foregroundStyle(Color.accentText) // design:spielinhalt
                .accessibilityLabel(Text("Buchstabe \(String(buchstabe))"))
            Text("\(teilnehmer[aktuell].name) ist dran").font(.title3.weight(.semibold))
            Text(teilnehmer.count > 1 ? "Gerät übergeben, die anderen schauen nicht hin." : "Finde zu jeder Kategorie ein Wort.").font(.footnote).foregroundStyle(.secondary)
            Spacer()
            Button("Los") { eingabe = Array(repeating: "", count: kat.count); phase = .eingabe }.buttonStyle(HauptKnopfStil())
        }.padding(.horizontal, Theme.seitenRand).padding(.bottom, 8)
    }

    private var eingabeAnsicht: some View {
        VStack(spacing: Theme.kartenAbstand) {
            ScrollView {
                VStack(spacing: Design.Abstand.s) {
                    Text("\(teilnehmer[aktuell].name): alles mit \(String(buchstabe))").font(.headline)
                    ForEach(kat.indices, id: \.self) { k in
                        HStack {
                            Text(kat[k]).font(.subheadline.weight(.semibold)).frame(width: 70, alignment: .leading)
                            TextField("\(String(buchstabe))…", text: $eingabe[k]).textFieldStyle(.roundedBorder).textInputAutocapitalization(.words).submitLabel(.next)
                                .accessibilityLabel(Text("\(kat[k]) mit \(String(buchstabe))"))
                        }
                    }
                }.padding(.horizontal, Theme.seitenRand)
            }
            Button(aktuell + 1 < teilnehmer.count ? "Fertig – weitergeben" : "Fertig – auswerten") { abgeben() }
                .buttonStyle(HauptKnopfStil()).padding(.horizontal, Theme.seitenRand).padding(.bottom, 8)
        }
    }

    private var auswertung: some View {
        let p = StadtLandFlussWertung.punkte(antworten: antworten, gueltig: gueltig, buchstabe: buchstabe)
        return VStack(spacing: Theme.kartenAbstand) {
            ScrollView {
                VStack(spacing: Theme.kartenAbstand) {
                    Text("Tippe eine Antwort an, um sie zu streichen oder wieder gelten zu lassen.").font(.footnote).foregroundStyle(.secondary)
                    ForEach(teilnehmer.indices, id: \.self) { s in
                        VStack(alignment: .leading, spacing: Design.Abstand.xs) {
                            HStack { Text(verbatim: teilnehmer[s].name).font(.headline); Spacer(); Text("+\(p[s])").font(.headline.monospacedDigit()).foregroundStyle(Color.accentText) }
                            ForEach(kat.indices, id: \.self) { k in
                                let a = antworten[s][k]
                                let ok = gueltig[s][k] && StadtLandFlussWertung.plausibel(a, buchstabe: buchstabe)
                                Button { gueltig[s][k].toggle() } label: {
                                    HStack { Text(kat[k]).font(.caption).foregroundStyle(.secondary).frame(width: 60, alignment: .leading)
                                        Text(a.isEmpty ? "–" : a).strikethrough(!ok && !a.isEmpty).foregroundStyle(ok ? Color.primary : Color.red); Spacer() }
                                }.buttonStyle(.plain)
                                .accessibilityElement(children: .ignore)
                                .accessibilityLabel(Text("\(kat[k]): \(a.isEmpty ? "keine Antwort" : a), \(ok ? "gilt" : "gilt nicht")"))
                                .accessibilityHint(Text("Doppeltippen, um die Wertung umzuschalten."))
                            }
                        }.card()
                    }
                }.padding(.horizontal, Theme.seitenRand)
            }
            Button(runde < runden ? "Nächste Runde" : "Ergebnis") { weiter(p) }.buttonStyle(HauptKnopfStil()).padding(.horizontal, Theme.seitenRand).padding(.bottom, 8)
        }
    }

    private func waehle(_ k: String, _ an: Bool) {
        var neu = StadtLandFlussWertung.alleKategorien.filter { $0 == k ? an : kat.contains($0) }
        if neu.count < StadtLandFlussWertung.mindestKategorien { neu = kat }
        kat = neu
        UserDefaults.standard.set(neu, forKey: "stadtlandfluss.kategorien")
        eingabe = Array(repeating: "", count: neu.count)
        antworten = Array(repeating: Array(repeating: "", count: neu.count), count: teilnehmer.count)
        gueltig = Array(repeating: Array(repeating: true, count: neu.count), count: teilnehmer.count)
    }

    private func neueRunde() {
        let frei = StadtLandFlussWertung.buchstaben.filter { !benutzt.contains($0) }
        buchstabe = (frei.isEmpty ? StadtLandFlussWertung.buchstaben : frei).randomElement()!
        benutzt.insert(buchstabe)
        antworten = Array(repeating: Array(repeating: "", count: kat.count), count: teilnehmer.count)
        gueltig = Array(repeating: Array(repeating: true, count: kat.count), count: teilnehmer.count)
        aktuell = 0; phase = .uebergabe
    }

    private func abgeben() {
        antworten[aktuell] = eingabe
        if aktuell + 1 < teilnehmer.count { aktuell += 1; phase = .uebergabe } else { phase = .auswertung }
    }

    private func weiter(_ p: [Int]) {
        for i in gesamt.indices { gesamt[i] += p[i] }
        if runde < runden { runde += 1; neueRunde(); return }
        let o = teilnehmer.indices.sorted { gesamt[$0] > gesamt[$1] }
        let platz = o.map { i in gesamt.filter { $0 > gesamt[i] }.count + 1 }
        ende(SpielEnde(reihenfolge: o.map { teilnehmer[$0].name }, punkte: o.map { "\(gesamt[$0])" }, plaetze: platz,
                       info: teilnehmer.count == 1 ? String(localized: "\(gesamt[0]) Punkte") : nil))
    }
}
#endif
