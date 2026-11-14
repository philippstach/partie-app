// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import StoreKit

/// Eine Trinkgeld-Stufe (verbrauchbarer In-App-Kauf). Der Preis kommt immer aus dem App Store, nie aus dem Code.
public struct TrinkgeldStufe: Identifiable, Hashable, Sendable {
    public let name: String      // kurz, ASCII: "klein", "mittel", "gross"
    public let titel: String     // Anzeige (deutscher Schlüssel im String-Katalog)
    public init(name: String, titel: String) { self.name = name; self.titel = titel }
    public var id: String { name }

    public static let klein = TrinkgeldStufe(name: "klein", titel: "Kleines Danke")
    public static let mittel = TrinkgeldStufe(name: "mittel", titel: "Mittleres Danke")
    public static let gross = TrinkgeldStufe(name: "gross", titel: "Großes Danke")
    public static let standard = [klein, mittel, gross]

    /// Produkt-ID in App Store Connect: `<Bundle-ID>.trinkgeld.<name>`
    public func produktID(bundleID: String) -> String { "\(bundleID).trinkgeld.\(name)" }
}

@Observable
@MainActor
public final class TrinkgeldLager {
    public enum Zustand: Equatable { case leer, laedt, bereit, kauft, danke, fehler }

    public private(set) var produkte: [Product] = []
    public private(set) var zustand: Zustand = .leer
    private let ids: [String]
    private var beobachter: Task<Void, Never>?

    public init(stufen: [TrinkgeldStufe] = TrinkgeldStufe.standard, bundleID: String = AppInfo.bundleID) {
        ids = stufen.map { $0.produktID(bundleID: bundleID) }
        // Offene Käufe (z. B. App wurde mitten im Kauf beendet) abschließen. Es wird nichts freigeschaltet.
        beobachter = Task.detached {
            for await ergebnis in Transaction.updates {
                switch ergebnis {
                case .verified(let t), .unverified(let t, _): await t.finish()
                }
            }
        }
    }

    public func laden() async {
        guard !ids.isEmpty, zustand == .leer || zustand == .fehler else { return }
        zustand = .laedt
        do {
            produkte = try await Product.products(for: ids).sorted { $0.price < $1.price }
            zustand = produkte.isEmpty ? .fehler : .bereit
        } catch { zustand = .fehler }
    }

    public func kaufen(_ produkt: Product) async {
        zustand = .kauft
        do {
            switch try await produkt.purchase() {
            case .success(let ergebnis):
                if case .verified(let t) = ergebnis { await t.finish(); zustand = .danke } else { zustand = .bereit }
            case .userCancelled, .pending: zustand = .bereit
            @unknown default: zustand = .bereit
            }
        } catch { zustand = .fehler }
    }
}

/// Abschnitt „Unterstützen“: freiwillig, schaltet nichts frei. Nicht „Spende“ nennen (Spende = Gemeinnützigkeit).
public struct TrinkgeldAbschnitt: View {
    @Bindable var lager: TrinkgeldLager
    let stufen: [TrinkgeldStufe]

    public init(lager: TrinkgeldLager, stufen: [TrinkgeldStufe] = TrinkgeldStufe.standard) {
        self.lager = lager; self.stufen = stufen
    }

    public var body: some View {
        Section {
            switch lager.zustand {
            case .leer, .laedt:
                HStack { ProgressView(); Text("Laden …", bundle: .module).foregroundStyle(.secondary) }
            case .fehler where lager.produkte.isEmpty:
                Text("Trinkgeld ist gerade nicht verfügbar.", bundle: .module).foregroundStyle(.secondary)
            default:
                ForEach(lager.produkte) { produkt in
                    Button {
                        Task { await lager.kaufen(produkt) }
                    } label: {
                        LabeledContent {
                            Text(produkt.displayPrice).monospacedDigit()
                        } label: {
                            Text(titel(fuer: produkt), bundle: .module)
                        }
                    }
                    .disabled(lager.zustand == .kauft)
                }
                if lager.zustand == .danke {
                    Label { Text("Danke dir!", bundle: .module) } icon: { Image(systemName: "heart.fill").foregroundStyle(.pink) }
                }
            }
        } header: {
            Text("Unterstützen", bundle: .module)
        } footer: {
            Text("Freiwillig. Es wird nichts freigeschaltet, alle Funktionen bleiben für alle gleich.", bundle: .module)
        }
        .task { await lager.laden() }
    }

    private func titel(fuer produkt: Product) -> LocalizedStringKey {
        let stufe = stufen.first { produkt.id.hasSuffix(".trinkgeld.\($0.name)") }
        return LocalizedStringKey(stufe?.titel ?? produkt.displayName)
    }
}
