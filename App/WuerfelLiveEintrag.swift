// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import SpieleKern
import WuerfelFunk
import WuerfelLive
import WuerfelScan

/// Einstellungs-Eintrag für die Live-Würfelerkennung (Test). Im Kinder-Modus gibt es weder Eintrag noch Kamera.
struct WuerfelLiveEintrag: View {
    @AppStorage(Modi.kinderKey) private var kinder = false

    var body: some View {
        if !kinder, LiveWuerfel.verfuegbar {
            NavigationLink {
                WuerfelLiveZiel()
            } label: {
                Label("Würfel mit Kamera erkennen", systemImage: "camera.viewfinder")
            }
            NavigationLink {
                FunkZiel(scanner: true)
            } label: {
                Label("Als Würfelscanner nutzen", systemImage: "iphone.gen3.radiowaves.left.and.right")
            }
            NavigationLink {
                FunkZiel(scanner: false)
            } label: {
                Label("Würfel vom Scanner empfangen", systemImage: "ipad.and.iphone")
            }
            if LernAufnahme.istBeta { LernAufnahmeEinstellungen() }   // 14.11.: Lern-Aufnahme nur in der Beta (TestFlight)
        }
    }
}

/// Zielseite mit zweiter Sperre: Wird der Kinder-Modus doch eingeschaltet, startet die Kamera nie.
private struct WuerfelLiveZiel: View {
    @AppStorage(Modi.kinderKey) private var kinder = false
    var body: some View {
        if kinder {
            ContentUnavailableView("Im Kinder-Modus nicht verfügbar", systemImage: "lock.fill")
        } else {
            LiveWuerfelSeite()
        }
    }
}

/// Scanner- und Empfangsseite mit derselben Kinder-Modus-Sperre wie die Kamera.
private struct FunkZiel: View {
    let scanner: Bool
    @AppStorage(Modi.kinderKey) private var kinder = false
    var body: some View {
        if kinder {
            ContentUnavailableView("Im Kinder-Modus nicht verfügbar", systemImage: "lock.fill")
        } else if scanner {
            WuerfelScannerSeite()
        } else {
            WuerfelEmpfangSeite().wuerfelScannerAnfrage()
        }
    }
}

/// Setzt die Empfangsseite und die Anbindung der Spiele an den Würfelscanner ein (Aufruf beim Start, neben `fuerFotoScanEinsetzen`).
enum FunkEinsetzen {
    static func einsetzen() {
        MainActor.assumeIsolated { einsetzenAufMain() }
    }

    @MainActor private static func einsetzenAufMain() {
        // Koppel-Blatt in den Spielen („Vom Scanner“): schließt beim ersten Wurf, die Verbindung bleibt bestehen.
        WuerfelKamera.scannerEmpfang = { fertig in
            AnyView(NavigationStack { WuerfelEmpfangSeite { augen in fertig(augen) } }
                .wuerfelScannerAnfrage()
                .overlay(alignment: .topTrailing) { Button("Abbrechen") { fertig(nil) }.padding() })
        }
        // Anbindung der Spiele: Zeichen „Scanner verbunden“, Würfe direkt ins Eingabe-Blatt, erwartete Würfelzahl, Rückfrage.
        WuerfelScannerFunk.stand = {
            let z = FunkZentrale.shared.zustand
            guard z.istVerbunden || z.istUnterbrochen else { return ScannerStand() }
            return ScannerStand(name: z.gegenueber, unterbrochen: z.istUnterbrochen)
        }
        WuerfelScannerFunk.anmelden = { id, wurf in
            let funk = FunkZentrale.shared
            // Ohne bekanntes Gerät wird erst auf Wunsch gesucht („Vom Scanner“): So fragt iOS nicht schon beim ersten Öffnen nach dem lokalen Netzwerk.
            if !funk.bekannte.isEmpty { funk.starten(als: .spielgeraet) }
            funk.empfangeWuerfe(id, wurf)
        }
        WuerfelScannerFunk.abmelden = { id in
            let funk = FunkZentrale.shared
            funk.beendeEmpfang(id)
            // Niemand verbunden und niemand wartet: Werben beenden. Ein verbundener Scanner bleibt verbunden.
            if funk.rolle == .spielgeraet, !funk.hatEmpfaenger, !funk.zustand.istVerbunden, !funk.zustand.istUnterbrochen { funk.beenden() }
        }
        WuerfelScannerFunk.meldeLage = { spiel, erwartet, gehalten in
            FunkZentrale.shared.meldeLage(FunkLage(spiel: spiel, erwartet: erwartet, gehalten: gehalten))
        }
        WuerfelScannerFunk.bilder = { FunkZentrale.shared.letzteBilder }
        WuerfelScannerFunk.anfrage = {
            guard let a = FunkZentrale.shared.anfrage else { return nil }
            return ScannerAnfrage(name: a.name, zusagen: { a.zusagen() }, ablehnen: { a.ablehnen() })
        }
    }
}

/// Würfel per Sprache (KI-9): Setzt die Haken, mit denen das Eingabe-Blatt der Spiele (SpieleKern) die Spracherkennung aus `WuerfelScan` nutzt.
/// Die Erkennung läuft nur auf dem Gerät, der Ton wird nicht gespeichert. Im Kinder-Modus gibt es keine Ansage.
enum AnsageEinsetzen {
    @MainActor private static var aktiv: AnsageHoerer?

    static func einsetzen() {
        MainActor.assumeIsolated {
            WuerfelAnsageHaken.verfuegbar = { !Modi.kinder && AnsageHoerer.verfuegbar }
            WuerfelAnsageHaken.hoeren = { hoechstens, laufend in
                let h = AnsageHoerer()
                aktiv = h
                defer { if aktiv === h { aktiv = nil } }
                await h.starten(hoechstens: hoechstens)
                switch h.zustand {
                case .verweigert: return .verweigert
                case .nichtVerfuegbar: return .nichtVerfuegbar
                default: break
                }
                var zuletzt: [Int] = []
                while h.zustand == .hoert {
                    if h.augen != zuletzt { zuletzt = h.augen; laufend(zuletzt) }
                    try? await Task.sleep(for: .milliseconds(120))
                }
                if h.augen != zuletzt { laufend(h.augen) }
                return .beendet
            }
            WuerfelAnsageHaken.stoppen = { aktiv?.stoppen() }
            eingabeartenEinsetzen()
        }
    }

    /// Kamera und Scanner als Eingabearten des gemeinsamen Eingabeblatts und von Zehntausend (SpieleKern kennt `WuerfelScan` nicht).
    /// Ohne Kamera (Simulator) bleibt der Haken leer, dann erscheint die Art nirgends. Der Scanner-Haken folgt dem Empfang aus `FunkEinsetzen`.
    @MainActor static func eingabeartenEinsetzen() {
        if WuerfelKamera.verfuegbar {
            WuerfelEingabeHaken.kamera = { anzahl, fertig, abbrechen in
                AnyView(WuerfelKameraSeite(erwartet: anzahl, hoechstens: anzahl) { augen in
                    if let augen { fertig(augen) } else { abbrechen() }
                })
            }
        }
        if WuerfelKamera.scannerEmpfang != nil {
            WuerfelEingabeHaken.scanner = { _, fertig, abbrechen in
                guard let seite = WuerfelKamera.scannerEmpfang else { return AnyView(EmptyView()) }
                return AnyView(seite { augen in
                    if let augen { fertig(augen) } else { abbrechen() }
                })
            }
        }
    }
}
