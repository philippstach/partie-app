// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import SpielHilfen
import SchiffsfrachtKern

@MainActor
public struct SchiffsfrachtModul: SpielModul {
    public init() {}
    public let id = "schiffsfracht"
    public let name = "Schiffsfracht"
    public let gattung = Gattung.wuerfel
    public let farbe = AkzentFarbeWert.blau
    public let symbol = "sailboat.fill"
    public let spielerzahl = 2...4
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(SpielRahmen(id: id, name: name, untertitel: "Schiff, Kapitän, Mannschaft – und Fracht", farbe: farbe, spieler: 2...4, computerErlaubt: true,
                            wuerfelWahl: true, regeln: "Jeder würfelt mit fünf Würfeln, bis zu dreimal. Zuerst brauchst du eine 6 (das Schiff), dann eine 5 (der Kapitän), dann eine 4 (die Mannschaft). Diese Würfel werden automatisch festgelegt, sobald sie in der richtigen Reihenfolge fallen; die anderen Würfel darfst du neu werfen. Hast du alle drei, zählen die übrigen zwei Würfel zusammen als deine Fracht (höchstens 12). Ohne vollständige Besatzung ist die Fracht null. Wer in einer Runde die meiste Fracht hat, bekommt einen Punkt. Nach fünf Runden gewinnt, wer die meisten Punkte hat. Du kannst nach jedem Wurf aufhören („Fertig“).",
                            umgebung: umgebung) { teilnehmer, ende, abbrechen in
            SchiffsfrachtSpiel(teilnehmer: teilnehmer, ende: ende, abbrechen: abbrechen, quelle: WuerfelWahl.quelle(id, vorgabe: umgebung.wuerfelQuelle))
        }.mitZiel("Würfle Schiff, Kapitän und Mannschaft und dazu möglichst viel Fracht. Nach fünf Runden gewinnt, wer die meisten Punkte hat.").mitAnleitung(Self.anleitung))
    }
}

struct SchiffsfrachtSpiel: View {
    let teilnehmer: [SpielTeilnehmer]
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    let quelle: WuerfelQuelle
    @State private var spiel: Schiffsfracht
    @State private var zufall = EchteWuerfelZufall()
    @State private var eingabe: Int?
    @State private var gemeldet = false
    @State private var stufe = ComputerStufe.gespeichert("schiffsfracht")
    private var fehler: Double { switch stufe { case .leicht: 0.45; case .mittel: 0.15; case .schwer: 0 } }

    init(teilnehmer: [SpielTeilnehmer], ende: @escaping (SpielEnde) -> Void, abbrechen: @escaping () -> Void, quelle: WuerfelQuelle) {
        self.teilnehmer = teilnehmer; self.ende = ende; self.abbrechen = abbrechen; self.quelle = quelle
        _spiel = State(initialValue: Schiffsfracht(spieler: teilnehmer.count))
    }

    private var amZugComputer: Bool { teilnehmer[spiel.amZug].computer }
    private func rolle(_ w: Int) -> String? { [6: String(localized: "Schiff"), 5: String(localized: "Kapitän"), 4: String(localized: "Mannschaft")][w] }

    var body: some View {
        VStack(spacing: Theme.kartenAbstand) {
            SpielKopf(mitte: String(localized: "Runde \(min(spiel.runde + 1, Schiffsfracht.runden)) von \(Schiffsfracht.runden)"), linksAktion: abbrechen) {
                RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                    if teilnehmer.contains(where: \.computer) { ComputerStufePicker(spiel: "schiffsfracht", stufe: $stufe) }
                    Button("Spiel beenden", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
                }
            }
            HStack(spacing: Design.Abstand.s) {
                ForEach(teilnehmer.indices, id: \.self) { i in
                    VStack(spacing: 2) {
                        Text(verbatim: teilnehmer[i].name).font(.footnote).lineLimit(1).minimumScaleFactor(0.7)
                        Text(verbatim: "\(spiel.punkte[i])").font(.title3.weight(.semibold))
                        Text(verbatim: spiel.ergebnisse[i].map { "\($0)" } ?? "–").font(.caption2).foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .frame(maxWidth: .infinity).padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: Design.Ecke.feld).fill(i == spiel.amZug && !spiel.rundeGewertet ? Color.appFlaeche.opacity(0.25) : Color.kartenGrund))
                }
            }.padding(.horizontal, Theme.seitenRand)
            Spacer(minLength: 0)
            if spiel.rundeGewertet {
                VStack(spacing: 10) {
                    Text(spiel.rundenSieger.isEmpty ? "Niemand hatte Fracht" : (spiel.rundenSieger.count == 1 ? "\(teilnehmer[spiel.rundenSieger[0]].name) gewinnt die Runde" : "Gleichstand in dieser Runde")).font(.headline)
                    Button(spiel.runde + 1 >= Schiffsfracht.runden ? "Ergebnis" : "Nächste Runde") { weiter() }.buttonStyle(HauptKnopfStil())
                }.padding(.horizontal, Theme.seitenRand)
            } else {
                würfel
                Text(statusText).font(.headline).foregroundStyle(Color.accentText).multilineTextAlignment(.center).padding(.horizontal)
                HStack(spacing: Design.Abstand.m) {
                    Button("Würfeln (\(3 - spiel.wuerfe) übrig)") { if quelle == .echt { eingabe = spiel.wuerfelAnzahl } else { spiel.wuerfeln(mit: &zufall) } }.buttonStyle(HauptKnopfStil()).disabled(amZugComputer || spiel.wuerfe >= 3).beimSchuetteln(aktiv: quelle == .app && !amZugComputer && spiel.wuerfe < 3) { spiel.wuerfeln(mit: &zufall) }
                    Button("Fertig") { spiel.fertig() }.nebenKnopf().dynamicTypeSize(...DynamicTypeSize.xxxLarge).disabled(amZugComputer || spiel.wuerfe == 0)
                }.padding(.horizontal, Theme.seitenRand)
            }
            Spacer(minLength: 0)
        }
        .background(Color.seitenGrund)
        .fortsetzbar("schiffsfracht", $spiel)
        .weicheAnimation(bei: spiel)
        .spielHaptik(zug: spiel, erfolg: (spiel.vorbei))
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .echteWuerfelEingabe(anzahl: $eingabe) { augen in zufall.lade(augen: augen); spiel.wuerfeln(mit: &zufall) }
        .uebergabeSeite(teilnehmer: teilnehmer, amZug: spiel.amZug, aktiv: !spiel.vorbei && !spiel.rundeGewertet, geheim: false)
        .computerZug(aktiv: amZugComputer && !spiel.vorbei && !spiel.rundeGewertet, id: "\(spiel.amZug)-\(spiel.wuerfe)-\(spiel.runde)") {
            var weiter = spiel.wuerfe == 0 || spiel.computerWillWeiter(stufe: stufe.rawValue)
            if spiel.wuerfe > 0, Double.random(in: 0..<1, using: &zufall) < fehler { weiter = Bool.random(using: &zufall) && spiel.wuerfe < 3 }   // Leichter Computer hört zu früh auf oder würfelt zu viel
            if weiter { spiel.wuerfeln(mit: &zufall) } else { spiel.fertig() }
        }
    }

    private var statusText: String {
        if spiel.wuerfe == 0 { return amZugComputer ? String(localized: "\(teilnehmer[spiel.amZug].name) würfelt …") : String(localized: "\(teilnehmer[spiel.amZug].name): Würfle!") }
        if spiel.mannschaftKomplett { return String(localized: "Besatzung komplett – Fracht: \(spiel.fracht)") }
        let bisher = spiel.fest.compactMap { rolle($0) }.joined(separator: ", ")
        return String(localized: "Noch gesucht: \(rolle(spiel.gesucht ?? 0) ?? "") (\(spiel.gesucht ?? 0))") + (bisher.isEmpty ? "" : " · " + bisher)
    }

    private var würfel: some View {
        HStack(spacing: 10) {
            ForEach(0..<5, id: \.self) { i in
                let w = spiel.becher.augen[i]
                let istFest = spiel.wuerfe > 0 && spiel.becher.gehalten[i] || festMarkiert(i)
                Group { if spiel.wuerfe == 0 { Image(systemName: "questionmark.square.fill").accessibilityLabel(Text("Noch nicht gewürfelt")) } else { WuerfelBild(w) } }.font(.system(size: 50))   // design:spielinhalt (feste Großdarstellung von Spielmaterial, kein Fließtext)
                    .foregroundStyle(istFest ? Color.appFlaeche : Color.primary).padding(2)
                    .overlay(RoundedRectangle(cornerRadius: Design.Ecke.klein).stroke(Color.appFlaeche, lineWidth: istFest ? 3 : 0))
                    .accessibilityValue(istFest ? Text("gehalten") : Text(verbatim: ""))
            }
        }
    }

    /// Ein Würfel gilt als festgelegt, wenn Schiff, Kapitän oder Mannschaft dort liegen (erste passende Würfel).
    private func festMarkiert(_ i: Int) -> Bool {
        guard spiel.wuerfe > 0 else { return false }
        var gebraucht = spiel.fest
        for (k, w) in spiel.becher.augen.enumerated() {
            if let p = gebraucht.firstIndex(of: w) { gebraucht.remove(at: p); if k == i { return true } }
        }
        return false
    }

    private func weiter() {
        if spiel.runde + 1 >= Schiffsfracht.runden {
            guard !gemeldet else { return }
            gemeldet = true
            ende(SpielEnde.nachPunkten(namen: teilnehmer.map(\.name), punkte: spiel.punkte))
        } else { spiel.naechsteRunde() }
    }

}
#endif
