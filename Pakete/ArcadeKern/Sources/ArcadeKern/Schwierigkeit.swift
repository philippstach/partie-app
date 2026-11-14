// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Gemeinsame Schwierigkeitskurve: steigt anfangs spürbar und flacht dann ab, erreicht die Grenze aber nie ruckartig.
/// `f(t) = 1 - 2^(-t / halbwert)`: bei `t = halbwert` ist die Hälfte erreicht, bei `3 × halbwert` sind es 87,5 %.
public enum Schwierigkeit {
    public static func anteil(_ t: Double, halbwert: Double) -> Double {
        guard t > 0, halbwert > 0 else { return 0 }
        return 1 - pow(2, -t / halbwert)
    }
    /// Wert zwischen `start` (leicht) und `grenze` (schwerster Wert) nach `t`.
    public static func wert(start: Double, grenze: Double, t: Double, halbwert: Double) -> Double {
        start + (grenze - start) * anteil(t, halbwert: halbwert)
    }
}

/// Punkte und Rekord: Rekord ist der höchste frühere Wert; ein Rekord zählt nur, wenn er echt höher ist (und größer als 0).
public enum Rekord {
    public static func istNeu(punkte: Int, bisher: Int?) -> Bool { punkte > 0 && punkte > (bisher ?? 0) }
}

/// Wahl „Leicht / Mittel / Schwer“ für Spiele ohne Computergegner (1, 2, 3). Sie verschiebt nur das Tempo und die Kurve,
/// die Fairness-Garantien der Spiele (schaffbare Lücken und Abstände) bleiben in jeder Stufe erhalten.
public enum ArcadeStufe {
    public static func begrenzt(_ stufe: Int) -> Int { min(3, max(1, stufe)) }
    /// Faktor für Tempo (Ball, Läufer, Fallgeschwindigkeit): 0,85 / 1 / 1,15.
    public static func tempoFaktor(_ stufe: Int) -> Double { [0.85, 1.0, 1.15][begrenzt(stufe) - 1] }
    /// Faktor für den Fortschritt auf der Schwierigkeitskurve (Höhe, Reihen): 0,6 / 1 / 1,5.
    public static func kurvenFaktor(_ stufe: Int) -> Double { [0.6, 1.0, 1.5][begrenzt(stufe) - 1] }
}
