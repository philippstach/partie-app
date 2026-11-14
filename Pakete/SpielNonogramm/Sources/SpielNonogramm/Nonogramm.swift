// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import SpielHilfen
import NonogrammKern

@MainActor
public struct NonogrammModul: SpielModul {
    public init() {}
    public let id = "nonogramm"
    public let name = "Nonogramm"
    public let gattung = Gattung.raetsel
    public let farbe = AkzentFarbeWert.blau
    public let symbol = "square.grid.4x3.fill"
    public let spielerzahl = 1...1
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(SpielRahmen(id: id, name: name, untertitel: "Zahlen verraten das Bild", farbe: farbe, spieler: 1...1,
                            regeln: "Die Zahlen am Rand einer Zeile oder Spalte sagen, wie lang die Blöcke gefüllter Felder sind – in dieser Reihenfolge und mit mindestens einem leeren Feld dazwischen. Tippe ein Feld, um es zu füllen; halte es gedrückt (oder wechsle die Betriebsart), um ein Feld als leer zu markieren. Erfüllt jede Zeile und Spalte ihre Zahlen, ist das Bild gelöst.",
                            umgebung: umgebung) { teilnehmer, ende, abbrechen in
            NonogrammSpiel(name: teilnehmer[0].name, ende: ende, abbrechen: abbrechen)
        }.mitZiel("Fülle die Felder so, dass jede Zeile und Spalte zu ihren Zahlen passt. Dann erscheint das Bild.").mitAnleitung(Self.anleitung))
    }
}

struct NonogrammSpiel: View {
    let name: String
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    /// D4: Die Größen sind die Stufen der Leiter.
    static let groessen = [5, 8, 10, 12, 15]
    @State private var n = Leiter.begrenzt("nonogramm", stufe: 1, anzahl: 5) == 0 ? 5 : 8
    @ScaledMetric(relativeTo: .caption) private var zeilenSchrift: CGFloat = 12
    @State private var puzzle: Nonogramm
    @State private var undo = RueckgaengigVerlauf<Nonogramm>()
    @State private var markieren = false
    @State private var zufall = SystemRandomNumberGenerator()
    @State private var start = Date()
    @State private var tag = false
    @State private var tipps = 0
    /// Schrift der Hinweiszahlen wächst mit der eingestellten Größe, aber höchstens so weit, wie das Raster Platz hat (`NonogrammLayout`).
    private var skala: CGFloat { min(zeilenSchrift / 12, CGFloat(NonogrammLayout.skalaGrenze(n: puzzle.n))) }
    private var spaltenPt: CGFloat { 11 * skala }
    private var zeilenPt: CGFloat { 12 * skala }
    private var hinweisBreite: CGFloat { CGFloat(NonogrammLayout.hinweisBreite(n: puzzle.n)) * skala }

    init(name: String, ende: @escaping (SpielEnde) -> Void, abbrechen: @escaping () -> Void) {
        self.name = name; self.ende = ende; self.abbrechen = abbrechen
        var g = SystemRandomNumberGenerator()
        _puzzle = State(initialValue: Nonogramm.zufaellig(n: Leiter.begrenzt("nonogramm", stufe: 1, anzahl: 5) == 0 ? 5 : 8, mit: &g))
    }

    var body: some View {
        VStack(spacing: Theme.kartenAbstand) {
            SpielKopf(mitte: "\(puzzle.n) × \(puzzle.n)", linksAktion: abbrechen) {
                RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                    Button("Rückgängig", systemImage: "arrow.uturn.backward") { undo.zurueck(&puzzle) }.disabled(!undo.kann)
                    Button("Neues Rätsel", systemImage: "shuffle") { tag = false; neu() }
                    Button("Tagesrätsel", systemImage: "calendar") { tag = true; neu() }
                    if let b = Bestleistung.lesen(Bestleistung.schluessel("nonogramm", variante: "\(puzzle.n)", tages: tag)) { Text("Bestzeit: \(b) s") }
                    Picker("Größe", selection: Binding(get: { puzzle.n }, set: { n = $0; neu() })) {
                        ForEach(Array(Self.groessen.enumerated()), id: \.offset) { i, g in
                            (Text(verbatim: "\(g) × \(g)") + Text(Leiter.offen("nonogramm", stufe: i) ? "" : " 🔒")).tag(g).disabled(!Leiter.offen("nonogramm", stufe: i))   // D4
                        }
                    }
                    Button("Spiel beenden", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
                }
            }
            SpielfeldKarte {
                Grid(horizontalSpacing: 2, verticalSpacing: 2) {
                    GridRow {
                        Color.clear.frame(width: hinweisBreite, height: 1)
                        ForEach(0..<puzzle.n, id: \.self) { s in
                            Text(puzzle.spaltenHinweise[s].map(String.init).joined(separator: "\n"))
                                .font(.system(size: spaltenPt, weight: .semibold, design: Design.zahlDesign).monospacedDigit()).multilineTextAlignment(.center) // design:spielinhalt
                                .foregroundStyle(puzzle.spalteErfuellt(s) ? Color.secondary.opacity(0.5) : Color.primary)
                                .frame(maxWidth: .infinity, alignment: .bottom).fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    ForEach(0..<puzzle.n, id: \.self) { z in
                        GridRow {
                            Text(puzzle.zeilenHinweise[z].map(String.init).joined(separator: " "))
                                .font(.system(size: zeilenPt, weight: .semibold, design: Design.zahlDesign).monospacedDigit()) // design:spielinhalt
                                .foregroundStyle(puzzle.zeileErfuellt(z) ? Color.secondary.opacity(0.5) : Color.primary)
                                .lineLimit(1).minimumScaleFactor(NonogrammLayout.kleinsterSchrumpf)   // viele Hinweise rücken zusammen statt über die Spalte zu laufen
                                .frame(width: hinweisBreite, alignment: .trailing)
                            ForEach(0..<puzzle.n, id: \.self) { s in feld(z * puzzle.n + s) }
                        }
                    }
                }
                .padding(4)
            }
            .padding(.horizontal, Theme.seitenRand)
            Picker("Betriebsart", selection: $markieren) {
                Label("Füllen", systemImage: "square.fill").tag(false)
                Label("Leer markieren", systemImage: "xmark").tag(true)
            }.pickerStyle(.segmented).padding(.horizontal, Theme.seitenRand)
            Button { if let i = puzzle.tipp(mit: &zufall) {
                tipps += 1
                ansage(puzzle.stand[i] == .gefuellt ? String(localized: "Tipp: Zeile \(i / puzzle.n + 1), Spalte \(i % puzzle.n + 1) gefüllt") : String(localized: "Tipp: Zeile \(i / puzzle.n + 1), Spalte \(i % puzzle.n + 1) geleert"))
                pruefeGeloest()
            } } label: { Label("Tipp", systemImage: "lightbulb") }.nebenKnopf().dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            Spacer(minLength: 0)
        }
        .background(Color.seitenGrund)
        .weicheAnimation(bei: puzzle)
        .spielHaptik(zug: puzzle, erfolg: puzzle.geloest, fehler: false).fortsetzbar("nonogramm", $puzzle, pruefen: { $0.istKonsistent })
        .rueckgaengigMerken(puzzle, in: undo)
    }

    private func feld(_ i: Int) -> some View {
        let f = puzzle.stand[i]
        return Button { tippe(i, lang: false) } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 3).fill(f == .gefuellt ? Color.appFlaeche : Color(.tertiarySystemFill))
                if f == .markiert { Image(systemName: "xmark").font(.system(size: 10, weight: .bold)).foregroundStyle(.secondary) } // design:spielinhalt
            }
            .aspectRatio(1, contentMode: .fit).frame(maxWidth: Theme.wideColumnWidth)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(LongPressGesture(minimumDuration: 0.35).onEnded { _ in tippe(i, lang: true) })
        .accessibilityLabel("Zeile \(i / puzzle.n + 1), Spalte \(i % puzzle.n + 1), \(f == .gefuellt ? String(localized: "gefüllt") : (f == .markiert ? String(localized: "markiert") : String(localized: "leer")))")
        .accessibilityHint(Text("Zum Füllen doppeltippen. Mit der Aktion „Markieren“ setzt du ein Kreuz."))
        .accessibilityAction(named: Text("Markieren")) { tippe(i, lang: true) }
    }

    private func tippe(_ i: Int, lang: Bool) {
        if lang || markieren { puzzle.markiere(i) } else { puzzle.tippe(i) }
        pruefeGeloest()
    }

    private func pruefeGeloest() {
        guard puzzle.geloest else { return }
        let sek = max(1, Int(Date().timeIntervalSince(start)))
        if let i = Self.groessen.firstIndex(of: puzzle.n) { Leiter.sieg("nonogramm", stufe: i, mitTipp: tipps > 0, tages: tag) }   // D4
        ende(SpielEnde(reihenfolge: [name], info: String(localized: "Gelöst in \(sek) Sekunden") + (tipps > 0 ? " · " + String(localized: "\(tipps) Tipps") : Bestleistung.zusatz("nonogramm", variante: "\(puzzle.n)", tages: tag, wert: sek))))
    }

    private func neu() {
        undo.leeren()
        if tag { var g = Tagesraetsel.generator(spiel: "nonogramm", variante: "\(n)"); puzzle = Nonogramm.zufaellig(n: n, mit: &g) }
        else { puzzle = Nonogramm.zufaellig(n: n, mit: &zufall) }
        start = Date(); tipps = 0
    }
}
#endif
