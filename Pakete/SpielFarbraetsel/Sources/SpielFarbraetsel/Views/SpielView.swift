// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern

struct SpielView: View {
    @Environment(GameStore.self) private var store
    /// Vom Rahmen: fragt „Spiel wirklich beenden?“ und führt zurück zum Start
    let abbrechen: () -> Void

    var body: some View {
        VStack(spacing: Theme.kartenAbstand) {
            HStack {
                RundKnopf(symbol: "chevron.left", beschriftung: "Zurück zum Start") { abbrechen() }
                Spacer(minLength: 8)
                kopfPille
                Spacer(minLength: 8)
                RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                    Button("Spiel beenden", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
                }
            }
            .padding(.horizontal, Theme.seitenRand)

            if let p = store.partie {
                BrettView(partie: p)
                    .padding(.horizontal, Theme.seitenRand)
                Fortschrittsbalken(wert: p.fortschritt)
                    .padding(.horizontal, Theme.seitenRand + 4)
            }
        }
        .padding(.top, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.seitenGrund)
        .safeAreaInset(edge: .bottom) {
            BottomBar {
                AktionsLeiste(eintraege: [
                    AktionsEintrag(symbol: "arrow.uturn.backward", titel: "Zurück",
                                   gesperrt: !(store.partie?.kannZurueck ?? false)) { store.zurueck() },
                    AktionsEintrag(symbol: "lightbulb.fill", titel: "Tipp") { store.hilfe() },
                ])
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: store.partie?.zuege) { _, _ in SpieleHaptik.erlaubt }
        .sensoryFeedback(.success, trigger: store.ergebnis) { _, neu in neu != nil && SpieleHaptik.erlaubt }
    }

    private var kopfPille: some View {
        TimelineView(.periodic(from: .now, by: 1)) { zeit in
            StatusPille(text: "\(Zeitformat.text(store.gespielteSekunden(zu: zeit.date))) · \(store.partie?.zuege ?? 0) \(String(localized: "Züge"))")
        }
    }
}

/// Das Spielfeld: ein Raster aus Farbkacheln. Tippen wählt aus, ein zweites Tippen tauscht.
struct BrettView: View {
    @Environment(GameStore.self) private var store
    @AppStorage("richtigeMarkieren") private var richtigeMarkieren = true
    let partie: Partie

    private let abstand: CGFloat = 3

    var body: some View {
        let spalten = partie.raetsel.spalten, zeilen = partie.raetsel.zeilen
        GeometryReader { geo in
            let breite = (geo.size.width - abstand * CGFloat(spalten - 1)) / CGFloat(spalten)
            let hoehe = (geo.size.height - abstand * CGFloat(zeilen - 1)) / CGFloat(zeilen)
            let seite = max(10, min(breite, hoehe))
            let gesamtB = seite * CGFloat(spalten) + abstand * CGFloat(spalten - 1)
            let gesamtH = seite * CGFloat(zeilen) + abstand * CGFloat(zeilen - 1)
            VStack(spacing: abstand) {
                ForEach(0..<zeilen, id: \.self) { z in
                    HStack(spacing: abstand) {
                        ForEach(0..<spalten, id: \.self) { s in
                            let platz = z * spalten + s
                            KachelView(farbe: Color(partie.raetsel.ziel[partie.belegung[platz]]),
                                       fest: partie.istFest(platz),
                                       richtig: richtigeMarkieren && partie.istRichtig(platz),
                                       gewaehlt: store.ausgewaehlt == platz,
                                       beschriftung: beschriftung(platz, z, s))
                                .frame(width: seite, height: seite)
                                .onTapGesture { withAnimation(.snappy(duration: 0.2)) { store.tippen(platz) } }
                        }
                    }
                }
            }
            .frame(width: gesamtB, height: gesamtH)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func beschriftung(_ platz: Int, _ z: Int, _ s: Int) -> Text {
        var t = Text("Zeile \(z + 1), Spalte \(s + 1)")
        if partie.istFest(platz) { t = t + Text(", fest") }
        else if partie.istRichtig(platz) { t = t + Text(", richtig") }
        return t
    }
}

struct KachelView: View {
    let farbe: Color
    let fest: Bool
    let richtig: Bool
    let gewaehlt: Bool
    let beschriftung: Text

    var body: some View {
        RoundedRectangle(cornerRadius: Theme.feldRadius / 2.5, style: .continuous)
            .fill(farbe)
            .overlay {
                if fest {
                    Circle().fill(.white.opacity(0.9)).frame(width: 7, height: 7)
                        .overlay(Circle().stroke(.black.opacity(0.35), lineWidth: 1))
                } else if richtig {
                    Circle().fill(.white.opacity(0.7)).frame(width: 4, height: 4)
                }
            }
            .overlay {
                if gewaehlt {
                    RoundedRectangle(cornerRadius: Theme.feldRadius / 2.5, style: .continuous)
                        .stroke(.white, lineWidth: 3)
                        .overlay(RoundedRectangle(cornerRadius: Theme.feldRadius / 2.5, style: .continuous)
                            .stroke(.black.opacity(0.5), lineWidth: 1).padding(-1))
                }
            }
            .scaleEffect(gewaehlt ? 1.12 : 1)
            .zIndex(gewaehlt ? 1 : 0)
            .contentShape(.rect)
            .accessibilityElement()
            .accessibilityLabel(beschriftung)
            .accessibilityAddTraits(gewaehlt ? [.isButton, .isSelected] : .isButton)
    }
}
#endif
