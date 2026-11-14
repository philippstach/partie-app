// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import SpielHilfen
import BackgammonKern

@MainActor
public struct BackgammonModul: SpielModul {
    /// Standard-Backgammon oder eine Variante (z. B. `BackgammonModul(id: "nardy", name: "Nardy", regeln: .nardy, regelText: …)`).
    public init(id: String = "backgammon", name: String = "Backgammon", regeln: BgRegeln = .standard, regelText: LocalizedStringKey? = nil, symbol: String = "circle.grid.cross.fill") {
        self.id = id; self.name = name; self.bgRegeln = regeln; self.regelText = regelText; self.symbol = symbol
    }
    public let id: String
    public let name: String
    let bgRegeln: BgRegeln
    let regelText: LocalizedStringKey?
    public let symbol: String
    public let gattung = Gattung.wuerfel
    public let farbe = AkzentFarbeWert.indigo
    public let spielerzahl = 1...2
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(SpielRahmen(id: id, name: name, untertitel: "Würfeln, ziehen, heimbringen", farbe: farbe, spieler: 2...2, computerErlaubt: true,
                            wuerfelWahl: true, regeln: regelText ?? "Jeder hat 15 Steine. Weiß zieht von oben rechts im Uhrzeigersinn nach unten rechts (Heimfeld), Schwarz umgekehrt. Du würfelst zwei Würfel und ziehst Steine um die Augenzahlen; bei einem Pasch viermal. Ein Punkt mit zwei oder mehr gegnerischen Steinen ist gesperrt, ein einzelner gegnerischer Stein wird geschlagen und muss über die Bar wieder einsteigen, bevor sonst gezogen werden darf. Sind alle deine Steine im Heimfeld, darfst du sie abtragen. Wer zuerst alle abgetragen hat, gewinnt. Du musst möglichst beide Würfel spielen.",
                            umgebung: umgebung) { teilnehmer, ende, abbrechen in
            BackgammonSpiel(regeln: bgRegeln, teilnehmer: teilnehmer, ende: ende, abbrechen: abbrechen, quelle: WuerfelWahl.quelle(id, vorgabe: umgebung.wuerfelQuelle), spielID: id)
        }.mitZiel("Bringe alle deine Steine ins Heimfeld und trage sie als Erster ab.").mitAnleitung([
            .figuren(symbol: "dice", titel: "Würfeln und ziehen", text: "Du würfelst zwei Würfel und ziehst Steine um die Augenzahlen, bei einem Pasch viermal.", figuren: ["🎲", "🎲", "⚪️"], bewegt: 2),
            .figuren(symbol: "lock", titel: "Sperren und schlagen", text: "Zwei gegnerische Steine sperren einen Punkt, ein einzelner wird geschlagen und muss über die Bar neu einsteigen.", figuren: ["⚪️", "⚫️", "⚫️"], bewegt: nil),
            .figuren(symbol: "flag.checkered", titel: "Abtragen", text: "Sind alle Steine im Heimfeld, trägst du sie ab. Wer zuerst alle abgetragen hat, gewinnt. Varianten zeigt die Spielauswahl.", figuren: ["⚪️", "🏁"], bewegt: nil),
        ]))
    }
}

public struct BackgammonSpiel: View {
    let regeln: BgRegeln
    let teilnehmer: [SpielTeilnehmer]
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    let quelle: WuerfelQuelle
    let spielID: String
    @State private var eingabe: Int?
    @State private var spiel: Backgammon
    @State private var zufall = SystemRandomNumberGenerator()
    @State private var gewaehlt: Int?          // 0–23 oder 24 = Bar
    @State private var meldung: String?
    @State private var denkt = false
    @State private var verlauf: [Backgammon] = []
    @State private var tipp: BgZug?
    @State private var stufe = ComputerStufe.gespeichert("backgammon")
    private var staerke: BackgammonStaerke { switch stufe { case .leicht: .leicht; case .mittel: .mittel; case .schwer: .schwer } }

    private func name(_ s: Int) -> String { teilnehmer[s - 1].name }
    private var computerDran: Bool { teilnehmer[spiel.dran - 1].computer }
    private var ziele: Set<Int> { gewaehlt.map { g in Set(spiel.zuege.filter { $0.von == g }.map(\.nach)) } ?? [] }
    private var quellen: Set<Int> { Set(spiel.zuege.map(\.von)) }

    init(regeln: BgRegeln = .standard, teilnehmer: [SpielTeilnehmer], ende: @escaping (SpielEnde) -> Void, abbrechen: @escaping () -> Void, quelle: WuerfelQuelle = .app, spielID: String = "backgammon") {
        self.spielID = spielID
        self.regeln = regeln; self.teilnehmer = teilnehmer; self.ende = ende; self.abbrechen = abbrechen; self.quelle = quelle
        _spiel = State(initialValue: Backgammon(regeln: regeln))
    }

    public var body: some View {
        VStack(spacing: Theme.kartenAbstand) {
            SpielKopf(mitte: name(spiel.dran), linksAktion: abbrechen) {
                RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                    if teilnehmer.contains(where: \.computer) { ComputerStufePicker(spiel: "backgammon", stufe: $stufe) }
                    Button("Spiel beenden", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
                }
            }
            SpielerLeiste(eintraege: [1, 2].map { .init(id: "\($0)", name: name($0), farbe: $0 == 1 ? .white : .black, wert: "\(spiel.pips($0))") }, aktiv: "\(spiel.dran)").padding(.horizontal, Theme.seitenRand)
            SpielfeldKarte {
                VStack(spacing: Design.Abstand.xs) {
                    reihe((12...23).map { $0 }, oben: true)
                    mitte
                    reihe((0...11).reversed().map { $0 }, oben: false)
                }
            }.padding(.horizontal, Theme.seitenRand)
            if !computerDran, spiel.gewinner == nil, !spiel.wuerfel.isEmpty {
                ZugKnoepfe(kannZurueck: !verlauf.isEmpty, tippMoeglich: !spiel.zuege.isEmpty, zurueck: zurueck, tipp: { tipp = BackgammonComputer.zugfolge(spiel).first })
            }
            if let m = meldung { Text(m).font(.subheadline.weight(.semibold)).multilineTextAlignment(.center) }
            Text("Zahlen unter den Namen: Restaugen bis zum Ende (Pips)").font(.caption2).foregroundStyle(.tertiary)
            Spacer(minLength: 0)
            aktion.padding(.horizontal, Theme.seitenRand).padding(.bottom, 8)
        }
        .background(Color.seitenGrund)
        .fortsetzbar(spielID, $spiel)
        .weicheAnimation(bei: spiel)
        .spielHaptik(zug: spiel, erfolg: spiel.gewinner != nil)
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .echteWuerfelEingabe(anzahl: $eingabe) { augen in spiel.setzeWurf(augen[0], augen[1]); meldung = nil; pruefeKeinZug() }
        .onAppear { computerWuerfelt() }
    }

    private var mitte: some View {
        HStack(spacing: 14) {
            ForEach([1, 2], id: \.self) { s in
                Button { if spiel.dran == s, spiel.bar[s] > 0, !computerDran { gewaehlt = 24 } } label: {
                    Text("Bar \(spiel.bar[s])").font(.caption.weight(.bold)).lineLimit(1).minimumScaleFactor(0.7).fixedSize().padding(.horizontal, 10).padding(.vertical, 6)
                        .background(gewaehlt == 24 && spiel.dran == s ? Color.appFlaeche.opacity(0.4) : Color(.tertiarySystemFill), in: Capsule())
                        .foregroundStyle(s == 1 ? Color.primary : Color.secondary)
                }.buttonStyle(.plain)
                    .accessibilityLabel(Text("Bar von \(name(s)): \(spiel.bar[s])"))
                    .accessibilityAddTraits(gewaehlt == 24 && spiel.dran == s ? .isSelected : [])
            }
            Spacer()
            ForEach(Array(spiel.wuerfel.enumerated()), id: \.offset) { _, w in WuerfelBild(w).font(spiel.wuerfel.count > 2 ? .title2 : .title).foregroundStyle(Color.appFlaeche).accessibilityLabel(Text("Würfel \(w)")) }
            Spacer()
            Text("Raus \(spiel.draussen[1]) / \(spiel.draussen[2])").font(.caption.weight(.semibold)).foregroundStyle(.secondary).lineLimit(1).minimumScaleFactor(0.7).fixedSize()
        }.frame(minHeight: 40).padding(.horizontal, 6)
    }

    private func reihe(_ idx: [Int], oben: Bool) -> some View {
        HStack(spacing: 2) { ForEach(idx, id: \.self) { punkt($0, oben: oben) } }.frame(height: 130)
    }

    private func punkt(_ i: Int, oben: Bool) -> some View {
        let n = spiel.punkte[i], anzahl = abs(n)
        let ziel = ziele.contains(i), quelle = quellen.contains(i) && !computerDran && spiel.wuerfel.count > 0
        return Button { tippe(i) } label: {
            ZStack(alignment: oben ? .top : .bottom) {
                Triangle(spitzeOben: !oben).fill(i % 2 == 0 ? Color.appFlaeche.opacity(0.35) : Color.secondary.opacity(0.3))
                VStack(spacing: 1) {
                    ForEach(0..<min(anzahl, 5), id: \.self) { k in
                        Circle().fill(n > 0 ? Color.white : Color(white: 0.12)).overlay(Circle().strokeBorder(Color.secondary.opacity(0.6)))
                            .overlay(k == 4 && anzahl > 5 ? Text("\(anzahl)").font(.caption2.weight(.bold)).foregroundStyle(n > 0 ? .black : .white) : nil)
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
                .frame(maxHeight: .infinity, alignment: oben ? .top : .bottom)
                if spiel.festgesetzt[i] != 0 {
                    Image(systemName: "pin.fill").font(.caption2).foregroundStyle(spiel.festgesetzt[i] == 1 ? Color.primary : Color.secondary)
                }
                if let t = tipp, t.von == i || t.nach == i { Rectangle().strokeBorder(Color.yellow, lineWidth: 4) }
                if ziel { Rectangle().strokeBorder(Color.orange, lineWidth: 3) }   // design:spielinhalt (Markierung auf dem Spielmaterial)
                else if gewaehlt == i { Rectangle().strokeBorder(Color.primary, lineWidth: 3) }
                else if quelle { Rectangle().strokeBorder(Color.appFlaeche.opacity(0.6), lineWidth: 1.5) }   // design:spielinhalt (Markierung auf dem Spielmaterial)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(n == 0 ? Text("Punkt \(i + 1), leer") : (n > 0 ? Text("Punkt \(i + 1), \(anzahl) weiße Steine") : Text("Punkt \(i + 1), \(anzahl) schwarze Steine")))
        .accessibilityValue(ziel ? Text("mögliches Ziel") : (quelle ? Text("kann ziehen") : Text(verbatim: "")))
        .accessibilityAddTraits(gewaehlt == i ? .isSelected : [])
    }

    @ViewBuilder private var aktion: some View {
        if let w = spiel.gewinner {
            Button("Ergebnis") { ende(SpielEnde(reihenfolge: [name(w), name(3 - w)], punkte: [15, spiel.draussen[3 - w]].map(String.init), info: String(localized: "\(name(w)) gewinnt"))) }.buttonStyle(HauptKnopfStil())
        } else if computerDran {
            Text("\(name(spiel.dran)) spielt …").foregroundStyle(.secondary)
        } else if spiel.paschWahl {
            VStack(spacing: 6) {
                Text("Acey-Deucey! Wähle einen Pasch.").font(.subheadline.weight(.semibold))
                HStack(spacing: Design.Abstand.s) {
                    ForEach(1...6, id: \.self) { n in
                        Button { spiel.waehlePasch(n); pruefeKeinZug() } label: { WuerfelBild(n).font(.title) }.nebenKnopf().dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                    }
                }
            }
        } else if spiel.wuerfel.isEmpty {
            Button("Würfeln") { if quelle == .echt { eingabe = 2 } else { spiel.wuerfeln(mit: &zufall); meldung = nil; pruefeKeinZug() } }.beimSchuetteln(aktiv: quelle == .app) { spiel.wuerfeln(mit: &zufall); meldung = nil; pruefeKeinZug() }.buttonStyle(HauptKnopfStil())
        } else if ziele.contains(-1) {
            Button("Abtragen") { zieh(nach: -1) }.buttonStyle(HauptKnopfStil())
        } else { Text("Wähle einen Stein und dann das Ziel.").font(.subheadline).foregroundStyle(.secondary) }
    }

    private func tippe(_ i: Int) {
        guard !computerDran, spiel.gewinner == nil, !spiel.wuerfel.isEmpty else { return }
        if gewaehlt != nil, ziele.contains(i) { zieh(nach: i); return }
        gewaehlt = quellen.contains(i) && spiel.punkte[i] * (spiel.dran == 1 ? 1 : -1) > 0 ? i : nil
    }

    private func zieh(nach: Int) {
        guard let g = gewaehlt else { return }
        // Bei mehreren Würfeln mit gleichem Ziel den kleinsten passenden nehmen
        let kandidaten = spiel.zuege.filter { $0.von == g && $0.nach == nach }.sorted { $0.wuerfel < $1.wuerfel }
        guard let z = kandidaten.first else { return }
        let vorher = spiel
        guard spiel.ziehe(z) else { return }
        if spiel.dran == vorher.dran, !spiel.wuerfel.isEmpty { verlauf.append(vorher) } else { verlauf = [] }
        tipp = nil; gewaehlt = nil
        nachZug()
    }

    /// Rückgängig gilt nur innerhalb des laufenden Wurfs – nie über einen neuen Wurf hinweg.
    private func zurueck() {
        tipp = nil; gewaehlt = nil
        if let l = verlauf.popLast() { spiel = l }
    }

    private func nachZug() {
        if spiel.gewinner != nil { return }
        if spiel.wuerfel.isEmpty { computerWuerfelt() } else { pruefeKeinZug() }
    }

    private func pruefeKeinZug() {
        if !spiel.wuerfel.isEmpty, spiel.zuege.isEmpty {
            meldung = "\(name(spiel.dran)) kann nicht ziehen."
            Task { try? await Task.sleep(for: .milliseconds(1100)); spiel.aussetzen(); gewaehlt = nil; computerWuerfelt() }
        }
    }

    private func computerWuerfelt() {
        guard spiel.gewinner == nil, computerDran, spiel.wuerfel.isEmpty, !denkt else { return }
        denkt = true
        Task {
            try? await Task.sleep(for: .milliseconds(700))
            spiel.wuerfeln(mit: &zufall)
            let folge = BackgammonComputer.zugfolge(spiel, fehler: staerke.fehler, mit: &zufall)
            if folge.isEmpty { meldung = "\(name(spiel.dran)) kann nicht ziehen."; try? await Task.sleep(for: .milliseconds(900)); spiel.aussetzen() }
            else { for z in folge { try? await Task.sleep(for: .milliseconds(550)); spiel.ziehe(z) } }
            if spiel.paschWahl {
                // Acey-Deucey: der Computer wählt den höchsten Pasch und spielt ihn
                try? await Task.sleep(for: .milliseconds(600)); spiel.waehlePasch(6)
                for z in BackgammonComputer.zugfolge(spiel) { try? await Task.sleep(for: .milliseconds(550)); spiel.ziehe(z) }
            }
            denkt = false
            if spiel.gewinner == nil { if spiel.wuerfel.isEmpty == false { spiel.aussetzen() }; meldung = nil; computerWuerfelt() }
        }
    }
}

private struct Triangle: Shape {
    let spitzeOben: Bool
    func path(in r: CGRect) -> Path {
        var p = Path()
        if spitzeOben { p.move(to: CGPoint(x: r.minX, y: r.maxY)); p.addLine(to: CGPoint(x: r.midX, y: r.minY)); p.addLine(to: CGPoint(x: r.maxX, y: r.maxY)) }
        else { p.move(to: CGPoint(x: r.minX, y: r.minY)); p.addLine(to: CGPoint(x: r.midX, y: r.maxY)); p.addLine(to: CGPoint(x: r.maxX, y: r.minY)) }
        p.closeSubpath(); return p
    }
}
#endif
