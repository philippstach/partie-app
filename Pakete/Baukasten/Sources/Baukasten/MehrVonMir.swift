// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
#if os(iOS)
import StoreKit
#endif

/// Eine eigene App für die Querverweise. `appStoreID` bleibt nil, bis die App live ist; solange wird sie nicht angezeigt.
public struct EigeneApp: Identifiable, Hashable, Sendable {
    public let id: String            // = linkKey
    public let name: String
    public let kurzbeschreibung: String
    public let symbol: String        // SF Symbol, nur als Platzhalter für das Icon
    public let farbe: AkzentFarbe
    public var appStoreID: String?
    public var kinderApp = false

    /// Normaler App-Store-Link: Rückfall, wenn das Blatt nicht lädt (kein Netz, App Store nicht erreichbar).
    public var storeURL: URL? { appStoreID.flatMap { URL(string: "https://apps.apple.com/app/id\($0)") } }
}

public enum EigeneAppKatalog {
    /// Zentrale Liste: Beim Livegang einer App hier die App-Store-ID eintragen, dann zeigen alle anderen Apps sie beim nächsten Update.
    public static var alle: [EigeneApp] = [
        .init(id: "sudoku", name: "Sudoku", kurzbeschreibung: "Zahlenrätsel", symbol: "square.grid.3x3.fill", farbe: .blau),
        .init(id: "10k", name: "10k", kurzbeschreibung: "Würfelspiel", symbol: "dice.fill", farbe: .orange),
        .init(id: "solitaer", name: "Solitär", kurzbeschreibung: "Kartenspiel", symbol: "suit.spade.fill", farbe: .gruen),
        .init(id: "viererreihe", name: "Viererreihe", kurzbeschreibung: "Vier gewinnt", symbol: "circle.grid.3x3.fill", farbe: .rot),
        .init(id: "galgen", name: "Galgenmännchen", kurzbeschreibung: "Wörter raten", symbol: "textformat.abc", farbe: .violett),
        .init(id: "kreuzwort", name: "Wortpfeil", kurzbeschreibung: "Schwedenrätsel für jeden Tag", symbol: "arrow.right.square.fill", farbe: .pink),
        .init(id: "rauswurf", name: "Rauswurf", kurzbeschreibung: "Würfeln, ziehen, rauswerfen", symbol: "figure.walk", farbe: .tuerkis),
        .init(id: "schocken", name: "Schocken", kurzbeschreibung: "Würfel & Deckel", symbol: "dice", farbe: .braun),
        .init(id: "yacht", name: "Yacht", kurzbeschreibung: "Das Würfelspiel", symbol: "sailboat.fill", farbe: .indigo),
    ]

    /// Was in der aktuellen App erscheinen darf: nicht die App selbst, nur Livegänge, in Kinder-Apps gar nichts
    /// (Leitlinie 1.3: keine Fremdwerbung/Links nach außen in der Kinderkategorie), Kinder-Apps nie als Ziel in anderen.
    public static func fuer(aktuell: String, kinderApp: Bool, katalog: [EigeneApp] = alle) -> [EigeneApp] {
        guard !kinderApp else { return [] }
        return katalog.filter { $0.id != aktuell && $0.appStoreID != nil && !$0.kinderApp }
    }
}

public struct MehrVonMirAbschnitt: View {
    let apps: [EigeneApp]
    @State private var offen: EigeneApp?
    @Environment(\.openURL) private var openURL

    public init(aktuell: String, kinderApp: Bool, katalog: [EigeneApp] = EigeneAppKatalog.alle) {
        apps = EigeneAppKatalog.fuer(aktuell: aktuell, kinderApp: kinderApp, katalog: katalog)
    }

    public var body: some View {
        if !apps.isEmpty {
            Section {
                ForEach(apps) { app in
                    Button { offen = app } label: {
                        Label {
                            VStack(alignment: .leading) {
                                Text(app.name).foregroundStyle(.primary)
                                Text(LocalizedStringKey(app.kurzbeschreibung), bundle: .module).font(.caption).foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: app.symbol).foregroundStyle(.white)
                                .frame(width: 30, height: 30)
                                .background(app.farbe.flaeche, in: .rect(cornerRadius: 7))
                        }
                    }
                }
            } header: { Text("Mehr von mir", bundle: .module) }
            #if os(iOS)
            .sheet(item: $offen) { app in
                ProduktSeite(appStoreID: app.appStoreID ?? "") {
                    // Laden fehlgeschlagen: Blatt schließen und den Link im App Store öffnen (dort erscheint die Offline-Meldung des Systems).
                    offen = nil
                    if let url = app.storeURL { openURL(url) }
                }
                .ignoresSafeArea()
            }
            #endif
        }
    }
}

#if os(iOS)
/// Zeigt die App-Store-Seite einer App im Blatt, ohne die App zu verlassen (SKStoreProductViewController).
struct ProduktSeite: UIViewControllerRepresentable {
    let appStoreID: String
    let beiFehler: () -> Void

    func makeUIViewController(context: Context) -> SKStoreProductViewController {
        let vc = SKStoreProductViewController()
        vc.delegate = context.coordinator
        let fehler = beiFehler
        vc.loadProduct(withParameters: [SKStoreProductParameterITunesItemIdentifier: appStoreID]) { geladen, _ in
            if !geladen { DispatchQueue.main.async { fehler() } }
        }
        return vc
    }
    func updateUIViewController(_ vc: SKStoreProductViewController, context: Context) {}
    func makeCoordinator() -> Koordinator { Koordinator() }

    final class Koordinator: NSObject, SKStoreProductViewControllerDelegate {
        func productViewControllerDidFinish(_ vc: SKStoreProductViewController) { vc.dismiss(animated: true) }
    }
}
#endif
