// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import SpielHilfen
import LichterAusKern

@MainActor
public struct LichterAusModul: SpielModul {
    public init() {}
    public let id = "lichteraus"
    public let name = "Lichter aus"
    public let gattung = Gattung.raetsel
    public let farbe = AkzentFarbeWert.blau
    public let symbol = "lightbulb.fill"
    public let spielerzahl = 1...1
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(SpielRahmen(id: id, name: name, untertitel: "Schalte alle Lichter aus", farbe: farbe, spieler: 1...1,
                            regeln: "Ein Tipp schaltet das Feld und seine vier Nachbarn um (an ↔ aus). Bring alle Lichter zum Erlöschen, mit möglichst wenigen Tipps.",
                            umgebung: umgebung) { teilnehmer, ende, abbrechen in
            LichterAusSpiel(name: teilnehmer[0].name, ende: ende, abbrechen: abbrechen)
        }.mitZiel("Bring alle Lichter zum Erlöschen, mit möglichst wenigen Tipps.").mitAnleitung(Self.anleitung))
    }
}

struct LichterAusSpiel: View {
    @Environment(\.accessibilityReduceMotion) private var bewegungReduziert
    let name: String
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    @State private var spiel = LichterAus()
    @State private var undo = RueckgaengigVerlauf<LichterAus>()
    @State private var zufall = SystemRandomNumberGenerator()
    @State private var tag = false
    @State private var tipp: Int?
    @State private var tipps = 0
    @AppStorage("lichteraus.groesse") private var groesse = 5
    @AppStorage("lichteraus.stufe") private var stufe = 1          // 0 leicht, 1 mittel, 2 schwer
    @AppStorage("lichteraus.muster") private var musterRoh = LichterAus.Muster.kreuz.rawValue
    private var muster: LichterAus.Muster { LichterAus.Muster(rawValue: musterRoh) ?? .kreuz }
    /// Zahl der Misch-Tipps: leicht = wenige, schwer = so viele wie das Feld hergibt.
    private var mischTipps: Int {
        let m = groesse * groesse
        switch stufe { case 0: return max(3, m / 5); case 2: return max(8, m * 2 / 3); default: return max(5, m / 3) }
    }
    private var variantenSchluessel: String { "\(groesse)-\(stufe)-\(musterRoh)" }

    var body: some View {
        VStack(spacing: Theme.kartenAbstand) {
            SpielKopf(mitte: String(localized: "\(spiel.zuege) Züge · \(spiel.anzahlAn) an"), linksAktion: abbrechen) {
                RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                    Button("Rückgängig", systemImage: "arrow.uturn.backward") { undo.zurueck(&spiel) }.disabled(!undo.kann)
                    Button("Neu mischen", systemImage: "shuffle") { tag = false; neu() }
                    Button("Tagesrätsel", systemImage: "calendar") { tag = true; neu() }
                    if let b = Bestleistung.lesen(Bestleistung.schluessel("lichteraus", variante: variantenSchluessel, tages: tag)) { Text("Beste Zugzahl: \(b)") }
                    Picker("Größe", selection: $groesse) { ForEach(3...7, id: \.self) { Text("\($0) × \($0)").tag($0) } }
                    Picker("Schwierigkeit", selection: $stufe) {
                        ForEach(Array(["Leicht", "Mittel", "Schwer"].enumerated()), id: \.offset) { i, n in
                            (Text(LocalizedStringKey(n)) + Text(Leiter.offen("lichteraus", stufe: i) ? "" : " 🔒")).tag(i).disabled(!Leiter.offen("lichteraus", stufe: i))
                        }
                    }
                    Picker("Muster", selection: $musterRoh) {
                        Text("Plus (4 Nachbarn)").tag(LichterAus.Muster.kreuz.rawValue)
                        Text("Diagonal").tag(LichterAus.Muster.diagonal.rawValue)
                        Text("Rund (8 Nachbarn)").tag(LichterAus.Muster.rund.rawValue)
                    }
                    Button("Spiel beenden", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
                }
            }
            SpielfeldKarte {
                let n = spiel.n
                Grid(horizontalSpacing: 6, verticalSpacing: 6) {
                    ForEach(0..<n, id: \.self) { z in
                        GridRow {
                            ForEach(0..<n, id: \.self) { s in
                                let i = z * n + s
                                Button { tippe(i) } label: {
                                    RoundedRectangle(cornerRadius: Theme.feldRadius, style: .continuous)
                                        .fill(spiel.an[i] ? Color.appFlaeche : Color(.tertiarySystemFill))
                                        .overlay(RoundedRectangle(cornerRadius: Theme.feldRadius, style: .continuous).stroke(Color.yellow, lineWidth: tipp == i ? 4 : 0))
                                        .overlay(Image(systemName: spiel.an[i] ? "lightbulb.fill" : "lightbulb").foregroundStyle(spiel.an[i] ? .white : .secondary))
                                        .aspectRatio(1, contentMode: .fit).frame(maxWidth: Theme.wideColumnWidth)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Zeile \(z + 1), Spalte \(s + 1), \(spiel.an[i] ? String(localized: "an") : String(localized: "aus"))")
                                .accessibilityHint(Text("Schaltet dieses Feld und seine Nachbarn um."))
                            }
                        }
                    }
                }
                .animation(bewegungReduziert ? nil : .snappy(duration: 0.15), value: spiel.an)   // G3
            }
            .padding(.horizontal, Theme.seitenRand)
            Button { tipp = spiel.hinweis(); tipps += 1; if let t = tipp { ansage(String(localized: "Tipp: Zeile \(t / spiel.n + 1), Spalte \(t % spiel.n + 1) antippen")) } } label: { Label("Tipp", systemImage: "lightbulb") }.nebenKnopf().dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            Spacer(minLength: 0)
        }
        .background(Color.seitenGrund)
        .spielHaptik(zug: spiel, erfolg: spiel.geschafft, fehler: false).fortsetzbar("lichteraus", $spiel, pruefen: { $0.istKonsistent })
        .rueckgaengigMerken(spiel, in: undo)
        .onAppear { stufe = Leiter.begrenzt("lichteraus", stufe: stufe, anzahl: 3); neu() }
        .onChange(of: variantenSchluessel) { _, _ in tag = false; neu() }
    }

    private func neu() {
        undo.leeren()
        spiel = LichterAus(n: groesse, muster: muster); tipp = nil; tipps = 0
        if tag { var g = Tagesraetsel.generator(spiel: "lichteraus"); spiel.mischen(tipps: mischTipps, mit: &g) } else { spiel.mischen(tipps: mischTipps, mit: &zufall) }
    }

    private func tippe(_ i: Int) {
        spiel.tippe(i); tipp = nil
        if spiel.geschafft {
            Leiter.sieg("lichteraus", stufe: stufe, mitTipp: tipps > 0, tages: tag)   // D4
            ende(SpielEnde(reihenfolge: [name], info: String(localized: "In \(spiel.zuege) Zügen") + (tipps == 0 ? Bestleistung.zusatz("lichteraus", variante: variantenSchluessel, tages: tag, wert: spiel.zuege) : "")))
        }
    }
}
#endif
