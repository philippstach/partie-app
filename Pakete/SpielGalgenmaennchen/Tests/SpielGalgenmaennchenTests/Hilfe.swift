// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

/// Manche Tests hängen an der App-Sprache des Geräts (Teilen-Text) und am Zeitverhalten der Oberfläche (Sieg-Moment).
/// Auf dem Mac (swift test und Mac Catalyst) gibt es kein App-Paket mit Sprache und keine Bewegungseinstellung; dort laufen sie nicht.
let nurAufDemTelefon: Bool = {
    #if os(iOS) && !targetEnvironment(macCatalyst)
    true
    #else
    false
    #endif
}()
