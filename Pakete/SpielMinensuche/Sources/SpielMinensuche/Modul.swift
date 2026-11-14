// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import Baukasten
import SpieleKern
import MinensucheKern

/// Einstellungen des Spiels, in UserDefaults.
enum Einstellung {
    static let fair = "fair"
    /// Wahl im Neues-Spiel-Blatt: 0 bis 2 = Stufe (leicht, mittel, schwer), 3 = Tagesrätsel
    static let wahl = "minensuche.wahl"
    static let teilen = "minensuche.teilen"
    /// 1.0 (M3): Haltedauer für langes Drücken: 0 = kurz (0,2 s), 1 = normal (0,3 s), 2 = lang (0,5 s)
    static let haltedauer = "minensuche.haltedauer"
    static func haltesekunden(_ wahl: Int) -> Double {
        switch wahl { case 0: 0.2; case 2: 0.5; default: 0.3 }
    }
}

#if canImport(UIKit)
/// Minensuche im `SpielRahmen`: Start, Spielregeln, Statistik, Neues-Spiel-Blatt, Fortsetzen und Ende kommen vom Rahmen.
/// Hier liegen nur Brett, Stufen, Tagesrätsel, Leiter und geteilte Rätsel.
@MainActor
public struct MinensucheModul: SpielModul {
    public init() {}
    public let id = "minensuche"
    public let name = "Minensuche"
    public let gattung = Gattung.raetsel
    public let farbe = AkzentFarbeWert.schiefer
    public let symbol = "flag.fill"
    public let spielerzahl = 1...1
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(
            SpielRahmen(id: id, name: name, untertitel: "Finde jede Mine – ohne zu raten.", farbe: farbe, spieler: 1...1,
                        regeln: "Decke alle Felder auf, unter denen keine Mine liegt. Eine Mine aufzudecken beendet die Partie. Eine Zahl sagt, wie viele der acht Nachbarfelder eine Mine enthalten, eine leere Fläche öffnet ihre Umgebung von selbst. Tippen deckt auf, lang drücken setzt eine Fahne, mit dem Fahnen-Knopf vertauschst du beides. Hast du rund um eine aufgedeckte Zahl genau so viele Fahnen gesetzt, wie sie angibt, öffnet ein Tipp darauf alle übrigen Nachbarn. Jedes Brett lässt sich allein durch Nachdenken lösen, der erste Zug ist immer sicher; das kannst du vor dem Start ausschalten. Der Hinweis deckt ein sicheres Feld auf und kostet 10 Sekunden Strafzeit. Eine Partie mit Hinweis zählt nicht als Bestzeit. Nach einer Mine kannst du einmal je Partie den letzten Zug zurücknehmen; das kostet 30 Sekunden, und eine so gewonnene Partie zählt nicht als Bestzeit. Sind alle Minen richtig mit einer Fahne markiert, öffnet sich der Rest des Bretts von selbst. Wie lange du für die Fahne drücken musst, stellst du vor dem Start ein. Jeden Tag gibt es ein Tagesrätsel, das für alle gleich ist; an aufeinanderfolgenden Tagen gelöst ergibt es eine Serie.",
                        umgebung: umgebung) { teilnehmer, ende, abbrechen in
                MinensucheNeuSpiel(name: teilnehmer.first?.name ?? "", ende: ende, abbrechen: abbrechen)
            }
            .mitZiel("Decke alle Felder ohne Mine auf, ohne auf eine Mine zu tippen.")
            .mitAnleitung(Array(MinensucheAnleitung.schritte.dropFirst()))
            .mitStartOptionen { _ in MinensucheOptionen() }
            .mitEndeInhalt { ende, _ in MinensucheEndeInhalt(ende: ende) }   // R2 (Blatt 8): in Tinte Werte und Feld am Ende
        )
    }
}

/// Karten im Neues-Spiel-Blatt: Stufe oder Tagesrätsel, „Ohne Raten“, Brett per Link teilen.
struct MinensucheOptionen: View {
    @AppStorage(Einstellung.wahl) private var wahl = 0
    @AppStorage(Einstellung.fair) private var fair = true
    @AppStorage(Einstellung.teilen) private var teilen = false
    @AppStorage(Einstellung.haltedauer) private var haltedauer = 1   // 1.0 (M3)
    @State private var statistik = SpielModell.gespeicherteStatistik()
    @Environment(\.designArt) private var art   // zeichnet beim Designwechsel neu

    var body: some View {
        if art == .tinte { tinteBody } else { klassischBody }
    }

    /// Große Tinte-Runde, Punkt 12: Tagesrätsel als Zeile, Stufen als Knöpfe wie im Farbfüller; nichts fällt weg
    private var tinteBody: some View {
        VStack(alignment: .leading, spacing: 14) {
            let heute = SpielModell.tagKennung(.now)
            let gestern = SpielModell.tagKennung(Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now)
            let serie = statistik.aktuelleSerie(heute: heute, gestern: gestern)
            Button { wahl = 3 } label: {
                HStack(spacing: 12) {
                    Image(systemName: wahl == 3 ? "checkmark.circle.fill" : "circle").font(.title2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Tagesrätsel heute").font(.headline)
                        Text(verbatim: statistik.letzterTag == heute ? String(localized: "Heute gelöst · Serie \(serie)")
                             : serie > 0 ? String(localized: "Serie \(serie) · heute noch offen") : String(localized: "Ein Brett für alle – jeden Tag neu"))
                            .font(.footnote).foregroundStyle(Color.schriftZweit)
                    }
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(wahl == 3 ? .isSelected : [])
            Divider().overlay(Color.linie)

            Text("Schwierigkeit").font(.headline)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) { ForEach(Array(Stufe.allCases.enumerated()), id: \.offset) { i, st in stufenKnopf(i, st) } }
                VStack(spacing: 8) { ForEach(Array(Stufe.allCases.enumerated()), id: \.offset) { i, st in stufenKnopf(i, st) } }
            }
            if wahl < 3 {
                let st = Stufe.allCases[min(max(wahl, 0), Stufe.allCases.count - 1)]
                Text(verbatim: st.beschreibung).font(.footnote).foregroundStyle(Color.schriftZweit)
                if let best = statistik.fuer(st).besteZeit {
                    Text("Bestzeit \(SpielModell.zeit(best))").font(.footnote).foregroundStyle(Color.schriftZweit)
                }
            }
            let gesperrt = Stufe.allCases.indices.first(where: { !Leiter.offen("minensuche", stufe: $0) })
            if let g = gesperrt {
                Text("Gesperrt. Gewinne \(Leiter.fehlend("minensuche", stufe: g)) Mal ohne Hinweis auf der Stufe davor.").font(.footnote).foregroundStyle(Color.schriftZweit)
            }

            // 1.0 (M3): Haltedauer für die Fahne, gilt für jede Partie
            Text("Lang drücken").font(.headline)
            Picker("Lang drücken", selection: $haltedauer) {
                Text("Kurz").tag(0)
                Text("Normal").tag(1)
                Text("Lang").tag(2)
            }
            .pickerStyle(.segmented)
            Text("Kurz = 0,2 s, normal = 0,3 s, lang = 0,5 s, bis die Fahne sitzt.").font(.footnote).foregroundStyle(Color.schriftZweit)

            if wahl < 3 {
                Toggle("Ohne Raten lösbar", isOn: $fair)
                Text("Jedes neue Brett lässt sich allein durch Nachdenken lösen. Gilt ab dem nächsten Spiel.").font(.footnote).foregroundStyle(Color.schriftZweit)
                if TeilenFreigabe.erlaubt() {
                    Toggle("Rätsel per Link teilen", isOn: $teilen)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear { statistik = SpielModell.gespeicherteStatistik(); if wahl != 3, !Leiter.offen("minensuche", stufe: min(max(wahl, 0), 2)) { wahl = 0 } }
    }

    private func stufenKnopf(_ i: Int, _ stufe: Stufe) -> some View {
        let offen = Leiter.offen("minensuche", stufe: i)
        let gewaehlt = wahl == i
        return Button { if offen { wahl = i } } label: {
            HStack(spacing: 4) {
                if !offen { Image(systemName: "lock.fill").font(.caption) }
                Text(stufe.name).lineLimit(1).minimumScaleFactor(0.7)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(gewaehlt ? Color.seitenGrund : Color.schrift)
            .frame(maxWidth: .infinity, minHeight: Theme.tapSize)
            .background(Capsule().fill(gewaehlt ? Color.schrift : Color.kartenGrund))
            .overlay(Capsule().strokeBorder(gewaehlt ? Color.clear : Color.linie, lineWidth: 1))
            .opacity(offen ? 1 : 0.8)   // Fund 5: gesperrte Stufen lesbar (vorher 0,55)
            .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .disabled(!offen)
        .accessibilityAddTraits(gewaehlt ? .isSelected : [])
    }

    private var klassischBody: some View {
        VStack(spacing: Theme.kartenAbstand) {
            let heute = SpielModell.tagKennung(.now)
            let gestern = SpielModell.tagKennung(Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now)
            let serie = statistik.aktuelleSerie(heute: heute, gestern: gestern)
            VStack(alignment: .leading, spacing: 6) {
                KartenKopf("Tagesrätsel", zusatz: wahl == 3 ? "✓" : nil)
                Text(verbatim: statistik.letzterTag == heute ? String(localized: "Heute gelöst · Serie \(serie)")
                     : serie > 0 ? String(localized: "Serie \(serie) · heute noch offen") : String(localized: "Ein Brett für alle – jeden Tag neu"))
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            .card()
            .kartenAktion { wahl = 3 }

            ForEach(Array(Stufe.allCases.enumerated()), id: \.offset) { i, stufe in
                let offen = Leiter.offen("minensuche", stufe: i)
                let zusatz: String? = !offen ? "🔒" : (wahl == i ? "✓" : nil)
                VStack(alignment: .leading, spacing: 6) {
                    KartenKopf(stufe.name, zusatz: zusatz)
                    if !offen { Text("Gesperrt. Gewinne \(Leiter.fehlend("minensuche", stufe: i)) Mal ohne Hinweis auf der Stufe davor.").font(.footnote).foregroundStyle(.secondary) }
                    Text(verbatim: stufe.beschreibung).font(.subheadline).foregroundStyle(.secondary)
                    if let best = statistik.fuer(stufe).besteZeit {
                        Text("Bestzeit \(SpielModell.zeit(best))").font(.subheadline).foregroundStyle(Color.accentText)
                    }
                }
                .card()
                .opacity(offen ? 1 : 0.8)   // Fund 5: gesperrte Stufen lesbar (vorher 0,55)
                .kartenAktion { if offen { wahl = i } }
            }

            // 1.0 (M3): Haltedauer für die Fahne, gilt für jede Partie
            VStack(alignment: .leading, spacing: 6) {
                KartenKopf("Lang drücken")
                Picker("Lang drücken", selection: $haltedauer) {
                    Text("Kurz").tag(0)
                    Text("Normal").tag(1)
                    Text("Lang").tag(2)
                }
                .pickerStyle(.segmented)
                Text("Kurz = 0,2 s, normal = 0,3 s, lang = 0,5 s, bis die Fahne sitzt.").font(.footnote).foregroundStyle(.secondary)
            }
            .card()

            if wahl < 3 {
                VStack(alignment: .leading, spacing: 6) {
                    Toggle("Ohne Raten lösbar", isOn: $fair)
                    Text("Jedes neue Brett lässt sich allein durch Nachdenken lösen. Gilt ab dem nächsten Spiel.").font(.footnote).foregroundStyle(.secondary)
                    if TeilenFreigabe.erlaubt() {
                        Toggle("Rätsel per Link teilen", isOn: $teilen)
                    }
                }
                .card()
            }
        }
        .onAppear { statistik = SpielModell.gespeicherteStatistik(); if wahl != 3, !Leiter.offen("minensuche", stufe: min(max(wahl, 0), 2)) { wahl = 0 } }
    }
}

/// Die laufende Partie im Rahmen: baut je nach Wahl ein neues Brett (oder setzt den gespeicherten Stand fort) und meldet das Ende.
struct MinensucheNeuSpiel: View {
    let name: String
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    @State private var modell = SpielModell()
    @State private var gestartet = false
    @State private var gemeldet = false
    @AppStorage(Einstellung.wahl) private var wahl = 0
    @AppStorage(Einstellung.teilen) private var teilen = false

    var body: some View {
        // Nach dem Ende bleibt das Brett stehen: Bei einem Sieg folgt der Ende-Bildschirm von selbst, nach einer Mine erst mit „Weiter“
        // (so lässt sich nachsehen, wo die Minen lagen). Zurück und „Spiel beenden“ führen dann ohne Rückfrage zum Ende-Bildschirm.
        SpielView(abbrechen: { if modell.ergebnis != nil { melden() } else { abbrechen() } }, weiter: melden)
            .environment(modell)
            .onAppear(perform: starten)
            .onChange(of: modell.ergebnis?.id) { _, _ in
                guard modell.ergebnis?.gewonnen == true else { return }
                Task { try? await Task.sleep(for: .milliseconds(900)); melden() }
            }
    }

    /// Fortsetzen (Stand liegt schon im Modell), geteiltes Rätsel von außen, Tagesrätsel oder neues Brett der gewählten Stufe.
    private func starten() {
        guard !gestartet else { return }
        gestartet = true
        if modell.laeuft { return }
        if let l = RaetselPost.abholen(spiel: "minensuche"),
           let s = l.werte["stufe"].flatMap(Stufe.init(rawValue:)), let seed = l.zahl("seed"), seed > 0 {
            modell.geteilt(s, seed: seed)
            return
        }
        if wahl == 3 { modell.tagesraetsel(); return }
        let i = min(max(wahl, 0), Stufe.allCases.count - 1)
        let stufe = Stufe.allCases[Leiter.offen("minensuche", stufe: i) ? i : 0]
        if teilen && TeilenFreigabe.erlaubt() {
            let seed = UInt64.random(in: 1...UInt64(Int32.max))
            let link = RaetselLink(spiel: "minensuche", werte: ["stufe": stufe.rawValue, "seed": String(seed)])
            ErgebnisTeilen.zeigenText(link.teilenText(satz: String(localized: "Minensuche, Stufe \(stufe.nameText): Schaffst du dieses Brett?")))
            modell.geteilt(stufe, seed: seed)
        } else {
            modell.neu(stufe)
        }
    }

    private func melden() {
        guard let e = modell.ergebnis, !gemeldet else { return }
        gemeldet = true
        // 1.0 (M3): nach der zweiten Chance keine Bestzeit
        let rekord: String? = e.neuerRekord ? String(localized: "Neue Bestzeit in „\(e.stufe.nameText)“.")
            : (e.gewonnen && e.zweiteChance ? String(localized: "Mit zweiter Chance gewonnen – zählt nicht als Bestzeit.")
                : (e.gewonnen && e.mitHinweis && e.art == .stufe ? String(localized: "Mit Hinweis gewonnen – zählt nicht als Bestzeit.") : nil))
        // Ohne angelegten Spieler gibt der Rahmen „Spieler 1“; ein leerer Name soll nie bis zum Ende-Bildschirm kommen
        let spielerName = name.trimmingCharacters(in: .whitespaces).isEmpty ? String(localized: "Spieler 1") : name
        // R2 (Blatt 8, nur Tinte): ein Satz unter der Schlagzeile, Hauptknopf „Noch einmal“
        let tinte = Design.ist(.tinte)
        let zeitText = SpielModell.zeit(e.dauer)
        let info: String? = !tinte ? rekord
            : (e.gewonnen ? (rekord ?? String(localized: "Alle Felder aufgedeckt in \(zeitText).")) : String(localized: "Mine getroffen nach \(zeitText)."))
        var ausgang = e.gewonnen ? SpielEnde(reihenfolge: [spielerName], info: info, einzel: .gewonnen) : SpielEnde.verloren(spielerName, info: info)
        if tinte { ausgang.nochmalTitel = "Noch einmal" }
        ausgang.dauer = e.dauer
        // Statistik je Stufe im Kern; das Tagesrätsel zählt eigens
        if e.art == .tag { ausgang.kennzahlen["tages"] = 1 }
        else if let i = Stufe.allCases.firstIndex(of: e.stufe) { ausgang.kennzahlen["stufe"] = Double(i) }
        modell.ergebnisSchliessen()
        ende(ausgang)
    }
}
#endif
