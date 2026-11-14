// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Speichern und Fortsetzen für Spiele im `SpielRahmen`: das Spiel schreibt seinen Zustand (Codable) beim Ändern,
/// der Rahmen bietet „Partie fortsetzen“ an und löscht den Stand beim Ende oder Abbrechen.
public enum SpielStand {
    /// Spiele, deren Stand der Spieler bewusst verworfen hat („Spiel beenden“): Beim Verlassen der Ansicht wird nicht noch einmal gesichert.
    nonisolated(unsafe) public static var verworfen: Set<String> = []

    private static func schluessel(_ spiel: String) -> String { "partie.stand.\(spiel)" }

    /// K-031/G-015: Kodieren mit fester Schlüsselreihenfolge. Ein `JSONEncoder` ohne `.sortedKeys` schreibt die Felder eines
    /// Structs nicht immer in derselben Reihenfolge (Dictionary mit Zufalls-Seed je Instanz; im Test 7 verschiedene Ausgaben
    /// für denselben Rommé-Stand bei 2000 Läufen). `Fortsetzbar` sah dadurch bei jeder Auswertung „neue“ Daten, schrieb in
    /// UserDefaults, das weckte alle @AppStorage-Beobachter, die nächste Auswertung kodierte wieder anders: Endlosschleife
    /// auf dem Hauptthread (Probe int5-hang-romme: `Fortsetzbar.body` onChange → `sichern` → `setObject:forKey:`).
    static func kodieren<T: Encodable>(_ wert: T) -> Data? {
        let e = JSONEncoder()
        e.outputFormatting = .sortedKeys
        return try? e.encode(wert)
    }

    public static func sichern<T: Encodable>(_ wert: T, spiel: String, defaults: UserDefaults = .standard) {
        guard let d = kodieren(wert) else { return }
        // K-031: Gleiche Daten nicht noch einmal schreiben. Jedes `defaults.set` löst synchron Benachrichtigungen für alle Beobachter aus
        // (AppStorage u. a.); mit neu angelegten Spielern führte das zu einer Render-Speicher-Schleife auf dem Hauptthread.
        if defaults.data(forKey: schluessel(spiel)) != d { defaults.set(d, forKey: schluessel(spiel)) }
        OffenesSpiel.setze(spiel, offen: true, defaults: defaults)
    }

    /// Beim Verlassen der Ansicht (Wegwischen, Zurück): Eine laufende Partie wird gesichert, außer der Spieler hat sie bewusst beendet.
    /// Liefert `true`, wenn gesichert wurde.
    @discardableResult
    public static func sichernBeimVerlassen<T: Encodable>(_ wert: T, spiel: String, laeuft: Bool, defaults: UserDefaults = .standard) -> Bool {
        guard laeuft, !verworfen.contains(spiel) else { return false }
        sichern(wert, spiel: spiel, defaults: defaults)
        return true
    }

    public static func laden<T: Decodable>(_ typ: T.Type = T.self, spiel: String, defaults: UserDefaults = .standard) -> T? {
        guard let d = defaults.data(forKey: schluessel(spiel)) else { return nil }
        return try? JSONDecoder().decode(T.self, from: d)
    }

    /// Der Ladeschritt von `fortsetzbar`: Ein gespeicherter, stimmiger Stand wird über `schreiben` übernommen (Ergebnis `true`).
    /// Ein unstimmiger Stand wird gelöscht statt geladen; ohne Stand passiert nichts (jeweils `false`).
    @discardableResult
    public static func uebernehmen<T: Decodable>(_ typ: T.Type = T.self, spiel: String, defaults: UserDefaults = .standard,
                                                 pruefen: (T) -> Bool = { _ in true }, schreiben: (T) -> Void) -> Bool {
        guard let g = laden(T.self, spiel: spiel, defaults: defaults) else { return false }
        guard pruefen(g) else { loeschen(spiel, defaults: defaults); return false }   // unstimmiger Stand: verwerfen statt abstürzen
        schreiben(g)
        return true
    }

    public static func vorhanden(_ spiel: String, defaults: UserDefaults = .standard) -> Bool {
        defaults.data(forKey: schluessel(spiel)) != nil
    }

    public static func loeschen(_ spiel: String, defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: schluessel(spiel))
        OffenesSpiel.setze(spiel, offen: false, defaults: defaults)
    }
}

#if canImport(UIKit)
import SwiftUI

public extension View {
    /// Fortsetzen ohne Eingriff in `init`: beim ersten Erscheinen wird ein gespeicherter Stand in `zustand` geladen,
    /// danach wird jede Änderung gespeichert. Der Rahmen löscht den Stand beim Start einer neuen Partie, beim Ende und beim Abbrechen.
    ///
    /// `standGeladen` meldet genau einmal je Partie, dass das Laden abgeschlossen ist: `true` = ein gespeicherter Stand wurde
    /// übernommen (Fortsetzen), `false` = frische Partie. Der Aufruf kommt nach dem Schreiben in `zustand`; erst ab hier ist sicher,
    /// wer am Zug ist. Spiele stoßen den Computer hier an statt in einem eigenen `onAppear` (dessen Reihenfolge zum Laden nicht
    /// festliegt). Spiele mit `computerZug(aktiv:id:)` brauchen das nicht, solange `aktiv` und `id` aus dem Zustand berechnet werden.
    func fortsetzbar<T: Codable>(_ spiel: String, _ zustand: Binding<T>, standGeladen: @escaping @MainActor (Bool) -> Void = { _ in }) -> some View {
        modifier(Fortsetzbar(spiel: spiel, lesen: { zustand.wrappedValue }, schreiben: { zustand.wrappedValue = $0 }, standGeladen: standGeladen))
    }
    func fortsetzbar<T: Codable>(_ spiel: String, _ zustand: Binding<T?>, standGeladen: @escaping @MainActor (Bool) -> Void = { _ in }) -> some View {
        modifier(Fortsetzbar(spiel: spiel, lesen: { zustand.wrappedValue }, schreiben: { zustand.wrappedValue = $0 }, standGeladen: standGeladen))
    }
    /// Mit Stimmigkeitsprüfung: Ein Stand, der zwar lesbar, aber in sich widersprüchlich ist (nach Updates, geänderten Optionen
    /// oder Beschädigung), wird verworfen statt geladen – das Spiel beginnt dann frisch, es gibt keinen Absturz.
    /// Ein verworfener Stand meldet `standGeladen(false)`.
    func fortsetzbar<T: Codable>(_ spiel: String, _ zustand: Binding<T>, pruefen: @escaping (T) -> Bool, standGeladen: @escaping @MainActor (Bool) -> Void = { _ in }) -> some View {
        modifier(Fortsetzbar(spiel: spiel, lesen: { zustand.wrappedValue }, schreiben: { zustand.wrappedValue = $0 }, pruefen: pruefen, standGeladen: standGeladen))
    }
    func fortsetzbar<T: Codable>(_ spiel: String, _ zustand: Binding<T?>, pruefen: @escaping (T) -> Bool, standGeladen: @escaping @MainActor (Bool) -> Void = { _ in }) -> some View {
        modifier(Fortsetzbar(spiel: spiel, lesen: { zustand.wrappedValue }, schreiben: { zustand.wrappedValue = $0 }, pruefen: pruefen, standGeladen: standGeladen))
    }
    /// Schreibt den Spielzustand bei jeder Änderung in den Speicher (Fortsetzen). Aufruf am Wurzel-View des Spiels.
    func spielstand<T: Encodable>(_ spiel: String, _ wert: T) -> some View {
        let daten = SpielStand.kodieren(wert)   // K-031: feste Reihenfolge, sonst ändert sich `daten` ohne echte Änderung
        return onChange(of: daten) { _, neu in
            if neu != nil { SpielStand.sichern(wert, spiel: spiel) }
        }
    }
}

struct Fortsetzbar<T: Codable>: ViewModifier {
    let spiel: String
    let lesen: () -> T?
    let schreiben: (T) -> Void
    var pruefen: (T) -> Bool = { _ in true }
    var standGeladen: @MainActor (Bool) -> Void = { _ in }
    @State private var geladen = false

    func body(content: Content) -> some View {
        let daten = lesen().flatMap { SpielStand.kodieren($0) }   // K-031: feste Reihenfolge, sonst Schleife (siehe `kodieren`)
        return content
            .onAppear {
                guard !geladen else { return }
                geladen = true
                standGeladen(SpielStand.uebernehmen(T.self, spiel: spiel, pruefen: pruefen, schreiben: schreiben))
            }
            .onChange(of: daten) { _, neu in
                if neu != nil, geladen, let w = lesen() { SpielStand.sichern(w, spiel: spiel) }
            }
    }
}
#endif
