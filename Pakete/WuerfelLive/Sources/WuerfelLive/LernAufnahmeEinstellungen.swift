// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import UIKit

/// Einstellungen der Lern-Aufnahme (Testfunktion): Schalter, Zähler, „Aufnahmen teilen“ und „Aufnahmen löschen“.
/// Als Zeilen für eine `Section` in den Einstellungen gedacht. Der Aufrufer zeigt sie im Kinder-Modus nicht.
public struct LernAufnahmeEinstellungen: View {
    @AppStorage(LernAufnahme.schalterKey) private var an = false
    @State private var anzahl = 0
    @State private var korrigiert = 0
    @State private var packt = false
    @State private var fehler = false
    @State private var teilen: TeilDatei?
    @State private var loeschenFragen = false

    public init() {}

    public var body: some View {
        Toggle(isOn: $an) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Lern-Aufnahme (Test)", bundle: .main)
                Text("Speichert Würfelbilder auf diesem Gerät, damit die Erkennung daraus lernen kann.", bundle: .main)
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .onAppear(perform: zaehle)
        .sheet(item: $teilen) { t in TeilBlatt(url: t.url).ignoresSafeArea() }
        .confirmationDialog(Text("Alle gespeicherten Würfelbilder löschen?", bundle: .main), isPresented: $loeschenFragen, titleVisibility: .visible) {
            Button(role: .destructive) { LernAufnahme.loescheAlle(); zaehle() } label: { Text("Löschen", bundle: .main) }
            Button(role: .cancel) {} label: { Text("Abbrechen", bundle: .main) }
        } message: {
            Text("Das lässt sich nicht rückgängig machen.", bundle: .main)
        }
        if an {
            Text("Bei jedem bestätigten Wurf werden das Standbild, die Rahmen, die bestätigten Augenzahlen und einige Bilder davor gespeichert, auch die Fotos deiner Umgebung. Die Bilder bleiben auf diesem Gerät und werden nicht gesendet. Sie verlassen es nur, wenn du „Aufnahmen teilen“ wählst. Zum Ausschalten genügt der Schalter, schon gespeicherte Bilder bleiben, bis du sie löschst.", bundle: .main)
                .font(.footnote).foregroundStyle(.secondary)
        }
        if anzahl > 0 || an {
            HStack {
                Text("Gespeicherte Würfe", bundle: .main)
                Spacer()
                (anzahl == 0 ? Text("Keine", bundle: .main) : Text("\(anzahl), davon \(korrigiert) korrigiert", bundle: .main))
                    .foregroundStyle(.secondary).monospacedDigit()
            }
            .accessibilityElement(children: .combine)
        }
        if anzahl > 0 {
            Button { packen() } label: {
                HStack {
                    Label { Text("Aufnahmen teilen", bundle: .main) } icon: { Image(systemName: "square.and.arrow.up") }
                    if packt { Spacer(); ProgressView() }
                }
            }
            .disabled(packt)
            if fehler {
                Text("Das Paket konnte nicht erstellt werden. Ist genug Speicher frei?", bundle: .main).font(.footnote).foregroundStyle(.red)
            }
            Button(role: .destructive) { loeschenFragen = true } label: {
                Label { Text("Aufnahmen löschen", bundle: .main) } icon: { Image(systemName: "trash") }
            }
            .disabled(packt)
        }
    }

    private func zaehle() {
        anzahl = LernAufnahme.anzahl()
        korrigiert = LernAufnahme.anzahlKorrigiert()
    }

    private func packen() {
        packt = true; fehler = false
        Task {
            let url = await Task.detached(priority: .userInitiated) { try? LernAufnahme.packe() }.value
            packt = false
            if let url { teilen = TeilDatei(url: url) } else { fehler = true }
        }
    }
}

private struct TeilDatei: Identifiable {
    let url: URL
    var id: URL { url }
}

/// Das iOS-Teilen-Blatt für eine Datei (AirDrop an den Mac, Dateien, Mail …).
private struct TeilBlatt: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> UIActivityViewController { UIActivityViewController(activityItems: [url], applicationActivities: nil) }
    func updateUIViewController(_ c: UIActivityViewController, context: Context) {}
}
#endif
