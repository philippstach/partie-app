// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

/// Eingabe von `anzahl` Würfeln über 6 Würfelflächen (echte Würfel, SPEZIFIKATION 15.2).
/// Jeder Tipp füllt den nächsten freien Platz, ein Tipp auf einen gefüllten Platz leert ihn.
/// Sind alle Plätze durch Tippen gefüllt, wird sofort `fertig` aufgerufen.
/// Blatt 15: Neben den Feldern steht die Kapsel „Ansagen“ (nur mit Spracherkennung auf dem Gerät). Nach einer Ansage trägt die App
/// nie von selbst ein: Erst prüfen, dann „Übernehmen“.
struct WuerfelEingabeFeld: View {
    let titel: String
    let anzahl: Int
    let fertig: ([Int]) -> Void

    @State private var plaetze: [Int?]
    @State private var ansage = AnsageSteuerung()
    @Environment(\.dynamicTypeSize) private var typeSize

    init(titel: String, anzahl: Int, fertig: @escaping ([Int]) -> Void) {
        self.titel = titel
        self.anzahl = anzahl
        self.fertig = fertig
        _plaetze = State(initialValue: Array(repeating: nil, count: anzahl))
    }

    private var voll: Bool { plaetze.allSatisfy { $0 != nil } }

    var body: some View {
        VStack(spacing: 10) {
            titelZeile
            HStack(spacing: 14) {
                HStack(spacing: 10) {
                    ForEach(0..<anzahl, id: \.self) { i in
                        Button { plaetze[i] = nil } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(feldRand(i), style: StrokeStyle(lineWidth: 1.5, dash: naechstes == i ? [] : [5, 4]))
                                if let w = plaetze[i] { DieView(wert: w, size: 56) }
                            }
                            .frame(width: 56, height: 56)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(String(localized: "Würfel \(i + 1) von \(anzahl)")
                                            + (plaetze[i].map { ": " + wort($0) } ?? ""))
                    }
                }
                if ansage.angeboten || ansage.hoert { kapsel }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Design.Abstand.s), count: typeSize.isAccessibilitySize ? 3 : 6), spacing: Design.Abstand.s) {
                ForEach(1...6, id: \.self) { w in
                    Button { tippe(w) } label: {
                        DieView(wert: w, size: 48).frame(maxWidth: .infinity, minHeight: 48)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(wort(w))
                }
            }
        }
        .padding(12)
        .background(Color.accentSoft, in: .rect(cornerRadius: Theme.cardRadius))
        .onDisappear { ansage.abbrechen() }
        .task {
            // Beim nächsten Wurf gleich mit der zuletzt benutzten Eingabeart beginnen (hier nur „Ansagen“ möglich).
            guard WuerfelEingabeArt.gemerkt() == .ansage else { return }
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled, ansage.angeboten, plaetze.allSatisfy({ $0 == nil }) else { return }
            ansage.starten(plaetze: $plaetze)
        }
    }

    /// Das Feld, das beim Zuhören als Nächstes gefüllt wird (durchgezogener heller Rand).
    private var naechstes: Int? { ansage.hoert ? plaetze.firstIndex(where: { $0 == nil }) : nil }

    private func feldRand(_ i: Int) -> Color {
        naechstes == i ? (Tisch.aktiv ? Tisch.elfenbein : Color.accentText) : Color.secondary.opacity(0.6)
    }

    /// Titelzeile: Frage, beim Zuhören die Anweisung, nach der Ansage die Bitte um Prüfung oder ein Hinweis.
    @ViewBuilder private var titelZeile: some View {
        if ansage.hoert {
            Label(anzahl <= 2 ? "Ich höre zu. Sag die Augen, zum Beispiel: vier." : "Ich höre zu. Sag die Augen: drei, fünf, eins.", systemImage: "waveform")
                .font(.footnote.weight(.semibold)).foregroundStyle(Tisch.aktiv ? Tisch.elfenbein : Color.primary)
                .symbolEffect(.variableColor.iterative, isActive: true)
        } else if voll {
            Text("Bitte prüfe die Augen.").font(.footnote.weight(.semibold)).foregroundStyle(Tisch.aktiv ? Tisch.elfenbein : Color.primary)
        } else if let hinweis = ansage.hinweis {
            Text(hinweis).font(.footnote.weight(.semibold)).foregroundStyle(.secondary).multilineTextAlignment(.center)
        } else {
            Text(titel).font(.footnote.weight(.semibold)).foregroundStyle(.secondary)
        }
    }

    private enum KapselArt { case ansagen, fertig, uebernehmen }

    /// Kapsel rechts neben den Feldern: „Ansagen“ · beim Zuhören „Fertig“ · bei vollen Feldern „Übernehmen“.
    private var kapselArt: KapselArt { ansage.hoert ? .fertig : (voll ? .uebernehmen : .ansagen) }

    private var kapsel: some View {
        let art = kapselArt
        let gefuellt = art != .ansagen
        let tinte = Tisch.aktiv
        return Button {
            switch art {
            case .fertig: ansage.stoppen()
            case .uebernehmen: abschliessen()
            case .ansagen: WuerfelEingabeArt.merke(.ansage); ansage.starten(plaetze: $plaetze)
            }
        } label: {
            HStack(spacing: 6) {
                switch art {
                case .ansagen: Image(systemName: "mic"); Text("Ansagen").lineLimit(1).minimumScaleFactor(0.7)
                case .fertig: Image(systemName: "stop.fill"); Text("Fertig").lineLimit(1).minimumScaleFactor(0.7)
                case .uebernehmen: Text("Übernehmen").lineLimit(1).minimumScaleFactor(0.7)
                }
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(gefuellt ? (tinte ? Tisch.dunkel : Color.onAccent) : (tinte ? Tisch.elfenbein : Color.accentText))
            .padding(.horizontal, 16)
            .frame(minHeight: 44)
            .background(Capsule().fill(gefuellt ? (tinte ? Tisch.elfenbein : Color.accentColor) : (tinte ? Color.white.opacity(0.17) : Color.accentColor.opacity(0.15))))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityHint(art == .ansagen ? Text("Sag die Augen deiner Würfel der Reihe nach, zum Beispiel: drei, fünf, eins.") : Text(verbatim: ""))
    }

    private func tippe(_ w: Int) {
        guard let k = plaetze.firstIndex(where: { $0 == nil }) else { return }
        plaetze[k] = w
        if plaetze.allSatisfy({ $0 != nil }) { abschliessen() }
    }

    /// Wurf übernehmen. Ganz von Hand getippt: Die App vergisst die gemerkte Eingabeart.
    private func abschliessen() {
        if !ansage.hatEingetragen { WuerfelEingabeArt.merke(nil) }
        fertig(plaetze.compactMap { $0 })
    }

    private func wort(_ n: Int) -> String {
        [String(localized: "Eins"), String(localized: "Zwei"), String(localized: "Drei"),
         String(localized: "Vier"), String(localized: "Fünf"), String(localized: "Sechs")][max(0, min(5, n - 1))]
    }
}

/// Schnelleingabe (SPEZIFIKATION 15.3): erst die 3 Endwürfel, dann Anzahl der Würfe und – bei Straße oder General –
/// die Frage „Alle drei im letzten Wurf?“.
struct EndergebnisEingabe: View {
    let spieler: String
    let maxWuerfe: Int
    let optionen: Optionen
    /// (Endwürfel, Würfe, aus einem Wurf)
    let eintragen: ([Int], Int, Bool) -> Void

    @State private var wuerfel: [Int]?
    @State private var wuerfe = 1
    @State private var einWurf = true

    var body: some View {
        if let w = wuerfel {
            VStack(spacing: 10) {
                HStack(spacing: 6) { ForEach(Array(w.enumerated()), id: \.offset) { _, x in DieView(wert: x, size: 40) } }
                Picker("Würfe", selection: $wuerfe) {
                    ForEach(1...maxWuerfe, id: \.self) { Text("\($0)").tag($0) }
                }
                .pickerStyle(.segmented)
                if Spielzustand.fragtNachEinemWurf(w, optionen: optionen) {
                    Picker("Alle drei im letzten Wurf?", selection: $einWurf) {
                        Text("Ja").tag(true)
                        Text("Nein").tag(false)
                    }
                    .pickerStyle(.segmented)
                }
                AdaptiveStack {
                    Button("Zurück") { wuerfel = nil }.sichtbarBordered().frame(maxWidth: .infinity)
                    Button { eintragen(w, wuerfe, einWurf) } label: { Text("Eintragen").font(.headline).frame(maxWidth: .infinity) }
                        .hauptKnopf()
                        .accessibilityIdentifier("eintragen")
                }
                .controlSize(.large)
            }
            .padding(12)
            .background(Color.accentSoft, in: .rect(cornerRadius: Theme.cardRadius))
        } else {
            WuerfelEingabeFeld(titel: String(localized: "\(spieler): Was hast du geworfen?"), anzahl: 3) { wuerfel = $0 }
        }
    }
}
