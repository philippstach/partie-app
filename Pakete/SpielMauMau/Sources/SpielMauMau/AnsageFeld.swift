// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import SpieleKern
import MauMauKern

/// KI-6 (Blatt 13 „Sag, wie ihr spielen wollt“): Eingabefeld und Bestätigung für die Varianten-Ansage.
/// Die App stellt nie still etwas um: Erst die Liste „Das stelle ich ein“, dann „Übernehmen“ oder „Verwerfen“.
/// Das Feld erscheint nur, wenn Apple Intelligence bereit ist (iOS 26, Gerät, Sprache). Sonst sieht alles aus wie vorher.
/// Allgemein gehalten (`SpielVarianten`), damit KI-7 es für weitere Spiele nach SpieleKern heben kann.

/// Wo die Ansage herkommt: das Apple-Modell, im Simulator ohne Modell eine Attrappe.
public enum AnsageQuelle {
    public static func laden() -> (status: VariantenStatus, ansage: VariantenAnsage?) {
        let status = VariantenStatus.aktuell()
        #if targetEnvironment(simulator)
        if status != .bereit { return (.bereit, VariantenAnsage(modell: AnsageAttrappe())) }
        #endif
        #if canImport(FoundationModels)
        if status == .bereit, let a = VariantenAnsage.apple() { return (.bereit, a) }
        #endif
        return (status == .bereit ? .verborgen : status, nil)
    }
}

/// Nur für den Simulator: erkennt ein paar Stichwörter, damit sich der Ablauf ohne Modell prüfen lässt.
struct AnsageAttrappe: VariantenModell {
    func waehle(anweisung: String, eingabe: String) async throws -> VariantenRohAntwort {
        let t = eingabe.lowercased()
        var vorlage: String?
        var a: [VariantenRohAntwort.Eintrag] = []
        if t.contains("wild") { vorlage = "wild" }
        if t.contains("schlicht") { vorlage = "schlicht" }
        if t.contains("streng") { vorlage = "streng" }
        if t.contains("sieben karten") || t.contains("7 karten") { a.append(.init(option: "start_karten", wert: "7")) }
        if t.contains("ass") { a.append(.init(option: "aussetzen", wert: "ass")) }
        if t.contains("neun") || t.contains("9 dreht") { a.append(.init(option: "neun_richtung", wert: "an")) }
        if t.contains("sieben zieh") || t.contains("7 zieh") { a.append(.init(option: "sieben_ziehen", wert: "an")) }
        if t.contains("joker") { a.append(.init(option: "mit Joker", wert: "an")) }
        return VariantenRohAntwort(vorlage: vorlage, aenderungen: a)
    }
}

extension VariantenWert {
    func anzeige(fuer option: VariantenOption?) -> LocalizedStringKey {
        switch self {
        case .an(let b): return b ? "an" : "aus"
        case .zahl(let n): return LocalizedStringKey(String(n))
        case .auswahl(let id):
            if case .auswahl(let e)? = option?.art, let t = e.first(where: { $0.id == id })?.titel { return LocalizedStringKey(t) }
            return LocalizedStringKey(id)
        }
    }
}

struct AnsageFeld<V: SpielVarianten>: View {
    /// Frischer Adapter mit dem heutigen Stand der Regeln (wird bei Ansage und Übernehmen neu gebildet).
    let spiel: () -> V
    let ansage: VariantenAnsage
    let aenderbar: Bool
    /// Im grauen Formular „Hausregeln“ ist die Füllung weiß wie die Zeilen dort; auf der Spielseite Papier (0xEFEEE9).
    var imFormular = false

    @State private var text = ""
    @State private var laeuft = false
    @State private var vorschlag: VariantenVorschlag?
    @State private var gesagt = ""
    @State private var meldung: LocalizedStringKey?
    @FocusState private var fokus: Bool

    private var fuellung: Color {
        if imFormular { return Color(.secondarySystemGroupedBackground) }
        return Color(UIColor { $0.userInterfaceStyle == .dark ? .secondarySystemFill : UIColor(red: 0xEF / 255, green: 0xEE / 255, blue: 0xE9 / 255, alpha: 1) })
    }
    private var kannSenden: Bool { aenderbar && !laeuft && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "pencil").font(.system(size: 20)).frame(width: 24).foregroundStyle(.secondary).accessibilityHidden(true)
                TextField("Sag, wie ihr spielen wollt", text: $text)
                    .font(.system(size: 16.5))
                    .focused($fokus)
                    .submitLabel(.send)
                    .onSubmit { senden() }
                    .disabled(!aenderbar)
                Button { senden() } label: {
                    ZStack {
                        Circle().fill(kannSenden ? Color.primary : Color.secondary.opacity(0.35))
                        if laeuft { ProgressView().controlSize(.small).tint(Color(.systemBackground)) }
                        else { Image(systemName: "arrow.up").font(.caption.weight(.bold)).foregroundStyle(Color(.systemBackground)) }
                    }
                    .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
                .disabled(!kannSenden)
                .accessibilityLabel(Text("Ansage senden"))
            }
            .padding(.leading, 16).padding(.trailing, 8).frame(height: 52)
            .background(Capsule().fill(fuellung))
            .opacity(aenderbar ? 1 : 0.5)
            if let meldung { Text(meldung).font(.footnote).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true) }
        }
        .sheet(item: $vorschlag) { v in
            AnsageBestaetigung(vorschlag: v, gesagt: gesagt, spielName: spiel().schema.spielName, schema: spiel().schema,
                               uebernehmen: {
                                   v.uebernehmen(in: spiel())
                                   text = ""; meldung = nil; vorschlag = nil
                               },
                               verwerfen: { vorschlag = nil })
            .presentationDetents([.medium, .large])
        }
    }

    private func senden() {
        guard kannSenden else { return }
        let satz = text.trimmingCharacters(in: .whitespacesAndNewlines)
        fokus = false; laeuft = true; meldung = nil
        Task {
            defer { laeuft = false }
            do {
                let v = try await ansage.ansagen(satz, fuer: spiel())
                if v.istLeer && v.verworfen.isEmpty && v.schonSo == 0 {
                    meldung = "Das habe ich nicht verstanden. Sag es zum Beispiel so: „Mit sieben Karten, das Ass setzt aus.“"
                } else { gesagt = satz; vorschlag = v }   // auch „schon so eingestellt“ und „kenne ich nicht“ als Blatt (Blatt 13)
            } catch VariantenFehler.nichtAenderbar {
                meldung = "Die Regeln lassen sich nur vor dem ersten Zug ändern."
            } catch {
                meldung = "Das hat gerade nicht geklappt. Versuch es noch einmal."
            }
        }
    }
}

extension VariantenVorschlag: Identifiable {
    public var id: String { spielID + "|" + aenderungen.map { "\($0.optionID)=\($0.neu)" }.joined(separator: ",") + "|\(verworfen.count)" }
}

/// Eine Zeile „Name … alt (durchgestrichen) → neu (fett)“ der Bestätigung. Auch für „Neue Partie sagen“ (Blatt 18), dort bei der Spielerzahl ohne alten Wert.
public struct AnsageAenderungZeile: View {
    let titel: LocalizedStringKey
    let alt: LocalizedStringKey?
    let neu: LocalizedStringKey
    let hoehe: CGFloat

    public init(aenderung: VariantenAenderung, option: VariantenOption?, hoehe: CGFloat = 51) {
        titel = LocalizedStringKey(aenderung.titel); alt = aenderung.alt.anzeige(fuer: option); neu = aenderung.neu.anzeige(fuer: option); self.hoehe = hoehe
    }
    public init(titel: LocalizedStringKey, neu: LocalizedStringKey, hoehe: CGFloat = 51) {
        self.titel = titel; alt = nil; self.neu = neu; self.hoehe = hoehe
    }

    public var body: some View {
        HStack(spacing: 8) {
            Text(titel).font(.subheadline)
            Spacer(minLength: 8)
            if let alt {
                Text(alt).font(.footnote).foregroundStyle(.secondary).strikethrough()
                Image(systemName: "arrow.right").font(.caption2).foregroundStyle(.secondary).accessibilityHidden(true)
            }
            Text(neu).font(.subheadline.weight(.semibold))
        }
        .frame(minHeight: hoehe)
        .accessibilityElement(children: .combine)
    }
}

public extension MauMauVarianten {
    /// Mau-Mau mit den gemerkten Hausregeln (wie `MauMauOptionen`); Änderungen werden gesichert und gelten beim nächsten Start. Für „Neue Partie sagen“ (Blatt 18).
    static func fuerStart() -> MauMauVarianten {
        MauMauVarianten(regeln: RegelSpeicher.gespeichert) { RegelSpeicher.sichern($0) }
    }
}

/// Bestätigungsblatt „Das stelle ich ein“ (Blatt 13, Entwurf k13c): oben der Satz, darunter jede Änderung mit alt und neu, dann was die App nicht kennt.
struct AnsageBestaetigung: View {
    let vorschlag: VariantenVorschlag
    let gesagt: String
    let spielName: String
    let schema: VariantenSchema
    let uebernehmen: () -> Void
    let verwerfen: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Text("Das stelle ich ein").font(.system(.headline, design: .serif))
                HStack { Spacer(); Button(action: verwerfen) {
                    Image(systemName: "xmark").font(.footnote.weight(.bold)).foregroundStyle(.primary)
                        .frame(width: 32, height: 32).background(Circle().fill(Color(.secondarySystemFill)))
                }.buttonStyle(.plain).accessibilityLabel(Text("Schließen")) }
            }
            .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 12)
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(verbatim: "„\(gesagt)“").font(.system(size: 17.5, design: .serif).italic()).foregroundStyle(.secondary)
                    if !vorschlag.aenderungen.isEmpty {
                        abschnitt("Das ändert sich") {
                            ForEach(vorschlag.aenderungen) { a in
                                AnsageAenderungZeile(aenderung: a, option: schema.option(a.optionID))
                                Divider()
                            }
                        }
                    }
                    if vorschlag.istLeer && vorschlag.verworfen.isEmpty {
                        Text("Das ist schon so eingestellt.").font(.subheadline)
                    }
                    if !vorschlag.verworfen.isEmpty {
                        abschnitt("Das kenne ich nicht") {
                            ForEach(Array(vorschlag.verworfen.enumerated()), id: \.offset) { _, v in
                                Text("„\(v.name)“ gibt es in \(spielName) hier nicht. Alles andere bleibt, wie es eingestellt ist.").font(.footnote).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20).padding(.bottom, 12)
            }
            VStack(spacing: 10) {
                if vorschlag.aenderungen.isEmpty {
                    Button(action: verwerfen) {
                        Text("Schließen").font(.subheadline.weight(.semibold)).foregroundStyle(Color(.systemBackground))
                            .frame(maxWidth: .infinity, minHeight: 54).background(Capsule().fill(Color.primary))
                    }.buttonStyle(.plain)
                } else {
                    Button(action: uebernehmen) {
                        Text("Übernehmen").font(.subheadline.weight(.semibold)).foregroundStyle(Color(.systemBackground))
                            .frame(maxWidth: .infinity, minHeight: 54).background(Capsule().fill(Color.primary))
                    }.buttonStyle(.plain)
                    Button(action: verwerfen) {
                        Text("Verwerfen").font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, minHeight: 50).overlay(Capsule().strokeBorder(Color.primary.opacity(0.7), lineWidth: 1))
                    }.buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20).padding(.bottom, 20).padding(.top, 8)
        }
    }

    @ViewBuilder private func abschnitt<I: View>(_ titel: LocalizedStringKey, @ViewBuilder _ inhalt: () -> I) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(titel).font(.caption.weight(.semibold)).textCase(.uppercase).foregroundStyle(.secondary)
            Divider()
            inhalt()
        }
    }
}
#endif
