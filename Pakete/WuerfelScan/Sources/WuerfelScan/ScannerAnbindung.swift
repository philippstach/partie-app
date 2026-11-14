// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI

/// Wie weit die Funkverbindung zum Würfelscanner gerade ist (für das Zeichen „Scanner verbunden“ im Spiel).
public struct ScannerStand: Equatable, Sendable {
    /// Name des Scanners; `nil`, solange keiner verbunden ist.
    public var name: String?
    /// Die Verbindung ist kurz weg und wird gerade wiederhergestellt.
    public var unterbrochen: Bool
    public init(name: String? = nil, unterbrochen: Bool = false) { self.name = name; self.unterbrochen = unterbrochen }
}

/// Offene Kopplungsanfrage eines unbekannten Scanners.
public struct ScannerAnfrage {
    public let name: String
    public let zusagen: () -> Void
    public let ablehnen: () -> Void
    public init(name: String, zusagen: @escaping () -> Void, ablehnen: @escaping () -> Void) {
        self.name = name; self.zusagen = zusagen; self.ablehnen = ablehnen
    }
}

/// Anbindung der Spiele an den Würfelscanner (zweites Gerät). Die Spiele kennen `WuerfelFunk` nicht; die App setzt diese Haken beim Start
/// (`FunkEinsetzen`). Ohne Haken zeigen die Spiele nichts davon.
public enum WuerfelScannerFunk {
    /// Ob der Scanner-Weg überhaupt angeboten wird.
    public static var verfuegbar: Bool { anmelden != nil }
    /// Aktueller Stand der Verbindung (wird im Aufbau der Ansicht gelesen, die Ansicht aktualisiert sich dann von selbst).
    nonisolated(unsafe) public static var stand: (@MainActor () -> ScannerStand)?
    /// Meldet dieses Spielgerät als Empfänger an (startet bei Bedarf das Werben) und gibt jeden ankommenden Wurf an `wurf`.
    nonisolated(unsafe) public static var anmelden: (@MainActor (_ id: UUID, _ wurf: @escaping ([Int]) -> Void) -> Void)?
    /// Meldet den Empfänger wieder ab. Die Verbindung bleibt; ohne Verbindung und ohne anderen Empfänger endet das Werben.
    nonisolated(unsafe) public static var abmelden: (@MainActor (_ id: UUID) -> Void)?
    /// Sagt dem Scanner, wie viele Würfel der nächste Wurf haben soll und wie viele gehalten sind (`erwartet` nil: egal).
    nonisolated(unsafe) public static var meldeLage: (@MainActor (_ spiel: String?, _ erwartet: Int?, _ gehalten: Int) -> Void)?
    /// Kleine Bildausschnitte (JPEG) der Würfel des zuletzt angekommenen Wurfs, in der Reihenfolge der Augen; leer, wenn der Scanner keine schickt.
    /// Wird im Wurf-Hook (`anmelden`) gelesen, bevor dieser gerufen wird.
    nonisolated(unsafe) public static var bilder: (@MainActor () -> [Data])?
    /// Offene Anfrage eines unbekannten Scanners.
    nonisolated(unsafe) public static var anfrage: (@MainActor () -> ScannerAnfrage?)?
}

public extension View {
    /// Zeigt die Rückfrage „Scanner verbinden?“, sobald ein unbekannter Scanner anfragt – auf jeder Seite, auf der dieser Modifier liegt.
    /// Die App legt ihn auf die Wurzel, jedes Blatt mit Würfeleingabe zusätzlich auf sich (ein Blatt verdeckt die Wurzel).
    func wuerfelScannerAnfrage() -> some View { modifier(ScannerAnfrageDialog()) }
}

private struct ScannerAnfrageDialog: ViewModifier {
    func body(content: Content) -> some View {
        let a = WuerfelScannerFunk.anfrage?()
        content.alert(
            Text("Scanner verbinden?", bundle: .main),
            isPresented: Binding(get: { a != nil }, set: { _ in }),
            presenting: a
        ) { a in
            Button { a.zusagen() } label: { Text("Verbinden", bundle: .main) }
            Button(role: .cancel) { a.ablehnen() } label: { Text("Ablehnen", bundle: .main) }
        } message: { a in
            Text("„\(a.name)“ möchte als Würfelscanner Würfe an dieses Gerät senden.", bundle: .main)
        }
    }
}
