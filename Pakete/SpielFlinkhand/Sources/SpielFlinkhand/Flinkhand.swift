// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import SpielHilfen
import FlinkhandKern

@MainActor
public struct FlinkhandModul: SpielModul {
    public init() {}
    public let id = "flinkhand"
    public let name = "Flinkhand"
    public let gattung = Gattung.karten
    public let farbe = AkzentFarbeWert.orange
    public let symbol = "hand.tap.fill"
    public let spielerzahl = 2...4
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(SpielRahmen(id: id, name: name, untertitel: "Wer ist am schnellsten?", farbe: farbe, spieler: 2...4, computerErlaubt: true,
                            regeln: "Alle Karten werden verteilt. Reihum legt jeder seine oberste Karte offen in die Mitte. Liegen zwei gleiche Bilder direkt übereinander, drückt jeder so schnell wie möglich auf „Schnapp!“. Wer zuerst drückt, bekommt den ganzen Stapel in der Mitte. Wer zu Unrecht drückt, muss eine Karte unter den Mittelstapel legen. Wer keine Karten mehr hat, scheidet aus; wer am Ende alle Karten hat, gewinnt. Mit mehreren Menschen an einem Gerät hat jeder seinen eigenen Knopf.",
                            umgebung: umgebung) { teilnehmer, ende, abbrechen in
            FlinkhandSpiel(teilnehmer: teilnehmer, ende: ende, abbrechen: abbrechen)
        }.mitZiel("Drücke bei zwei gleichen Bildern als Erster auf Schnapp und sammle so alle Karten. Wer alle hat, gewinnt.").mitAnleitung(Self.anleitung))
    }
}

private let motivSymbole = Array(TierMotive.symbole.prefix(Flinkhand.motive))
private let motivFarben = TierMotive.farben
/// Namen der Motive für VoiceOver (gleiche Reihenfolge wie `TierMotive.symbole`).
private let motivNamen: [LocalizedStringKey] = ["Schildkröte", "Hase", "Vogel", "Fisch", "Ameise", "Marienkäfer", "Pfote", "Blatt", "Katze", "Hund", "Echse", "Teddybär"]

struct FlinkhandSpiel: View {
    let teilnehmer: [SpielTeilnehmer]
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    @State private var spiel: Flinkhand
    @State private var zufall = SystemRandomNumberGenerator()
    @State private var meldung = " "
    @State private var gemeldet = false
    @State private var tick = 0
    @State private var stufe = ComputerStufe.gespeichert("flinkhand")
    /// Reaktionszeit des Computers in Sekunden (Bereich).
    private var reaktion: ClosedRange<Double> { switch stufe { case .leicht: 1.4...2.4; case .mittel: 0.8...1.7; case .schwer: 0.5...1.0 } }

    init(teilnehmer: [SpielTeilnehmer], ende: @escaping (SpielEnde) -> Void, abbrechen: @escaping () -> Void) {
        self.teilnehmer = teilnehmer; self.ende = ende; self.abbrechen = abbrechen
        var g = SystemRandomNumberGenerator()
        _spiel = State(initialValue: Flinkhand(spieler: teilnehmer.count, mit: &g))
    }

    private var computer: [Int] { teilnehmer.indices.filter { teilnehmer[$0].computer } }
    private var menschen: [Int] { teilnehmer.indices.filter { !teilnehmer[$0].computer } }

    var body: some View {
        VStack(spacing: Theme.kartenAbstand) {
            SpielKopf(mitte: String(localized: "Mitte: \(spiel.mitte.count)"), linksAktion: abbrechen) {
                RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                    if !computer.isEmpty { ComputerStufePicker(spiel: "flinkhand", stufe: $stufe) }
                    Button("Spiel beenden", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
                }
            }
            HStack(spacing: Design.Abstand.s) {
                ForEach(teilnehmer.indices, id: \.self) { i in
                    VStack(spacing: 2) {
                        Text(verbatim: teilnehmer[i].name).font(.footnote).lineLimit(1).minimumScaleFactor(0.7)
                        Text(verbatim: "\(spiel.haende[i].count)").font(.title3.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: Design.Ecke.feld).fill(i == spiel.amZug ? Color.appFlaeche.opacity(0.25) : Color.kartenGrund))
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text(verbatim: teilnehmer[i].name))
                    .accessibilityValue(Text("\(spiel.haende[i].count) Karten übrig"))
                }
            }.padding(.horizontal, Theme.seitenRand)
            Spacer(minLength: 0)
            HStack(spacing: -40) {
                ForEach(Array(spiel.mitte.suffix(2).enumerated()), id: \.offset) { _, m in
                    RoundedRectangle(cornerRadius: Design.Ecke.feld).fill(Color.kartenGrund)
                        .overlay(RoundedRectangle(cornerRadius: Design.Ecke.feld).stroke(spiel.passt ? Color.appFlaeche : .secondary.opacity(0.4), lineWidth: spiel.passt ? 4 : 1))
                        .overlay(Image(systemName: motivSymbole[m]).font(.system(size: 54)).foregroundStyle(motivFarben[m]))   // design:spielinhalt (feste Großdarstellung von Spielmaterial, kein Fließtext)
                        .frame(width: 110, height: 150)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(Text(motivNamen[m]))
                }
            }
            .accessibilityElement(children: .contain)
            Text(meldung).font(.headline).foregroundStyle(Color.accentText).frame(minHeight: 24)
            Spacer(minLength: 0)
            HStack(spacing: Design.Abstand.m) {
                ForEach(menschen, id: \.self) { i in
                    Button { druecke(i) } label: { Text(menschen.count > 1 ? "Schnapp! (\(teilnehmer[i].name))" : "Schnapp!").frame(maxWidth: .infinity) }
                        .buttonStyle(HauptKnopfStil())
                        .disabled(spiel.haende[i].isEmpty || spiel.sieger != nil)
                }
            }.padding(.horizontal, Theme.seitenRand).padding(.bottom, 8)
        }
        .background(Color.seitenGrund)
        .fortsetzbar("flinkhand", $spiel)
        .weicheAnimation(bei: spiel)
        .spielHaptik(zug: spiel, erfolg: (spiel.sieger != nil))
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .task(id: "\(spiel.mitte.count)-\(spiel.amZug)-\(tick)") {
            guard spiel.sieger == nil else { return }
            if spiel.passt {
                let c = computer.filter { !spiel.haende[$0].isEmpty }.randomElement(using: &zufall)
                try? await Task.sleep(nanoseconds: UInt64(c != nil ? Double.random(in: reaktion) * 1e9 : 3.0 * 1e9))
                guard !Task.isCancelled else { return }
                if let c { druecke(c) } else { spiel.lege(); tick += 1 }
            } else {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { return }
                spiel.lege(); tick += 1
            }
            pruefe()
        }
    }

    private func druecke(_ i: Int) {
        guard spiel.sieger == nil else { return }
        if spiel.schnapp(i) { meldung = String(localized: "\(teilnehmer[i].name) war schneller!") }
        else { meldung = String(localized: "\(teilnehmer[i].name): Falsch! Eine Karte Strafe.") }
        tick += 1; pruefe()
    }

    private func pruefe() {
        guard let w = spiel.sieger, !gemeldet else { return }
        gemeldet = true
        let rang = teilnehmer.indices.sorted { a, b in a == w ? true : (b == w ? false : spiel.haende[a].count > spiel.haende[b].count) }
        Task {
            try? await Task.sleep(nanoseconds: 900_000_000)
            ende(SpielEnde(reihenfolge: rang.map { teilnehmer[$0].name }, punkte: rang.map { "\(spiel.haende[$0].count)" }))
        }
    }
}
#endif
