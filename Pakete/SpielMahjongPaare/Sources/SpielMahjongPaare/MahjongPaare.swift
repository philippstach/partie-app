// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import SpielHilfen
import MahjongPaareKern

@MainActor
public struct MahjongPaareModul: SpielModul {
    public init() {}
    public let id = "mahjongpaare"
    public let name = "Mahjong-Paare"
    public let gattung = Gattung.raetsel
    public let farbe = AkzentFarbeWert.blau
    public let symbol = "square.stack.3d.up.fill"
    public let spielerzahl = 1...1
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(SpielRahmen(id: id, name: name, untertitel: "Gleiche Steine paarweise entfernen", farbe: farbe, spieler: 1...1,
                            regeln: "Entferne alle Steine, indem du zwei gleiche freie Steine antippst. Ein Stein ist frei, wenn kein anderer auf ihm liegt und er links oder rechts nichts berührt. Der Tipp zeigt ein mögliches Paar. Jedes Spiel ist lösbar – aber ein falscher Zug kann dich festfahren; dann beginnst du neu.",
                            umgebung: umgebung) { teilnehmer, ende, abbrechen in
            MahjongSpiel(name: teilnehmer[0].name, ende: ende, abbrechen: abbrechen)
        }.mitZiel("Entferne alle Steine vom Brett, indem du immer zwei gleiche freie Steine antippst.").mitAnleitung(Self.anleitung))
    }
}

private let bilder = ["🌸", "🍀", "🌙", "⭐️", "🔥", "💧", "🍎", "🍋", "🍇", "🐟", "🐦", "🦊", "🐢", "🌵", "🍄", "🎲", "🔔", "🎵", "⚓️", "🗝️", "🧩", "🪁", "🎈", "🍒", "🥕", "🌻", "🪐", "🍩"]

struct MahjongSpiel: View {
    let name: String
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    @State private var spiel: MahjongPaare
    @State private var undo = RueckgaengigVerlauf<MahjongPaare>()
    @State private var gewaehlt: Int?
    @State private var tipp: (Int, Int)?
    @State private var start = Date()
    @State private var tag = false
    @State private var brett = MahjongPaare.Brett.pyramide
    private var variante: String { brett == .pyramide ? "" : "\(brett.rawValue)" }

    init(name: String, ende: @escaping (SpielEnde) -> Void, abbrechen: @escaping () -> Void) {
        self.name = name; self.ende = ende; self.abbrechen = abbrechen
        var g = SystemRandomNumberGenerator()
        _spiel = State(initialValue: MahjongPaare(mit: &g))
    }

    var body: some View {
        VStack(spacing: Theme.kartenAbstand) {
            SpielKopf(mitte: "\(spiel.verbleibend) Steine", linksAktion: abbrechen) {
                RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                    Button("Rückgängig", systemImage: "arrow.uturn.backward") { undo.zurueck(&spiel) }.disabled(!undo.kann)
                    Button("Tipp", systemImage: "lightbulb") {
                        tipp = spiel.moeglichePaare.first
                        if let t = tipp { let a = spiel.steine[t.0], b = spiel.steine[t.1]; ansage(String(localized: "Tipp: Stein in Reihe \(a.y / 2 + 1), Spalte \(a.x / 2 + 1) und Stein in Reihe \(b.y / 2 + 1), Spalte \(b.x / 2 + 1)")) }
                    }
                    Button("Neu mischen", systemImage: "shuffle") { tag = false; neu() }
                    Button("Tagesrätsel", systemImage: "calendar") { tag = true; neu() }
                    if let b = Bestleistung.lesen(Bestleistung.schluessel("mahjongpaare", variante: variante, tages: tag)) { Text("Bestzeit: \(b) s") }
                    Picker("Brett", selection: $brett) { Text("Klein (36)").tag(MahjongPaare.Brett.klein); Text("Mittel (52)").tag(MahjongPaare.Brett.mittel); Text("Pyramide (56)").tag(MahjongPaare.Brett.pyramide) }
                    Button("Spiel beenden", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
                }
            }
            SpielfeldKarte {
                GeometryReader { g in
                    let u = (g.size.width - 24) / 13
                    ZStack(alignment: .topLeading) {
                        ForEach(Array(spiel.steine.enumerated().sorted { ($0.element.ebene, $0.element.y, $0.element.x) < ($1.element.ebene, $1.element.y, $1.element.x) }), id: \.offset) { i, s in
                            if !s.entfernt { stein(i, s, u) }
                        }
                    }
                    .frame(width: g.size.width, height: g.size.height, alignment: .topLeading)
                }
                .aspectRatio(0.95, contentMode: .fit).frame(maxWidth: Theme.wideColumnWidth)
            }.padding(.horizontal, Theme.seitenRand)
            if spiel.festgefahren {
                VStack(spacing: Design.Abstand.s) {
                    Text("Kein Paar mehr möglich.").font(.headline)
                    Button("Steine mischen") { var g = SystemRandomNumberGenerator(); spiel.mischeRest(mit: &g); gewaehlt = nil; tipp = nil }.buttonStyle(HauptKnopfStil())
                    Button("Neu beginnen") { neu() }.buttonStyle(ZweitKnopfStil())
                }.card().padding(.horizontal, Theme.seitenRand)
            } else {
                Text("Tippe zwei gleiche freie Steine an.").font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .background(Color.seitenGrund)
        .weicheAnimation(bei: spiel)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .spielHaptik(zug: spiel, erfolg: spiel.geloest, fehler: spiel.festgefahren).fortsetzbar("mahjongpaare", $spiel, pruefen: { $0.istKonsistent })
        .onChange(of: brett) { tag = false; neu() }
        .rueckgaengigMerken(spiel, in: undo)
    }

    private func stein(_ i: Int, _ s: MahjongStein, _ u: CGFloat) -> some View {
        let frei = spiel.frei(i)
        let markiert = gewaehlt == i, istTipp = tipp.map { $0.0 == i || $0.1 == i } ?? false
        let breite = u * 2 - 2, hoehe = breite * 1.2
        return Button { tippe(i) } label: {
            Text(bilder[s.motiv % bilder.count]).font(.system(size: breite * 0.55))   // design:spielinhalt (skaliert mit Feld/Karte/Würfel)
                .frame(width: breite, height: hoehe)
                .background(frei ? Color(.systemBackground) : Color(.secondarySystemBackground), in: .rect(cornerRadius: 5))
                .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(markiert ? Color.appFlaeche : (istTipp ? Color.orange : Color.secondary.opacity(0.5)), lineWidth: markiert || istTipp ? 3 : 1))   // design:spielinhalt (Markierung auf dem Spielmaterial)
                .opacity(frei ? 1 : 0.55)
                .shadow(color: .black.opacity(0.25), radius: 1, x: 2, y: 2)
        }
        .buttonStyle(.plain)
        .offset(x: 12 + CGFloat(s.x) * u - CGFloat(s.ebene) * 4, y: 8 + CGFloat(s.y) * u * 1.2 - CGFloat(s.ebene) * 4)
        .accessibilityHint(frei ? Text("Zum Auswählen doppeltippen, dann den passenden zweiten Stein antippen.") : Text("Dieser Stein ist blockiert."))
        .accessibilityAddTraits(markiert ? .isSelected : [])
        .accessibilityLabel(frei ? "Freier Stein \(s.motiv + 1), Ebene \(s.ebene + 1), Reihe \(s.y / 2 + 1), Spalte \(s.x / 2 + 1)" : "Blockierter Stein \(s.motiv + 1), Ebene \(s.ebene + 1), Reihe \(s.y / 2 + 1), Spalte \(s.x / 2 + 1)")
    }

    private func tippe(_ i: Int) {
        tipp = nil
        guard spiel.frei(i) else { return }
        if let g = gewaehlt {
            if g == i { gewaehlt = nil; return }
            if spiel.entferne(g, i) { gewaehlt = nil; ansage(String(localized: "Paar entfernt, \(spiel.steine.filter { !$0.entfernt }.count) Steine übrig"))
                if spiel.geloest { ende(SpielEnde(reihenfolge: [name], info: String(localized: "Geschafft in \(Int(Date().timeIntervalSince(start))) Sekunden") + Bestleistung.zusatz("mahjongpaare", variante: variante, tages: tag, wert: max(1, Int(Date().timeIntervalSince(start)))))) }
                return }
        }
        gewaehlt = i
        ansage(String(localized: "Stein gewählt. Jetzt den passenden zweiten Stein antippen."))
    }

    private func neu() {
        undo.leeren()
        if tag { var g = Tagesraetsel.generator(spiel: "mahjongpaare"); spiel = MahjongPaare(brett: brett, mit: &g) }
        else { var g = SystemRandomNumberGenerator(); spiel = MahjongPaare(brett: brett, mit: &g) }
        gewaehlt = nil; tipp = nil; start = Date()
    }
}
#endif
