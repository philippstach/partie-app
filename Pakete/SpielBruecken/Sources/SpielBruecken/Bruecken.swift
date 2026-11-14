// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import SpielHilfen
import BrueckenKern

@MainActor
public struct BrueckenModul: SpielModul {
    public init() {}
    public let id = "bruecken"
    public let name = "Brücken"
    public let gattung = Gattung.raetsel
    public let farbe = AkzentFarbeWert.blau
    public let symbol = "point.3.connected.trianglepath.dotted"
    public let spielerzahl = 1...1
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(SpielRahmen(id: id, name: name, untertitel: "Inseln verbinden", farbe: farbe, spieler: 1...1,
                            regeln: "Verbinde die Inseln mit Brücken. Die Zahl auf einer Insel sagt, wie viele Brücken von ihr ausgehen. Brücken verlaufen nur waagrecht oder senkrecht, kreuzen sich nicht, und zwischen zwei Inseln liegen höchstens zwei. Am Ende müssen alle Inseln zusammenhängen. Tippe nacheinander zwei benachbarte Inseln an: einmal ergibt eine Brücke, zweimal eine doppelte, dreimal löscht sie.",
                            umgebung: umgebung) { teilnehmer, ende, abbrechen in
            BrueckenSpiel(name: teilnehmer[0].name, ende: ende, abbrechen: abbrechen)
        }.mitZiel("Verbinde alle Inseln mit Brücken, sodass jede Insel genau ihre Zahl an Brücken hat und alle zusammenhängen.").mitAnleitung(Self.anleitung))
    }
}

struct BrueckenSpiel: View {
    let name: String
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    @State private var spiel: Bruecken
    @State private var undo = RueckgaengigVerlauf<Bruecken>()
    @State private var gewaehlt: Int?
    @State private var start = Date()
    @State private var tag = false
    @State private var tipps = 0
    @State private var stufe = 1
    private static let stufen: [(groesse: Int, inseln: Int)] = [(7, 8), (7, 10), (9, 14), (11, 20)]
    private var variante: String { stufe == 1 ? "" : "\(stufe)" }

    init(name: String, ende: @escaping (SpielEnde) -> Void, abbrechen: @escaping () -> Void) {
        self.name = name; self.ende = ende; self.abbrechen = abbrechen
        var g = SystemRandomNumberGenerator()
        _spiel = State(initialValue: Bruecken.zufaellig(groesse: Self.stufen[1].groesse, inseln: Self.stufen[1].inseln, mit: &g))
    }

    var body: some View {
        VStack(spacing: Theme.kartenAbstand) {
            SpielKopf(mitte: "\(spiel.inseln.count) Inseln", linksAktion: abbrechen) {
                RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                    Button("Rückgängig", systemImage: "arrow.uturn.backward") { undo.zurueck(&spiel) }.disabled(!undo.kann)
                    Button("Neues Rätsel", systemImage: "shuffle") { tag = false; neu() }
                    Button("Tagesrätsel", systemImage: "calendar") { tag = true; neu() }
                    if let b = Bestleistung.lesen(Bestleistung.schluessel("bruecken", variante: variante, tages: tag)) { Text("Bestzeit: \(b) s") }
                    Picker("Schwierigkeit", selection: $stufe) {
                        ForEach(Array(["Leicht", "Mittel", "Schwer", "Experte"].enumerated()), id: \.offset) { i, n in
                            (Text(LocalizedStringKey(n)) + Text(Leiter.offen("bruecken", stufe: i) ? "" : " 🔒")).tag(i).disabled(!Leiter.offen("bruecken", stufe: i))
                        }
                    }
                    Button("Alle Brücken entfernen", systemImage: "trash") { var g = SystemRandomNumberGenerator(); _ = g; spiel = Bruecken(inseln: spiel.inseln, groesse: spiel.groesse, loesung: spiel.loesung); gewaehlt = nil }
                    Button("Spiel beenden", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
                }
            }
            SpielfeldKarte {
                GeometryReader { g in
                    let seite = min(g.size.width, g.size.height)
                    let u = seite / CGFloat(spiel.groesse)
                    let p = { (i: Insel) -> CGPoint in CGPoint(x: (CGFloat(i.x) + 0.5) * u, y: (CGFloat(i.y) + 0.5) * u) }
                    ZStack {
                        Canvas { ctx, _ in
                            for (paar, c) in spiel.bruecken where c > 0 {
                                let a = p(spiel.inseln[paar.a]), b = p(spiel.inseln[paar.b])
                                let waag = abs(a.y - b.y) < 1
                                for k in 0..<c {
                                    let off = c == 2 ? (k == 0 ? -4.0 : 4.0) : 0.0
                                    var w = Path()
                                    w.move(to: CGPoint(x: a.x + (waag ? 0 : off), y: a.y + (waag ? off : 0)))
                                    w.addLine(to: CGPoint(x: b.x + (waag ? 0 : off), y: b.y + (waag ? off : 0)))
                                    ctx.stroke(w, with: .color(.secondary), lineWidth: 3)
                                }
                            }
                        }
                        ForEach(spiel.inseln.indices, id: \.self) { i in
                            let isl = spiel.inseln[i], grad = spiel.grad(i)
                            Button { tippe(i) } label: {
                                Text("\(isl.n)").font(.system(size: u * 0.4, weight: .bold, design: Design.zahlDesign))   // design:spielinhalt (skaliert mit Feld/Karte/Würfel)
                                    .frame(width: u * 0.8, height: u * 0.8)
                                    .foregroundStyle(grad == isl.n ? Color.white : Color.primary)
                                    .background(grad == isl.n ? Color.appFlaeche : (grad > isl.n ? Color.red.opacity(0.35) : Color(.systemBackground)), in: Circle())
                                    .overlay(Circle().strokeBorder(gewaehlt == i ? Color.orange : Color.secondary, lineWidth: gewaehlt == i ? 4 : 2))   // design:spielinhalt (Markierung auf dem Spielmaterial)
                            }
                            .buttonStyle(.plain)
                            .position(p(isl))
                            .accessibilityLabel("Insel in Zeile \(isl.y + 1), Spalte \(isl.x + 1): \(grad) von \(isl.n) Brücken")
                            .accessibilityHint(Text(LocalizedStringKey(gewaehlt == nil ? "Doppeltippen, dann eine zweite Insel in gerader Linie antippen, um eine Brücke zu bauen." : "Doppeltippen baut oder ändert die Brücke von der gewählten Insel hierher.")))
                            .accessibilityAddTraits(gewaehlt == i ? .isSelected : [])
                            .accessibilityValue(Text(LocalizedStringKey(grad > isl.n ? "Zu viele Brücken" : (grad == isl.n ? "Fertig" : ""))))
                        }
                    }
                    .frame(width: seite, height: seite)
                }.aspectRatio(1, contentMode: .fit).frame(maxWidth: Theme.wideColumnWidth)
            }.padding(.horizontal, Theme.seitenRand)
            Text(gewaehlt == nil ? "Tippe eine Insel, dann eine Nachbarinsel." : "Tippe die Nachbarinsel für die Brücke.").font(.subheadline).foregroundStyle(.secondary)
            Button { if let p = spiel.tipp() {
                tipps += 1; gewaehlt = nil
                let a = spiel.inseln[p.a], b = spiel.inseln[p.b]
                ansage(String(localized: "Tipp: Brücke zwischen Zeile \(a.y + 1), Spalte \(a.x + 1) und Zeile \(b.y + 1), Spalte \(b.x + 1)"))
                pruefeGeloest()
            } } label: { Label("Tipp", systemImage: "lightbulb") }.nebenKnopf().dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            Spacer(minLength: 0)
        }
        .background(Color.seitenGrund)
        .weicheAnimation(bei: spiel)
        .spielHaptik(zug: spiel, erfolg: spiel.geloest, fehler: false).fortsetzbar("bruecken", $spiel, pruefen: { $0.istKonsistent })
        .onChange(of: stufe) { tag = false; neu() }
        .onAppear { let s = Leiter.begrenzt("bruecken", stufe: stufe, anzahl: 4); if s != stufe { stufe = s } }
        .rueckgaengigMerken(spiel, in: undo)
    }

    private func pruefeGeloest() {
        guard spiel.geloest else { return }
        let sek = max(1, Int(Date().timeIntervalSince(start)))
        Leiter.sieg("bruecken", stufe: stufe, mitTipp: tipps > 0, tages: tag)   // D4
        ende(SpielEnde(reihenfolge: [name], info: String(localized: "Gelöst in \(sek) Sekunden") + (tipps > 0 ? " · " + String(localized: "\(tipps) Tipps") : Bestleistung.zusatz("bruecken", variante: variante, tages: tag, wert: sek))))
    }

    private func tippe(_ i: Int) {
        guard let g = gewaehlt else { gewaehlt = i; return }
        if g == i { gewaehlt = nil; return }
        if spiel.umschalten(g, i) {
            gewaehlt = nil
            let a = spiel.inseln[g], b = spiel.inseln[i]
            let anzahl = spiel.bruecken.first { ($0.key.a == g && $0.key.b == i) || ($0.key.a == i && $0.key.b == g) }?.value ?? 0
            ansage(String(localized: "Zwischen Zeile \(a.y + 1), Spalte \(a.x + 1) und Zeile \(b.y + 1), Spalte \(b.x + 1): \(anzahl) Brücken"))
        } else {
            gewaehlt = i
            ansage(String(localized: "Insel gewählt. Jetzt die Nachbarinsel antippen."))
        }
        pruefeGeloest()
    }

    private func neu() {
        undo.leeren()
        if tag { var g = Tagesraetsel.generator(spiel: "bruecken"); spiel = Bruecken.zufaellig(groesse: Self.stufen[stufe].groesse, inseln: Self.stufen[stufe].inseln, mit: &g) }
        else { var g = SystemRandomNumberGenerator(); spiel = Bruecken.zufaellig(groesse: Self.stufen[stufe].groesse, inseln: Self.stufen[stufe].inseln, mit: &g) }
        gewaehlt = nil; start = Date(); tipps = 0
    }
}
#endif
