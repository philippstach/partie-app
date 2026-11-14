// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit) && canImport(GameKit)
import SwiftUI
import KlarGlas

/// Freunde aus Game Center ansehen und mit den Personen der Spielerliste verknüpfen.
/// `person == nil`: alle Freunde, ein Tipp auf einen noch nicht verknüpften Freund fragt „Mit vorhandener Person verknüpfen oder neu anlegen?“.
/// `person != nil`: Der gewählte Freund wird direkt mit dieser Person verknüpft.
public struct GameCenterFreundeBlatt: View {
    let verzeichnis: SpielerVerzeichnis
    let person: Spieler?
    let fertig: () -> Void
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var online = GameCenterOnline.gemeinsam

    @State private var freunde: [GCFreund] = []
    @State private var laedt = true
    @State private var gewaehlt: GCFreund?

    public init(verzeichnis: SpielerVerzeichnis, person: Spieler? = nil, fertig: @escaping () -> Void = {}) {
        self.verzeichnis = verzeichnis; self.person = person; self.fertig = fertig
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.kartenAbstand) {
                    if laedt {
                        ProgressView().frame(maxWidth: .infinity, minHeight: 120)
                    } else if freunde.isEmpty {
                        VStack(alignment: .leading, spacing: Design.Abstand.s) {
                            Text("Keine Freunde gefunden").font(.headline)
                            Text(online.fehler ?? String(localized: "Füge in der App „Spiele“ von Apple Freunde hinzu. Dann erscheinen sie hier."))
                                .font(.footnote).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading).card()
                    } else {
                        ForEach(freunde) { f in zeile(f) }
                        Text("Verknüpft wird nur hier auf dem Gerät. Es wird nichts an andere gesendet.")
                            .font(.footnote).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(Theme.seitenRand)
            }
            .background(Color.seitenGrund)
            .navigationTitle(person.map { String(localized: "Freund für \($0.name)") } ?? String(localized: "Game-Center-Freunde"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { BlattSchliessenKnopf { dismiss() } } }
            .task { await laden() }
            .sheet(item: $gewaehlt) { f in
                GameCenterVerknuepfenBlatt(freund: f, verzeichnis: verzeichnis) { fertig(); aktualisieren() }.formSheet()
            }
        }
    }

    private func zeile(_ f: GCFreund) -> some View {
        let verknuepft = verzeichnis.mitGameCenter(f.id)
        return Button { tippen(f) } label: {
            HStack(spacing: 12) {
                SpielerAvatar(name: f.name, farbe: Spieler.farbe(verknuepft?.farbeIndex ?? 0), groesse: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: f.name).font(.body.weight(.semibold)).foregroundStyle(Color.schrift)
                    if let v = verknuepft {
                        Text("Verknüpft mit \(v.name)").font(.footnote).foregroundStyle(.secondary)
                    } else {
                        Text("Noch nicht verknüpft").font(.footnote).foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 4)
                Image(systemName: verknuepft == nil ? "link.badge.plus" : "checkmark.circle.fill").foregroundStyle(Color.accentText)
            }
            .frame(minHeight: Theme.tapSize)
        }
        .buttonStyle(.plain)
        .card()
        .accessibilityElement(children: .combine)
    }

    private func tippen(_ f: GCFreund) {
        if let p = person {
            verzeichnis.verknuepfen(p.id, gameCenterID: f.id)
            fertig(); dismiss()
        } else {
            gewaehlt = f
        }
    }

    private func aktualisieren() { freunde = freunde.map { $0 } }

    private func laden() async {
        laedt = true
        freunde = await online.freunde()
        laedt = false
    }
}

/// Erstes Auftauchen eines Freundes: mit einer vorhandenen Person verknüpfen oder eine neue anlegen.
/// Wird auch gezeigt, wenn beim Start einer Online-Partie ein Gegner noch zu keiner Person gehört.
public struct GameCenterVerknuepfenBlatt: View {
    let freund: GCFreund
    let verzeichnis: SpielerVerzeichnis
    let fertig: () -> Void
    @Environment(\.dismiss) private var dismiss

    public init(freund: GCFreund, verzeichnis: SpielerVerzeichnis, fertig: @escaping () -> Void = {}) {
        self.freund = freund; self.verzeichnis = verzeichnis; self.fertig = fertig
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.kartenAbstand) {
                    VStack(alignment: .leading, spacing: Design.Abstand.s) {
                        Text("\(freund.name) ist neu hier").font(.headline)
                        Text("Gibt es \(freund.name) schon in deiner Spielerliste? Dann verknüpfe die beiden, damit es keine doppelte Person gibt.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading).card()

                    if !verzeichnis.ohneGameCenter.isEmpty {
                        VStack(alignment: .leading, spacing: Design.Abstand.s) {
                            Text("Mit vorhandener Person verknüpfen").font(.footnote.weight(.semibold)).foregroundStyle(.secondary)
                            ForEach(verzeichnis.ohneGameCenter) { p in
                                Button {
                                    verzeichnis.verknuepfen(p.id, gameCenterID: freund.id); fertig(); dismiss()
                                } label: {
                                    HStack(spacing: 12) {
                                        SpielerAvatar(name: p.name, farbe: Spieler.farbe(p.farbeIndex), groesse: 32)
                                        Text(verbatim: p.name).foregroundStyle(Color.schrift)
                                        Spacer(minLength: 4)
                                    }
                                    .frame(minHeight: Theme.tapSize).contentShape(.rect)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading).card()
                    }

                    Button("Neu anlegen") {
                        verzeichnis.freundAnlegen(name: freund.name, gameCenterID: freund.id); fertig(); dismiss()
                    }
                    .buttonStyle(HauptKnopfStil())
                    Button("Jetzt nicht") { dismiss() }
                        .font(.subheadline.weight(.semibold)).foregroundStyle(Color.accentText).frame(minHeight: Theme.tapSize)
                }
                .padding(Theme.seitenRand)
            }
            .background(Color.seitenGrund)
            .navigationTitle("Neuer Freund")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
#endif
