// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import SpielHilfen
import ZahlenfusionKern

@MainActor
public struct ZahlenfusionModul: SpielModul {
    public init() {}
    public let id = "zahlenfusion"
    public let name = "Zahlenfusion"
    public let gattung = Gattung.raetsel
    public let farbe = AkzentFarbeWert.blau
    public let symbol = "plus.square.fill"
    public let spielerzahl = 1...1
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(SpielRahmen(id: id, name: name, untertitel: "Gleiche Zahlen verschmelzen", farbe: farbe, spieler: 1...1,
                            regeln: "Wische in eine Richtung: alle Kacheln rutschen dorthin, gleiche Zahlen verschmelzen zur Summe. Nach jedem Zug erscheint eine neue 2 oder 4. Erreiche die 2048 – oder so viele Punkte wie möglich, bis nichts mehr geht.",
                            umgebung: umgebung) { teilnehmer, ende, abbrechen in
            ZahlenfusionSpiel(name: teilnehmer[0].name, ende: ende, abbrechen: abbrechen)
        }.mitZiel("Verschmilz gleiche Zahlen, bis du die 2048 erreichst, oder sammle so viele Punkte wie möglich, bis nichts mehr geht.").mitAnleitung(Self.anleitung))
    }
}

struct ZahlenfusionSpiel: View {
    @Environment(\.accessibilityReduceMotion) private var bewegungReduziert
    let name: String
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    @State private var spiel = Zahlenfusion()
    @State private var groesse = 4
    private var variante: String { spiel.n == 4 ? "" : "\(spiel.n)" }
    @State private var zufall = SystemRandomNumberGenerator()
    @State private var weiterNach2048 = false
    @State private var tag = false
    @State private var tagGen = ZufallsQuelle(seed: Tagesraetsel.seed(spiel: "zahlenfusion"))
    @State private var verlauf: [(Zahlenfusion, ZufallsQuelle)] = []
    @State private var zurueckGenutzt = 0
    @State private var tippGezeigt: FusionRichtung?

    var body: some View {
        VStack(spacing: Theme.kartenAbstand) {
            SpielKopf(mitte: "\(spiel.punkte) Punkte", linksAktion: abbrechen) {
                RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                    Button("Neu beginnen", systemImage: "arrow.counterclockwise") { tag = false; neu() }
                    Button("Tagesrätsel", systemImage: "calendar") { tag = true; neu() }
                    if let b = Bestleistung.lesen(Bestleistung.schluessel("zahlenfusion", variante: variante, tages: tag)) { Text("Beste Punktzahl: \(b)") }
                    Picker("Größe", selection: $groesse) { ForEach(3...6, id: \.self) { Text("\($0) × \($0)").tag($0) } }
                    Button("Spiel beenden", systemImage: "xmark.circle", role: .destructive) { fertig() }
                }
            }
            SpielfeldKarte {
                // Quadratisches Brett aus der verfügbaren Breite berechnen (ein Color.clear-Feld hat keine eigene Größe und wurde sonst zum flachen Balken)
                GeometryReader { geo in
                    let luecke: CGFloat = 6
                    let seite = max(20, (geo.size.width - luecke * CGFloat(spiel.n - 1)) / CGFloat(spiel.n))
                    Grid(horizontalSpacing: luecke, verticalSpacing: luecke) {
                        ForEach(0..<spiel.n, id: \.self) { z in
                            GridRow {
                                ForEach(0..<spiel.n, id: \.self) { s in kachel(spiel.feld[z * spiel.n + s], zeile: z, spalte: s).frame(width: seite, height: seite) }
                            }
                        }
                    }
                    .frame(width: geo.size.width, height: geo.size.width)
                }
                .aspectRatio(1, contentMode: .fit)
                .animation(bewegungReduziert ? nil : .snappy(duration: 0.12), value: spiel.feld)   // G3
                .onChange(of: groesse) { tag = false; neu() }
            }
            .padding(.horizontal, Theme.seitenRand)
            .gesture(DragGesture(minimumDistance: 20).onEnded { w in
                if abs(w.translation.width) > abs(w.translation.height) { zug(w.translation.width > 0 ? .rechts : .links) }
                else { zug(w.translation.height > 0 ? .unten : .oben) }
            })
            HStack(spacing: Design.Abstand.s) {
                RundKnopf(symbol: "arrow.left", beschriftung: "Nach links") { zug(.links) }
                RundKnopf(symbol: "arrow.up", beschriftung: "Nach oben") { zug(.oben) }
                RundKnopf(symbol: "arrow.down", beschriftung: "Nach unten") { zug(.unten) }
                RundKnopf(symbol: "arrow.right", beschriftung: "Nach rechts") { zug(.rechts) }
            }
            ZugKnoepfe(kannZurueck: !verlauf.isEmpty && zurueckGenutzt < 3, tippMoeglich: spiel.tippRichtung != nil,
                       zurueck: { zurueck() }, tipp: { tippGezeigt = spiel.tippRichtung; if let t = tippGezeigt { ansage(t.hinweisText) } })
            Group {
                if let t = tippGezeigt {
                    Label(t.hinweisText, systemImage: t.symbol).font(.footnote.bold())
                } else {
                    Text("Wische auf dem Brett oder nutze die Pfeile. Zurück: noch \(max(0, 3 - zurueckGenutzt))×").font(.footnote).foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .background(Color.seitenGrund)
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .spielHaptik(zug: spiel, erfolg: spiel.vorbei, fehler: false).fortsetzbar("zahlenfusion", $spiel, pruefen: { $0.istKonsistent })
        .onAppear { neu() }
    }

    private func kachel(_ w: Int, zeile: Int, spalte: Int) -> some View {
        let stufe = w == 0 ? 0 : Int(log2(Double(w)))
        return Color.clear.aspectRatio(1, contentMode: .fit)
            .overlay(
                Text(w == 0 ? "" : "\(w)")
                    .font(.system(size: w >= 1024 ? 20 : (w >= 128 ? 26 : 32), weight: .bold, design: Design.zahlDesign).monospacedDigit())   // design:spielinhalt (skaliert mit Feld/Karte/Würfel)
                    .minimumScaleFactor(0.5)
                    .foregroundStyle(w >= 8 ? .white : .primary))
            .background(w == 0 ? Color(.tertiarySystemFill) : Color.appFlaeche.opacity(min(1, 0.15 + Double(stufe) * 0.085)),
                        in: .rect(cornerRadius: Theme.feldRadius))
            .accessibilityLabel(w == 0 ? "Zeile \(zeile + 1), Spalte \(spalte + 1), leer" : "Zeile \(zeile + 1), Spalte \(spalte + 1), \(w)")
    }

    private func neu() {
        verlauf = []; zurueckGenutzt = 0; weiterNach2048 = false
        spiel = Zahlenfusion(n: groesse)
        if tag { tagGen = Tagesraetsel.generator(spiel: "zahlenfusion"); spiel.neueKachel(mit: &tagGen); spiel.neueKachel(mit: &tagGen) }
        else { spiel.neueKachel(mit: &zufall); spiel.neueKachel(mit: &zufall) }
    }

    private func zug(_ r: FusionRichtung) {
        let vorher = (spiel, tagGen)
        tippGezeigt = nil
        let ging = tag ? spiel.bewege(r, mit: &tagGen) : spiel.bewege(r, mit: &zufall)
        guard ging else { ansage(String(localized: "Kein Zug in diese Richtung")); return }
        ansage(String(localized: "Höchste Kachel \(spiel.hoechste), \(spiel.punkte) Punkte"))
        verlauf.append(vorher); if verlauf.count > 3 { verlauf.removeFirst() }
        if spiel.erreicht2048 && !weiterNach2048 { weiterNach2048 = true; fertig(gewonnen: true); return }
        if spiel.vorbei { fertig() }
    }

    private func zurueck() {
        guard let v = verlauf.popLast(), zurueckGenutzt < 3 else { return }
        spiel = v.0; tagGen = v.1; zurueckGenutzt += 1; tippGezeigt = nil
    }

    private func fertig(gewonnen: Bool = false) {
        let text = gewonnen ? String(localized: "2048 geschafft! ") : (spiel.vorbei ? String(localized: "Keine Züge mehr. ") : "")
        let zusatz = zurueckGenutzt == 0 ? Bestleistung.zusatz("zahlenfusion", variante: variante, tages: tag, wert: spiel.punkte, hoeherIstBesser: true) : ""
        ende(SpielEnde(reihenfolge: [name], punkte: ["\(spiel.punkte)"], info: text + String(localized: "\(spiel.punkte) Punkte · höchste Kachel \(spiel.hoechste)") + zusatz))
    }
}

extension FusionRichtung {
    var symbol: String { switch self { case .links: "arrow.left"; case .rechts: "arrow.right"; case .oben: "arrow.up"; case .unten: "arrow.down" } }
    var hinweisText: String {
        switch self {
        case .links: String(localized: "Tipp: nach links")
        case .rechts: String(localized: "Tipp: nach rechts")
        case .oben: String(localized: "Tipp: nach oben")
        case .unten: String(localized: "Tipp: nach unten")
        }
    }
}
#endif
