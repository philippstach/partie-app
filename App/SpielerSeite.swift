// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

struct SpielerSeite: View {
    @Environment(SpielerVerzeichnis.self) private var verzeichnis
    @Environment(StatistikDienst.self) private var statistik
    @Environment(\.dismiss) private var dismiss
    @State private var neu = false
    @State private var neuIch = false
    @State private var loeschen: Spieler?
    @State private var bearbeiten: Spieler?
    @State private var statistikVon: Spieler?

    /// Design-Runde 3: nur in Tinte heißt „Ich“ verständlicher „Dein Profil“; Klar und Salon bleiben wie sie waren.
    private var tinte: Bool { Design.art == .tinte }

    private func abschnittTitel(_ t: LocalizedStringKey) -> some View {
        Text(t).font(.footnote.weight(.semibold)).foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading).accessibilityAddTraits(.isHeader)
    }

    private func zeile(_ s: Spieler) -> some View {
        let sum = statistik.summe(spieler: s.id)
        return HStack(spacing: Design.Abstand.m) {
            SpielerBildKreis(s, groesse: 48)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: s.name).font(.headline)
                Text("\(sum.partien) Partien · \(sum.siege) Siege").font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            Menu {
                Button("Bearbeiten") { bearbeiten = s }
                if !s.ich { Button(tinte ? "Als mein Profil festlegen" : "Das bin ich") { verzeichnis.alsIchMarkieren(s.id) } }
                Button("Löschen", role: .destructive) { loeschen = s }
            } label: { Image(systemName: "ellipsis").frame(width: 44, height: 44) }
        }
        .card()
        .kartenAktion { statistikVon = s }
        .accessibilityHint(Text("Doppeltippen für die Statistik dieser Person"))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.kartenAbstand) {
                    SpielerSeitenKopf()   // Designwechsel: Tinte Verzeichnis-Titel, Salon Senf-Farbblock; in klar nichts
                    abschnittTitel(tinte ? "Dein Profil" : "Ich")
                    if tinte {
                        Text("So erscheinst du in jedem Spiel: mit Name, Foto und Farbe.")
                            .font(.footnote).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading)
                    }
                    if let ich = verzeichnis.ich {
                        zeile(ich)
                    } else {
                        Text("Lege dich selbst an, am besten mit Foto – du stehst dann in jedem Spiel bereit.")
                            .font(.subheadline).foregroundStyle(.secondary).card()
                        Button(tinte ? "Mein Profil anlegen" : "Mich anlegen") { neuIch = true }.buttonStyle(HauptKnopfStil())
                    }

                    abschnittTitel(tinte ? "Mitspieler" : "Andere Spieler")
                    let andere = verzeichnis.menschen.filter { !$0.ich }
                    if andere.isEmpty {
                        Text("Noch niemand. Lege Mitspielerinnen und Mitspieler von Hand an, sie stehen dann in jedem Spiel bereit.")
                            .font(.subheadline).foregroundStyle(.secondary).card()
                    }
                    ForEach(andere) { zeile($0) }
                    Button("Neue Person") { neu = true }.buttonStyle(HauptKnopfStil())
                }
                .padding(Theme.seitenRand)
            }
            .background(Color.seitenGrund)
            .navigationTitle("Spieler")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { BlattSchliessenKnopf { dismiss() } } }
            .sheet(item: $statistikVon) { s in SpielerStatistikBlatt(spieler: s).formSheet() }
            .sheet(isPresented: $neu) { SpielerBearbeitenBlatt(verzeichnis: verzeichnis, alsIch: false).formSheet() }
            .sheet(isPresented: $neuIch) { SpielerBearbeitenBlatt(verzeichnis: verzeichnis, alsIch: true).formSheet() }
            .sheet(item: $bearbeiten) { p in SpielerBearbeitenBlatt(person: p, verzeichnis: verzeichnis).formSheet() }
            .confirmationDialog("Spieler löschen?", isPresented: Binding(get: { loeschen != nil }, set: { if !$0 { loeschen = nil } }), titleVisibility: .visible) {
                Button("Löschen", role: .destructive) { if let l = loeschen { verzeichnis.loeschen(l.id) }; loeschen = nil }
                Button("Abbrechen", role: .cancel) { loeschen = nil }
            } message: { Text("Die Statistik der bisherigen Partien bleibt erhalten.") }
        }
    }
}
