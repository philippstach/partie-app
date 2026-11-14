// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI

/// Das laufende Kamerabild einer `LiveWuerfel`-Sitzung, damit auch andere Seiten (Würfelscanner in `WuerfelFunk`) dasselbe Bild zeigen können.
/// Das Bild füllt die Fläche (9:16, am Rand angeschnitten), genau wie in `LiveWuerfelSeite`.
public struct LiveKameraBild: View {
    private let live: LiveWuerfel
    public init(_ live: LiveWuerfel) { self.live = live }
    public var body: some View { KameraVorschau(sitzung: live.sitzung) }
}
#endif
