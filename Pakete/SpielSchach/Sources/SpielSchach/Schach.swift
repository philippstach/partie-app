// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import SpielHilfen
import SchachKern

@MainActor
public struct SchachModul: SpielModul {
    public init() {}
    public let id = "schach"
    public let name = "Schach"
    public let gattung = Gattung.brett
    public let farbe = AkzentFarbeWert.tuerkis
    public let symbol = "crown.fill"
    public let spielerzahl = 1...2
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(SpielRahmen(id: id, name: name, untertitel: "Der Klassiker", farbe: farbe, spieler: 2...2, computerErlaubt: true,
                            regeln: "Weiß beginnt. Jede Figur zieht auf ihre Art: Bauer ein Feld vor (zwei vom Start aus) und schlägt schräg, Springer in L-Form, Läufer diagonal, Turm gerade, Dame beides, König ein Feld. Wer den gegnerischen König so bedroht, dass er nicht mehr entkommen kann, setzt matt und gewinnt. Es gibt Rochade, „en passant“ und Umwandlung (hier immer in eine Dame). Kann der Spieler am Zug nicht ziehen und steht nicht im Schach, ist es Patt – Remis.",
                            umgebung: umgebung) { teilnehmer, ende, abbrechen in
            SchachSpiel(teilnehmer: teilnehmer, ende: ende, abbrechen: abbrechen)
        }.mitZiel("Setze den gegnerischen König matt: Er steht im Schach und kann nicht mehr entkommen.").mitAnleitung([
            .figuren(symbol: "crown", titel: "Jede Figur zieht anders", text: "Bauer ein Feld vor, Springer in L-Form, Läufer diagonal, Turm gerade, Dame beides, König ein Feld.", figuren: ["♙", "♞", "♝", "♜"], bewegt: nil),
            .figuren(symbol: "exclamationmark.shield", titel: "Schach und Matt", text: "Bedrohst du den König so, dass er nicht entkommen kann, setzt du matt und gewinnst.", figuren: ["♚", "♜"], bewegt: nil),
            .figuren(symbol: "sparkles", titel: "Sonderzüge", text: "Es gibt Rochade, „en passant“ und Umwandlung in eine Dame. Kann man nicht ziehen und steht nicht im Schach, ist es Patt.", figuren: ["♟", "♛"], bewegt: nil),
        ]))
    }
}

struct SchachSpiel: View {
    let teilnehmer: [SpielTeilnehmer]
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    @State private var spiel = Schach()
    @State private var gewaehlt: Int?
    @State private var denkt = false
    @State private var stufe = ComputerStufe.gespeichert("schach")
    private var staerke: SchachStaerke { switch stufe { case .leicht: .leicht; case .mittel: .mittel; case .schwer: .schwer } }
    @State private var verlauf: [Schach] = []
    @State private var tipp: SchachZug?
    @State private var tippRechnet = false
    @State private var letzter: SchachZug?

    private func name(_ s: Int) -> String { teilnehmer[s == 1 ? 0 : 1].name }
    private var computerDran: Bool { teilnehmer[spiel.dran == 1 ? 0 : 1].computer }
    private var ziele: Set<Int> { gewaehlt.map { Set(spiel.zuege(von: $0).map(\.nach)) } ?? [] }
    private let glyphen = ["", "♙♟", "♘♞", "♗♝", "♖♜", "♕♛", "♔♚"]

    private func glyph(_ p: Int) -> String {
        let i = abs(p); guard i > 0 else { return "" }
        let paar = Array(glyphen[i]); return String(paar[1])   // gefüllte Figur, Farbe über foregroundStyle
    }

    var body: some View {
        VStack(spacing: Theme.kartenAbstand) {
            SpielKopf(mitte: name(spiel.dran) + (spiel.imSchach ? " – " + String(localized: "Schach!") : ""), linksAktion: abbrechen) {
                RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                    if teilnehmer.contains(where: \.computer) {
                        ComputerStufePicker(spiel: "schach", stufe: $stufe)
                    }
                    Button("Aufgeben", systemImage: "flag", role: .destructive) { beenden(gewinner: -spiel.dran) }
                    Button("Spiel verlassen", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
                }
            }
            SpielfeldKarte {
                Grid(horizontalSpacing: 0, verticalSpacing: 0) {
                    ForEach(0..<8, id: \.self) { z in GridRow { ForEach(0..<8, id: \.self) { s in feld(z * 8 + s) } } }
                }.clipShape(RoundedRectangle(cornerRadius: 6))
            }.padding(.horizontal, Theme.seitenRand)
            ZugKnoepfe(kannZurueck: !verlauf.isEmpty && !denkt, tippMoeglich: !computerDran && !spiel.zuege.isEmpty, rechnet: tippRechnet, zurueck: zurueck, tipp: holeTipp)
            if spiel.imSchach, !spiel.zuege.isEmpty {
                StatusChip(symbol: "exclamationmark.triangle.fill", text: Text("Schach!"), ton: .warnung)
                    .accessibilityAddTraits(.isStaticText)
            }
            Text(denkt ? "\(name(spiel.dran)) denkt nach …" : "\(name(spiel.dran)) ist dran (\(spiel.dran == 1 ? "Weiß" : "Schwarz"))")
                .font(.subheadline).foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
        .background(Color.seitenGrund)
        .fortsetzbar("schach", $spiel)
        .weicheAnimation(bei: spiel)
        .spielHaptik(zug: spiel, erfolg: (spiel.zuege.isEmpty || spiel.remis))
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .onAppear { computer() }
    }

    private func feld(_ i: Int) -> some View {
        let r = i / 8, c = i % 8, hell = (r + c) % 2 == 0
        let p = spiel.brett[i]
        let imSchachKoenig = spiel.imSchach && p == 6 * spiel.dran
        return Button { tippe(i) } label: {
            ZStack {
                Rectangle().fill(hell ? Color.appFlaeche.opacity(0.2) : Color.appFlaeche.opacity(0.62))
                if imSchachKoenig { Rectangle().fill(Color.red.opacity(0.45)) }
                if let l = letzter, l.von == i || l.nach == i { Rectangle().fill(Color.yellow.opacity(0.25)) }
                if gewaehlt == i { Rectangle().strokeBorder(Color.primary, lineWidth: 3) }
                if let t = tipp, t.von == i || t.nach == i { Rectangle().strokeBorder(Color.yellow, lineWidth: 4) }
                // Weiße Figuren bekommen eine dunkle Kontur (auf hellen Feldern sonst kaum zu sehen), schwarze einen hellen Schimmer
                Text(glyph(p)).font(.system(size: 34)).foregroundStyle(p > 0 ? Color.white : Color.black)   // design:spielinhalt (Spielmaterial im Feld)
                    .shadow(color: p > 0 ? .black : .white.opacity(0.55), radius: 0, x: 1, y: 0)
                    .shadow(color: p > 0 ? .black : .white.opacity(0.55), radius: 0, x: -1, y: 0)
                    .shadow(color: p > 0 ? .black : .white.opacity(0.55), radius: 0, x: 0, y: 1)
                    .shadow(color: p > 0 ? .black : .white.opacity(0.55), radius: 0, x: 0, y: -1)
                if ziele.contains(i) { Circle().fill(Color.primary.opacity(0.4)).padding(p == 0 ? 15 : 3) }
            }.aspectRatio(1, contentMode: .fit).frame(maxWidth: Theme.wideColumnWidth)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: "\(["a", "b", "c", "d", "e", "f", "g", "h"][c])\(8 - r)" + (p == 0 ? String(localized: ", leer") : ", " + [String(localized: "Bauer"), String(localized: "Springer"), String(localized: "Läufer"), String(localized: "Turm"), String(localized: "Dame"), String(localized: "König")][abs(p) - 1] + " " + (p > 0 ? String(localized: "weiß") : String(localized: "schwarz")))))
        .accessibilityValue(ziele.contains(i) ? Text("mögliches Ziel") : Text(verbatim: ""))
        .accessibilityAddTraits(gewaehlt == i ? .isSelected : [])
    }

    private func tippe(_ i: Int) {
        guard !denkt, !computerDran, !spiel.zuege.isEmpty else { return }
        if let g = gewaehlt, let z = spiel.zuege(von: g).first(where: { $0.nach == i && ($0.umwandlung ?? 5) == 5 }) {
            verlauf.append(spiel); tipp = nil; letzter = z
            spiel.ziehe(z); SpielZug.gemacht("schach"); gewaehlt = nil; nachZug(); return
        }
        gewaehlt = spiel.brett[i] * spiel.dran > 0 ? i : nil
    }

    private func nachZug() {
        if spiel.schachmatt { beenden(gewinner: -spiel.dran); return }
        if spiel.imSchach, !spiel.zuege.isEmpty { UIAccessibility.post(notification: .announcement, argument: String(localized: "Schach!")) }
        if spiel.remis {
            let grund = spiel.remisGrund.map { String(localized: String.LocalizationValue($0)) } ?? ""
            ende(SpielEnde(reihenfolge: [name(1), name(-1)], plaetze: [1, 1], info: String(localized: "Remis") + (grund.isEmpty ? "" : " – " + grund)))
            return
        }
        computer()
    }

    private func beenden(gewinner: Int) {
        ende(SpielEnde(reihenfolge: [name(gewinner), name(-gewinner)], info: spiel.schachmatt ? String(localized: "Schachmatt – \(name(gewinner)) gewinnt") : String(localized: "\(name(gewinner)) gewinnt")))
    }

    private func zurueck() {
        tipp = nil; gewaehlt = nil; letzter = nil
        while let l = verlauf.popLast() { spiel = l; if !teilnehmer[l.dran == 1 ? 0 : 1].computer { break } }
    }

    private func holeTipp() {
        tippRechnet = true
        let stand = spiel
        Task {
            let z = await Task.detached { SchachComputer.wahl(stand, tiefe: 3) }.value
            if spiel == stand { tipp = z; gewaehlt = nil }
            tippRechnet = false
        }
    }

    private func computer() {
        guard computerDran, !spiel.zuege.isEmpty else { return }
        denkt = true
        let stand = spiel, st = staerke
        Task {
            try? await Task.sleep(for: .milliseconds(400))
            let z = await Task.detached { SchachComputer.wahl(stand, staerke: st) }.value
            denkt = false
            guard spiel == stand else { return }
            if let z, spiel.ziehe(z) { letzter = z; nachZug() }
        }
    }
}
#endif
