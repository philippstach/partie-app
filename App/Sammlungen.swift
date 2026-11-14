// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import Observation
import KlarGlas
import SpieleKern

/// Eigene Listen („Familienabend“, „Unterwegs“ …) aus Spielen, lokal gespeichert (Version 1.0, A4).
@Observable @MainActor
final class Sammlungen {
    struct Liste: Codable, Identifiable, Equatable { var id = UUID(); var name: String; var ids: [String] = [] }
    private static let schluessel = "partie.sammlungen"
    private(set) var listen: [Liste]

    init() {
        if let d = UserDefaults.standard.data(forKey: Self.schluessel), let l = try? JSONDecoder().decode([Liste].self, from: d) { listen = l } else { listen = [] }
    }

    private func sichern() { if let d = try? JSONEncoder().encode(listen) { UserDefaults.standard.set(d, forKey: Self.schluessel) } }

    func neu(_ name: String) -> UUID? {
        let n = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !n.isEmpty else { return nil }
        let l = Liste(name: n); listen.append(l); sichern(); return l.id
    }
    func loeschen(_ id: UUID) { listen.removeAll { $0.id == id }; sichern() }
    func umbenennen(_ id: UUID, _ name: String) {
        let n = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !n.isEmpty, let i = listen.firstIndex(where: { $0.id == id }) else { return }
        listen[i].name = n; sichern()
    }
    func enthaelt(_ liste: UUID, _ spiel: String) -> Bool { listen.first { $0.id == liste }?.ids.contains(spiel) ?? false }
    func umschalten(_ liste: UUID, _ spiel: String) {
        guard let i = listen.firstIndex(where: { $0.id == liste }) else { return }
        if let k = listen[i].ids.firstIndex(of: spiel) { listen[i].ids.remove(at: k) } else { listen[i].ids.append(spiel) }
        sichern()
    }
}

/// Spielprofil (A5): Kurzregel, Herkunft, Spielerzahl, Dauer, eigene Statistik und Start.
struct SpielProfilBlatt: View {
    let modul: any SpielModul
    let starten: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(StatistikDienst.self) private var statistik
    @Environment(SpielerVerzeichnis.self) private var spieler
    @Environment(Favoriten.self) private var favoriten

    var body: some View {
        let info = SpielMetadaten.info(modul.id)
        let s = statistik.summe(spiel: modul.id, ich: spieler.ich?.id)
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.kartenAbstand) {
                    SpielBild(farbe: modul.gattung.farbe.color, miniatur: SpielMiniaturen.art(modul))
                    Text(verbatim: modul.name).font(.title.bold())
                    SpielartLabel(text: Text(modul.gattung.name), farbe: modul.gattung.farbe.color)
                    if !info.kurz.isEmpty { Text(verbatim: SpielMetadaten.kurzText(modul.id)).foregroundStyle(.secondary) }
                    VStack(alignment: .leading, spacing: Design.Abstand.s) {
                        if !info.land.isEmpty { zeile("Herkunft", Text(verbatim: SpielMetadaten.landText(info.land))) }
                        zeile("Spieler", Text(modul.spielerzahl.lowerBound == modul.spielerzahl.upperBound ? "1 Spieler" : "\(modul.spielerzahl.lowerBound)–\(modul.spielerzahl.upperBound) Spieler"))
                        zeile("Dauer", Text("ca. \(WasSpielenWirBlatt.minuten(modul)) Min."))
                        zeile("Partien", Text("\(s.partien)"))
                        zeile("Siege", Text("\(s.siege)"))
                    }
                    .card()
                    Button("Spielen") { dismiss(); starten() }.buttonStyle(HauptKnopfStil())
                    Button { favoriten.umschalten(modul.id) } label: {
                        Label(favoriten.enthaelt(modul.id) ? "Aus Favoriten entfernen" : "Zu Favoriten hinzufügen",
                              systemImage: favoriten.enthaelt(modul.id) ? "heart.slash" : "heart").frame(maxWidth: .infinity)
                    }.buttonStyle(ZweitKnopfStil())
                }
                .padding(Theme.seitenRand)
            }
            .background(Color.seitenGrund)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { BlattSchliessenKnopf { dismiss() } } }
        }
    }

    private func zeile(_ titel: LocalizedStringKey, _ wert: Text) -> some View {
        HStack { Text(titel).foregroundStyle(.secondary); Spacer(); wert }
    }
}
