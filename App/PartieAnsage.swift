// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern
import SpielMauMau

/// KI-N (Blatt 18 „Neue Partie sagen“): Aus einem Satz wie „Mau-Mau zu dritt mit sieben Karten“ wird im Blatt „Spiel suchen“ ein Vorschlag
/// mit Spiel, Spielerzahl und Regeln. Gesetzt wird erst nach „Übernehmen“; die Partie startet erst mit „Spielen“ auf der Spielseite.
/// Die Regeln stellt die Varianten-Ansage aus KI-5/KI-6 ein (zuerst nur Mau-Mau), die Spielerzahl liest die App selbst aus dem Satz.
struct PartieVorschlag: Identifiable {
    let modul: any SpielModul
    /// Beim Anlegen gemerkt: `modul.id` ist an den Hauptakteur gebunden, `Identifiable.id` nicht.
    let id: String
    /// Neue Spielerzahl (nur im Bereich des Spiels), sonst `nil`.
    let spieler: Int?
    let regeln: VariantenVorschlag?
    /// Genannt, aber nicht einstellbar (Spielerzahl außerhalb des Bereichs, Option, die das Spiel nicht hat).
    let unbekannt: [String]
    /// Der Satz nennt noch mehr, das sich in diesem Spiel nicht ansagen lässt (Spiel ohne Varianten-Ansage).
    let nichtAnsagbar: Bool

    var hatAenderung: Bool { spieler != nil || !(regeln?.aenderungen.isEmpty ?? true) }
    var schonSo: Bool { !hatAenderung && unbekannt.isEmpty && !nichtAnsagbar && (regeln?.schonSo ?? 0) > 0 }
}

@MainActor
enum PartieAnsage {
    /// Spiele, deren Regeln sich ansagen lassen. KI-7 trägt hier die weiteren Spiele ein.
    static func varianten(fuer id: String) -> (any SpielVarianten)? {
        id == MauMauModul.kennung ? MauMauVarianten.fuerStart() : nil
    }

    // MARK: Spielerzahl aus dem Satz

    private static let zahlwoerter: [String: Int] = ["zwei": 2, "drei": 3, "vier": 4, "fünf": 5, "sechs": 6, "sieben": 7, "acht": 8, "neun": 9, "zehn": 10]
    private static let ordinal: [String: Int] = ["zweit": 2, "dritt": 3, "viert": 4, "fünft": 5, "sechst": 6, "siebt": 7, "acht": 8, "neunt": 9, "zehnt": 10]

    /// „zu dritt“, „zu viert“, „mit drei Spielern“, „für 4 Personen“, „3 Leute“ → Zahl und die genannte Wendung.
    static func spielerzahl(in text: String) -> (zahl: Int, wort: String)? {
        let t = text.lowercased()
        let muster: [String] = [
            #"\bzu (zweit|dritt|viert|fünft|sechst|siebt|acht|neunt|zehnt)\b"#,
            #"\b(\d{1,2}|zwei|drei|vier|fünf|sechs|sieben|acht|neun|zehn) (?:mit)?spieler(?:n|innen)?\b"#,
            #"\b(\d{1,2}|zwei|drei|vier|fünf|sechs|sieben|acht|neun|zehn) (?:personen|leute|leuten|menschen)\b"#,
        ]
        for m in muster {
            guard let re = try? NSRegularExpression(pattern: m),
                  let treffer = re.firstMatch(in: t, range: NSRange(t.startIndex..., in: t)),
                  let ganz = Range(treffer.range, in: t), let g1 = Range(treffer.range(at: 1), in: t) else { continue }
            let w = String(t[g1])
            let zahl = Int(w) ?? ordinal[w] ?? zahlwoerter[w]
            if let zahl { return (zahl, String(t[ganz])) }
        }
        return nil
    }

    private static let fuellwoerter: Set<String> = ["ich", "wir", "will", "wollen", "möchte", "möchten", "spielen", "spiel", "mit", "und", "zu", "für", "bitte", "eine", "ein", "partie", "runde", "neue", "neues", "gern", "gerne", "mal", "heute", "dem", "der", "die", "das", "den", "im", "in", "auf", "als", "von", "dritt", "viert", "zweit", "fünft", "sechst", "spielern", "spieler", "personen", "leuten", "leute"]

    /// Wörter des Satzes, die weder Spielname noch Spielerzahl noch Füllwort sind.
    static func uebrig(_ text: String, modul: any SpielModul, spieler: String?) -> [String] {
        var t = text.lowercased()
        if let spieler { t = t.replacingOccurrences(of: spieler, with: " ") }
        let name = Set(modul.name.lowercased().split { !$0.isLetter && !$0.isNumber }.map(String.init))
        return t.split { !$0.isLetter && !$0.isNumber }.map(String.init)
            .filter { !name.contains($0) && !fuellwoerter.contains($0) && !zahlwoerter.keys.contains($0) && Int($0) == nil }
    }

    // MARK: Vorschlag

    /// Vorschlag zum besten Treffer der Suche, oder `nil`, wenn der Satz nur ein Spiel nennt (dann bleibt alles wie heute).
    static func vorschlag(_ text: String, modul: any SpielModul) async -> PartieVorschlag? {
        var unbekannt: [String] = []
        var zahl: Int?
        let genannt = spielerzahl(in: text)
        if let g = genannt {
            if modul.spielerzahl.upperBound > 1, modul.spielerzahl.contains(g.zahl) { zahl = g.zahl } else { unbekannt.append(g.wort) }
        }
        var regeln: VariantenVorschlag?
        var nichtAnsagbar = false
        if let v = varianten(fuer: modul.id) {
            if let ansage = AnsageQuelle.laden().ansage, let r = try? await ansage.ansagen(text, fuer: v) {
                regeln = r; unbekannt += r.verworfen.map(\.name)
            }
        } else {
            nichtAnsagbar = uebrig(text, modul: modul, spieler: genannt?.wort).count >= 2
        }
        let v = PartieVorschlag(modul: modul, id: modul.id, spieler: zahl, regeln: regeln, unbekannt: unbekannt, nichtAnsagbar: nichtAnsagbar)
        return v.hatAenderung || !unbekannt.isEmpty || nichtAnsagbar || v.schonSo ? v : nil
    }

    /// „Übernehmen“: merkt die Spielerzahl für die Spielseite vor und setzt die Regeln. Startet nichts.
    static func uebernehmen(_ v: PartieVorschlag) {
        if let n = v.spieler { SpielerVormerkung.merken(n, fuer: v.modul.id) }
        if let r = v.regeln, let ziel = varianten(fuer: v.modul.id) { r.uebernehmen(in: ziel) }
    }
}

/// Abschnitt „DAS STELLE ICH EIN“ im Blatt „Spiel suchen“ (Blatt 18): Spielname mit Spielart-Punkt, Änderungen, „Übernehmen“ und „Verwerfen“.
struct PartieVorschlagAbschnitt: View {
    let vorschlag: PartieVorschlag
    let uebernehmen: () -> Void
    let verwerfen: () -> Void

    private var m: any SpielModul { vorschlag.modul }
    private var schema: VariantenSchema? { PartieAnsage.varianten(fuer: m.id)?.schema }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Das stelle ich ein").font(.caption.weight(.semibold)).textCase(.uppercase).foregroundStyle(.secondary)
            Divider()
            HStack(spacing: 10) {
                Circle().fill(m.gattung.farbe.color).frame(width: 10, height: 10).accessibilityHidden(true)
                Text(verbatim: m.name).font(.system(size: 25, weight: .bold, design: .serif))
            }
            if let n = vorschlag.spieler {
                AnsageAenderungZeile(titel: "Spieler", neu: LocalizedStringKey(String(n)), hoehe: 47)
                Divider()
            }
            if let r = vorschlag.regeln {
                ForEach(r.aenderungen) { a in
                    AnsageAenderungZeile(aenderung: a, option: schema?.option(a.optionID), hoehe: 47)
                    Divider()
                }
            }
            if vorschlag.schonSo { Text("Das ist schon so eingestellt.").font(.subheadline) }
            if vorschlag.hatAenderung { Text("Alles andere bleibt, wie es eingestellt ist.").font(.footnote).foregroundStyle(.secondary) }
            if !vorschlag.unbekannt.isEmpty || vorschlag.nichtAnsagbar {
                Text("Das kenne ich nicht").font(.caption.weight(.semibold)).textCase(.uppercase).foregroundStyle(.secondary).padding(.top, 6)
                Divider()
                ForEach(vorschlag.unbekannt, id: \.self) { w in
                    Text("„\(w)“ gibt es in \(m.name) hier nicht. Alles andere bleibt, wie es eingestellt ist.").font(.footnote).foregroundStyle(.secondary)
                }
                if vorschlag.nichtAnsagbar {
                    Text("Regeln lassen sich in \(m.name) noch nicht ansagen. Alles andere bleibt, wie es eingestellt ist.").font(.footnote).foregroundStyle(.secondary)
                }
            }
            if vorschlag.hatAenderung {
                Button("Übernehmen", action: uebernehmen).buttonStyle(HauptKnopfStil()).padding(.top, 6)
                Button("Verwerfen", action: verwerfen).zweitKnopf()
            } else {
                Button("Schließen", action: verwerfen).zweitKnopf().padding(.top, 6)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
