// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

/// App-Symbol wechseln (Konzept 2.3): die Symbole der Spiele bleiben unverändert, nur das Bild wechselt, der Name bleibt „Partie“.
struct SymbolSeite: View {
    @State private var aktuell: String? = UIApplication.shared.alternateIconName
    @State private var fehler: String?
    @State private var suche = ""

    private let spalten = [GridItem(.adaptive(minimum: 84), spacing: 14)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Wähle, welches Bild Partie auf deinem Home-Bildschirm zeigt: das Partie-Zeichen oder das Symbol eines deiner Lieblingsspiele. Es ist immer dieselbe App, nur das Bild ändert sich. Das Spiel selbst öffnest du weiterhin in Partie.")
                    .font(.subheadline).foregroundStyle(.secondary)
                LazyVGrid(columns: spalten, spacing: 18) {
                    if suche.isEmpty || "Partie".localizedCaseInsensitiveContains(suche) { kachel(name: "Partie", icon: nil, vorschau: "AppIcon") }
                    ForEach(SpielKatalog.spielbar.filter { UIImage(named: "Vorschau-\($0.id)") != nil && (suche.isEmpty || $0.name.localizedCaseInsensitiveContains(suche)) }, id: \.id) { m in
                        kachel(name: m.name, icon: "Symbol-\(m.id)", vorschau: "Symbol-\(m.id)")
                    }
                }
                Text("Der Name unter dem Symbol bleibt „Partie“. iOS zeigt beim Wechsel einen Hinweis, das ist normal. Das Bild mit dem Rahmen ist gerade gewählt.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            .padding(Theme.seitenRand)
        }
        .background(Color.seitenGrund)
        .searchable(text: $suche, prompt: Text("Spiel suchen"))
        .navigationTitle("App-Symbol")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Symbol nicht geändert", isPresented: Binding(get: { fehler != nil }, set: { if !$0 { fehler = nil } })) {
            Button("OK") { fehler = nil }
        } message: { Text(fehler ?? "") }
    }

    private func kachel(name: String, icon: String?, vorschau: String) -> some View {
        Button {
            UIApplication.shared.setAlternateIconName(icon) { e in
                DispatchQueue.main.async {
                    if let e { fehler = e.localizedDescription } else { aktuell = icon }
                }
            }
        } label: {
            VStack(spacing: 6) {
                Group {
                    if let ui = vorschauBild(icon) {
                        Image(uiImage: ui).resizable().scaledToFit()
                    } else { Color.gray.opacity(0.2) }
                }
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color.primary.opacity(aktuell == icon ? 0.7 : 0), lineWidth: 3))   // Auswahlring neutral (Konzept 3.3: keine Akzentrahmen)
                Text(verbatim: name).font(.caption).foregroundStyle(.primary).lineLimit(1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: name))
        .accessibilityAddTraits(aktuell == icon ? [.isSelected] : [])
    }

    private func vorschauBild(_ icon: String?) -> UIImage? {
        guard let icon else { return UIImage(named: "Vorschau-partie") }
        return UIImage(named: icon.replacingOccurrences(of: "Symbol-", with: "Vorschau-"))
    }

}


/// App-Symbol passend zum Spiel, mit dem Partie startet (Schalter „App-Symbol anpassen“ in den Einstellungen).
@MainActor
enum AppSymbol {
    static func anwenden(folgtStart: Bool, spiel: String) {
        let ziel: String? = (folgtStart && !spiel.isEmpty && UIImage(named: "Vorschau-\(spiel)") != nil) ? "Symbol-\(spiel)" : nil
        guard UIApplication.shared.alternateIconName != ziel else { return }
        UIApplication.shared.setAlternateIconName(ziel) { _ in }
    }
}
