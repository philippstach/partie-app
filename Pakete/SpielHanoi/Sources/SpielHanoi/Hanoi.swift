// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import SpielHilfen
import HanoiKern

@MainActor
public struct HanoiModul: SpielModul {
    public init() {}
    public let id = "hanoi"
    public let name = "Turm von Hanoi"
    public let gattung = Gattung.raetsel
    public let farbe = AkzentFarbeWert.blau
    public let symbol = "line.3.horizontal.decrease"
    public let spielerzahl = 1...1
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(SpielRahmen(id: id, name: name, untertitel: "Setze den Turm um", farbe: farbe, spieler: 1...1,
                            regeln: "Versetze alle Scheiben vom linken auf den rechten Stab. Du darfst immer nur die oberste Scheibe nehmen und nie eine größere auf eine kleinere legen. Tippe erst den Stab, von dem du nimmst, dann den Zielstab. Mit n Scheiben schaffst du es in mindestens 2ⁿ − 1 Zügen.",
                            umgebung: umgebung) { teilnehmer, ende, abbrechen in
            HanoiSpiel(name: teilnehmer[0].name, ende: ende, abbrechen: abbrechen)
        }.mitZiel("Setze den ganzen Turm auf den rechten Stab, mit möglichst wenigen Zügen.").mitAnleitung(Self.anleitung))
    }
}

struct HanoiSpiel: View {
    let name: String
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    @State private var scheiben = 4
    @State private var staebeZahl = 3
    @State private var fortgesetzt = false
    @State private var spiel = Hanoi(scheiben: 4)
    private var variante: String { staebeZahl == 3 ? "\(scheiben)" : "\(scheiben)-\(staebeZahl)" }
    private var maxScheiben: Int { staebeZahl == 4 ? 9 : 8 }
    @State private var von: Int?
    @State private var tag = false
    @State private var tipp: (von: Int, nach: Int)?
    @State private var tipps = 0
    /// Tagesrätsel: Die Scheibenzahl wechselt täglich zwischen 4 und 8.
    private var tagesScheiben: Int { Int(Tagesraetsel.seed(spiel: "hanoi") % 5) + 4 }

    var body: some View {
        VStack(spacing: Theme.kartenAbstand) {
            SpielKopf(mitte: "\(spiel.zuege) Züge · Ziel \(spiel.minimum)", linksAktion: abbrechen) {
                RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                    Button("Zug zurück", systemImage: "arrow.uturn.backward") { spiel.zurueck(); von = nil }.disabled(!spiel.kannZurueck)
                    Button("Neu beginnen", systemImage: "arrow.counterclockwise") { neu() }
                    Button("Tagesrätsel (\(tagesScheiben) Scheiben)", systemImage: "calendar") { tag = true; Tagesraetsel.merkeStart(spiel: "hanoi"); if scheiben != tagesScheiben { scheiben = tagesScheiben } else { neu() } }
                    if let b = Bestleistung.lesen(Bestleistung.schluessel("hanoi", variante: variante, tages: tag)) { Text("Beste Zugzahl: \(b)") }
                    Picker("Scheiben", selection: $scheiben) { ForEach(3...maxScheiben, id: \.self) { Text("\($0) Scheiben").tag($0) } }
                    Picker("Stäbe", selection: $staebeZahl) { Text("3 Stäbe").tag(3); Text("4 Stäbe (leichter)").tag(4) }
                    Button("Spiel beenden", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
                }
            }
            SpielfeldKarte {
                HStack(alignment: .bottom, spacing: Design.Abstand.s) {
                    ForEach(0..<spiel.anzahlStaebe, id: \.self) { s in stab(s) }
                }
                .frame(height: 300)
                .padding(8)
            }
            .padding(.horizontal, Theme.seitenRand)
            Text(tipp.map { String(localized: "Tipp: von Stab \($0.von + 1) nach Stab \($0.nach + 1)") } ?? (von == nil ? String(localized: "Wähle einen Stab.") : String(localized: "Wähle den Zielstab."))).font(.subheadline).foregroundStyle(tipp == nil ? Color.secondary : Color.appFlaeche)
            HStack(spacing: Design.Abstand.m) {
                Button { spiel.zurueck(); von = nil; tipp = nil } label: { Label("Zug zurück", systemImage: "arrow.uturn.backward") }
                    .nebenKnopf().dynamicTypeSize(...DynamicTypeSize.xxxLarge).disabled(!spiel.kannZurueck || spiel.geloest)
                Button { tipp = spiel.hinweis().map { ($0.von, $0.nach) }; tipps += 1; if let t = tipp { ansage(String(localized: "Tipp: von Stab \(t.0 + 1) nach Stab \(t.1 + 1)")) } } label: { Label("Tipp", systemImage: "lightbulb") }.nebenKnopf().dynamicTypeSize(...DynamicTypeSize.xxxLarge).disabled(spiel.geloest)
            }
            Spacer(minLength: 0)
        }
        .background(Color.seitenGrund)
        .weicheAnimation(bei: spiel)
        .spielHaptik(zug: spiel, erfolg: spiel.geloest, fehler: false).fortsetzbar("hanoi", $spiel, pruefen: { $0.istKonsistent })
        .onChange(of: spiel.scheiben) { _, n in if scheiben != n { fortgesetzt = true; scheiben = n } }
        .onChange(of: spiel.anzahlStaebe) { _, n in if staebeZahl != n { staebeZahl = n } }
        .onChange(of: staebeZahl) { _, _ in if spiel.anzahlStaebe == staebeZahl { return }; if scheiben > maxScheiben { scheiben = maxScheiben } else { tag = false; neu() } }
        .onChange(of: scheiben) { _, neu in
            if fortgesetzt { fortgesetzt = false; return }   // Scheibenzahl kommt aus dem geladenen Stand
            if neu != tagesScheiben { tag = false }; self.neu()
        }
    }

    private func stab(_ s: Int) -> some View {
        Button { tippe(s) } label: {
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 4).fill(Color.secondary.opacity(0.35)).frame(width: 8, height: 280)
                VStack(spacing: 3) {
                    Spacer(minLength: 0)
                    ForEach(Array(spiel.staebe[s].reversed()), id: \.self) { d in
                        RoundedRectangle(cornerRadius: Design.Ecke.klein, style: .continuous)
                            .fill(Color.kartenGrund)
                            .overlay(RoundedRectangle(cornerRadius: Design.Ecke.klein, style: .continuous).fill(Color.appFlaeche.opacity(0.35 + 0.65 * Double(spiel.scheiben - d + 1) / Double(spiel.scheiben))))
                            .frame(width: 30 + CGFloat(d) * 80 / CGFloat(spiel.scheiben) * 1.0, height: 26)
                            .overlay(Text("\(d)").font(.caption.weight(.bold)).foregroundStyle(.white))
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(von == s ? Color.appFlaeche.opacity(0.12) : Color.clear, in: .rect(cornerRadius: Design.Ecke.feld))
            .overlay(RoundedRectangle(cornerRadius: Design.Ecke.feld).stroke(Color.yellow, style: StrokeStyle(lineWidth: 3, dash: tipp?.nach == s ? [6, 4] : [])).opacity(tipp?.von == s || tipp?.nach == s ? 1 : 0))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Stab \(s + 1), \(spiel.staebe[s].count) Scheiben")
        .accessibilityValue(spiel.staebe[s].last.map { Text("Oberste Scheibe: \($0)") } ?? Text("Leer"))
        .accessibilityAddTraits(von == s ? .isSelected : [])
    }

    private func neu() { spiel = Hanoi(scheiben: scheiben, staebe: staebeZahl); von = nil; tipp = nil; tipps = 0 }

    private func tippe(_ s: Int) {
        guard let v = von else { if !spiel.staebe[s].isEmpty { von = s }; return }
        if v == s { von = nil; return }
        let ok = spiel.ziehe(von: v, nach: s)
        von = nil; tipp = nil
        ansage(ok ? String(localized: "Scheibe von Stab \(v + 1) auf Stab \(s + 1) gelegt") : String(localized: "Nicht erlaubt: keine größere Scheibe auf eine kleinere"))
        if spiel.geloest { ende(SpielEnde(reihenfolge: [name], info: String(localized: "\(spiel.zuege) Züge (Minimum \(spiel.minimum))") + (tipps == 0 ? Bestleistung.zusatz("hanoi", variante: variante, tages: tag, wert: spiel.zuege) : ""))) }
    }
}
#endif
