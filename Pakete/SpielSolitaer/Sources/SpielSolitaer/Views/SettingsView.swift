// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import PhotosUI
import SwiftUI
import KlarGlas
import SpieleKern

struct SettingsView: View {
    @Environment(AppModel.self) private var app
    @Environment(Router.self) private var router
    @State private var openInfo: Set<String> = []

    var body: some View {
        @Bindable var prefs = app.prefs
        ScrollViewReader { proxy in
        ScrollView {
            VStack(spacing: Design.Abstand.l) {
                preview

                // Spiel: Schwierigkeit, Zufall, automatisch ablegen, Anzeige
                VStack(alignment: .leading, spacing: 10) {
                    EinstellungsKopf(gruppe: .spiel).id("spiel")
                    pickerLabel("Schwierigkeit")
                    Picker("Schwierigkeit", selection: $prefs.difficulty) {
                        Text("Gemischt").tag(0)
                        Text("Leicht").tag(1)
                        Text("Mittel").tag(2)
                        Text("Schwer").tag(3)
                    }
                    .pickerStyle(.segmented)
                    .disabled(!prefs.solvableDeals)
                    footer("Gilt für lösbare Partien.", info: "Leicht heißt: Wer den Tipps folgt, kommt sehr weit oder gewinnt. Gilt für alle Spiele mit lösbaren Partien.", id: "difficulty")
                    Toggle("Zufällige Partien", isOn: Binding(get: { !prefs.solvableDeals }, set: { prefs.solvableDeals = !$0 }))
                    footer("Sonst sind alle Partien lösbar.", info: "Lösbare Partien hat ein Computer vorab bis zum Sieg durchgespielt. Zufällige Partien sind manchmal nicht zu gewinnen.", id: "random")
                    pickerLabel("Karten ablegen")
                    Picker("Karten ablegen", selection: $prefs.autoFoundation) {
                        Text("Automatisch").tag(true)
                        Text("Selbst").tag(false)
                    }
                    .pickerStyle(.segmented)
                    footer("Automatisch legt sichere Karten selbst ab.", info: "Bei „Automatisch“ wandern Karten aufs Ziel, sobald sie sicher nicht mehr gebraucht werden. Bei „Selbst“ legst du jede Karte mit Tippen oder Ziehen ab. „Fertig spielen“ gibt es in beiden Fällen, sobald alles aufgedeckt ist. Gilt für Klondike, FreeCell und Yukon.", id: "auto")
                    Divider().padding(.vertical, 2)
                    pickerLabel("Anzeige")
                    Toggle("Zeit", isOn: $prefs.showTime)
                    Toggle("Züge", isOn: $prefs.showMoves)
                    Toggle("Punkte", isOn: $prefs.showScore)
                    Divider().padding(.vertical, 2)

                    // Spielarten: Klondike ziehen 1/3, Spider-Farben
                    pickerLabel("Klondike: Karten ziehen")
                    Picker("Karten ziehen", selection: $prefs.drawCount) {
                        Text("1 Karte").tag(1)
                        Text("3 Karten").tag(3)
                    }
                    .pickerStyle(.segmented)
                    pickerLabel("Spider: Farben")
                    Picker("Farben", selection: $prefs.spiderColors) {
                        Text("1 Farbe").tag(1)
                        Text("2 Farben").tag(2)
                        Text("4 Farben").tag(4)
                    }
                    .pickerStyle(.segmented)
                    pickerLabel("Klondike: Wertung")
                    Picker("Wertung", selection: $prefs.klondikeScoring) {
                        Text("Standard").tag(0)
                        Text("Streng").tag(1)
                        Text("Streng fortlaufend").tag(2)
                        Text("Aus").tag(3)
                    }
                    .pickerStyle(.menu)
                    footer("Streng: Start bei −52, +5 je Karte aufs Ziel.", info: "Bei der strengen Wertung startest du bei −52 Punkten; jede Karte aufs Ziel bringt +5, jede Karte vom Ziel zurück −5. Beim Ziehen von 1 Karte gibt es 1 Durchgang, bei 3 Karten 3 Durchgänge. „Streng fortlaufend“ addiert die Punkte über alle Partien (Gesamtwertung). Tagesspiel und Tagesziele zählen immer Standard.", id: "scoring")
                    footer("Gilt ab der nächsten Partie.", info: prefs.spiderColors == 4 ? "Bei 4 Farben ist nicht jede Partie lösbar." : nil, id: "modes")
                }
                .card()

                // Aussehen: Rücken, Tisch, vierfarbig, Linkshänder
                AppearanceCard()
                    .id("aussehen")


                // Hilfe und Über
                VStack(alignment: .leading, spacing: 10) {
                    EinstellungsKopf(gruppe: .ueber)
                    NavigationLink(value: MenuRoute.rules) { rowLabel("Regeln", "book") }
                    Divider()
                    Button { prefs.seenHints = [] } label: { rowLabel("Hinweise wieder zeigen", "lightbulb") }
                }
                .buttonStyle(.plain)
                .card()

                // Fußzeile: Version und Build
                VStack(spacing: Design.Abstand.xs) {
                    Text(verbatim: versionText).font(.footnote.monospacedDigit()).foregroundStyle(.secondary)
                    Label("Ohne Werbung. Ohne Konto.", systemImage: "heart.fill")
                        .font(.caption).foregroundStyle(Color.appFarbe)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .accessibilityElement(children: .combine)
            }
            .toggleStyle(.switch)
            .padding(16)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
        .onAppear {
            if router.scrollToAppearance { proxy.scrollTo("aussehen", anchor: .top) }
            if router.scrollToGameSettings { proxy.scrollTo("spiel", anchor: .top) }
        }
        }
        .background(Color.seitenGrund)
        .navigationTitle("Einstellungen")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// „Solitär 1.0 (3)“
    private var versionText: String {
        let info = Bundle.main.infoDictionary
        let v = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = info?["CFBundleVersion"] as? String ?? "1"
        return "\(String(localized: "Solitär")) \(v) (\(b))"
    }

    /// Live-Vorschau: drei Karten auf dem gewählten Tisch und Rücken; ändert sich sofort mit
    private var preview: some View {
        let table = app.prefs.activeTable
        return ZStack {
            TableBackground(style: table)
            HStack(spacing: -14) {
                CardFaceView(face: CardFace(rank: 13, suit: .hearts), width: 62, fourColor: app.prefs.fourColor).rotationEffect(.degrees(-8))
                CardBackView(width: 62, style: app.prefs.cardBack, table: table).rotationEffect(.degrees(0))
                CardFaceView(face: CardFace(rank: 1, suit: .spades), width: 62, fourColor: app.prefs.fourColor).rotationEffect(.degrees(8))
            }
            .shadow(color: .black.opacity(0.18), radius: 3, y: 1)
        }
        .frame(height: 128)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
        .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).strokeBorder(Color.primary.opacity(0.08), lineWidth: 1))
        .accessibilityHidden(true)
    }

    private func rowLabel(_ title: LocalizedStringKey, _ symbol: String) -> some View {
        HStack {
            Image(systemName: symbol).foregroundStyle(Color.appFarbe).frame(width: 26)
            Text(title).foregroundStyle(.primary)
            Spacer()
            Image(systemName: "chevron.right").font(.footnote).foregroundStyle(.tertiary)
        }
        .frame(minHeight: Theme.tapSize)
        .contentShape(Rectangle())
    }

    /// Zeile, die die Seite in Safari öffnet

    private func pickerLabel(_ text: LocalizedStringKey) -> some View {
        Text(text).font(.subheadline.weight(.medium)).padding(.top, 2)
    }

    /// Erklärtext in einer Zeile; das ⓘ klappt die ausführliche Erklärung auf
    private func footer(_ short: LocalizedStringKey, info: LocalizedStringKey? = nil, id: String) -> some View {
        VStack(alignment: .leading, spacing: Design.Abstand.xs) {
            HStack(spacing: 6) {
                Text(short).font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                if info != nil {
                    Button {
                        withAnimation(.easeOut(duration: 0.15)) {
                            if openInfo.contains(id) { openInfo.remove(id) } else { openInfo.insert(id) }
                        }
                    } label: {
                        Image(systemName: openInfo.contains(id) ? "info.circle.fill" : "info.circle")
                            .foregroundStyle(Color.appFarbe)
                            .frame(minWidth: Theme.tapSize, minHeight: Theme.tapSize)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, -14)
                    .accessibilityLabel(Text("Mehr dazu"))
                }
            }
            if let info, openInfo.contains(id) {
                Text(info).font(.caption).foregroundStyle(.secondary).transition(.opacity)
            }
        }
    }
}

/// Einstellungen → „Aussehen“: Raster mit Vorschau-Karten (Rücken) und Mini-Tischen. Der Rücken wird auf dem gewählten Tisch gezeigt,
/// damit man den weißen Rand bei zu ähnlichen Farben schon in der Auswahl sieht.
private struct AppearanceCard: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var pickedPhoto: PhotosPickerItem?
    @State private var photoFailed = false

    var body: some View {
        @Bindable var prefs = app.prefs
        VStack(alignment: .leading, spacing: Design.Abstand.m) {
            EinstellungsKopf(gruppe: .aussehen)
            Text("Kartenrücken").font(.subheadline.weight(.medium)).padding(.top, 4).font(.subheadline.weight(.medium))
            grid {
                ForEach(CardBackStyle.allCases) { style in
                    cell(title: style.title, selected: prefs.cardBack == style) { prefs.cardBack = style } preview: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10).fill(prefs.activeTable.color)
                            CardBackView(width: 40, style: style, table: prefs.activeTable)
                        }
                        .frame(height: 76)
                    }
                }
            }
            Text("Tisch").font(.subheadline.weight(.medium)).padding(.top, 4)
            grid {
                ForEach(TableStyle.basic) { style in
                    cell(title: style.title, selected: prefs.tableStyle == style) { prefs.tableStyle = style } preview: {
                        ZStack {
                            TableBackground(style: style).clipShape(RoundedRectangle(cornerRadius: 10))
                            HStack(spacing: 5) {
                                SlotView(size: CGSize(width: 22, height: 31), tint: style.tint)
                                CardBackView(width: 22, style: prefs.cardBack, table: style)
                            }
                        }
                        .frame(height: 76)
                    }
                }
            }
            // Jahreszeiten: vier weitere Tische und der Schalter „Automatisch nach Jahreszeit“
            Text("Jahreszeiten").font(.subheadline.weight(.medium)).padding(.top, 4)
            grid {
                ForEach(TableStyle.seasons) { style in
                    cell(title: style.title, selected: prefs.tableStyle == style) { prefs.tableStyle = style } preview: {
                        ZStack {
                            TableBackground(style: style).clipShape(RoundedRectangle(cornerRadius: 10))
                            HStack(spacing: 5) {
                                SlotView(size: CGSize(width: 22, height: 31), tint: style.tint)
                                CardBackView(width: 22, style: prefs.cardBack, table: style)
                            }
                        }
                        .frame(height: 76)
                    }
                }
            }
            Toggle("Automatisch nach Jahreszeit", isOn: $prefs.autoSeason)
            if prefs.autoSeason {
                Text("Gerade: \(Text(TableStyle.season(for: .now).title)) – überschreibt die Tischwahl.").font(.caption).foregroundStyle(.secondary)
            }
            // Eigenes Foto als Tisch (keine Berechtigung nötig)
            HStack(spacing: Design.Abstand.m) {
                PhotosPicker(selection: $pickedPhoto, matching: .images) {
                    Label(prefs.tablePhoto == nil ? "Eigenes Foto…" : "Foto ändern…", systemImage: "photo")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.appFarbe)
                        .frame(minHeight: Theme.tapSize)
                        .contentShape(Rectangle())
                }
                if prefs.tablePhoto != nil {
                    Button("Foto entfernen", role: .destructive) { prefs.removeTablePhoto() }
                        .font(.subheadline)
                        .frame(minHeight: Theme.tapSize)
                }
                Spacer()
            }
            if photoFailed { Text("Das Foto konnte nicht geladen werden.").font(.caption).foregroundStyle(.red) }
            Text("Gilt sofort, für alle Spiele.").font(.caption).foregroundStyle(.secondary)
            Divider()
            Text("Kartengröße").font(.subheadline.weight(.medium))
            Picker("Kartengröße", selection: $prefs.largeCards) {
                Text("Normal").tag(false)
                Text("Groß").tag(true)
            }
            .pickerStyle(.segmented)
            Toggle("Vierfarbige Karten", isOn: $prefs.fourColor)
            Toggle("Linkshänder", isOn: $prefs.leftHanded)        }
        .card()
        .onChange(of: pickedPhoto) { _, item in
            guard let item else { return }
            Task {
                let data = try? await item.loadTransferable(type: Data.self)
                var ok = false
                if let data { ok = await app.prefs.setTablePhotoInBackground(data: data) }
                photoFailed = !ok
                pickedPhoto = nil
            }
        }
    }

    private func grid<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: typeSize.isAccessibilitySize ? 130 : 72), spacing: 10)], spacing: 10) { content() }
    }

    private func cell<Preview: View>(title: LocalizedStringKey, selected: Bool, action: @escaping () -> Void,
                                     @ViewBuilder preview: () -> Preview) -> some View {
        Button(action: action) {
            VStack(spacing: Design.Abstand.xs) {
                preview()
                    .overlay {
                        RoundedRectangle(cornerRadius: 10).strokeBorder(selected ? Color.appFarbe : Color.primary.opacity(0.12),
                                                                         lineWidth: selected ? 2.5 : 1)
                    }
                Text(title).font(.caption).foregroundStyle(.primary).lineLimit(typeSize.isAccessibilitySize ? 2 : 1).minimumScaleFactor(0.7)
            }
            .frame(minHeight: Theme.tapSize)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
    }
}
