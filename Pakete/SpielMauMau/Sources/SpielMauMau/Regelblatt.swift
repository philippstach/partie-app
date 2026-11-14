// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import MauMauKern

/// Gemerkte Hausregeln (frei kombinierbar), geladen beim Start einer Partie.
enum RegelSpeicher {
    static let schluessel = "partie.regeln.maumau-neu"
    static var gespeichert: NRegeln {
        guard let d = UserDefaults.standard.data(forKey: schluessel), let r = try? JSONDecoder().decode(NRegeln.self, from: d) else { return .standard }
        return r
    }
    static func sichern(_ r: NRegeln) {
        if let d = try? JSONEncoder().encode(r) { UserDefaults.standard.set(d, forKey: schluessel) }
    }
}

/// KI-3 („Frag nach den Regeln“): die eingestellten Hausregeln als kurzer Text für den Regel-Chat.
/// Der Chat nennt nur Regeln und Zahlen, die in diesem Text oder im Regelwissen stehen.
public enum MauMauRegelAuskunft {
    /// Die zuletzt gespeicherten Hausregeln (wie sie beim Start der nächsten Partie geladen werden).
    public static func aktiveRegeln() -> String { beschreibung(RegelSpeicher.gespeichert) }

    public static func beschreibung(_ r: NRegeln) -> String {
        func ja(_ b: Bool) -> String { b ? "an" : "aus" }
        let aussetzen: String
        switch r.aussetzen {
        case .keine: aussetzen = "keine Karte"
        case .acht: aussetzen = "die 8"
        case .ass: aussetzen = "das Ass"
        }
        var zeilen = [
            "Karten auf der Hand: \(r.startkarten).",
            // T-7: Die Kurzfassung nannte nur „an“; auf „7 auf eine 7?“ fehlte dem Modell die Kernaussage (Kontern ist Teil von „7 lässt ziehen“, es gibt keinen eigenen Schalter).
            r.siebenZiehen
                ? "7 lässt ziehen: an. Wer eine 7 legt, lässt den Nächsten 2 Karten ziehen. Der Nächste darf mit einer eigenen 7 kontern (7 auf eine 7 ist erlaubt), dann muss der Übernächste 4 ziehen, danach 6 und so weiter. Auf eine offene 7 darf nur eine 7 gelegt werden, auch kein Bube. Wer keine 7 hat, zieht alle Karten auf einmal."
                : "7 lässt ziehen: aus. Die 7 ist eine normale Karte, es gibt kein Kontern.",
            "Aussetzen: \(aussetzen).",
            "Bube als letzte Karte: \(ja(r.bubeAlsSchluss)).",
            "Bube auf Bube: \(ja(r.bubeAufBube)).",
            "9 wechselt die Richtung: \(ja(r.neunRichtung)).",
            "„Mau“ sagen ist Pflicht: \(ja(r.maueSagen)).",
            "Gezogene Karte gleich legen: \(ja(r.sofortLegen)).",
            "Mehrere Runden mit Punkten: \(ja(r.mehrrunden)).",
        ]
        if r.mehrrunden { zeilen.append("Spielende bei \(r.zielPunkte) Punkten.") }
        return zeilen.joined(separator: " ")
    }
}

/// Regelblatt: Schnellwahl (Vorlagen) und jeder Schalter einzeln. Gilt nur vor dem ersten Zug.
struct RegelBlatt: View {
    @Binding var regeln: NRegeln
    let aenderbar: Bool
    let spieler: Int
    @Environment(\.dismiss) private var schliessen
    /// KI-6 (Blatt 13): Ansage nur mit Apple Intelligence; sonst bleibt das Blatt wie vorher.
    @State private var ansage = AnsageQuelle.laden()

    private let vorlagen: [(LocalizedStringKey, NRegeln)] = [
        ("Standard (7 zieht, 8 setzt aus)", .standard), ("Ass setzt aus", .ass), ("Sieben Karten auf die Hand", .sieben),
        ("Schlicht (ohne 7 und 8)", .schlicht), ("Streng (Bube nicht zuletzt)", .streng), ("Wild (9 dreht, Mau, sofort legen)", .wild),
    ]

    var body: some View {
        NavigationStack {
            Form {
                if let a = ansage.ansage {
                    Section {
                        AnsageFeld(spiel: { MauMauVarianten(regeln: regeln, aenderbar: { aenderbar }) { regeln = $0 } }, ansage: a, aenderbar: aenderbar, imFormular: true)
                            .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0)).listRowBackground(Color.clear)
                        if !aenderbar { Text("Die Regeln lassen sich nur vor dem ersten Zug ändern.").font(.system(size: 13.5)).foregroundStyle(.secondary).listRowBackground(Color.clear) }
                    }
                } else {
                    if !aenderbar { Section { Text("Die Regeln lassen sich nur vor dem ersten Zug ändern.").foregroundStyle(.secondary) } }
                    if ansage.status == .nichtBereit { Section { Text("Apple Intelligence lädt noch. Dann kannst du die Regeln ansagen.").font(.footnote).foregroundStyle(.secondary) } }
                    if ansage.status == .aus { Section { Text("Schalte Apple Intelligence in den Einstellungen ein, dann kannst du die Regeln ansagen.").font(.footnote).foregroundStyle(.secondary) } }
                }
                Section("Schnellwahl") {
                    ForEach(vorlagen.indices, id: \.self) { i in
                        Button { var r = vorlagen[i].1; r.mehrrunden = regeln.mehrrunden; r.zielPunkte = regeln.zielPunkte; regeln = r } label: { Text(vorlagen[i].0).foregroundStyle(.primary) }
                    }
                }.disabled(!aenderbar)
                Section("Karten und Sonderkarten") {
                    Picker("Karten auf der Hand", selection: $regeln.startkarten) { ForEach(5...7, id: \.self) { Text(verbatim: "\($0)").tag($0) } }
                    Toggle("7 lässt ziehen (stapelbar)", isOn: $regeln.siebenZiehen)
                    Picker("Aussetzen", selection: $regeln.aussetzen) {
                        Text("Mit der 8").tag(Aussetzen.acht); Text("Mit dem Ass").tag(Aussetzen.ass); Text("Niemand setzt aus").tag(Aussetzen.keine)
                    }
                    Toggle("Bube darf die letzte Karte sein", isOn: $regeln.bubeAlsSchluss)
                    Toggle("Bube auf Bube erlaubt", isOn: $regeln.bubeAufBube)
                }.disabled(!aenderbar)
                Section("Weitere Hausregeln") {
                    Toggle("9 wechselt die Richtung (ab drei Personen)", isOn: $regeln.neunRichtung)
                    Toggle("„Mau“ sagen (sonst Strafkarte)", isOn: $regeln.maueSagen)
                    Toggle("Gezogene Karte gleich legen", isOn: $regeln.sofortLegen)
                }.disabled(!aenderbar)
                Section("Runden") {
                    Toggle("Mehrere Runden mit Punkten", isOn: $regeln.mehrrunden)
                    if regeln.mehrrunden {
                        Picker("Spielende bei", selection: $regeln.zielPunkte) { ForEach([50, 100, 150], id: \.self) { Text("\($0) Punkten").tag($0) } }
                        Text("Wer die Runde gewinnt, bekommt nichts; die anderen die Augen ihrer Restkarten (Bube 20, Ass 11, Dame und König 10, Zahlen ihre Augen). Wer zuerst die Zielsumme erreicht, verliert.").font(.footnote).foregroundStyle(.secondary)
                    }
                }.disabled(!aenderbar)
                if spieler >= 5 { Section { Text("Ab fünf Personen wird mit zwei Blättern gespielt (64 Karten).").font(.footnote).foregroundStyle(.secondary) } }
            }
            .navigationTitle("Hausregeln")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Fertig") { schliessen() } } }
        }
    }
}
/// 1.0 (M1): Hausregeln schon im Blatt „Neues Spiel“. Zeigt die gemerkten Regeln kurz und öffnet das Regelblatt.
/// Der Punkt „Hausregeln“ im Menü der laufenden Partie bleibt (vor dem ersten Zug änderbar).
struct MauMauOptionen: View {
    let eintraege: [SpielerEintrag]
    @State private var regeln = RegelSpeicher.gespeichert
    @State private var blatt = false

    private var zusammenfassung: String {
        var teile: [String] = []
        teile.append(String(localized: "\(regeln.startkarten) Karten"))
        if regeln.siebenZiehen { teile.append(String(localized: "7 zieht")) }
        switch regeln.aussetzen {
        case .acht: teile.append(String(localized: "8 setzt aus"))
        case .ass: teile.append(String(localized: "Ass setzt aus"))
        case .keine: break
        }
        if regeln.neunRichtung { teile.append(String(localized: "9 dreht")) }
        if regeln.maueSagen { teile.append(String(localized: "Mau sagen")) }
        if regeln.sofortLegen { teile.append(String(localized: "sofort legen")) }
        if regeln.mehrrunden { teile.append(String(localized: "Runden bis \(regeln.zielPunkte)")) }
        return teile.joined(separator: " · ")
    }

    /// KI-6 (Blatt 13): Feld „Sag, wie ihr spielen wollt“ über der Karte „Hausregeln“, nur mit Apple Intelligence.
    @State private var ansage = AnsageQuelle.laden()

    var body: some View {
        VStack(spacing: 18) {   // Blatt 13: Feld 18 pt über der Zeile „Hausregeln“
            if let a = ansage.ansage {
                AnsageFeld(spiel: { MauMauVarianten(regeln: regeln) { regeln = $0 } }, ansage: a, aenderbar: true).padding(.top, 6)
            }
            hausregeln
            MauMauBeginnKarte(eintraege: eintraege)   // T-097: Wer beginnt
            if ansage.ansage == nil, ansage.status == .nichtBereit {
                Text("Apple Intelligence lädt noch. Dann kannst du die Regeln ansagen.").font(.footnote).foregroundStyle(.secondary)
            } else if ansage.ansage == nil, ansage.status == .aus {
                Text("Schalte Apple Intelligence in den Einstellungen ein, dann kannst du die Regeln ansagen.").font(.footnote).foregroundStyle(.secondary)
            }
        }
    }

    private var hausregeln: some View {
        Button { blatt = true } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Hausregeln", systemImage: "slider.horizontal.3").font(.headline).foregroundStyle(Color.accentText)
                    Text(verbatim: zusammenfassung).font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .card()
        .accessibilityHint(Text("Öffnet die Hausregeln"))
        .sheet(isPresented: $blatt) {
            RegelBlatt(regeln: $regeln, aenderbar: true, spieler: max(2, eintraege.count)).presentationDetents([.large])
        }
        .onChange(of: regeln) { _, neu in RegelSpeicher.sichern(neu) }
        .onAppear { regeln = RegelSpeicher.gespeichert }
    }
}
#endif
