// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI

// Vorschau/Demo: zeigt die Einstellungen so, wie jede App sie bekommt. Kein Teil der App-Logik.
#if DEBUG
private struct DemoEinstellungen: View {
    @State private var akzent = AkzentSpeicher(standard: .gruen, speicher: FluechtigerSpeicher())
    @State private var lager = TrinkgeldLager(bundleID: "de.philippstach.demo")
    let konfig = BaukastenKonfiguration(appName: "Demo", links: AppLinks(key: "yacht", appStoreID: "1"), standardAkzent: .gruen)

    var body: some View {
        NavigationStack {
            Form {
                Section("Aussehen") { AkzentAuswahl(speicher: akzent) }
                BaukastenUeberGruppe(konfig: konfig, trinkgeldLager: lager)
            }
            .navigationTitle("Einstellungen")
        }
        .baukastenAkzent(akzent.gewaehlt)
    }
}

#Preview("Einstellungen") { DemoEinstellungen() }
#Preview("Einstellungen dunkel, große Schrift") {
    DemoEinstellungen().preferredColorScheme(.dark).dynamicTypeSize(.accessibility2)
}
#endif
