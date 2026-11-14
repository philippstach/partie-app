// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

/// Die Bilanz des Abends als Zeilen (Name, verlorene Partien und Hälften). Die erste Zeile liegt hinten.
struct AbendBilanz: View {
    let abend: Abend
    var klein = false

    var body: some View {
        VStack(alignment: .leading, spacing: klein ? 6 : 10) {
            ForEach(Array(abend.bilanz.enumerated()), id: \.element.name) { i, zeile in
                HStack(spacing: 10) {
                    Text(zeile.avatar ?? String(zeile.name.prefix(1)).uppercased())
                        .font(zeile.avatar != nil ? .system(size: klein ? 16 : 20) : .system(.subheadline, design: Design.zahlDesign, weight: .bold))
                        .frame(width: klein ? 28 : 34, height: klein ? 28 : 34)
                        .background(Color.accentColor.opacity(0.18), in: .circle)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(zeile.name).font(.subheadline.weight(.semibold))
                        if i == 0 && zeile.partienVerloren > 0 {
                            StatusChip(text: Text("liegt hinten"), ton: .warnung).fixedSize()
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("\(zeile.partienVerloren) verloren")
                            .font(.system(.subheadline, design: Design.zahlDesign, weight: .bold)).foregroundStyle(Color.accentText)
                        Text("\(zeile.haelftenVerloren) Hälften").font(.caption2).foregroundStyle(.secondary)
                    }
                }
                .accessibilityElement(children: .combine)
            }
        }
    }
}


/// Eine Medaille: goldener Kreis mit Symbol (keine fremden Grafiken).
struct AuszeichnungKarte: View {
    let auszeichnung: Abend.Auszeichnung

    private var symbol: String {
        switch auszeichnung.id {
        case "schockKoenig": "crown.fill"
        case "pechvogel": "cloud.rain.fill"
        default: "leaf.fill"
        }
    }

    private var titel: String {
        switch auszeichnung.id {
        case "schockKoenig": String(localized: "Schock-König")
        case "pechvogel": String(localized: "Pechvogel")
        default: String(localized: "Glückspilz")
        }
    }

    private var wertText: String {
        switch auszeichnung.id {
        case "schockKoenig": String(localized: "\(auszeichnung.wert) × Schock aus")
        default: String(localized: "\(auszeichnung.wert) Deckel bekommen")
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.title.weight(.semibold))
                .foregroundStyle(Color.onAccent)
                .frame(width: 56, height: 56)
                .background(Color.accentColor, in: .circle)
            VStack(alignment: .leading, spacing: 2) {
                Text(titel).font(.caption.weight(.semibold)).foregroundStyle(.secondary).textCase(.uppercase)
                Text(auszeichnung.namen.joined(separator: " & ")).font(.title3.weight(.bold))
                Text(wertText).font(.footnote).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}

/// Der Inhalt des Abschlusses; auch als Bild zum Teilen (1080 × 1350, hell).
struct AbendBild: View {
    let abend: Abend
    var datum = Date()

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: Design.Abstand.xs) {
                Text("Euer Abend").font(.system(.largeTitle, design: Design.zahlDesign).weight(.black)).foregroundStyle(Color.accentText)
                Text("\(datum.formatted(date: .long, time: .omitted)) · \(abend.partien) Partien")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            AbendBilanz(abend: abend)
            let aus = abend.auszeichnungen
            if !aus.isEmpty {
                Divider()
                ForEach(aus, id: \.id) { AuszeichnungKarte(auszeichnung: $0) }
            }
            Spacer(minLength: 0)
            Text("Schocken").font(.footnote.weight(.semibold)).tracking(3).foregroundStyle(.tertiary)
        }
        .padding(28)
    }
}

/// Abend-Abschluss als Sheet: Bilanz, Auszeichnungen, als Bild teilen, Abend beenden.
struct AbendAbschlussView: View {
    @Environment(AbendStore.self) private var abendStore
    @Environment(\.dismiss) private var dismiss
    @State private var bild: Image?
    @State private var beenden = false

    var body: some View {
        let a = abendStore.abend
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    AbendBild(abend: a).card()
                    if TeilenFreigabe.erlaubt(), let bild {
                        ShareLink(item: bild, preview: SharePreview(String(localized: "Euer Abend"), image: bild)) {
                            Label("Als Bild teilen", systemImage: "square.and.arrow.up").frame(maxWidth: .infinity)
                        }
                        .hauptKnopf()
                    }
                    Button("Abend beenden", role: .destructive) { beenden = true }
                        .frame(minHeight: Theme.tapSize)
                }
                .padding()
                .frame(maxWidth: 560).frame(maxWidth: .infinity)
            }
            .background(Color.seitenGrund)
            .navigationTitle("Euer Abend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Fertig") { dismiss() } } }
            .alert("Abend beenden?", isPresented: $beenden) {
                Button("Abend beenden", role: .destructive) { abendStore.neuerAbend(); dismiss() }
                Button("Abbrechen", role: .cancel) {}
            } message: { Text("Die Bilanz von heute wird gelöscht.") }
            .task { rendern(a) }
        }
    }

    /// Rendert den Abschluss lokal als Bild (1080 × 1350, hell), ohne Netz.
    @MainActor
    private func rendern(_ a: Abend) {
        let inhalt = AbendBild(abend: a)
            .frame(width: 540, height: 675)
            .background(Color(red: 0.965, green: 0.945, blue: 0.894))
            .environment(\.colorScheme, .light)
            .tint(.accentColor)
        let r = ImageRenderer(content: inhalt)
        r.scale = 2
        if let ui = r.uiImage { bild = Image(uiImage: ui) }
    }
}
