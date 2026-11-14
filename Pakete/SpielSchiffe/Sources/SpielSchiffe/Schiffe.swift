// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import SchiffeKern

@MainActor
public struct SchiffeModul: SpielModul {
    public init() {}
    public let id = "schiffeversenken"
    public let name = "Schiffe versenken"
    public let gattung = Gattung.brett
    public let farbe = AkzentFarbeWert.tuerkis
    public let symbol = "scope"
    public let spielerzahl = 1...1
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(SpielRahmen(id: id, name: name, untertitel: "Du gegen den Computer", farbe: farbe, spieler: 1...1,
                            regeln: "Jeder hat fünf Schiffe (Längen 5, 4, 3, 3, 2), die sich nicht berühren. Du beginnst und tippst ein Feld der gegnerischen Flotte an. Treffer: Du darfst noch einmal. Wasser: der Computer ist dran. Wer zuerst alle Schiffe des Gegners versenkt, gewinnt.",
                            einzelText: "Ein Spieler: Du gegen den Computer.",
                            umgebung: umgebung) { teilnehmer, ende, abbrechen in
            SchiffeSpiel(name: teilnehmer[0].name, ende: ende, abbrechen: abbrechen)
        }.mitZiel("Versenke als Erster alle fünf Schiffe des Gegners.").mitAnleitung([
            .figuren(symbol: "ferry", titel: "Flotte", text: "Jeder hat fünf Schiffe, die sich nicht berühren. Du siehst nur deine eigenen.", figuren: ["🚢", "🚢"], bewegt: nil),
            .figuren(symbol: "scope", titel: "Feld antippen", text: "Tippe ein Feld der gegnerischen Flotte an. Bei einem Treffer darfst du noch einmal, bei Wasser ist der andere dran.", figuren: ["🎯", "🌊"], bewegt: nil),
            .figuren(symbol: "flag.checkered", titel: "Versenken", text: "Wer zuerst alle Schiffe des Gegners versenkt, gewinnt.", figuren: ["💥", "🏆"], bewegt: nil),
        ]))
    }
}

/// Gespeicherte Partie: beide Flotten samt Beschuss, Computergedächtnis, wer dran ist.
struct SchiffeStand: Codable {
    var meine: Flotte
    var gegner: Flotte
    var computer: SchiffeComputer
    var begonnen: Bool
    var dran: Bool
}

struct SchiffeSpiel: View {
    let name: String
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    @State private var art = SchiffeArt.gespeichert
    @State private var stufe = ComputerStufe.gespeichert("schiffe", standard: .schwer)
    @State private var meine = Flotte(regeln: SchiffeArt.gespeichert.regeln)
    @State private var gegner = Flotte(regeln: SchiffeArt.gespeichert.regeln)
    @State private var computer = SchiffeComputer()
    @State private var zufall = SystemRandomNumberGenerator()
    @State private var begonnen = false
    @State private var dran = true
    @State private var tipp: Int?   // F4
    @State private var hinweis: LocalizedStringKey = "Verteile deine Flotte."

    var body: some View {
        VStack(spacing: Theme.kartenAbstand) {
            SpielKopf(mitte: begonnen ? (dran ? name : String(localized: "Computer")) : String(localized: "Aufstellen"), linksAktion: abbrechen) {
                RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                    ComputerStufePicker(spiel: "schiffe", stufe: $stufe)
                    Picker("Regeln", selection: $art) {
                        ForEach(SchiffeArt.allCases) { Text($0.titel).tag($0) }
                    }
                    .disabled(begonnen)   // nur beim Aufstellen
                    Button("Spiel beenden", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
                }
            }
            if begonnen {
                VStack(alignment: .leading, spacing: 6) {
                    SectionLabel("Gegnerische Flotte")
                    brett(gegner, zeigeSchiffe: false, tippbar: dran)
                }.card()
                VStack(alignment: .leading, spacing: 6) {
                    SectionLabel("Deine Flotte")
                    brett(meine, zeigeSchiffe: true, tippbar: false).frame(maxWidth: 280).frame(maxWidth: .infinity)
                }.card()
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    SectionLabel("Deine Flotte")
                    brett(meine, zeigeSchiffe: true, tippbar: false)
                }.card()
                Button("Neu verteilen", systemImage: "shuffle") { meine.zufaellig(mit: &zufall) }.buttonStyle(ZweitKnopfStil())
                Button("Schlacht beginnen") { starten() }.buttonStyle(HauptKnopfStil())
            }
            HStack(spacing: Design.Abstand.m) {
                Text(hinweis).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                if begonnen, dran {
                    Button { var k = SchiffeComputer(); tipp = k.wahl(gegen: gegner, mit: &zufall); if let t = tipp { UIAccessibility.post(notification: .announcement, argument: String(localized: "Tipp: Zeile \(t / 10 + 1), Spalte \(t % 10 + 1).")) } } label: { Label("Tipp", systemImage: "lightbulb") }.nebenKnopf().dynamicTypeSize(...DynamicTypeSize.xxxLarge)   // F4: Zielwahl des Computers
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Theme.seitenRand)
        .background(Color.seitenGrund)
        .fortsetzbar("schiffe", Binding(
            get: { SchiffeStand(meine: meine, gegner: gegner, computer: computer, begonnen: begonnen, dran: dran) },
            set: { s in
                meine = s.meine; gegner = s.gegner; computer = s.computer; begonnen = s.begonnen; dran = s.dran
                if begonnen { hinweis = dran ? "Du bist dran." : "Der Computer schießt …"; if !dran { computerZug() } }
            }))
        .weicheAnimation(bei: [meine.beschossen.count, gegner.beschossen.count, begonnen ? 1 : 0])
        .spielHaptik(zug: [meine.beschossen.count, gegner.beschossen.count, begonnen ? 1 : 0], erfolg: begonnen && (gegner.versenktAlle || meine.versenktAlle), fehler: false)
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .onChange(of: art) { _, neu in
            neu.sichern()
            if !begonnen { meine = Flotte(regeln: neu.regeln); meine.zufaellig(mit: &zufall) }
        }
        .onAppear { if !SpielStand.vorhanden("schiffe") { meine.zufaellig(mit: &zufall) } }
    }

    private func brett(_ f: Flotte, zeigeSchiffe: Bool, tippbar: Bool) -> some View {
        let versenkt = Set(f.versenkteSchiffe.flatMap { $0 })
        return Grid(horizontalSpacing: 1.5, verticalSpacing: 1.5) {
            ForEach(0..<f.n, id: \.self) { z in
                GridRow {
                    ForEach(0..<f.n, id: \.self) { s in
                        let i = z * f.n + s
                        let beschossen = f.beschossen.contains(i), schiff = f.treffer(i)
                        Button { tipp = nil; schiesse(i) } label: {
                            ZStack {
                                Rectangle().fill(beschossen ? (schiff ? Color.red.opacity(versenkt.contains(i) ? 0.9 : 0.6) : Color.secondary.opacity(0.18))
                                                 : (zeigeSchiffe && schiff ? Color.appFlaeche.opacity(0.7) : Color.appFlaeche.opacity(0.12)))
                                if beschossen { Image(systemName: schiff ? "flame.fill" : "circle.fill").font(.system(size: 9)).foregroundStyle(schiff ? .white : .secondary) }   // design:spielinhalt (Spielmaterial im Feld)
                            }
                            .aspectRatio(1, contentMode: .fit).frame(maxWidth: Theme.wideColumnWidth)
                        }
                        .buttonStyle(.plain)
                        .overlay(Rectangle().strokeBorder(Color.yellow, lineWidth: 3).opacity(tippbar && tipp == i ? 1 : 0))
                        .disabled(!tippbar || beschossen)
                        .accessibilityValue(tippbar && tipp == i ? Text("Tipp") : Text(verbatim: ""))
                        .accessibilityLabel("Zeile \(z + 1), Spalte \(s + 1)\(beschossen ? (schiff ? ", Treffer" : ", Wasser") : "")")
                    }
                }
            }
        }
    }

    private func starten() {
        gegner = Flotte(regeln: meine.regeln); gegner.zufaellig(mit: &zufall)
        computer = SchiffeComputer(); begonnen = true; dran = true; hinweis = "Tippe ein Feld der gegnerischen Flotte."
    }

    private func schiesse(_ i: Int) {
        guard dran, let treffer = gegner.schiesse(i) else { return }
        if gegner.versenktAlle { fertig(gewonnen: true); return }
        if treffer, gegner.regeln.extraschuss { hinweis = "Treffer! Du darfst noch einmal."; return }
        dran = false; hinweis = treffer ? "Treffer! Der Computer schießt …" : "Wasser. Der Computer schießt …"
        computerZug()
    }

    private func computerZug() {
        Task {
            try? await Task.sleep(for: .milliseconds(700))
            let i = computer.wahl(gegen: meine, stufe: stufe.rawValue, mit: &zufall)
            let treffer = meine.schiesse(i) ?? false
            if meine.versenktAlle { fertig(gewonnen: false); return }
            if treffer, meine.regeln.extraschuss { hinweis = "Der Computer hat getroffen und schießt noch einmal …"; computerZug() }
            else { dran = true; hinweis = "Du bist dran." }
        }
    }

    private func fertig(gewonnen: Bool) {
        ende(SpielEnde(reihenfolge: gewonnen ? [name, String(localized: "Computer")] : [String(localized: "Computer"), name],
                       info: gewonnen ? String(localized: "Alle Schiffe versenkt!") : String(localized: "Deine Flotte wurde versenkt.")))
    }
}

/// Wählbare Regelart im „Mehr“-Menü (gilt beim Aufstellen, wird gemerkt).
enum SchiffeArt: String, CaseIterable, Identifiable {
    case klassisch, klein, gross, dicht, abwechselnd
    var id: String { rawValue }
    var titel: LocalizedStringKey {
        switch self {
        case .klassisch: "Klassisch (10 × 10)"; case .klein: "Klein (8 × 8)"; case .gross: "Groß (12 × 12)"
        case .dicht: "Schiffe dürfen sich berühren"; case .abwechselnd: "Ohne Extraschuss nach Treffer"
        }
    }
    var regeln: FlottenRegeln {
        switch self { case .klassisch: .klassisch; case .klein: .klein; case .gross: .gross; case .dicht: .dicht; case .abwechselnd: .abwechselnd }
    }
    static var gespeichert: SchiffeArt { SchiffeArt(rawValue: UserDefaults.standard.string(forKey: "partie.regeln.schiffe") ?? "") ?? .klassisch }
    func sichern() { UserDefaults.standard.set(rawValue, forKey: "partie.regeln.schiffe") }
}
#endif
