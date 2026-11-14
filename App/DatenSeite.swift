// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import UniformTypeIdentifiers
import KlarGlas
import SpieleKern
import WidgetKit
import UserNotifications
import CoreSpotlight

/// Die Sicherungsdatei zum Teilen: wird erst beim Teilen gebaut (mit allen Fotos), nicht bei jedem Neuzeichnen.
struct SicherungsDatei: Transferable {
    let spieler: [Spieler]
    let partien: [PartieErgebnis]
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .json) { d in
            let daten = try Datensicherung.erstellen(spieler: d.spieler, partien: d.partien, foto: { SpielerBilder.daten($0) })
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(Datensicherung.dateiname())
            try daten.write(to: url, options: .atomic)
            return SentTransferredFile(url)
        }
    }
}

/// „Was Partie speichert“ (I1): Liste der lokalen Daten, Export, Alles löschen. Nichts verlässt das Gerät.
struct DatenSeite: View {
    @Environment(StatistikDienst.self) private var statistik
    @Environment(SpielerVerzeichnis.self) private var spieler
    @Environment(Favoriten.self) private var favoriten
    @Environment(IcloudVerwalter.self) private var icloud
    @State private var loeschen = false
    @AppStorage(Modi.kinderKey) private var kinder = false
    @State private var geloescht = false
    @State private var statistikLoeschen = false
    @State private var importOffen = false
    @State private var meldung: Text?

    private var offene: Int { OffenesSpiel.alle().filter { id in SpielKatalog.sichtbar.contains { $0.id == id } }.count }

    var body: some View {
        Form {
            Group {   // Designwechsel: Zeilengrund des Designs für alle Abschnitte (nicht eingerückt, damit die Zeilen darunter unverändert bleiben)
            Section {
                zeile("chart.bar", "Gespielte Partien", "\(statistik.ereignisse.count)")
                zeile("person.2", "Spieler", "\(spieler.alle.count)")
                zeile("heart", "Favoriten", "\(favoriten.ids.count)")
                zeile("play.circle", "Offene Partien", "\(offene)")
                zeile("slider.horizontal.3", "Einstellungen und Spielstände der Spiele", "")
            } header: { Text("Auf diesem Gerät gespeichert") } footer: {
                Text(icloud.aktiv ? "Deine Daten liegen auf deinem Gerät und, solange der iCloud-Abgleich an ist, in deinem privaten iCloud-Speicher. Partie hat keine Konten, keine eigenen Server und kein Tracking."
                                  : "Alle Daten bleiben auf deinem Gerät. Partie hat keine Konten, keine Server und kein Tracking.")
            }
            Section {
                Toggle("Mit iCloud abgleichen", isOn: Binding(get: { icloud.aktiv }, set: { icloud.aktiv = $0 }))
                if icloud.aktiv {
                    HStack {
                        Text(icloudStatus).foregroundStyle(.secondary).font(.subheadline)
                        Spacer()
                        Button("Jetzt abgleichen") { icloud.jetzt() }.disabled(icloud.status == .laeuft)
                    }
                }
            } header: { Text("iCloud") } footer: {
                Text("Gleicht Spieler, Fotos und Statistik zwischen deinen Geräten mit derselben Apple-ID ab, im privaten iCloud-Speicher. Es wird nur hinzugefügt: Löschen auf einem Gerät löscht nichts auf dem anderen.")
            }
            Section {
                ShareLink(item: SicherungsDatei(spieler: spieler.alle, partien: statistik.ereignisse), preview: SharePreview(Datensicherung.dateiname())) {
                    Label("Alles sichern (Spieler, Fotos, Partien)", systemImage: "externaldrive")
                }
                Button("Sicherung einlesen", systemImage: "square.and.arrow.down") { importOffen = true }
                ShareLink(item: statistik.csv()) { Label("Statistik exportieren (CSV)", systemImage: "square.and.arrow.up") }
            }
            // Fund 33: Zurücksetzen und Löschen als eigener, abgesetzter Abschnitt in Rot (vorher direkt unter „Alles sichern“ wie harmlose Zeilen)
            Section {
                Button("Statistik zurücksetzen", systemImage: "arrow.counterclockwise", role: .destructive) { freigegeben(String(localized: "Statistik zurücksetzen")) { statistikLoeschen = true } }
                    .foregroundStyle(Color.meldungRot)
                Button("Alle Daten löschen", systemImage: "trash", role: .destructive) { freigegeben(String(localized: "Alle Daten löschen")) { loeschen = true } }
                    .foregroundStyle(Color.meldungRot)
            }
            if geloescht {
                Section { Text("Alles gelöscht. Beende Partie und öffne sie neu, damit alle Ansichten leer starten.").font(.footnote) }
            }
            }.designZeilen()
        }
        .designListe()
        .fileImporter(isPresented: $importOffen, allowedContentTypes: [.json]) { ergebnis in einlesen(ergebnis) }
        .alert(meldung ?? Text(verbatim: ""), isPresented: Binding(get: { meldung != nil }, set: { if !$0 { meldung = nil } })) {
            Button("OK", role: .cancel) {}
        }
        .navigationTitle("Daten und Sicherung")   // Fund 17: wie der Zeilenname in den Einstellungen
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Statistik zurücksetzen?", isPresented: $statistikLoeschen, titleVisibility: .visible) {
            Button("Zurücksetzen", role: .destructive) { statistik.zuruecksetzen() }
            Button("Abbrechen", role: .cancel) {}
        } message: { Text("Alle gespeicherten Partien werden gelöscht.") }
        .confirmationDialog("Alle Daten löschen?", isPresented: $loeschen, titleVisibility: .visible) {
            Button("Alles löschen", role: .destructive) { alleLoeschen() }
            Button("Abbrechen", role: .cancel) {}
        } message: { Text("Partien, Spieler, Favoriten, Spielstände und Einstellungen werden unwiderruflich entfernt.") }
    }

    private var icloudStatus: LocalizedStringKey {
        switch icloud.status {
        case .aus: "Aus"
        case .laeuft: "Gleicht ab …"
        case .fertig(let t, _): "Zuletzt abgeglichen: \(t.formatted(date: .abbreviated, time: .shortened))"
        case .keinKonto: "Kein iCloud-Konto angemeldet"
        case .fehler: "Abgleich fehlgeschlagen, wird später erneut versucht"
        }
    }

    private func zeile(_ symbol: String, _ titel: LocalizedStringKey, _ wert: String) -> some View {
        HStack {
            Label(titel, systemImage: symbol)
            Spacer()
            Text(verbatim: wert).foregroundStyle(.secondary).monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }

    /// Liest eine Sicherungsdatei ein und fügt hinzu, was fehlt. Vorhandenes wird nie überschrieben oder gelöscht.
    private func einlesen(_ ergebnis: Result<URL, Error>) {
        guard case .success(let url) = ergebnis else { return }
        let zugriff = url.startAccessingSecurityScopedResource()
        defer { if zugriff { url.stopAccessingSecurityScopedResource() } }
        guard let daten = try? Data(contentsOf: url) else { meldung = Text("Die Datei konnte nicht gelesen werden."); return }
        do {
            let u = spieler.uebernehmen(try Datensicherung.lesen(daten), statistik: statistik)
            meldung = u.nichtsNeu ? Text("Nichts Neues: Alles aus der Sicherung war schon da.")
                                  : Text("Übernommen: \(u.spieler) Personen, \(u.fotos) Fotos, \(u.partien) Partien.")
        } catch SicherungFehler.zuNeu {
            meldung = Text("Diese Sicherung stammt aus einer neueren Version von Partie. Bitte aktualisiere Partie und versuche es noch einmal.")
        } catch {
            meldung = Text("Das ist keine Sicherung von Partie.")
        }
    }

    /// C-003: Im Kinder-Modus braucht das Löschen die gleiche Freigabe wie das Ausschalten des Modus.
    private func freigegeben(_ grund: String, dann aktion: @escaping () -> Void) {
        guard kinder else { aktion(); return }
        Task { if await KinderSchutz.freigeben(grund: grund) { aktion() } }
    }

    private func alleLoeschen() {
        statistik.zuruecksetzen()
        for s in spieler.alle { spieler.loeschen(s.id) }
        favoriten.zuruecksetzen()
        icloud.zuruecksetzen()
        AllesLoeschen.aufraeumen()
        geloescht = true
    }
}

/// C-002: Alles, was „Alle Daten löschen“ außer Statistik und Spielern entfernen muss: Widget-Daten (App Group), geplante und
/// zugestellte Mitteilungen, Spotlight-Einträge, Live Activity und die gespeicherten Einstellungen.
enum AllesLoeschen {
    @MainActor
    static func aufraeumen() {
        if let bundle = Bundle.main.bundleIdentifier { UserDefaults.standard.removePersistentDomain(forName: bundle) }
        UserDefaults(suiteName: PartieGeteilt.gruppe)?.removePersistentDomain(forName: PartieGeteilt.gruppe)
        let zentrum = UNUserNotificationCenter.current()
        zentrum.removeAllPendingNotificationRequests()
        zentrum.removeAllDeliveredNotifications()
        CSSearchableIndex.default().deleteAllSearchableItems { _ in }
        AktivitaetVerwalter.beenden()
        WidgetCenter.shared.reloadAllTimelines()
    }
}
