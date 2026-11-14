// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Viererreihe über Game Center (rundenbasiert): Was zwischen den Geräten geschickt wird und wie es gelesen wird.
/// Reine Logik ohne Game Kit, mit `swift test` prüfbar. Es geht immer der ganze Stand der Partie (Beginner und Züge) hin und her.
enum ViererOnlineDaten {
    struct Paket: Codable, Equatable {
        var version = 1
        var partie: Partie
    }

    /// Die Partie als Daten für `matchData` (höchstens wenige hundert Bytes, Grenze von Game Center sind 64 KB).
    static func kodieren(_ partie: Partie) -> Data {
        (try? JSONEncoder().encode(Paket(partie: partie))) ?? Data()
    }

    /// Liest `matchData`. Leer (neue Partie, noch kein Zug) ergibt eine frische Partie mit Spieler 1 am Zug.
    /// `nil`, wenn die Daten nicht lesbar oder unstimmig sind (dann bleibt der eigene Stand unberührt).
    static func lesen(_ daten: Data?) -> Partie? {
        guard let daten, !daten.isEmpty else { return neu() }
        return (try? JSONDecoder().decode(Paket.self, from: daten))?.partie
    }

    static func neu() -> Partie? { try? Partie(beginner: 1, zuege: []) }

    /// Soll der Stand `fern` den eigenen Stand `eigen` ersetzen? Nur, wenn er dieselbe Partie ist und weiter fortgeschritten.
    static func uebernehmen(fern: Partie, eigen: Partie) -> Bool {
        fern.beginner == eigen.beginner
            && fern.zuege.count > eigen.zuege.count
            && Array(fern.zuege.prefix(eigen.zuege.count)) == eigen.zuege
    }
}

/// Verbindung zwischen dem Spielbildschirm und der Online-Partie.
struct ViererOnlineLink {
    /// Meine Nummer: 1 = Rot (hat die Partie begonnen), 2 = Blau.
    let meineNummer: Int
    /// Der zuletzt vom Netz gelesene Stand.
    let fern: Partie?
    /// Wird nach jedem eigenen Zug gerufen.
    let senden: (Partie) -> Void
}

#if canImport(UIKit) && canImport(GameKit)
import SwiftUI
import GameKit
import KlarGlas
import SpieleKern

/// Karte im Neues-Spiel-Blatt: „Online mit Freund“. Das ist der einzige Einstieg; ohne Game Center bleibt alles wie bisher.
struct ViererOnlineKarte: View {
    let verzeichnis: SpielerVerzeichnis
    @State private var zeigen = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Online mit Freund", systemImage: "person.2.wave.2").font(.headline).foregroundStyle(Color.accentText)
            Text("Jeder spielt auf dem eigenen Gerät, abwechselnd. Die Einladung läuft über Game Center.")
                .font(.footnote).foregroundStyle(.secondary)
            Button { zeigen = true } label: {
                Text("Online spielen").font(.subheadline.weight(.semibold)).foregroundStyle(Color.accentText).frame(minHeight: Theme.tapSize, alignment: .leading)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading).card()
        .fullScreenCover(isPresented: $zeigen) {
            ViererOnlineEinstieg(verzeichnis: verzeichnis) { zeigen = false }
        }
    }
}

/// Startseite der Online-Partie (Anmelden, Freunde einladen, Freunde verknüpfen) und, sobald eine Partie offen ist, das Brett.
struct ViererOnlineEinstieg: View {
    let verzeichnis: SpielerVerzeichnis
    let schliessen: () -> Void
    @ObservedObject private var gc = GameCenterOnline.gemeinsam
    @State private var arbeitet = false
    @State private var freundeBlatt = false

    var body: some View {
        Group {
            if let m = gc.aktuellesMatch {
                ViererOnlinePartie(match: m, verzeichnis: verzeichnis, zurueck: { gc.schliessen() })
                    .id(m.matchID)
            } else {
                startSeite
            }
        }
        .background(Color.seitenGrund.ignoresSafeArea())
    }

    private var startSeite: some View {
        VStack(spacing: Theme.kartenAbstand) {
            HStack {
                Text("Viererreihe online").font(.title2.bold())
                Spacer()
                RundKnopf(symbol: "xmark", beschriftung: "Schließen", klein: true) { schliessen() }
            }
            VStack(alignment: .leading, spacing: Design.Abstand.s) {
                Text("Spiele mit einem Game-Center-Freund, jeder auf dem eigenen Gerät. Wer dran ist, bekommt eine Mitteilung.")
                    .font(.subheadline)
                Text("Die App funktioniert auch ohne Game Center. Hier wird nur angemeldet, wenn du es antippst.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading).card()

            if gc.angemeldet {
                Button("Freund einladen oder Partie öffnen") { Task { await gc.partienZeigen() } }
                    .buttonStyle(HauptKnopfStil())
                Button { freundeBlatt = true } label: {
                    Label("Freunde mit Personen verknüpfen", systemImage: "link").font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.accentText).frame(minHeight: Theme.tapSize)
                }
                .buttonStyle(.plain)
            } else {
                Button { Task { arbeitet = true; await gc.anmelden(); arbeitet = false } } label: {
                    if arbeitet { ProgressView() } else { Text("Bei Game Center anmelden") }
                }
                .buttonStyle(HauptKnopfStil()).disabled(arbeitet)
            }
            if let f = gc.fehler {
                Text(verbatim: f).font(.footnote).foregroundStyle(.red).frame(maxWidth: .infinity, alignment: .leading)
            }
            Spacer(minLength: 0)
        }
        .padding(Theme.seitenRand)
        .sheet(isPresented: $freundeBlatt) { GameCenterFreundeBlatt(verzeichnis: verzeichnis).formSheet() }
    }
}

/// Eine offene Online-Partie: das gewohnte Brett, gesperrt, solange der andere am Zug ist.
struct ViererOnlinePartie: View {
    let match: GKTurnBasedMatch
    let verzeichnis: SpielerVerzeichnis
    let zurueck: () -> Void
    @ObservedObject private var gc = GameCenterOnline.gemeinsam
    @State private var ausstehend: Partie?
    @State private var sendeFehler = false
    @State private var beendet = false
    @State private var neuerFreund: GCFreund?

    /// Pro Start der App wird ein Freund nur einmal gefragt, wenn man „Jetzt nicht“ wählt.
    @MainActor private static var abgefragt: Set<String> = []

    private var nummer: Int { gc.meineNummer(match) ?? 1 }
    private var partie: Partie { ViererOnlineDaten.lesen(match.matchData) ?? ViererOnlineDaten.neu() ?? (try! Partie(beginner: 1, zuege: [])) }
    private var gegner: GKPlayer? { gc.gegner(match) }

    private var meinName: String { verzeichnis.ich?.name ?? String(localized: "Ich") }
    private var gegnerName: String {
        guard let g = gegner else { return String(localized: "Freund") }
        return verzeichnis.mitGameCenter(g.gamePlayerID)?.name ?? g.displayName
    }

    private var teilnehmer: [SpielTeilnehmer] {
        let ich = SpielTeilnehmer(name: meinName), er = SpielTeilnehmer(name: gegnerName)
        return nummer == 1 ? [ich, er] : [er, ich]
    }

    var body: some View {
        VStack(spacing: 0) {
            ViererNeuSpiel(
                teilnehmer: teilnehmer,
                ende: { _ in beendet = true },
                abbrechen: zurueck,
                bilanz: { (0, 0) },
                vorgabe: vorgabe,
                online: ViererOnlineLink(meineNummer: nummer, fern: partie, senden: { senden($0) })
            )
            if sendeFehler, let p = ausstehend {
                HStack {
                    Text("Der Zug ist noch nicht angekommen.").font(.footnote)
                    Spacer()
                    Button("Erneut senden") { senden(p) }.font(.footnote.weight(.semibold))
                }
                .padding(12).background(Color.kartenGrund)
            } else if match.status == .open, !gc.amZug(match) {
                Text("\(gegnerName) ist am Zug. Du bekommst eine Mitteilung.").font(.footnote).foregroundStyle(.secondary).padding(8)
            }
        }
        .overlay { if beendet { ende } }
        .task {
            guard let g = gegner, verzeichnis.mitGameCenter(g.gamePlayerID) == nil, !Self.abgefragt.contains(g.gamePlayerID) else { return }
            Self.abgefragt.insert(g.gamePlayerID)
            neuerFreund = GCFreund(id: g.gamePlayerID, name: g.displayName)
        }
        .sheet(item: $neuerFreund) { f in GameCenterVerknuepfenBlatt(freund: f, verzeichnis: verzeichnis).formSheet() }
    }

    private var vorgabe: NeuSpiel {
        var s = NeuSpiel(zweiSpieler: true, stufe: .mittel, beginner: 1)
        if let p = ViererOnlineDaten.lesen(match.matchData) { s.partie = p }
        return s
    }

    private var ende: some View {
        VStack(spacing: Design.Abstand.m) {
            Text(titel).font(.title3.bold())
            Button("Fertig") { beendet = false; zurueck() }.buttonStyle(HauptKnopfStil())
        }
        .padding(24).frame(maxWidth: 320).background(Color.kartenGrund, in: .rect(cornerRadius: 20)).shadow(radius: 12)
    }

    private var titel: String {
        switch partie.gewinner {
        case .some(let g): g == nummer ? String(localized: "Du hast gewonnen") : String(localized: "\(gegnerName) hat gewonnen")
        case nil: String(localized: "Unentschieden")
        }
    }

    /// Schickt den Stand nach meinem Zug. Endet die Partie mit diesem Zug, wird sie in Game Center beendet.
    private func senden(_ p: Partie) {
        ausstehend = p; sendeFehler = false
        Task { @MainActor in
            let daten = ViererOnlineDaten.kodieren(p)
            let ok: Bool
            if p.status == .laeuft {
                ok = await gc.zugAbgeben(match, daten: daten)
            } else {
                ok = await gc.beenden(match, daten: daten, ichGewonnen: p.gewinner.map { $0 == nummer })
            }
            if ok { ausstehend = nil } else { sendeFehler = true }
        }
    }
}
#endif
