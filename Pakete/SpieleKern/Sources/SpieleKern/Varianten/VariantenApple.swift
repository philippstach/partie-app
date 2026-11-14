// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

/// Verfügbarkeit des Apple-Sprachmodells für die Ansage. Alles hinter `#if canImport(FoundationModels)` und `#available(iOS 26)`;
/// iOS 17 bis 25, Geräte ohne Apple Intelligence und Sprachen ohne Modell ergeben `.verborgen`.
public extension VariantenStatus {
    static func aktuell(sprache: Locale = Locale(identifier: "de_DE")) -> VariantenStatus {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *) {
            let modell = SystemLanguageModel.default
            switch modell.availability {
            case .available:
                return modell.supportsLocale(sprache) ? .bereit : .verborgen
            case .unavailable(.modelNotReady): return .nichtBereit
            case .unavailable(.appleIntelligenceNotEnabled): return .aus
            case .unavailable: return .verborgen
            }
        }
        #endif
        return .verborgen
    }
}

#if canImport(FoundationModels)

/// Strukturierte Antwort des Modells. Das Modell nennt Schlüssel und Wert als Text; die App prüft und setzt (siehe `VariantenPruefer`).
@available(iOS 26.0, macOS 26.0, *)
@Generable
struct VariantenModellAntwort {
    @Guide(description: "id der gemeinten Vorlage aus der Liste VORLAGEN, sonst leer lassen")
    var vorlage: String?
    @Guide(description: "Nur die Optionen, die die Person ausdrücklich ändern will, höchstens zehn", .maximumCount(10))
    var aenderungen: [VariantenModellAenderung]
}

@available(iOS 26.0, macOS 26.0, *)
@Generable
struct VariantenModellAenderung {
    @Guide(description: "id der Option aus der Liste OPTIONEN")
    var option: String
    @Guide(description: "Bei Schaltern „an“ oder „aus“, bei Zahlen eine Ziffer, bei Auswahl genau eine genannte id")
    var wert: String
}

/// Echtes Modell: Apple Intelligence auf dem Gerät. Kein Zwischenspeicher, eine frische Sitzung je Ansage (die Anweisung hängt vom Spielstand ab).
@available(iOS 26.0, macOS 26.0, *)
public struct AppleVariantenModell: VariantenModell {
    public init() {}
    public func waehle(anweisung: String, eingabe: String) async throws -> VariantenRohAntwort {
        guard SystemLanguageModel.default.availability == .available else { throw VariantenFehler.nichtVerfuegbar }
        let sitzung = LanguageModelSession(instructions: anweisung)
        let antwort = try await sitzung.respond(to: eingabe, generating: VariantenModellAntwort.self,
                                                options: GenerationOptions(sampling: .greedy, maximumResponseTokens: 300))
        let a = antwort.content
        return VariantenRohAntwort(vorlage: a.vorlage, aenderungen: a.aenderungen.map { .init(option: $0.option, wert: $0.wert) })
    }
}

public extension VariantenAnsage {
    /// Ansage mit dem Apple-Modell, oder `nil`, wenn sie nicht angeboten wird (Status nicht `.bereit`).
    static func apple() -> VariantenAnsage? {
        if #available(iOS 26.0, macOS 26.0, *), VariantenStatus.aktuell() == .bereit { return VariantenAnsage(modell: AppleVariantenModell()) }
        return nil
    }
}

#endif
