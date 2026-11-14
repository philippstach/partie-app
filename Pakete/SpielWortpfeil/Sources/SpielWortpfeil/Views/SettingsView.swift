// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern

struct SettingsView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var confirmStep = 0

    var body: some View {
        @Bindable var prefs = store.preferences
        NavigationStack {
            Form {
                Section {
                    Toggle("Zeit anzeigen", systemImage: "timer", isOn: $prefs.showTimer)
                } header: { EinstellungsKopf(gruppe: .spiel) }
                .listRowBackground(Color.karte)
                Section {
                    Toggle("Fehler sofort zeigen", systemImage: "exclamationmark.circle", isOn: $prefs.showErrors)
                    Toggle("Richtige Wörter zeigen", systemImage: "sparkles", isOn: $prefs.showCorrectWords)
                    Toggle("Starthilfe", systemImage: "character.cursor.ibeam", isOn: $prefs.startHelp)
                    Toggle("Vorschläge zur Stufe", systemImage: "lightbulb.min", isOn: $prefs.suggestions)
                } footer: {
                    Text("Falsche Buchstaben werden sofort rot, richtige Wörter leuchten kurz auf. Mit Starthilfe steht der erste Buchstabe jedes Wortes schon drin. Nichts davon zählt als Hilfe. Die Starthilfe gilt für neue Rätsel.")
                }
                .listRowBackground(Color.karte)
                Section {
                    Toggle("Tagesrätsel-Erinnerung", systemImage: "bell", isOn: Binding(
                        get: { prefs.reminderOn },
                        set: { on in Task { await store.setReminder(enabled: on) } }))
                    if prefs.reminderOn {
                        DatePicker("Uhrzeit", selection: Binding(
                            get: { Calendar.current.date(bySettingHour: prefs.reminderMinutes / 60, minute: prefs.reminderMinutes % 60, second: 0, of: .now) ?? .now },
                            set: { d in
                                let c = Calendar.current.dateComponents([.hour, .minute], from: d)
                                prefs.reminderMinutes = (c.hour ?? 9) * 60 + (c.minute ?? 0)
                                Task { await store.refreshReminders() }
                            }), displayedComponents: .hourAndMinute)
                    }
                    if store.reminderPermission == .denied {
                        Button("Mitteilungen in den iPhone-Einstellungen erlauben") {
                            if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                        }
                        .font(.footnote)
                    }
                } header: {
                    Text("Erinnerung")
                } footer: {
                    Text("Eine Mitteilung auf diesem iPhone, nur wenn du zustimmst. Sie entfällt, wenn du das Tagesrätsel schon gelöst hast.")
                }
                .listRowBackground(Color.karte)
                Section {
                    NavigationLink {
                        FlaggedView()
                    } label: {
                        LabeledContent("Gemerkte Fragen", value: "\(store.flagged.count)")
                    }
                } footer: {
                    Text("Fragen, die dir unpassend vorkamen, merkt die App nur auf diesem Gerät.")
                }
                .listRowBackground(Color.karte)
                Section {
                    Button("Fortschritt zurücksetzen", role: .destructive) { confirmStep = 1 }
                } footer: {
                    Text("Löscht Statistik, Erfolge, gelöste Rätsel, Zeiten und das laufende Rätsel. Deine Einstellungen und gemerkten Fragen bleiben.")
                }
                .listRowBackground(Color.karte)
                Section {
                    LabeledContent("Version", value: Self.version)
                    // Fund 185: eigene Partie-Seiten (Adressen als Platzhalter in `PartieLinks`, bis die Seiten stehen)
                    Link("Datenschutz", destination: PartieLinks.datenschutz)
                    Link("Hilfe & Support", destination: PartieLinks.support)
                    Link("Impressum", destination: PartieLinks.impressum)

                    if store.library.isDemo { Text("Dies ist eine Vorabversion mit Probe-Rätseln.").font(.footnote).foregroundStyle(.secondary) }
                } header: { EinstellungsKopf(gruppe: .ueber) }
                .listRowBackground(Color.karte)
            }
            .scrollContentBackground(.hidden)
            .background(Color.papier)
            .tint(Color.kwAkzent)
            .task { await store.refreshReminders() }
            // zweistufige Bestätigung
            .confirmationDialog("Fortschritt zurücksetzen?", isPresented: Binding(get: { confirmStep == 1 }, set: { if !$0 && confirmStep == 1 { confirmStep = 0 } }),
                                titleVisibility: .visible) {
                Button("Weiter", role: .destructive) { confirmStep = 2 }
                Button("Abbrechen", role: .cancel) { confirmStep = 0 }
            } message: {
                Text("Statistik, Erfolge und gelöste Rätsel werden gelöscht.")
            }
            .alert("Wirklich alles löschen?", isPresented: Binding(get: { confirmStep == 2 }, set: { if !$0 { confirmStep = 0 } })) {
                Button("Endgültig löschen", role: .destructive) { store.resetProgress(); confirmStep = 0; dismiss() }
                Button("Abbrechen", role: .cancel) { confirmStep = 0 }
            } message: {
                Text("Das lässt sich nicht rückgängig machen.")
            }
            .navigationTitle("Einstellungen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Fertig") { dismiss() } }
            }
        }
    }

    private static var version: String {
        let info = Bundle.main.infoDictionary
        let v = info?["CFBundleShortVersionString"] as? String ?? "–"
        let b = info?["CFBundleVersion"] as? String ?? "–"
        return "\(v) (\(b))"
    }
}

/// Liste der gemerkten Fragen (nur lokal); Wischen löscht.
struct FlaggedView: View {
    @Environment(GameStore.self) private var store

    var body: some View {
        List {
            if store.flagged.isEmpty {
                Text("Noch keine Fragen gemerkt. Im Spiel findest du „Frage merken“ im Menü oben rechts.")
                    .foregroundStyle(.secondary).listRowBackground(Color.karte)
            }
            ForEach(store.flagged) { f in
                VStack(alignment: .leading, spacing: Design.Abstand.xs) {
                    Text(f.clue).font(.headline).foregroundStyle(Color.tinte)
                    Text("Lösung: \(f.answer)").font(.subheadline).foregroundStyle(Color.kwAkzent)
                    Text("\(f.puzzleID) · \(Day(f.date)?.date().formatted(.dateTime.day().month(.abbreviated).year()) ?? f.date)")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
                .accessibilityElement(children: .combine)
                .listRowBackground(Color.karte)
            }
            .onDelete { store.removeFlagged(at: $0) }
        }
        .scrollContentBackground(.hidden)
        .background(Color.papier)
        .navigationTitle("Gemerkte Fragen")
        .navigationBarTitleDisplayMode(.inline)
    }
}
#endif
