// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern
import WuerfelScan

/// Echte Würfel: die Augen des Wurfs eintragen – tippen (Tasten in Daumenhöhe, am iPad auch Tastatur 1–6), ansagen oder mit der Kamera lesen.
/// Gehaltene Würfel stehen schon fest.
struct RealEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.geraeteSchema) private var geraet
    @Environment(\.colorScheme) private var schema
    let dice: [Int]          // aktuelle Würfel (leer vor dem ersten Wurf)
    let held: Set<Int>
    let rollNumber: Int
    let onDone: ([Int]) -> Void

    @State private var values: [Int?] = Array(repeating: nil, count: 5)
    @State private var active = 0
    @State private var zeigeKamera = false
    @State private var zeigeScanner = false
    /// Meldet dieses Blatt beim Würfelscanner als Empfänger an (siehe `WuerfelScannerFunk`).
    @State private var empfaengerID = UUID()
    @State private var kameraHinweis: String?
    @State private var hoerer = AnsageHoerer()
    /// Plätze, die beim Start der Ansage leer waren: nur diese füllt die Ansage (schon gefüllte Würfel bleiben).
    @State private var ansagePlaetze: [Int] = []
    /// Bildausschnitte der Würfel vom Scanner je Platz (zum Prüfen und Korrigieren) und die vom Scanner erkannten Augen.
    @State private var ausschnitte: [Int: Data] = [:]
    @State private var erkanntVomScanner: [Int: Int] = [:]
    /// Zählt Tastentipps (für den Tast-Impuls).
    @State private var tipps = 0
    /// Kamera, Scanner oder Ansage haben in diesem Blatt Augen geliefert (sonst vergisst „Wurf übernehmen“ die gemerkte Eingabeart).
    @State private var hilfeGenutzt = false
    @FocusState private var tastatur: Bool

    /// Positionen, die neu eingetippt werden (alle im ersten Wurf, sonst die nicht gehaltenen)
    private var slots: [Int] { dice.isEmpty ? Array(0..<5) : (0..<5).filter { !held.contains($0) } }
    private var complete: Bool { slots.allSatisfy { values[$0] != nil } }

    var body: some View {
        NavigationStack {
            VStack(spacing: Design.Abstand.xl) {
                Text("Tippe die Augen deiner Würfel ein, so wie sie am Tisch liegen.")
                    .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)

                HStack(spacing: 10) {
                    ForEach(0..<5, id: \.self) { i in slot(i) }
                }

                scannerZeichen
                ausschnittReihe

                Spacer(minLength: 0)

                if hoerer.zustand == .hoert {
                    Label("Ich höre zu. Sag die Augen, zum Beispiel: drei, fünf, eins.", systemImage: "waveform")
                        .font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
                        .symbolEffect(.variableColor.iterative, isActive: true)
                } else if let kameraHinweis {
                    Text(kameraHinweis).font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
                }

                // Blatt 15: vier gleich breite Flächen mit Zeichen und Kurzwort; fehlt einer, teilen sich die übrigen die Breite.
                EingabeArtReihe(eingabeKnoepfe)

                // Zifferntasten in einer Reihe direkt über „Wurf übernehmen“: kurzer Daumenweg, jeder Tipp springt zum nächsten freien Würfel.
                GeometryReader { geo in
                    let kante = max(36, min(64, (geo.size.width - 5 * 8) / 6))
                    HStack(spacing: 8) {
                        ForEach(1...6, id: \.self) { n in
                            Button { enter(n) } label: {
                                DieView(value: n, state: .free, size: kante)
                                    .frame(minHeight: Theme.tapSize)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(n)")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(height: 68)
            }
            .padding()
            .safeAreaInset(edge: .bottom) {
                BottomBar {
                    Button {
                        melden()
                        dismiss()
                    } label: { Text("Wurf übernehmen").font(.headline).frame(maxWidth: .infinity) }
                        .hauptKnopf().disabled(!complete)
                        .accessibilityHint(complete ? "" : "Erst alle Würfel eintippen")
                }
            }
            .navigationTitle("Wurf \(rollNumber) eintragen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }
            }
            .onAppear { active = slots.first ?? 0; tastatur = true; scannerAnmelden() }
            .task { await gemerkteArtOeffnen() }
            .onDisappear { hoerer.stoppen(); WuerfelScannerFunk.abmelden?(empfaengerID) }
            .sensoryFeedback(.impact(weight: .light), trigger: tipps)
            .onChange(of: hoerer.augen) { _, augen in angesagt(augen) }
            .onChange(of: hoerer.beendet) { _, beendet in if beendet { ansageBeendet() } }
            // Tastatur (iPad, Mac): 1–6 trägt ein, Löschen nimmt zurück, Eingabe übernimmt den Wurf.
            .focusable().focused($tastatur).focusEffectDisabled()
            .onKeyPress(characters: .decimalDigits) { taste in
                guard let n = Int(taste.characters), (1...6).contains(n) else { return .ignored }
                enter(n); return .handled
            }
            .onKeyPress(.delete) { back(); return .handled }
            .onKeyPress(.return) {
                guard complete else { return .ignored }
                melden(); dismiss(); return .handled
            }
            .wuerfelKamera(isPresented: $zeigeKamera, hoechstens: 5) { augen in
                guard let augen else { return }
                uebernehmen(augen)
            }
            .wuerfelScannerEmpfang(isPresented: $zeigeScanner) { augen in
                guard let augen else { return }
                uebernehmen(augen)
            }
        }
        .blattSchema()   // Tinte hell: das Blatt folgt dem Gerät, nicht dem dunklen Filz darunter
        // T-8: Beim NavigationStack erreicht `preferredColorScheme` den Inhalt nicht; Titel und Anleitung blieben fast weiß auf weiß. Nur hier, andere Blätter sind in Ordnung.
        .environment(\.colorScheme, geraet ?? schema)
        .presentationDetents([.large])
        .wuerfelScannerAnfrage()
    }

    // MARK: Eingabearten (Kamera, Scanner, Ansagen, Zurück)

    private var eingabeKnoepfe: [EingabeKnopfDaten] {
        var k: [EingabeKnopfDaten] = []
        if WuerfelKamera.verfuegbar {
            k.append(EingabeKnopfDaten(id: "kamera", symbol: "camera", wort: "Kamera", vorlesetext: "Mit Kamera lesen",
                                       hinweis: "Fotografiere die Würfel von oben. Du kannst jeden Wert danach noch ändern.") { waehle(.kamera) })
        }
        if WuerfelKamera.scannerEmpfang != nil, scannerStand?.name == nil {
            k.append(EingabeKnopfDaten(id: "scanner", symbol: "iphone.gen3.radiowaves.left.and.right", wort: "Scanner", vorlesetext: "Vom Scanner",
                                       hinweis: "Ein zweites Gerät mit Partie liest die Würfel und schickt den Wurf hierher.") { waehle(.scanner) })
        }
        if AnsageHoerer.verfuegbar {
            if hoerer.zustand == .hoert {
                k.append(EingabeKnopfDaten(id: "ansage", symbol: "stop.fill", wort: "Fertig", vorlesetext: "Fertig", hervorgehoben: true) { hoerer.stoppen() })
            } else {
                k.append(EingabeKnopfDaten(id: "ansage", symbol: "mic", wort: "Ansagen", vorlesetext: "Ansagen",
                                           hinweis: "Sag die Augen deiner Würfel der Reihe nach, zum Beispiel: drei, fünf, eins.",
                                           gesperrt: slots.allSatisfy { values[$0] != nil }) { waehle(.ansage) })
            }
        }
        k.append(EingabeKnopfDaten(id: "zurueck", symbol: "delete.left", wort: "Zurück", vorlesetext: "Zurück",
                                   gesperrt: slots.allSatisfy { values[$0] == nil }) { back() })
        return k
    }

    /// Wurf übernehmen. Ganz von Hand getippt: Die App vergisst die gemerkte Eingabeart.
    private func melden() {
        if !hilfeGenutzt { WuerfelEingabeArt.merke(nil) }
        onDone(slots.compactMap { values[$0] })
    }

    /// Öffnet die Eingabeart und merkt sie sich für den nächsten Wurf.
    private func waehle(_ art: WuerfelEingabeArt) {
        WuerfelEingabeArt.merke(art)
        starte(art)
    }

    private func starte(_ art: WuerfelEingabeArt) {
        switch art {
        case .kamera: if WuerfelKamera.verfuegbar { zeigeKamera = true }
        case .scanner: if WuerfelKamera.scannerEmpfang != nil, scannerStand?.name == nil { zeigeScanner = true }
        case .ansage: if AnsageHoerer.verfuegbar { ansagen() }
        }
    }

    /// Beim Öffnen gleich mit der zuletzt benutzten Eingabeart beginnen (kurz warten, bis das Blatt steht).
    private func gemerkteArtOeffnen() async {
        guard let art = WuerfelEingabeArt.gemerkt() else { return }
        try? await Task.sleep(for: .milliseconds(350))
        guard !Task.isCancelled, slots.allSatisfy({ values[$0] == nil }) else { return }
        starte(art)
    }

    // MARK: Würfelscanner (zweites Gerät)

    private var scannerStand: ScannerStand? { WuerfelScannerFunk.stand?() }

    /// Zeichen „Scanner verbunden“: Solange es steht, landet jeder Wurf des Scanners hier in den Plätzen, ohne dass man etwas öffnen muss.
    @ViewBuilder private var scannerZeichen: some View {
        if let st = scannerStand, let name = st.name {
            VStack(spacing: 2) {
                Label {
                    if st.unterbrochen {
                        Text("Scanner „\(name)“: Verbindung wird wiederhergestellt …")
                    } else {
                        Text("Scanner „\(name)“ verbunden")
                    }
                } icon: {
                    if st.unterbrochen { ProgressView() } else { Image(systemName: "link").foregroundStyle(.green) }
                }
                .font(.footnote.weight(.semibold))
                Text("Lege die Würfel unter das andere Gerät. Der Wurf erscheint hier.")
                    .font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }
            .accessibilityElement(children: .combine)
        }
    }

    /// Meldet das Blatt als Empfänger an und sagt dem Scanner, wie viele Würfel erwartet werden.
    private func scannerAnmelden() {
        WuerfelScannerFunk.anmelden?(empfaengerID) { augen in vomScanner(augen) }
        WuerfelScannerFunk.meldeLage?("Yacht", slots.count, dice.isEmpty ? 0 : held.count)
    }

    private func vomScanner(_ augen: [Int]) {
        uebernehmen(augen, bilder: WuerfelScannerFunk.bilder?() ?? [])
        tipps += 1
    }

    /// Die kleinen Fotos der Würfel vom Scanner, je Platz mit der erkannten Zahl. Ein Tipp öffnet die Zahlen 1–6 zum Korrigieren.
    @ViewBuilder private var ausschnittReihe: some View {
        if !ausschnitte.isEmpty {
            HStack(spacing: 10) {
                ForEach(slots, id: \.self) { i in
                    if let d = ausschnitte[i], let bild = Self.bild(d) {
                        Menu {
                            ForEach(1...6, id: \.self) { n in
                                Button("\(n)") { values[i] = n; active = slots.first(where: { values[$0] == nil }) ?? i; tipps += 1 }
                            }
                        } label: {
                            bild.resizable().scaledToFill()
                                .frame(width: 64, height: 64)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .overlay(alignment: .bottomTrailing) {
                                    let korrigiert = values[i] != nil && values[i] != erkanntVomScanner[i]
                                    Text(values[i].map(String.init) ?? "?")
                                        .font(.callout.bold().monospacedDigit()).foregroundStyle(.white)
                                        .frame(minWidth: 24, minHeight: 24)
                                        .background(korrigiert ? Color.orange : Color.green, in: Capsule())
                                        .padding(3)
                                }
                        }
                        .accessibilityLabel("Würfel \(i + 1): \(values[i].map(String.init) ?? "leer")")
                    }
                }
            }
        }
    }

    private static func bild(_ d: Data) -> Image? {
        #if canImport(UIKit)
        UIImage(data: d).map { Image(uiImage: $0) }
        #else
        nil
        #endif
    }

    @ViewBuilder
    private func slot(_ i: Int) -> some View {
        if slots.contains(i) {
            Button { active = i } label: {
                DieView(value: values[i] ?? 1, state: values[i] == nil ? .unknown : .free, size: 54)
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.appFlaeche, lineWidth: active == i ? 3 : 0).padding(-3))   // design:spielinhalt (Markierung auf dem Spielmaterial)
                    .frame(minHeight: Theme.tapSize)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Würfel \(i + 1): \(values[i].map(String.init) ?? "leer")")
            .accessibilityAddTraits(active == i ? .isSelected : [])
        } else {
            DieView(value: dice[i], state: .held, size: 54)
                .accessibilityElement()
                .accessibilityLabel("Würfel \(i + 1): \(dice[i]), gehalten")
        }
    }

    /// Augen aus dem Foto in die freien Plätze legen; was nicht stimmt, korrigiert man mit den Zifferntasten.
    private func uebernehmen(_ augen: [Int], bilder: [Data] = []) {
        let gehalten = (0..<5).filter { held.contains($0) && !dice.isEmpty }.map { dice[$0] }
        if !augen.isEmpty { hilfeGenutzt = true }
        let stellen = WuerfelZuordnung.zuordnenMitPosition(erkannt: augen, gehalten: gehalten, plaetze: slots.count)
        let passend = stellen.map { augen[$0] }
        values = Array(repeating: nil, count: 5)
        ausschnitte = [:]; erkanntVomScanner = [:]
        for (platz, stelle) in zip(slots, stellen) {
            values[platz] = augen[stelle]
            if bilder.count == augen.count { ausschnitte[platz] = bilder[stelle]; erkanntVomScanner[platz] = augen[stelle] }
        }
        active = slots.first(where: { values[$0] == nil }) ?? slots.first ?? 0
        if passend.isEmpty {
            kameraHinweis = String(localized: "Keine Würfel erkannt. Lege sie einzeln auf eine einfarbige Fläche, fotografiere von oben und versuche es noch einmal, oder tippe die Augen ein.")
        } else if passend.count < slots.count {
            kameraHinweis = String(localized: "Nicht alle Würfel erkannt. Ergänze die fehlenden mit den Zifferntasten.")
        } else {
            kameraHinweis = String(localized: "Bitte prüfe die Augen, bevor du den Wurf übernimmst.")
        }
    }

    // MARK: Ansage

    private func ansagen() {
        kameraHinweis = nil
        // Nur die leeren Plätze werden angesagt; was schon steht, bleibt.
        ansagePlaetze = slots.filter { values[$0] == nil }
        guard !ansagePlaetze.isEmpty else { return }
        Task {
            await hoerer.starten(hoechstens: ansagePlaetze.count)
            switch hoerer.zustand {
            case .verweigert: kameraHinweis = String(localized: "Kein Zugriff auf Mikrofon oder Spracherkennung. Erlaube beides in den iOS-Einstellungen unter Partie.")
            case .nichtVerfuegbar: kameraHinweis = String(localized: "Die Ansage ist auf diesem Gerät gerade nicht verfügbar. Tippe die Augen ein.")
            default: break
            }
        }
    }

    /// Verstandene Augen der Reihe nach in die freien Plätze legen (schon während des Sprechens).
    private func angesagt(_ augen: [Int]) {
        guard hoerer.zustand == .hoert || hoerer.beendet, !augen.isEmpty else { return }
        hilfeGenutzt = true
        for (i, platz) in ansagePlaetze.enumerated() { values[platz] = i < augen.count ? augen[i] : nil }
        active = slots.first(where: { values[$0] == nil }) ?? slots.last ?? 0
        tipps += 1
    }

    private func ansageBeendet() {
        let n = hoerer.augen.count
        if n == 0 {
            kameraHinweis = String(localized: "Nichts verstanden. Sag die Augen einzeln und deutlich, oder tippe sie ein.")
        } else if n < ansagePlaetze.count {
            kameraHinweis = String(localized: "Nicht alle Würfel verstanden. Ergänze die fehlenden mit den Zifferntasten.")
        } else {
            kameraHinweis = String(localized: "Bitte prüfe die Augen, bevor du den Wurf übernimmst.")
        }
    }

    private func enter(_ n: Int) {
        tipps += 1
        values[active] = n
        if let next = slots.first(where: { values[$0] == nil }) { active = next }
    }

    private func back() {
        if values[active] == nil, let last = slots.last(where: { values[$0] != nil }) { active = last }
        values[active] = nil
    }
}
