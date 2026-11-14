// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas

/// Auswahl der Personen aus dem gemeinsamen Verzeichnis (Konzept 3), für alle Spiele gleich: Chips mit Foto bzw. Avatar und Name,
/// vorn die zuletzt Spielenden. Tippen übergibt den Namen an das Spiel, das ihn in seine Spielerliste einträgt.
/// „Neu“ legt direkt eine Person mit Foto an und wählt sie gleich aus. Ohne Verzeichnis (Spiel außerhalb der Sammlung) bleibt die Zeile leer.
public struct BekannteSpielerLeiste: View {
    @Environment(\.spielUmgebung) private var umgebung
    @State private var neuAnlegen = false
    @ScaledMetric(relativeTo: .subheadline) private var kreis: CGFloat = 28
    let benutzt: [String]
    let waehlen: (String) -> Void

    public init(benutzt: [String], waehlen: @escaping (String) -> Void) { self.benutzt = benutzt; self.waehlen = waehlen }

    public var body: some View {
        if let verzeichnis = umgebung?.spieler {
            // F21-010: Platzhalter-Namen („Spieler 8“) sind keine bekannten Spieler
            let platzhalter = Set((1...12).map { SpielerListe<EmptyView>.vorgabeName($0).lowercased() })
            let frei = verzeichnis.zuletztGespielt.filter { s in !platzhalter.contains(s.name.lowercased()) && !benutzt.contains { $0.caseInsensitiveCompare(s.name) == .orderedSame } }
            VStack(alignment: .leading, spacing: 6) {
                Text("Bekannte Spieler", bundle: nil).font(.footnote.weight(.semibold)).foregroundStyle(.secondary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Design.Abstand.s) {
                        ForEach(frei) { s in
                            Button { waehlen(s.name) } label: {
                                HStack(spacing: Design.Abstand.s) {
                                    SpielerBildKreis(s, groesse: kreis)
                                    Text(verbatim: s.name).font(.subheadline.weight(.medium)).lineLimit(1)
                                }
                                .padding(.leading, 6).padding(.trailing, 12).padding(.vertical, 6)
                                .frame(minHeight: Theme.tapSize)
                                .background(Capsule().fill(Spieler.farbe(s.farbeIndex).opacity(0.18)))
                                .contentShape(.capsule)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(Text(verbatim: s.name))
                            .accessibilityHint(Text("Zum Mitspielen hinzufügen"))
                        }
                        Button { neuAnlegen = true } label: {
                            Label("Neu", systemImage: "plus").font(.subheadline.weight(.semibold)).foregroundStyle(Color.accentText)
                                .padding(.horizontal, 14).padding(.vertical, 6).frame(minHeight: Theme.tapSize)
                                .background(Capsule().fill(Color.accentText.opacity(0.12)))
                                .contentShape(.capsule)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Text("Neue Person"))
                        .accessibilityHint(Text("Neue Person mit Foto anlegen"))
                    }
                }
            }
            .sheet(isPresented: $neuAnlegen) {
                SpielerBearbeitenBlatt(verzeichnis: verzeichnis) { p in waehlen(p.name) }.formSheet()
            }
        }
    }
}

/// Bild der Person mit diesem Namen aus dem Verzeichnis (Foto, Zeichen oder Initiale); für Spiele mit eigener Spielerliste.
/// Unbekannte Namen zeigen die Initiale ohne Farbrand.
public struct BekanntePersonBild: View {
    @Environment(\.spielUmgebung) private var umgebung
    let name: String
    var groesse: CGFloat

    public init(name: String, groesse: CGFloat = 36) { self.name = name; self.groesse = groesse }

    public var body: some View {
        if let p = umgebung?.spieler.menschen.first(where: { $0.name.caseInsensitiveCompare(name.trimmingCharacters(in: .whitespaces)) == .orderedSame }) {
            SpielerBildKreis(p, groesse: groesse)
        } else {
            SpielerAvatar(name: name, farbe: nil, groesse: groesse)
        }
    }
}
#endif
