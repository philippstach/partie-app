// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import PhotosUI
import KlarGlas

/// Blatt zum Anlegen und Ändern einer Person: Foto (aus der Mediathek, ohne Berechtigungsabfrage), Avatar-Zeichen, Farbe, Name.
/// `person == nil` legt neu an. `fertig` bekommt die gesicherte Person.
public struct SpielerBearbeitenBlatt: View {
    let person: Spieler?
    let verzeichnis: SpielerVerzeichnis
    let fertig: (Spieler) -> Void
    /// `true`: legt die eigene Person („Ich“) an, `false`: eine andere; `nil`: wie bisher (die erste Person ist „Ich“).
    let alsIch: Bool?
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var avatar = ""
    @State private var farbe = 0
    @State private var auswahl: PhotosPickerItem?
    @State private var neuesBild: Data?
    @State private var bildWeg = false
    /// Gewähltes Foto, das gerade zugeschnitten wird, und das Original für „Ausschnitt ändern“.
    @State private var zuschneiden: Data?
    @State private var roh: Data?
    @FocusState private var nameFokus: Bool
    /// Game Center: Verknüpfung dieser Person (nur beim Ändern einer anderen Person, nicht bei „Ich“).
    @State private var gcID: String?
    @State private var gcWahl = false

    private static let zeichen = ["😀", "😎", "🤓", "🥳", "😺", "🐶", "🦊", "🐼", "🦁", "🐸", "🐙", "🦄", "🌟", "🔥", "🍀", "⚽️", "🎸", "🚀", "🍕", "👑"]

    public init(person: Spieler? = nil, verzeichnis: SpielerVerzeichnis, alsIch: Bool? = nil, fertig: @escaping (Spieler) -> Void = { _ in }) {
        self.person = person; self.verzeichnis = verzeichnis; self.alsIch = alsIch; self.fertig = fertig
    }

    private var sauber: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var doppelt: Bool { verzeichnis.nameVergeben(sauber, ausser: person?.id) }
    private var kannSichern: Bool { !sauber.isEmpty && !doppelt }

    /// Vorschau mit dem aktuellen Stand der Eingabe (noch nicht gesichert).
    private var vorschau: some View {
        Group {
            if let d = neuesBild, let b = UIImage(data: d) {
                Image(uiImage: b).resizable().scaledToFill().frame(width: 96, height: 96).clipShape(.circle)
                    .overlay(Circle().strokeBorder(Spieler.farbe(farbe), lineWidth: 4))
            } else if !bildWeg, let p = person, p.bildNr != nil, SpielerBilder.bild(p.id) != nil {
                SpielerBildKreis(p, groesse: 96)
            } else {
                SpielerAvatar(name: sauber.isEmpty ? "?" : sauber, farbe: Spieler.farbe(farbe), groesse: 96,
                              symbol: avatar.isEmpty ? nil : avatar)
            }
        }
        .accessibilityHidden(true)
    }

    private var hatBild: Bool { neuesBild != nil || (!bildWeg && person?.bildNr != nil) }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.kartenAbstand) {
                    VStack(spacing: Design.Abstand.m) {
                        vorschau
                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: 10) {
                                PhotosPicker(selection: $auswahl, matching: .images, photoLibrary: .shared()) {
                                    Label(hatBild ? "Foto ändern" : "Foto wählen", systemImage: "photo")
                                        .font(.subheadline.weight(.semibold)).foregroundStyle(Color.accentText)
                                        .frame(minHeight: Theme.tapSize).padding(.horizontal, 12)
                                }
                                if let r = roh, neuesBild != nil {
                                    Button { zuschneiden = r } label: {
                                        Label("Ausschnitt ändern", systemImage: "crop").font(.subheadline.weight(.semibold))
                                            .foregroundStyle(Color.accentText).frame(minHeight: Theme.tapSize).padding(.horizontal, 12)
                                    }
                                    .buttonStyle(.plain)
                                }
                                if hatBild {
                                    Button { neuesBild = nil; roh = nil; bildWeg = true; auswahl = nil } label: {
                                        Label("Foto entfernen", systemImage: "trash").font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.secondary).frame(minHeight: Theme.tapSize).padding(.horizontal, 12)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            VStack(spacing: 0) {
                                PhotosPicker(selection: $auswahl, matching: .images, photoLibrary: .shared()) {
                                    Label(hatBild ? "Foto ändern" : "Foto wählen", systemImage: "photo")
                                        .font(.subheadline.weight(.semibold)).foregroundStyle(Color.accentText)
                                        .frame(minHeight: Theme.tapSize).padding(.horizontal, 12)
                                }
                                if let r = roh, neuesBild != nil {
                                    Button { zuschneiden = r } label: {
                                        Label("Ausschnitt ändern", systemImage: "crop").font(.subheadline.weight(.semibold))
                                            .foregroundStyle(Color.accentText).frame(minHeight: Theme.tapSize).padding(.horizontal, 12)
                                    }
                                    .buttonStyle(.plain)
                                }
                                if hatBild {
                                    Button { neuesBild = nil; roh = nil; bildWeg = true; auswahl = nil } label: {
                                        Label("Foto entfernen", systemImage: "trash").font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.secondary).frame(minHeight: Theme.tapSize).padding(.horizontal, 12)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity).card()

                    VStack(alignment: .leading, spacing: Design.Abstand.s) {
                        Text("Name").font(.footnote.weight(.semibold)).foregroundStyle(.secondary)
                        TextField("Name", text: $name)
                            .textContentType((alsIch == true || person?.ich == true) ? .givenName : nil)   // T-023: nur beim eigenen Spieler schlägt Apple den Vornamen vor
                            .textInputAutocapitalization(.words).autocorrectionDisabled().submitLabel(.done)
                            .focused($nameFokus).frame(minHeight: Theme.tapSize)
                        if doppelt {
                            Text("Diesen Namen gibt es schon.").font(.footnote).foregroundStyle(.red)
                                .accessibilityAddTraits(.isStaticText)
                        }
                    }
                    .card()

                    if hatBild {
                        Text("Mit Foto wird kein Zeichen angezeigt. Entferne das Foto, um ein Zeichen zu wählen.")
                            .font(.footnote).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading).card()
                    } else {
                    VStack(alignment: .leading, spacing: Design.Abstand.s) {
                        Text("Zeichen").font(.footnote.weight(.semibold)).foregroundStyle(.secondary)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 44), spacing: 6)], spacing: 6) {
                            auswahlZeile(inhalt: Text(verbatim: sauber.prefix(1).uppercased().isEmpty ? "A" : sauber.prefix(1).uppercased()).font(.title3.weight(.semibold)),
                                         gewaehlt: avatar.isEmpty, beschriftung: "Initiale") { avatar = "" }
                            ForEach(Self.zeichen, id: \.self) { z in
                                auswahlZeile(inhalt: Text(verbatim: z).font(.title2), gewaehlt: avatar == z, beschriftung: z) { avatar = z }
                            }
                        }
                    }
                    .card()
                    }

                    VStack(alignment: .leading, spacing: Design.Abstand.s) {
                        Text(hatBild ? "Rahmenfarbe" : "Farbe").font(.footnote.weight(.semibold)).foregroundStyle(.secondary)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 44), spacing: 6)], spacing: 6) {
                            ForEach(0..<Spieler.farbenHex.count, id: \.self) { i in
                                Button { farbe = i } label: {
                                    Circle().fill(Spieler.farbe(i)).frame(width: 30, height: 30)
                                        .overlay { if farbe == i { Image(systemName: "checkmark").font(.footnote.bold()).foregroundStyle(.white) } }
                                        .frame(width: 44, height: 44).contentShape(.rect)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(Text("Farbe \(i + 1)"))
                                .accessibilityAddTraits(farbe == i ? .isSelected : [])
                            }
                        }
                    }
                    .card()

                    #if canImport(GameKit)
                    if let p = person, p.art == .mensch, !p.ich { gameCenterKarte(p) }
                    #endif

                    Button("Sichern") { sichern() }.buttonStyle(HauptKnopfStil()).disabled(!kannSichern)
                }
                .padding(Theme.seitenRand)
            }
            .background(Color.seitenGrund)
            .navigationTitle(person != nil ? "Person ändern" : (alsIch == true ? "Ich" : "Neue Person"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { BlattSchliessenKnopf { dismiss() } } }
            .onAppear {
                if let p = person {
                    gcID = p.gameCenterID
                    name = p.name; farbe = p.farbeIndex
                    avatar = p.zeichen ?? ""
                } else {
                    farbe = verzeichnis.freieFarbe(); nameFokus = true
                }
            }
            .onChange(of: auswahl) { _, neu in
                guard let neu else { return }
                Task {
                    if let d = try? await neu.loadTransferable(type: Data.self) { roh = d; zuschneiden = d }
                }
            }
            .sheet(isPresented: Binding(get: { zuschneiden != nil }, set: { if !$0 { zuschneiden = nil; auswahl = nil } })) {
                if let z = zuschneiden {
                    FotoZuschnittBlatt(daten: z) { neuesBild = $0; bildWeg = false }.formSheet()
                }
            }
        }
    }

    #if canImport(GameKit)
    private func gameCenterKarte(_ p: Spieler) -> some View {
        VStack(alignment: .leading, spacing: Design.Abstand.s) {
            Text("Game Center").font(.footnote.weight(.semibold)).foregroundStyle(.secondary)
            if gcID != nil {
                Label("Mit einem Game-Center-Freund verknüpft", systemImage: "link").font(.subheadline)
                Button { verzeichnis.verknuepfungLoesen(p.id); gcID = nil } label: {
                    Text("Verknüpfung lösen").font(.subheadline.weight(.semibold)).foregroundStyle(Color.accentText).frame(minHeight: Theme.tapSize)
                }
                .buttonStyle(.plain)
            } else {
                Button { gcWahl = true } label: {
                    Label("Mit Game-Center-Freund verbinden", systemImage: "person.2.badge.plus")
                        .font(.subheadline.weight(.semibold)).foregroundStyle(Color.accentText).frame(minHeight: Theme.tapSize)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading).card()
        .sheet(isPresented: $gcWahl) {
            GameCenterFreundeBlatt(verzeichnis: verzeichnis, person: p) {
                gcID = verzeichnis.alle.first(where: { $0.id == p.id })?.gameCenterID
            }.formSheet()
        }
    }
    #endif

    private func auswahlZeile<V: View>(inhalt: V, gewaehlt: Bool, beschriftung: String, aktion: @escaping () -> Void) -> some View {
        Button(action: aktion) {
            inhalt.frame(width: 44, height: 44)
                .background(Circle().fill(gewaehlt ? Color.accentText.opacity(0.18) : Color.feldGrund))
                .overlay { if gewaehlt { Circle().strokeBorder(Color.accentText, lineWidth: 2) } }
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: beschriftung))
        .accessibilityAddTraits(gewaehlt ? .isSelected : [])
    }

    private func sichern() {
        guard kannSichern else { return }
        let aenderung: SpielerVerzeichnis.BildAenderung = neuesBild.map { .neu($0) } ?? (bildWeg ? .entfernen : .behalten)
        if let p = verzeichnis.speichern(id: person?.id, name: sauber, avatar: avatar, farbeIndex: farbe, bild: aenderung, ich: alsIch) {
            fertig(p); dismiss()
        }
    }
}
#endif
