// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import FuchsjagdKern

/// Ablage: ein Platz je Start-Gans, gefressene Gänse sind grau. Bei 17 und 20 Gänsen in zwei Reihen.
struct FuchsAblage: View {
    let spiel: Fuchsjagd
    let breite: CGFloat
    var hoeheMax: CGFloat = 44

    private static func mass(_ spiel: Fuchsjagd, _ breite: CGFloat, _ platzMax: CGFloat) -> (reihen: Int, proReihe: Int, platz: CGFloat) {
        let n = spiel.startGaense
        let reihen = n > 13 ? 2 : 1
        let proReihe = Int((Double(n) / Double(reihen)).rounded(.up))
        return (reihen, proReihe, min(platzMax, (breite - 24 - CGFloat(proReihe - 1) * 4) / CGFloat(proReihe)))
    }
    /// Gesamthöhe der Karte (für die Platzberechnung im Spielbildschirm).
    static func hoehe(_ spiel: Fuchsjagd, breite: CGFloat, platzMax: CGFloat) -> CGFloat {
        let m = mass(spiel, breite, platzMax)
        return CGFloat(m.reihen) * m.platz + CGFloat(m.reihen - 1) * 4 + 16
    }

    var body: some View {
        let n = spiel.startGaense
        let (reihen, proReihe, platz) = Self.mass(spiel, breite, hoeheMax)
        let uebrig = spiel.gaense.count
        VStack(spacing: Design.Abstand.xs) {
            ForEach(0..<reihen, id: \.self) { r in
                HStack(spacing: Design.Abstand.xs) {
                    ForEach(0..<proReihe, id: \.self) { i in
                        let nr = r * proReihe + i
                        if nr < n {
                            Circle().fill(nr < uebrig ? Color.appFlaeche : Color.clear)
                                .overlay(Circle().strokeBorder(nr < uebrig ? Color.clear : Color.secondary.opacity(0.5), lineWidth: 1.5))
                                .frame(width: platz, height: platz)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity).padding(.vertical, 8)
        .card()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(uebrig) von \(n) Gänsen übrig, \(spiel.geschlagen) gefressen"))
    }
}

/// Verlauf: die letzten Züge, neueste oben, in Kurzschreibweise (a–g, 1–7).
struct FuchsVerlauf: View {
    let spiel: Fuchsjagd
    let zeilen: Int

    var body: some View {
        let h = spiel.historie
        VStack(alignment: .leading, spacing: Design.Abstand.xs) {
            Text("Verlauf · Zug \(min(h.count / 2 + 1, spiel.zuglimit / 2)) von \(spiel.zuglimit / 2)").font(.footnote.weight(.semibold)).foregroundStyle(.secondary)
            if h.isEmpty {
                Text("Noch kein Zug").font(.subheadline).foregroundStyle(.secondary)
            } else {
                ForEach(Array(h.enumerated().reversed().prefix(zeilen)), id: \.offset) { i, z in
                    Text(verbatim: "\(i + 1). \(i % 2 == 0 ? String(localized: "Gans") : String(localized: "Fuchs")) \(Fuchsjagd.notation(z))\(z.schlag != nil ? ", " + String(localized: "frisst \(Fuchsjagd.notation(z.schlag!))") : "")")
                        .font(.subheadline.monospacedDigit()).lineLimit(1).minimumScaleFactor(0.8)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(Theme.innen)
        .card()
        .accessibilityElement(children: .combine)
    }
}

/// Regeln dieser Partie (iPad-Seitenspalte).
struct FuchsRegelKarte: View {
    let spiel: Fuchsjagd
    let stufe: ComputerStufe?
    var match: FuchsMatch?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Regeln dieser Partie").font(.footnote.weight(.semibold)).foregroundStyle(.secondary)
            Text(FuchsText.variante(spiel.regeln.variante)).font(.subheadline)
            if spiel.regeln.fuchsMussSchlagen { Text("Fuchs muss springen").font(.subheadline) }
            if spiel.regeln.gaenseDiagonal { Text("Gänse ziehen auch schräg").font(.subheadline) }
            if spiel.regeln.variante.fuchsSchraeg { Text("Fuchs zieht auch schräg").font(.subheadline) }
            Text(spiel.regeln.remisBeiLimit ? "Nach 80 Zügen unentschieden" : "Nach 80 Zügen gewinnt der Fuchs").font(.subheadline)
            if let stufe { Text("Computer: \(FuchsText.stufe(stufe))").font(.subheadline) }
            if let match { Text("Match: Partie \(min(match.partie, 2)) von 2").font(.subheadline) }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(Theme.innen)
        .card()
        .accessibilityElement(children: .combine)
    }
}

enum FuchsText {
    static func variante(_ v: FuchsVariante) -> LocalizedStringKey {
        switch v { case .dreizehn: "13 Gänse"; case .siebzehn: "17 Gänse"; case .zweiFuechse: "Zwei Füchse" }
    }
    static func stufe(_ s: ComputerStufe) -> String {
        switch s { case .leicht: String(localized: "Leicht"); case .mittel: String(localized: "Mittel"); case .schwer: String(localized: "Schwer") }
    }
    static func seite(_ s: Fuchsjagd.Seite) -> String { s == .gaense ? String(localized: "Gänse") : String(localized: "Fuchs") }
    /// Einblendung am Spielende (Titel).
    static func ausgang(_ a: Fuchsjagd.Ausgang, regeln: FuchsRegeln) -> String {
        switch a {
        case .remis: String(localized: "Unentschieden")
        case .sieg(.gaense): String(localized: "Der Fuchs sitzt in der Falle")
        case .sieg(.fuchs): String(localized: "Der Fuchs entkommt")
        }
    }
}

/// Spielende-Einblendung über dem stehenden Brett.
struct FuchsEndeKarte: View {
    let titel: String
    let zeile: String
    let punkteZeile: String
    let knopf: LocalizedStringKey
    let weiter: () -> Void

    var body: some View {
        VStack(spacing: Design.Abstand.s) {
            Text(verbatim: titel).font(.title3.weight(.bold)).multilineTextAlignment(.center)
            Text(verbatim: zeile).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
            Text(verbatim: punkteZeile).font(.subheadline.weight(.semibold)).multilineTextAlignment(.center)
            Button(knopf, action: weiter).buttonStyle(HauptKnopfStil()).padding(.top, 6)
        }
        .padding(Theme.innen).frame(maxWidth: 420)
        .background(.regularMaterial, in: .rect(cornerRadius: Theme.cardRadius))
        .padding(Theme.seitenRand)
        .accessibilityElement(children: .contain)
    }
}
#endif
