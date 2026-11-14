// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import SpielHilfen
import PechvogelKern

@MainActor
public struct PechvogelModul: SpielModul {
    public init() {}
    public let id = "pechvogel"
    public let name = "Pechvogel"
    public let gattung = Gattung.karten
    public let farbe = AkzentFarbeWert.rot
    public let symbol = "bird.fill"
    public let spielerzahl = 2...4
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(SpielRahmen(id: id, name: name, untertitel: "Wer bleibt auf dem Pechvogel sitzen?", farbe: farbe, spieler: 2...4, computerErlaubt: true,
                            regeln: "Es gibt 13 Tierpaare und einen einzelnen Pechvogel. Alle Karten werden verteilt, Paare in der Hand legt jeder sofort ab. Dann zieht reihum jeder verdeckt eine Karte aus der Hand seines Nachbarn. Passt sie zu einer eigenen Karte, kommt das Paar sofort weg. Wer keine Karten mehr hat, ist raus und in Sicherheit. Wer am Ende den Pechvogel allein auf der Hand hat, verliert. Tipp: Mische deine Hand zwischendurch nicht, aber lass dir nicht anmerken, wo der Pechvogel steckt!",
                            umgebung: umgebung) { teilnehmer, ende, abbrechen in
            PechvogelSpiel(teilnehmer: teilnehmer, ende: ende, abbrechen: abbrechen)
        }.mitZiel("Lege alle Paare ab und lass den einzelnen Pechvogel bei den anderen. Wer ihn am Ende hat, verliert.").mitAnleitung([
            .figuren(symbol: "square.on.square", titel: "Paare ablegen", text: "Alle Karten werden verteilt. Paare in der Hand legst du sofort ab.", figuren: ["🐘", "🐘"], bewegt: nil),
            .figuren(symbol: "hand.point.left", titel: "Karte ziehen", text: "Reihum ziehst du verdeckt eine Karte aus der Hand deines Nachbarn. Passt sie, kommt das Paar weg.", figuren: ["🂠", "👉", "🂠"], bewegt: nil),
            .figuren(symbol: "bird", titel: "Pechvogel", text: "Wer am Ende den einzelnen Pechvogel auf der Hand hat, verliert.", figuren: ["🐦", "😱"], bewegt: nil),
        ]))
    }
}

private let tierSymbole = TierMotive.symbole
private let tierFarben = TierMotive.farben

struct PechKarte: View {
    let motiv: Int?          // nil = verdeckt
    var gewaehlt = false
    var body: some View {
        Group {
            if let m = motiv {
                KartenFlaeche(groesse: .klein, beschriftung: m == Pechvogel.pechvogel ? Text("Pechvogel") : Text("Tierkarte")) {
                    if m == Pechvogel.pechvogel {
                        Image(systemName: "bird.fill").font(.title).foregroundStyle(.primary).overlay(Image(systemName: "exclamationmark").font(.caption.bold()).foregroundStyle(.red).offset(x: 14, y: -14))
                    } else {
                        Image(systemName: tierSymbole[m]).font(.title).foregroundStyle(tierFarben[m])
                    }
                }
                .markiert(gewaehlt)
            } else {
                KartenFlaeche(groesse: .klein, seite: .ruecken) { EmptyView() }.markiert(gewaehlt)
            }
        }
    }
}

struct PechvogelSpiel: View {
    let teilnehmer: [SpielTeilnehmer]
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    @State private var spiel: Pechvogel
    @State private var zufall = SystemRandomNumberGenerator()
    @State private var gemeldet = false
    @State private var schritte = 0

    init(teilnehmer: [SpielTeilnehmer], ende: @escaping (SpielEnde) -> Void, abbrechen: @escaping () -> Void) {
        self.teilnehmer = teilnehmer; self.ende = ende; self.abbrechen = abbrechen
        var g = SystemRandomNumberGenerator()
        _spiel = State(initialValue: Pechvogel(spieler: teilnehmer.count, mit: &g))
    }

    private var menschen: [Int] { teilnehmer.menschen }
    private var amZugComputer: Bool { teilnehmer[spiel.amZug].computer }
    private var sicht: Int { amZugComputer ? (menschen.first ?? 0) : spiel.amZug }
    private var kannHandeln: Bool { spiel.verlierer == nil && !amZugComputer }

    var body: some View {
        ZStack {
            Color.seitenGrund.ignoresSafeArea()
            VStack(spacing: Theme.kartenAbstand) {
                SpielKopf(mitte: spiel.verlierer == nil ? String(localized: "\(teilnehmer[spiel.amZug].name) zieht") : String(localized: "Spielende"), linksAktion: abbrechen) {
                    RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                        Button("Spiel beenden", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
                    }
                }
                ScrollView(.vertical) {
                    VStack(spacing: Design.Abstand.m) {
                        ForEach(teilnehmer.indices.filter { $0 != sicht }, id: \.self) { i in gegnerReihe(i) }
                    }.padding(.horizontal, Theme.seitenRand)
                }
                if !spiel.letzteAblage.isEmpty {
                    HStack(spacing: 6) {
                        Text("Paar abgelegt:").font(.footnote).foregroundStyle(.secondary)
                        ForEach(spiel.letzteAblage, id: \.self) { m in Image(systemName: tierSymbole[m]).foregroundStyle(tierFarben[m]) }
                    }
                }
                Spacer(minLength: 0)
                eigene
            }
        }
        .uebergabeSeite(teilnehmer: teilnehmer, amZug: spiel.amZug, aktiv: spiel.verlierer == nil)
        .fortsetzbar("pechvogel", $spiel)
        .weicheAnimation(bei: spiel)
        .spielHaptik(zug: spiel, erfolg: (spiel.aktive.count <= 1))
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .task(id: "\(spiel.amZug)-\(schritte)") {
            guard spiel.verlierer == nil, amZugComputer else { return }
            try? await Task.sleep(nanoseconds: 1_100_000_000)
            guard !Task.isCancelled, let i = spiel.computerWahl(mit: &zufall) else { return }
            spiel.ziehe(i, mit: &zufall); schritte += 1
            nachZug()
        }
    }

    private func gegnerReihe(_ i: Int) -> some View {
        let istNachbar = spiel.nachbar == i && spiel.amZug == sicht
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(verbatim: teilnehmer[i].name).font(.footnote.weight(.semibold))
                if spiel.haende[i].isEmpty { Label("raus", systemImage: "checkmark.circle.fill").font(.caption).foregroundStyle(.green) }
                Spacer()
                if i == spiel.amZug { Image(systemName: "hand.point.right.fill").foregroundStyle(Color.appFlaeche) }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: -22) {
                    ForEach(spiel.haende[i].indices, id: \.self) { k in
                        PechKarte(motiv: spiel.verlierer != nil ? spiel.haende[i][k] : nil)
                            .onTapGesture { if istNachbar, kannHandeln { spiel.ziehe(k, mit: &zufall); schritte += 1; nachZug() } }
                            .accessibilityAddTraits(.isButton)   // G1
                            .accessibilityHint(Text("Doppeltippen, um die Karte zu ziehen"))
                            .offset(y: istNachbar && kannHandeln ? -3 : 0)
                    }
                }.padding(.vertical, 6).padding(.leading, 4)
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: Design.Ecke.feld).fill(istNachbar ? Color.appFlaeche.opacity(0.2) : Color.kartenGrund))
    }

    private var eigene: some View {
        VStack(spacing: 6) {
            Text(kannHandeln ? String(localized: "Tippe eine verdeckte Karte deines Nachbarn an.") : " ").font(.footnote).foregroundStyle(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: -10) {
                    ForEach(spiel.haende[sicht].indices, id: \.self) { k in PechKarte(motiv: spiel.haende[sicht][k]) }
                }.padding(.horizontal, Theme.seitenRand).padding(.vertical, 6)
            }
            if spiel.haende[sicht].isEmpty { Label("Du bist raus!", systemImage: "checkmark.circle.fill").foregroundStyle(.green) }
        }.padding(.bottom, 8)
    }

    private func nachZug() {
        if let v = spiel.verlierer, !gemeldet {
            gemeldet = true
            let rest = teilnehmer.indices.filter { $0 != v }
            Task {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                ende(SpielEnde(reihenfolge: rest.map { teilnehmer[$0].name } + [teilnehmer[v].name], punkte: [],
                               plaetze: rest.map { _ in 1 } + [2], info: String(localized: "\(teilnehmer[v].name) bleibt auf dem Pechvogel sitzen")))
            }
            return
        }
    }
}
#endif
