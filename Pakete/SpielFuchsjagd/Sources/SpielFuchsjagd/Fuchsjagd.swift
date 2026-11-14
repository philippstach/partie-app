// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import SpielHilfen
import FuchsjagdKern

/// Fuchsjagd : die eine Fassung des Spiels in der Sammlung. Der Kern ist geteilt, Spielstände liegen unter der eigenen ID.
@MainActor
public struct FuchsjagdModul: SpielModul {
    public init() {}
    public let id = "fuchsjagd-neu"
    public let name = "Fuchsjagd"
    public let gattung = Gattung.brett
    public let farbe = AkzentFarbeWert.orange
    public let symbol = "pawprint.fill"
    public let spielerzahl = 1...2
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(SpielRahmen(id: id, name: name, untertitel: "Ein Fuchs gegen die Gänse", farbe: farbe, spieler: 1...2, computerErlaubt: true,
                            regeln: "Auf dem Kreuzbrett steht ein Fuchs gegen 13 Gänse (oder 17 Gänse, oder zwei Füchse gegen 20 Gänse). Die Gänse beginnen und ziehen immer ein Feld nach vorn (nach oben) oder zur Seite, nie zurück. Der Fuchs zieht ein Feld in alle vier Richtungen (bei 17 Gänsen auch schräg) oder springt über eine Gans auf das freie Feld dahinter und frisst sie. Die Gänse gewinnen, wenn sie den Fuchs so einkreisen, dass er sich nicht mehr bewegen kann. Der Fuchs gewinnt, wenn zu wenige Gänse übrig sind oder nach 80 Zügen jeder Seite noch niemand eingesperrt ist (wählbar: dann unentschieden). Zwei Menschen spielen zwei Partien mit Seitentausch; gewertet werden die Gänse. Tippe eine Figur an, dann ein markiertes Zielfeld.",
                            einzelText: "Du gegen den Computer – wähle deine Seite.",
                            umgebung: umgebung) { teilnehmer, ende, abbrechen in
            FuchsjagdSpielNeu(teilnehmer: teilnehmer, ende: ende, abbrechen: abbrechen)
        }.mitZiel("Gänse: Kreise den Fuchs ein, bis er nicht mehr ziehen kann. Fuchs: Friss die Gänse, bis zu wenige übrig sind.").mitAnleitung([
            .figuren(symbol: "hare", titel: "Fuchs gegen Gänse", text: "Ein Fuchs spielt gegen die Gänse. Die Gänse beginnen und ziehen ein Feld nach vorn oder zur Seite.", figuren: ["🦊", "🪿", "🪿"], bewegt: nil),
            .figuren(symbol: "arrow.up.right", titel: "Der Fuchs springt", text: "Der Fuchs zieht in vier Richtungen oder springt über eine Gans und frisst sie.", figuren: ["🦊", "🪿", "▫️"], bewegt: 0),
            .figuren(symbol: "flag.checkered", titel: "Wer gewinnt", text: "Die Gänse gewinnen, wenn der Fuchs sich nicht mehr bewegen kann. Bleiben zu wenige Gänse, gewinnt der Fuchs.", figuren: ["🪿", "🪿", "🏆"], bewegt: nil),
        ]))
    }
}

/// Gespeicherter Stand (Fortsetzen): Partie, Seite des ersten Teilnehmers, Match.
struct FuchsStandNeu: Codable, Equatable {
    var spiel: Fuchsjagd
    var meineSeite: Fuchsjagd.Seite
    var match: FuchsMatch?
}

struct FuchsjagdSpielNeu: View {
    let teilnehmer: [SpielTeilnehmer]
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    static let id = "fuchsjagd-neu"
    @Environment(\.dynamicTypeSize) private var schrift
    @State private var meineSeite = Fuchsjagd.Seite.gaense
    @State private var stufe = ComputerStufe.gespeichert("fuchsjagd-neu")
    @AppStorage("partie.regeln.fuchsjagd-neu.zwang") private var fuchsZwang = false
    @AppStorage("partie.regeln.fuchsjagd-neu.diagonal") private var gaenseDiagonal = false
    @AppStorage("partie.regeln.fuchsjagd-neu.remis") private var remisBeiLimit = false
    @AppStorage("partie.regeln.fuchsjagd-neu.match") private var matchAn = true
    @AppStorage("partie.regeln.fuchsjagd-neu.variante") private var varianteRoh = FuchsVariante.dreizehn.rawValue
    @State private var stand: FuchsStandNeu?
    @State private var gewaehlt: Pos?
    @State private var zufall = SystemRandomNumberGenerator()
    @State private var gebucht = false
    @State private var tick = 0
    @State private var verlauf: [Fuchsjagd] = []
    @State private var tipp: FuchsZug?
    @State private var tippRechnet = false

    private var variante: FuchsVariante { FuchsVariante(rawValue: varianteRoh) ?? .dreizehn }
    private var zweiMenschen: Bool { teilnehmer.count > 1 && !teilnehmer[0].computer && !teilnehmer[1].computer }
    private var mitComputer: Bool { teilnehmer.count < 2 || teilnehmer[0].computer || teilnehmer[1].computer }
    private var grosseSchrift: Bool { schrift.isAccessibilitySize }
    private var regelnWahl: FuchsRegeln { FuchsRegeln(fuchsMussSchlagen: fuchsZwang, gaenseDiagonal: gaenseDiagonal, variante: variante, remisBeiLimit: remisBeiLimit) }

    // MARK: Namen

    private func nameFuer(_ seite: Fuchsjagd.Seite, _ st: FuchsStandNeu) -> String {
        if teilnehmer.count > 1 { return seite == st.meineSeite ? teilnehmer[0].name : teilnehmer[1].name }
        return seite == st.meineSeite ? teilnehmer[0].name : String(localized: "Computer")
    }
    private func istComputer(_ seite: Fuchsjagd.Seite, _ st: FuchsStandNeu) -> Bool {
        teilnehmer.count > 1 ? (seite == st.meineSeite ? teilnehmer[0].computer : teilnehmer[1].computer) : seite != st.meineSeite
    }

    var body: some View {
        Group { if let st = stand { spielAnsicht(st) } else { auswahl } }
            .background(Color.seitenGrund)
            .fortsetzbar(Self.id, $stand)
            .weicheAnimation(bei: stand?.spiel)
            .spielHaptik(zug: stand?.spiel, erfolg: stand?.spiel.sieger != nil)
            .dynamicTypeSize(...DynamicTypeSize.accessibility3)
    }

    // MARK: Seitenwahl

    private var auswahl: some View {
        GeometryReader { geo in
            let quer = geo.size.width > geo.size.height
            let vorschau = quer ? min(geo.size.height - 150, geo.size.width * 0.45) : min(geo.size.width - 2 * Theme.seitenRand, geo.size.height * 0.4)
            VStack(spacing: Theme.kartenAbstand) {
                SpielKopf(mitte: "Fuchsjagd", linksAktion: abbrechen) { Color.clear.frame(width: 44, height: 44) }
                if quer {
                    HStack(alignment: .top, spacing: Theme.kartenAbstand) {
                        brettVorschau(vorschau)
                        ScrollView { optionen }
                    }.padding(.horizontal, Theme.seitenRand)
                } else {
                    brettVorschau(max(vorschau, 160))
                    ScrollView { optionen.padding(.horizontal, Theme.seitenRand) }
                }
                Button("Los geht’s", action: starten)
                    .buttonStyle(HauptKnopfStil()).padding(.horizontal, Theme.seitenRand).padding(.bottom, 8)
            }
        }
    }

    private func brettVorschau(_ seite: CGFloat) -> some View {
        FuchsBrettNeu(spiel: Fuchsjagd(regeln: regelnWahl), aktiv: false, seite: max(seite, 120))
            .padding(Theme.spielfeldRand)
            .background(Color.appFlaeche.opacity(0.08), in: .rect(cornerRadius: Theme.cardRadius))
            .accessibilityHidden(true)
    }

    private var optionen: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(teilnehmer.count > 1 ? "\(teilnehmer[0].name) spielt" : "Du spielst").font(.headline)
            Picker("Seite", selection: $meineSeite) { Text("Gänse (beginnen)").tag(Fuchsjagd.Seite.gaense); Text("Fuchs").tag(Fuchsjagd.Seite.fuchs) }.pickerStyle(.segmented)
            Picker("Aufstellung", selection: $varianteRoh) {
                ForEach(FuchsVariante.allCases, id: \.rawValue) { Text(FuchsText.variante($0)).tag($0.rawValue) }
            }.pickerStyle(.segmented)
            if mitComputer { ComputerStufePicker(spiel: Self.id, stufe: $stufe).pickerStyle(.segmented) }
            if zweiMenschen { Toggle("Zwei Partien mit Seitentausch", isOn: $matchAn) }
            Toggle("Fuchs muss springen, wenn er kann", isOn: $fuchsZwang)
            Toggle("Gänse dürfen auch schräg ziehen", isOn: $gaenseDiagonal)
            Toggle("Nach 80 Zügen unentschieden", isOn: $remisBeiLimit)
        }.padding(Theme.innen).card()
    }

    private func starten() {
        stand = FuchsStandNeu(spiel: Fuchsjagd(regeln: regelnWahl), meineSeite: meineSeite, match: zweiMenschen && matchAn ? FuchsMatch(seiteErster: meineSeite) : nil)
        verlauf = []; tipp = nil; gebucht = false; gewaehlt = nil; tick += 1
    }

    // MARK: Spielbildschirm

    private func spielAnsicht(_ st: FuchsStandNeu) -> some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                if w > h { quer(st, w, h) } else if w >= 700 { iPadHoch(st, w, h) } else { handy(st, w, h) }
                if st.spiel.ausgang != nil, !gebucht {
                    Color.black.opacity(0.25).ignoresSafeArea().accessibilityHidden(true)
                    endeKarte(st)
                }
            }
        }
        .task(id: "\(tick)-\(st.spiel.zuege)") { await computerZug() }
        .onChange(of: st.spiel.ausgang) { _, a in
            if let a { UIAccessibility.post(notification: .announcement, argument: FuchsText.ausgang(a, regeln: st.spiel.regeln)) }
        }
    }

    private func kopf(_ st: FuchsStandNeu) -> some View {
        let dran = nameFuer(st.spiel.amZug, st)
        return SpielKopf(mitte: st.spiel.ausgang == nil ? String(localized: "\(dran) ist dran") : String(localized: "Spielende"), linksAktion: abbrechen) {
            RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                Button("Neu beginnen", systemImage: "arrow.counterclockwise") { stand = nil }
                Button("Spiel beenden", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
            }
        }
    }

    private func leiste(_ st: FuchsStandNeu) -> some View {
        let s = st.spiel
        return SpielerLeiste(eintraege: [Fuchsjagd.Seite.gaense, .fuchs].map { seite in
            .init(id: "\(seite.rawValue)", name: nameFuer(seite, st), farbe: Spieler.farbe(seite == .gaense ? 0 : 1),
                  wert: seite == .gaense ? String(localized: "Gänse · \(s.gaense.count)") : String(localized: "Fuchs · \(s.geschlagen) gefressen"))
        }, aktiv: s.ausgang == nil ? "\(s.amZug.rawValue)" : nil)
        .padding(.horizontal, Theme.seitenRand)
    }

    private func brett(_ st: FuchsStandNeu, _ seite: CGFloat) -> some View {
        FuchsBrettNeu(spiel: st.spiel, gewaehlt: gewaehlt, tipp: tipp, aktiv: st.spiel.ausgang == nil && !istComputer(st.spiel.amZug, st), aktion: tippe, seite: seite)
            .padding(Theme.spielfeldRand)
            .background(Color.appFlaeche.opacity(0.08), in: .rect(cornerRadius: Theme.cardRadius))
    }

    private func knoepfe(_ st: FuchsStandNeu) -> some View {
        ZugKnoepfe(kannZurueck: !verlauf.isEmpty && st.spiel.ausgang == nil, tippMoeglich: st.spiel.ausgang == nil && !istComputer(st.spiel.amZug, st), rechnet: tippRechnet, zurueck: zurueck, tipp: holeTipp)
            .padding(.bottom, 4)
    }

    /// Zugzähler und, wenn der Fuchs springen kann, der Sprung-Hinweis.
    private func hinweis(_ st: FuchsStandNeu) -> some View {
        let s = st.spiel
        let sprung = s.ausgang == nil && s.amZug == .fuchs && !istComputer(.fuchs, st) && s.zuegeDes(.fuchs).contains { $0.schlag != nil }
        return Group {
            if sprung { Text(s.regeln.fuchsMussSchlagen ? "Sprung ist Pflicht" : "Sprung möglich").font(.footnote.weight(.semibold)).foregroundStyle(Color.accentText) }
            else { Text("Zug \(min(s.zuege / 2 + 1, s.zuglimit / 2)) von \(s.zuglimit / 2)").font(.footnote).foregroundStyle(.secondary) }
        }.frame(maxWidth: .infinity)
    }

    private func handy(_ st: FuchsStandNeu, _ w: CGFloat, _ h: CGFloat) -> some View {
        let s = st.spiel, rand = Theme.seitenRand
        let platzMax: CGFloat = h < 700 ? 24 : 30
        let ablage = FuchsAblage.hoehe(s, breite: w - 2 * rand, platzMax: platzMax)
        let fest = 44 + (grosseSchrift ? 120 : 66) + ablage + 44 + 20 + 12 * 6
        let seite = max(180, min(w - 2 * rand - 2 * Theme.spielfeldRand, h - fest - 2 * Theme.spielfeldRand))
        let rest = h - fest - seite
        let zeilen = grosseSchrift ? 0 : min(9, Int((rest - 56) / 22))
        return VStack(spacing: Design.Abstand.m) {
            kopf(st); leiste(st)
            brett(st, seite)
            FuchsAblage(spiel: s, breite: w - 2 * rand, hoeheMax: platzMax).padding(.horizontal, rand)
            hinweis(st)
            if zeilen >= 2 { FuchsVerlauf(spiel: s, zeilen: zeilen).padding(.horizontal, rand).frame(maxHeight: .infinity) } else { Spacer(minLength: 0) }
            knoepfe(st)
        }
    }

    private func iPadHoch(_ st: FuchsStandNeu, _ w: CGFloat, _ h: CGFloat) -> some View {
        let s = st.spiel, rand = Theme.seitenRand
        let spalte = min(w, 700)
        let seite = max(300, min(620, spalte - 2 * rand - 2 * Theme.spielfeldRand, h * 0.55))
        return VStack(spacing: Design.Abstand.m) {
            kopf(st); leiste(st)
            brett(st, seite)
            FuchsAblage(spiel: s, breite: spalte - 2 * rand, hoeheMax: 40).padding(.horizontal, rand)
            hinweis(st)
            HStack(spacing: Design.Abstand.m) {
                FuchsVerlauf(spiel: s, zeilen: 7)
                FuchsRegelKarte(spiel: s, stufe: mitComputer ? stufe : nil, match: st.match)
            }.padding(.horizontal, rand).frame(maxHeight: .infinity)
            knoepfe(st)
        }.frame(maxWidth: spalte).frame(maxWidth: .infinity)
    }

    private func quer(_ st: FuchsStandNeu, _ w: CGFloat, _ h: CGFloat) -> some View {
        let s = st.spiel, rand = Theme.seitenRand
        let seite = max(200, min(h - 44 - 12 * 2 - 2 * Theme.spielfeldRand - 8, w * 0.6))
        let gross = h >= 600
        return VStack(spacing: Design.Abstand.m) {
            kopf(st)
            HStack(alignment: .top, spacing: Design.Abstand.m) {
                brett(st, seite)
                VStack(spacing: Design.Abstand.m) {
                    leiste(st).padding(.horizontal, 0)
                    FuchsAblage(spiel: s, breite: w - seite - 3 * rand, hoeheMax: gross ? 36 : 22)
                    hinweis(st)
                    if gross && !grosseSchrift {
                        FuchsVerlauf(spiel: s, zeilen: 8).frame(maxHeight: .infinity)
                        FuchsRegelKarte(spiel: s, stufe: mitComputer ? stufe : nil, match: st.match).frame(height: 160)
                    } else { Spacer(minLength: 0) }
                    knoepfe(st)
                }
            }.padding(.horizontal, rand)
        }
    }

    private func endeKarte(_ st: FuchsStandNeu) -> some View {
        let s = st.spiel
        let a = s.ausgang ?? .remis
        let punkte = "\(nameFuer(.gaense, st)): \(s.punkte(.gaense)) · \(nameFuer(.fuchs, st)): \(s.punkte(.fuchs))"
        let nochEine = (st.match?.partie ?? 2) < 2
        let teil = st.match.map { String(localized: "Partie \(min($0.partie, 2)) von 2") + " · " } ?? ""
        return FuchsEndeKarte(titel: FuchsText.ausgang(a, regeln: s.regeln),
                              zeile: teil + String(localized: "\(s.zuege) Züge · \(s.geschlagen) Gänse gefressen"),
                              punkteZeile: punkte,
                              knopf: nochEine ? "Partie 2 starten, Seiten getauscht" : "Zum Ergebnis", weiter: weiter)
    }

    // MARK: Ablauf

    private func zug(_ z: FuchsZug) {
        guard var st = stand, st.spiel.ausgang == nil else { return }
        let wer = st.spiel.amZug
        st.spiel.ziehe(z); stand = st; gewaehlt = nil; tipp = nil; tick += 1
        UIAccessibility.post(notification: .announcement, argument: "\(wer == .gaense ? String(localized: "Gans") : String(localized: "Fuchs")) \(Fuchsjagd.notation(z))")
    }

    private func tippe(_ p: Pos) {
        guard let st = stand, st.spiel.ausgang == nil, !istComputer(st.spiel.amZug, st), Fuchsjagd.gueltig(p) else { return }
        let s = st.spiel
        if let g = gewaehlt, let z = s.ziele(von: g).first(where: { $0.nach == p }) { verlauf.append(s); zug(z); return }
        let eigene = s.amZug == .fuchs ? s.fuechse.contains(p) : s.gaense.contains(p)
        if eigene, !s.ziele(von: p).isEmpty { gewaehlt = gewaehlt == p ? nil : p; return }
        // Ein Fuchs: ein Tipp auf ein Ziel reicht auch ohne vorherige Wahl
        if s.amZug == .fuchs, s.fuechse.count == 1, let z = s.ziele(von: s.fuchs).first(where: { $0.nach == p }) { verlauf.append(s); zug(z); return }
        gewaehlt = nil
    }

    private func computerZug() async {
        guard let st = stand, st.spiel.ausgang == nil, istComputer(st.spiel.amZug, st) else { return }
        try? await Task.sleep(nanoseconds: 800_000_000)
        guard !Task.isCancelled, let jetzt = stand, jetzt.spiel == st.spiel, let z = jetzt.spiel.computerZug(tiefe: stufe.rawValue, mit: &zufall) else { return }
        zug(z)
    }

    private func zurueck() {
        guard var st = stand else { return }
        tipp = nil; gewaehlt = nil
        while let l = verlauf.popLast() { st.spiel = l; stand = st; tick += 1; if !istComputer(l.amZug, st) { break } }
    }

    private func holeTipp() {
        guard let st = stand else { return }
        tippRechnet = true
        let stellung = st.spiel
        Task {
            let z = await Task.detached { () -> FuchsZug? in var g = SystemRandomNumberGenerator(); return stellung.computerZug(tiefe: 3, mit: &g) }.value
            if stand?.spiel == stellung { tipp = z; gewaehlt = nil }
            tippRechnet = false
        }
    }

    /// „Weiter“ nach dem Spielende: nächste Partie des Matches oder Ergebnis an den Rahmen.
    private func weiter() {
        guard var st = stand, st.spiel.ausgang != nil, !gebucht else { return }
        if var m = st.match {
            let folgt = m.buche(st.spiel)
            st.match = m
            if folgt {
                st.spiel = Fuchsjagd(regeln: st.spiel.regeln); st.meineSeite = m.seiteErster
                stand = st; verlauf = []; tipp = nil; gewaehlt = nil; tick += 1
                return
            }
            gebucht = true; melde(st, summe: m.summe)
        } else {
            gebucht = true; melde(st, summe: nil)
        }
    }

    private func melde(_ st: FuchsStandNeu, summe: [Int]?) {
        let s = st.spiel
        if let summe {
            let namen = [teilnehmer[0].name, teilnehmer[1].name]
            var e = SpielEnde.nachPunkten(namen: namen, punkte: summe, info: String(localized: "Zwei Partien mit Seitentausch"))
            if summe[0] == summe[1] { e.plaetze = [1, 1]; e.info = String(localized: "Unentschieden nach zwei Partien") }
            ende(e); return
        }
        let andere: (Fuchsjagd.Seite) -> Fuchsjagd.Seite = { $0 == .fuchs ? .gaense : .fuchs }
        let info = FuchsText.ausgang(s.ausgang ?? .remis, regeln: s.regeln) + " · " + String(localized: "\(s.zuege) Züge · \(s.geschlagen) Gänse gefressen")
        switch s.ausgang {
        case .sieg(let w)?:
            ende(SpielEnde(reihenfolge: [nameFuer(w, st), nameFuer(andere(w), st)], punkte: [String(s.punkte(w)), String(s.punkte(andere(w)))], plaetze: [1, 2], info: info))
        default:
            ende(SpielEnde(reihenfolge: [nameFuer(.gaense, st), nameFuer(.fuchs, st)], punkte: [String(s.punkte(.gaense)), String(s.punkte(.fuchs))], plaetze: [1, 1], info: info))
        }
    }
}
#endif
