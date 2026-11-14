// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(MultipeerConnectivity) && canImport(UIKit)
import SwiftUI
import WuerfelLive

// MARK: - Scanner (z. B. iPhone)

/// Am Scanner (z. B. iPhone): Spielgerät auswählen, danach zeigt die Seite das Kamerabild mit Rahmen und schickt jeden fertigen Wurf hinüber.
/// Die Verbindung gehört der `FunkZentrale`. Bekannte Spielgeräte werden von selbst eingeladen, nach einem Abbruch wird neu verbunden.
/// Gesendet wird erst, wenn so viele Würfel gelesen sind, wie das Spielgerät erwartet („Trotzdem senden“ geht von Hand).
public struct WuerfelScannerSeite: View {
    @State private var funk = FunkZentrale.shared
    @State private var live = LiveWuerfel()
    @State private var melder = WurfMelder()
    @State private var letzterStand: FunkStand?
    @State private var trennenFragen = false

    public init() {}

    public var body: some View {
        Group {
            if gekoppelt { lesen } else { auswahl }
        }
        .navigationTitle(Text("Als Würfelscanner nutzen", bundle: .main))
        .navigationBarTitleDisplayMode(.inline)
        // Solange gekoppelt ist, beendet weder Wischen vom Rand noch ein versehentlicher Zurück-Tipp die Kopplung: Trennen geht nur über den eigenen Knopf mit Rückfrage.
        .navigationBarBackButtonHidden(gekoppelt)
        .interactiveDismissDisabled(gekoppelt)
        .toolbar {
            if gekoppelt {
                ToolbarItem(placement: .topBarLeading) {
                    Button { trennenFragen = true } label: { Text("Trennen", bundle: .main) }
                }
            }
        }
        .confirmationDialog(Text("Kopplung beenden?", bundle: .main), isPresented: $trennenFragen, titleVisibility: .visible) {
            Button(role: .destructive) { beenden() } label: { Text("Trennen", bundle: .main) }
            Button(role: .cancel) {} label: { Text("Abbrechen", bundle: .main) }
        }
        .onAppear { funk.starten(als: .scanner) }
        // Ohne Scanner-Seite liest keine Kamera mehr: Funk beenden. Beim nächsten Öffnen verbindet sich das bekannte Spielgerät von selbst.
        .onDisappear { live.stoppen(); funk.beenden(); UIApplication.shared.isIdleTimerDisabled = false }
    }

    /// Verbunden oder gerade beim Wiederverbinden: Die Kamera liest weiter, Würfe werden nachgereicht.
    private var gekoppelt: Bool { funk.zustand.istVerbunden || funk.zustand.istUnterbrochen }

    /// Wie viele Würfel das Spielgerät für den nächsten Wurf erwartet (`nil`: egal).
    private var erwartet: Int? { funk.lage?.erwartet }

    private func vollzaehlig(_ anzahl: Int) -> Bool { erwartet.map { anzahl == $0 } ?? true }

    /// Beendet die Kopplung auf Wunsch und geht zur Geräteauswahl zurück.
    private func beenden() {
        live.stoppen(); melder.zuruecksetzen(); letzterStand = nil
        funk.trennen()
    }

    // MARK: Geräte wählen

    private var auswahl: some View {
        List {
            Section { RollenKopf(symbol: "iphone.gen3.radiowaves.left.and.right", text: "Dieses Gerät liegt über den Würfeln und liest sie. Gespielt wird auf dem anderen Gerät.") }
            Section {
                if funk.gefunden.isEmpty {
                    HStack { ProgressView(); Text("Suche Spielgerät …", bundle: .main).padding(.leading, 8) }
                    SuchHinweis(funk: funk, hilfe: "Nichts gefunden. Beide Geräte brauchen WLAN und Bluetooth. Öffne auf dem Spielgerät in einem Würfelspiel „Wurf eintragen“ und tippe auf „Vom Scanner“, oder in den Einstellungen „Würfel vom Scanner empfangen“.")
                }
                ForEach(funk.gefunden) { f in
                    Button { funk.verbinde(mit: f) } label: {
                        HStack {
                            Label(f.name, systemImage: "ipad.and.iphone")
                            Spacer()
                            if case .wartetAufZusage = funk.zustand, funk.zustand.gegenueber == f.name {
                                ProgressView()
                            } else if f.bekannt {
                                Text("Bekannt", bundle: .main).font(.footnote).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                if case .getrennt(_, .abgelehnt) = funk.zustand {
                    Text("Das Spielgerät hat die Verbindung abgelehnt.", bundle: .main).font(.footnote).foregroundStyle(.secondary)
                } else if case .getrennt(_, .keineAntwort) = funk.zustand {
                    Text("Das Spielgerät hat nicht geantwortet. Prüfe, ob dort die Anfrage angezeigt wurde, und versuche es noch einmal.", bundle: .main).font(.footnote).foregroundStyle(.secondary)
                }
            } header: { Text("Spielgeräte in der Nähe", bundle: .main) } footer: {
                Text("Auf dem Spielgerät musst du die Verbindung einmal bestätigen, danach verbinden sich beide von selbst. Übertragen werden die Augenzahlen und kleine Ausschnitte der Würfel, nur zwischen deinen Geräten.", bundle: .main)
            }
            BekannteGeraeteAbschnitt(funk: funk)
        }
    }

    // MARK: Lesen

    private var lesen: some View {
        ZStack {
            if live.zustand == .verweigert || live.zustand == .keineKamera {
                ContentUnavailableView("Keine Kamera verfügbar", systemImage: "camera.slash")
                    .foregroundStyle(.white)
            } else {
                GeometryReader { geo in bildEbene(geo.size) }
                    .ignoresSafeArea(edges: .bottom)
            }
            VStack(spacing: 0) {
                verbindungsZeichen
                Spacer(minLength: 0)
                tafel
            }
            .padding(.horizontal, 12).padding(.top, 8).padding(.bottom, 12)
        }
        .background(Color.black)
        .task {
            UIApplication.shared.isIdleTimerDisabled = true
            live.hoechstens = erwartet
            await live.starten()
        }
        .onChange(of: live.wuerfel) { _, neu in beobachte(neu) }
        .onChange(of: funk.lage) { _, neu in live.hoechstens = neu?.erwartet }
        .onChange(of: gekoppelt) { _, jetzt in if !jetzt { live.stoppen(); melder.zuruecksetzen(); letzterStand = nil } }
        .sensoryFeedback(trigger: funk.letzteQuittung) { _, neu in neu?.angekommen == true ? .success : nil }
    }

    /// Meldet den Stand der Kamera ans Spielgerät und schickt den Wurf, sobald er vollständig und ruhig ist.
    private func beobachte(_ neu: [AngezeigterWuerfel]) {
        let stand = FunkStand(erkannt: neu.count, erwartet: erwartet, sicher: neu.allesSicher)
        if stand != letzterStand { letzterStand = stand; funk.sendeStand(stand) }
        if let w = melder.beobachte(augen: neu.map(\.augen), sicher: neu.allesSicher && vollzaehlig(neu.count)) { funk.sende(w.mitBildern(live.ausschnitte(von: neu))) }
    }

    private func trotzdemSenden() {
        guard let w = melder.erzwinge(augen: live.wuerfel.map(\.augen)) else { return }
        funk.sende(w.mitBildern(live.ausschnitte(von: live.wuerfel)))
    }

    /// Wer ist verbunden; beim Wiederverbinden mit Kreisel.
    private var verbindungsZeichen: some View {
        HStack(spacing: 8) {
            if funk.zustand.istUnterbrochen { ProgressView().tint(.white) }
            Label(funk.zustand.gegenueber ?? "", systemImage: "link").font(.headline)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14).frame(minHeight: 36)
        .background(.black.opacity(0.5), in: Capsule())
        .frame(maxWidth: .infinity, alignment: .center)
    }

    /// Kamerabild mit Rahmen um jeden gelesenen Würfel (dieselbe Darstellung wie auf der Kamera-Seite).
    /// Das Bild füllt die Fläche (9:16, am Rand angeschnitten); Rahmen werden auf denselben Ausschnitt umgerechnet.
    private func bildEbene(_ groesse: CGSize) -> some View {
        let bb = max(groesse.width, groesse.height * 9 / 16), bh = bb * 16 / 9
        let ox = (groesse.width - bb) / 2, oy = (groesse.height - bh) / 2
        return ZStack {
            LiveKameraBild(live)
            ForEach(live.wuerfel) { w in
                let farbe: Color = w.sicher ? .green : .white
                let r = CGRect(x: ox + w.rahmen.minX * bb, y: oy + w.rahmen.minY * bh, width: w.rahmen.width * bb, height: w.rahmen.height * bh)
                let bx = min(max(r.minX + 6, 24), groesse.width - 24)
                let by = r.minY - 18 < 24 ? min(r.minY + 22, groesse.height - 24) : r.minY - 18
                RoundedRectangle(cornerRadius: max(6, r.width * 0.16), style: .continuous)
                    .stroke(farbe, style: StrokeStyle(lineWidth: 3, dash: w.sicher ? [] : [7, 5]))
                    .shadow(color: .black.opacity(0.5), radius: 2)
                    .frame(width: r.width, height: r.height)
                    .position(x: r.midX, y: r.midY)
                    .accessibilityHidden(true)
                Text("\(w.augen)").font(.title3.bold().monospacedDigit()).foregroundStyle(.black)
                    .frame(minWidth: 34, minHeight: 30).background(farbe, in: Capsule())
                    .shadow(color: .black.opacity(0.4), radius: 2)
                    .position(x: bx, y: by)
                    .accessibilityHidden(true)
            }
        }
        .frame(width: groesse.width, height: groesse.height)
        .clipped()
        .animation(.easeOut(duration: 0.12), value: live.wuerfel)
    }

    /// Unten: was gelesen wird, ob etwas fehlt, und ob das Spielgerät den letzten Wurf angenommen hat.
    private var tafel: some View {
        let augen = live.wuerfel.map(\.augen)
        let voll = vollzaehlig(augen.count)
        return VStack(spacing: 8) {
            Group {
                if augen.isEmpty {
                    Text("Lege die Würfel unter die Kamera.", bundle: .main).font(.headline)
                } else if !voll, let e = erwartet {
                    Text("\(augen.count) von \(e) Würfeln erkannt", bundle: .main).font(.headline)
                } else {
                    Text(augen.map(String.init).joined(separator: "  "))
                        .font(.system(size: 40, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(live.wuerfel.allesSicher ? Color.green : Color.primary)
                }
            }
            .accessibilityElement(children: .combine)
            if !voll, !augen.isEmpty {
                Button { trotzdemSenden() } label: { Text("Trotzdem senden", bundle: .main).frame(minHeight: 36) }
                    .buttonStyle(.bordered)
                    .accessibilityHint(Text("Schickt die gelesenen Würfel, auch wenn nicht alle erkannt sind.", bundle: .main))
            }
            quittung
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity).padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    /// Zeile „Bei … angekommen“ mit Haken, oder was schiefging.
    @ViewBuilder private var quittung: some View {
        let name = funk.zustand.gegenueber ?? ""
        if funk.zustand.istUnterbrochen {
            Label { Text("Verbindung wird wiederhergestellt. Würfe gehen danach von selbst raus.", bundle: .main) } icon: { ProgressView() }
                .font(.footnote).foregroundStyle(.secondary)
        } else if funk.offeneWuerfe > 0 {
            Label { Text("Wird an „\(name)“ gesendet …", bundle: .main) } icon: { ProgressView() }
                .font(.footnote).foregroundStyle(.secondary)
        } else if let q = funk.letzteQuittung {
            switch q.grund {
            case .angenommen, .doppelt:
                Label { Text("Bei „\(name)“ angekommen", bundle: .main) } icon: { Image(systemName: "checkmark.circle.fill").foregroundStyle(.green) }
                    .font(.footnote)
            case .keinEmpfaenger:
                Label { Text("„\(name)“ nimmt gerade keinen Wurf an. Öffne dort „Wurf eintragen“.", bundle: .main) } icon: { Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange) }
                    .font(.footnote)
            case .ungueltig, .anderer:
                Label { Text("„\(name)“ hat den Wurf nicht angenommen.", bundle: .main) } icon: { Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange) }
                    .font(.footnote)
            }
        } else if funk.lage?.bereit == false {
            Label { Text("„\(name)“ ist noch nicht bereit. Öffne dort „Wurf eintragen“.", bundle: .main) } icon: { Image(systemName: "hourglass") }
                .font(.footnote).foregroundStyle(.secondary)
        }
    }
}

// MARK: - Spielgerät (z. B. iPad)

/// Am Spielgerät (z. B. iPad): wartet auf den Scanner, fragt (über `wuerfelScannerAnfrage`) nach der Zusage und gibt jeden Wurf an das Spiel weiter.
/// Die Verbindung gehört der `FunkZentrale` und bleibt bestehen, wenn die Seite schließt.
/// Die Seite meldet sich nur als Empfänger an und ab. Die Rückfrage „Scanner verbinden?“ liegt außerhalb (App-Wurzel und Blätter).
public struct WuerfelEmpfangSeite: View {
    @State private var funk = FunkZentrale.shared
    @State private var empfaengerID = UUID()
    @State private var letzterWurf: [Int] = []
    private let onWurf: ([Int]) -> Void

    /// `onWurf` bekommt die Augen jedes Wurfs; ohne Spiel (Einstellungen) kann es leer bleiben.
    public init(onWurf: @escaping ([Int]) -> Void = { _ in }) { self.onWurf = onWurf }

    private var verbunden: Bool { funk.zustand.istVerbunden || funk.zustand.istUnterbrochen }

    public var body: some View {
        List {
            Section { RollenKopf(symbol: "ipad.and.iphone", text: "Auf diesem Gerät wird gespielt. Es bekommt die Würfe vom Gerät, das die Würfel liest.") }
            Section {
                if verbunden, let n = funk.zustand.gegenueber {
                    HStack(spacing: 8) {
                        if funk.zustand.istUnterbrochen { ProgressView() }
                        Label(n, systemImage: "link").font(.headline)
                    }
                    if funk.zustand.istUnterbrochen {
                        Text("Verbindung wird wiederhergestellt …", bundle: .main).font(.footnote).foregroundStyle(.secondary)
                    }
                    Text(letzterWurf.isEmpty ? "Warte auf den ersten Wurf …" : letzterWurf.map(String.init).joined(separator: "  "))
                        .font(.system(size: 44, weight: .bold, design: .rounded).monospacedDigit())
                        .frame(maxWidth: .infinity)
                    if let s = funk.stand, s.erkannt > 0 {
                        Group {
                            if let e = s.erwartet {
                                Text("Der Scanner sieht \(s.erkannt) von \(e) Würfeln.", bundle: .main)
                            } else {
                                Text("Der Scanner sieht \(s.erkannt) Würfel.", bundle: .main)
                            }
                        }
                        .font(.footnote).foregroundStyle(.secondary)
                    }
                } else {
                    HStack { ProgressView(); Text("Warte auf den Scanner …", bundle: .main).padding(.leading, 8) }
                    Text("Öffne auf dem anderen Gerät „Als Würfelscanner nutzen“.", bundle: .main).font(.footnote).foregroundStyle(.secondary)
                    SuchHinweis(funk: funk, hilfe: "Noch nichts gefunden. Beide Geräte brauchen WLAN und Bluetooth und müssen nah beieinander sein.")
                }
            } header: { Text("Verbindung", bundle: .main) }
            BekannteGeraeteAbschnitt(funk: funk)
        }
        .navigationTitle(Text("Würfel vom Scanner empfangen", bundle: .main))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            funk.starten(als: .spielgeraet)
            funk.empfangeWuerfe(empfaengerID) { augen in letzterWurf = augen; onWurf(augen) }
        }
        // Nur abmelden, nicht trennen: Der Scanner bleibt verbunden und der nächste Wurf kommt ohne neues Koppeln an.
        .onDisappear { funk.beendeEmpfang(empfaengerID) }
    }
}

// MARK: - Bausteine

/// Ein Satz und ein Bild: welche Rolle dieses Gerät hat.
private struct RollenKopf: View {
    let symbol: String
    let text: LocalizedStringKey
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbol).font(.largeTitle).foregroundStyle(.tint).frame(width: 48)
                .accessibilityHidden(true)
            Text(text, bundle: .main).font(.subheadline)
        }
    }
}

/// Hilfe, wenn die Liste leer bleibt: Funk gesperrt (mit Knopf zu den Einstellungen) oder nach 8 Sekunden ohne Fund.
private struct SuchHinweis: View {
    let funk: FunkZentrale
    let hilfe: LocalizedStringKey
    @Environment(\.openURL) private var openURL

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { zeit in
            if !funk.funkGeht {
                VStack(alignment: .leading, spacing: 8) {
                    Label { Text("Funk ist aus oder nicht erlaubt", bundle: .main).font(.subheadline.bold()) } icon: { Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange) }
                    Text("Erlaube Partie in den iOS-Einstellungen das lokale Netzwerk und schalte WLAN und Bluetooth ein.", bundle: .main).font(.footnote).foregroundStyle(.secondary)
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                    } label: { Text("Einstellungen öffnen", bundle: .main) }
                }
            } else if let seit = funk.suchtSeit, zeit.date.timeIntervalSince(seit) >= 8 {
                Text(hilfe, bundle: .main).font(.footnote).foregroundStyle(.secondary)
            }
        }
    }
}

/// Liste der Geräte, die sich von selbst verbinden, mit „Vergessen“.
private struct BekannteGeraeteAbschnitt: View {
    let funk: FunkZentrale
    var body: some View {
        if !funk.bekannte.isEmpty {
            Section {
                ForEach(funk.bekannte) { g in
                    HStack {
                        Label(g.name, systemImage: "checkmark.seal")
                        Spacer()
                        if funk.gegenueberKennung == g.kennung, funk.zustand.istVerbunden {
                            Text("Verbunden", bundle: .main).font(.footnote).foregroundStyle(.secondary)
                        }
                        Button(role: .destructive) { funk.vergiss(g.kennung) } label: { Text("Vergessen", bundle: .main) }
                            .buttonStyle(.borderless)
                    }
                }
            } header: { Text("Bekannte Geräte", bundle: .main) } footer: {
                Text("Bekannte Geräte verbinden sich von selbst und fragen nicht mehr nach. Nach „Vergessen“ musst du die Verbindung wieder bestätigen.", bundle: .main)
            }
        }
    }
}
#endif
