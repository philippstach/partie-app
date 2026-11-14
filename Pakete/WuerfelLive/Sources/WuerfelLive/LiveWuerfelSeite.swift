// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI

/// Würfel mit der Kamera lesen: Das Kamerabild füllt die Seite, jeder erkannte Würfel bekommt Rahmen und Zahl.
/// Unten liegen die gelesenen Würfel als Würfelbilder. Sobald alle sicher erkannt sind, hält das Bild von selbst an;
/// ein Tipp auf einen Würfel (im Bild oder unten) ändert seinen Wert oder nimmt ihn heraus.
/// Der Aufrufer sorgt dafür, dass die Seite im Kinder-Modus nicht erreichbar ist.
public struct LiveWuerfelSeite: View {
    @State private var live = LiveWuerfel()
    /// Würfel, dessen Wert gerade geändert wird.
    @State private var auswahl: Int?
    /// Aufeinanderfolgende Auswertungen, in denen alle Würfel sicher waren (für das selbsttätige Anhalten).
    @State private var sicherFolge = 0
    /// Nach „Neu scannen“ hält das Bild erst wieder von selbst an, wenn sich die Würfel geändert haben.
    @State private var gesperrteWerte: [Int]?
    /// Sekunden, in denen es kein vollständiges, sicheres Ergebnis gab (für Hinweise wie „Näher ran“ und „Selbst eintippen“).
    @State private var ohneErgebnis = 0
    @Environment(\.openURL) private var openURL

    private let erwartet: Int?
    private let hoechstens: Int?
    private let onUebernehmen: (([Int]) -> Void)?
    private let onAbbrechen: (() -> Void)?

    /// Zum Ausprobieren (Einstellungen): nur lesen, nichts übernehmen.
    public init() { erwartet = nil; hoechstens = nil; onUebernehmen = nil; onAbbrechen = nil }

    /// Im Spiel: `erwartet` Würfel liegen auf dem Tisch (falls bekannt), mehr als `hoechstens` gibt es nicht; „Übernehmen“ liefert die Augen in Lesereihenfolge.
    public init(erwartet: Int?, hoechstens: Int? = nil, onUebernehmen: @escaping ([Int]) -> Void, onAbbrechen: @escaping () -> Void) {
        self.erwartet = erwartet; self.hoechstens = hoechstens ?? erwartet; self.onUebernehmen = onUebernehmen; self.onAbbrechen = onAbbrechen
    }

    private var angehalten: Bool { live.standbild != nil }

    public var body: some View {
        Group {
            switch live.zustand {
            case .verweigert:
                hinweis("Kein Kamerazugriff", "Erlaube Partie in den iOS-Einstellungen den Zugriff auf die Kamera. Die Bilder bleiben auf deinem Gerät.", knopf: true)
            case .keineKamera:
                hinweis("Keine Kamera gefunden", "Dieses Gerät hat keine Kamera, die Partie nutzen kann.", knopf: false)
            default:
                kamera
            }
        }
        .navigationTitle(Text("Würfel mit Kamera", bundle: .main))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            live.hoechstens = hoechstens
            // Lern-Aufnahme (Testfunktion der Einstellungen, standardmäßig aus): gilt für diese Kamera-Sitzung.
            live.lernAufnahme = LernAufnahme.schalterAn
            #if DEBUG
            // Simulator ohne Kamera: Startargument `-wuerfeltestbild <Pfad>` zeigt dieses Bild als Standbild.
            let a = ProcessInfo.processInfo.arguments
            if let i = a.firstIndex(of: "-wuerfeltestbild"), a.indices.contains(i + 1) { live.ladeTestbild(pfad: a[i + 1]); return }
            #endif
            await live.starten()
        }
        .task {
            // Einmal pro Sekunde: Zählt, wie lange es noch kein vollständiges, sicheres Ergebnis gibt.
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                if angehalten || (!live.wuerfel.isEmpty && live.wuerfel.allesSicher && vollzaehlig(live.wuerfel)) { ohneErgebnis = 0 } else { ohneErgebnis += 1 }
            }
        }
        .onDisappear {
            // Beim Ausprobieren (ohne „Übernehmen“) gilt ein angehaltenes, geprüftes Bild beim Verlassen als bestätigt.
            if onUebernehmen == nil, angehalten { live.bestaetige() }
            live.stoppen()
        }
        .onChange(of: angehalten) { _, jetzt in if jetzt { sageErgebnisAn() } }
        .onChange(of: live.wuerfel) { _, neu in beobachte(neu) }
        .onChange(of: live.nachpruefung) { _, neu in if case .gefunden(let id) = neu { withAnimation(.snappy) { auswahl = id } } }
        .sensoryFeedback(trigger: angehalten) { _, jetzt in jetzt ? .success : nil }
        .sensoryFeedback(.selection, trigger: auswahl)
    }

    // MARK: Ablauf

    private func vollzaehlig(_ wuerfel: [AngezeigterWuerfel]) -> Bool { erwartet.map { wuerfel.count == $0 } ?? true }

    /// VoiceOver: Beim Anhalten das Ergebnis ansagen, zum Beispiel „5 Würfel: 2, 3, 3, 5, 6“.
    private func sageErgebnisAn() {
        let augen = live.wuerfel.map(\.augen)
        guard !augen.isEmpty else { return }
        let liste = augen.map(String.init).joined(separator: ", ")
        UIAccessibility.post(notification: .announcement, argument: String(localized: "\(augen.count) Würfel: \(liste)", bundle: .main))
    }

    /// Hinweis zur Entfernung, aus Größe und Lage der Rahmen (normiert auf das Bild). Erst nach ein paar Sekunden ohne Ergebnis, damit er nicht flackert.
    private enum Entfernung { case zuNah, zuFern }
    private var entfernungsTipp: Entfernung? {
        guard !angehalten, !live.wuerfel.isEmpty, ohneErgebnis >= 3 else { return nil }
        let breiten = live.wuerfel.map(\.rahmen.width).sorted()
        let mitte = breiten[breiten.count / 2]
        let angeschnitten = live.wuerfel.contains { $0.rahmen.minX < 0.01 || $0.rahmen.minY < 0.01 || $0.rahmen.maxX > 0.99 || $0.rahmen.maxY > 0.99 }
        if angeschnitten || mitte > 0.30 { return .zuNah }
        if mitte < 0.05 { return .zuFern }
        return nil
    }
    /// Nach 6 Sekunden ohne Ergebnis wird das Eintippen angeboten.
    private var zeigeEintippen: Bool { onAbbrechen != nil && !angehalten && ohneErgebnis >= 6 }

    /// Alle Würfel sicher und etwa eine halbe Sekunde unverändert: Das Bild hält von selbst an.
    private func beobachte(_ wuerfel: [AngezeigterWuerfel]) {
        guard !angehalten else { return }
        let werte = wuerfel.map(\.augen)
        if let g = gesperrteWerte, g != werte.sorted() || wuerfel.isEmpty { gesperrteWerte = nil }
        guard wuerfel.allesSicher, vollzaehlig(wuerfel), gesperrteWerte == nil else { sicherFolge = 0; return }
        sicherFolge += 1
        if sicherFolge >= (erwartet == nil ? 8 : 4) { sicherFolge = 0; live.anhalten() }
    }

    private func waehle(_ w: AngezeigterWuerfel) {
        if !angehalten { live.anhalten() }
        withAnimation(.snappy) { auswahl = auswahl == w.id ? nil : w.id }
    }

    /// Tipp auf eine freie Stelle im Bild: Dort fehlt ein Würfel – die Umgebung wird noch einmal geprüft.
    private func tippeAufBild(_ ort: CGPoint, _ groesse: CGSize) {
        let bb = max(groesse.width, groesse.height * 9 / 16), bh = bb * 16 / 9
        let nx = (ort.x - (groesse.width - bb) / 2) / bb, ny = (ort.y - (groesse.height - bh) / 2) / bh
        guard (0...1).contains(nx), (0...1).contains(ny) else { return }
        auswahl = nil
        live.pruefe(bei: CGPoint(x: nx, y: ny))
    }

    private func neuScannen() {
        // Beim Ausprobieren (ohne „Übernehmen“) bestätigt „Neu scannen“ das angehaltene Bild für die Lern-Aufnahme.
        if onUebernehmen == nil { live.bestaetige() }
        gesperrteWerte = live.wuerfel.map(\.augen).sorted()
        auswahl = nil; sicherFolge = 0
        live.neuAufnehmen()
    }

    // MARK: Aufbau

    private var kamera: some View {
        ZStack {
            GeometryReader { geo in bildEbene(geo.size) }
                .ignoresSafeArea(edges: .bottom)
            VStack(spacing: 0) {
                kopf
                Spacer(minLength: 0)
                tafel
            }
            .padding(.horizontal, 12).padding(.top, 8).padding(.bottom, 12)
        }
        .background(Color.black)
    }

    /// Schließen (nur im Spiel) und Zoomstufen.
    private var kopf: some View {
        HStack(alignment: .top) {
            if let onAbbrechen {
                Button { onAbbrechen() } label: {
                    Image(systemName: "xmark").font(.body.weight(.semibold)).foregroundStyle(.white)
                        .frame(width: 44, height: 44).background(.black.opacity(0.45), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Schließen", bundle: .main))
            }
            lernAnzeige
            Spacer(minLength: 0)
            lampenKnopf
            zoomWahl
        }
    }

    /// Zeigt, dass die Lern-Aufnahme läuft und wie viele Würfe schon gespeichert sind.
    @ViewBuilder private var lernAnzeige: some View {
        if live.lernAufnahme {
            Label { Text("Lern-Aufnahme: \(live.lernGespeichert) gespeichert", bundle: .main) } icon: { Image(systemName: "record.circle").foregroundStyle(.red) }
                .font(.footnote.weight(.semibold)).foregroundStyle(.white)
                .padding(.horizontal, 10).frame(minHeight: 44)
                .background(.black.opacity(0.45), in: Capsule())
                .padding(.leading, onAbbrechen == nil ? 0 : 8)
        }
    }

    /// Taschenlampe (nur im Live-Bild und wenn das Gerät eine hat). Im Dunkeln hebt der Knopf sich gelb hervor.
    @ViewBuilder private var lampenKnopf: some View {
        if !angehalten, live.lampeVerfuegbar {
            let hervor = live.dunkel && !live.lampeAn
            Button { live.lampe(!live.lampeAn) } label: {
                Image(systemName: live.lampeAn ? "flashlight.on.fill" : "flashlight.off.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(live.lampeAn || hervor ? Color.black : Color.white)
                    .frame(width: 44, height: 44)
                    .background(live.lampeAn ? Color.yellow : (hervor ? Color.yellow.opacity(0.85) : Color.black.opacity(0.45)), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Taschenlampe", bundle: .main))
            .accessibilityAddTraits(live.lampeAn ? .isSelected : [])
        }
    }

    /// Bild (Live, Standbild oder das kurz stehende Bild bei der Zoom-Automatik) mit Rahmen und Zahlen.
    /// Das Bild füllt die Fläche (9:16, am Rand angeschnitten); Rahmen werden auf denselben Ausschnitt umgerechnet.
    private func bildEbene(_ groesse: CGSize) -> some View {
        let bb = max(groesse.width, groesse.height * 9 / 16), bh = bb * 16 / 9
        let ox = (groesse.width - bb) / 2, oy = (groesse.height - bh) / 2
        return ZStack {
            if let bild = live.standbild ?? live.eingefroren {
                Image(uiImage: bild).resizable().scaledToFill().frame(width: groesse.width, height: groesse.height).clipped()
            } else {
                KameraVorschau(sitzung: live.sitzung)
            }
            if case .laeuft(let p) = live.nachpruefung {
                ProgressView().tint(.white).controlSize(.large)
                    .padding(14).background(.black.opacity(0.45), in: Circle())
                    .position(x: ox + p.x * bb, y: oy + p.y * bh)
            }
            ForEach(live.wuerfel) { w in
                // Ein noch nicht bestätigter Würfel wird nie von selbst grün (auch nicht im angehaltenen Bild): Er bleibt orange, bis sein Wert gewählt wird.
                let sicher = w.sicher
                let gewaehlt = auswahl == w.id
                let farbe: Color = gewaehlt ? .yellow : (sicher ? .green : (angehalten ? .orange : .white))
                // Rahmen 15 % größer gezeichnet, so groß wie der Ausschnitt, den das Augen-Netz liest.
                let rr = w.rahmen.insetBy(dx: -w.rahmen.width * 0.075, dy: -w.rahmen.height * 0.075)
                let r = CGRect(x: ox + rr.minX * bb, y: oy + rr.minY * bh, width: rr.width * bb, height: rr.height * bh)
                // Würfelbild an der oberen linken Ecke, aber immer vollständig im sichtbaren Bild.
                let bx = min(max(r.minX + 8, 26), groesse.width - 26)
                let by = r.minY - 20 < 26 ? min(r.minY + 24, groesse.height - 26) : r.minY - 20
                RoundedRectangle(cornerRadius: max(6, r.width * 0.16), style: .continuous)
                    .stroke(farbe, style: StrokeStyle(lineWidth: gewaehlt ? 4 : 3, dash: sicher ? [] : [7, 5]))
                    .shadow(color: .black.opacity(0.5), radius: 2)
                    .frame(width: r.width, height: r.height)
                    .contentShape(Rectangle())
                    .onTapGesture { waehle(w) }
                    .position(x: r.midX, y: r.midY)
                    .accessibilityLabel(Text("Würfel \(w.augen)", bundle: .main))
                    .accessibilityAddTraits(.isButton)
                // Das gelesene Würfelbild statt einer kleinen Zahl; ein neuer Wert blendet kurz über.
                Wuerfelbild(augen: w.augen).frame(width: 36, height: 36)
                    .padding(3).background(farbe, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .shadow(color: .black.opacity(0.4), radius: 2)
                    .animation(.easeInOut(duration: 0.25), value: w.augen)
                    .transition(.opacity)
                    .onTapGesture { waehle(w) }
                    .position(x: bx, y: by)
                    .accessibilityHidden(true)
            }
        }
        .frame(width: groesse.width, height: groesse.height)
        .clipped()
        .contentShape(Rectangle())
        .gesture(SpatialTapGesture().onEnded { tippeAufBild($0.location, groesse) })
        .animation(.easeOut(duration: 0.12), value: live.wuerfel)
    }

    /// Zoomstufen und Automatik (nur im Live-Bild, nur wenn das Gerät mehrere Objektive hat).
    @ViewBuilder private var zoomWahl: some View {
        if !angehalten, live.zoomStufen.count > 1 {
            HStack(spacing: 2) {
                ForEach(live.zoomStufen) { z in
                    zoomKnopf(Text(z.name), aktiv: !live.automatik && live.zoomIndex == z.id) { live.waehleZoom(z.id) }
                }
                zoomKnopf(Text("Auto", bundle: .main), aktiv: live.automatik) { live.automatik.toggle() }
            }
            .padding(3).background(.black.opacity(0.45), in: Capsule())
        }
    }

    private func zoomKnopf(_ titel: Text, aktiv: Bool, _ aktion: @escaping () -> Void) -> some View {
        Button(action: aktion) {
            titel.font(.footnote.bold()).padding(.horizontal, 10).frame(minHeight: 38)
                .background(aktiv ? Color.white : Color.clear, in: Capsule())
                .foregroundStyle(aktiv ? Color.black : Color.white)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(aktiv ? .isSelected : [])
    }

    // MARK: Tafel unten

    /// Stand, gelesene Würfel und Knöpfe. Feste Mindesthöhe: wechselnder Inhalt lässt das Bild nicht springen.
    private var tafel: some View {
        VStack(spacing: 12) {
            stand
            if let id = auswahl, let w = live.wuerfel.first(where: { $0.id == id }) {
                korrekturZeile(w)
            } else {
                wuerfelZeile
            }
            if zeigeEintippen, let onAbbrechen {
                Button { onAbbrechen() } label: {
                    Label { Text("Selbst eintippen", bundle: .main) } icon: { Image(systemName: "keyboard") }
                        .font(.body.weight(.semibold)).frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.plain)
            }
            knoepfe
        }
        .padding(14)
        .frame(maxWidth: 520)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .environment(\.colorScheme, .dark)
    }

    @ViewBuilder private var stand: some View {
        Group {
            if case .laeuft = live.nachpruefung {
                Text("Suche an der angetippten Stelle …", bundle: .main)
            } else if auswahl != nil {
                Text("Welche Augenzahl zeigt der Würfel?", bundle: .main)
            } else if live.nachpruefung == .nichts {
                Label { Text("Dort wurde kein Würfel gefunden. Tippe genau auf den Würfel.", bundle: .main) } icon: { Image(systemName: "questionmark.circle.fill").foregroundStyle(.yellow) }
            } else if angehalten {
                Label { Text("Angehalten. Tippe auf einen Würfel, um ihn zu ändern, oder auf einen fehlenden Würfel im Bild.", bundle: .main) } icon: { Image(systemName: "checkmark.circle.fill").foregroundStyle(.green) }
            } else if live.dunkel && !angehalten {
                Label {
                    if live.lampeVerfuegbar && !live.lampeAn { Text("Zu dunkel. Schalte die Taschenlampe ein oder sorge für mehr Licht.", bundle: .main) }
                    else { Text("Zu dunkel. Sorge für mehr Licht, dann wird das Lesen sicherer.", bundle: .main) }
                } icon: { Image(systemName: "sun.min.fill").foregroundStyle(.yellow) }
            } else if live.wuerfel.isEmpty {
                if ohneErgebnis >= 6 {
                    Label { Text("Noch kein Würfel gefunden. Geh näher ran oder sorge für mehr Licht.", bundle: .main) } icon: { Image(systemName: "lightbulb.fill").foregroundStyle(.yellow) }
                } else {
                    Text("Halte das iPhone über die Würfel.", bundle: .main)
                }
            } else if let t = entfernungsTipp, !(live.wuerfel.allesSicher && vollzaehlig(live.wuerfel)) {
                switch t {
                case .zuFern: Label { Text("Näher ran. Die Würfel sind noch sehr klein.", bundle: .main) } icon: { Image(systemName: "plus.magnifyingglass").foregroundStyle(.yellow) }
                case .zuNah: Label { Text("Etwas weiter weg. Die Würfel sind zu groß oder angeschnitten.", bundle: .main) } icon: { Image(systemName: "minus.magnifyingglass").foregroundStyle(.yellow) }
                }
            } else if let e = erwartet, live.wuerfel.count != e {
                Text("\(live.wuerfel.count) von \(e) Würfeln erkannt", bundle: .main)
            } else if live.wuerfel.allesSicher {
                Label { Text("Alle Würfel erkannt", bundle: .main) } icon: { Image(systemName: "checkmark.circle.fill").foregroundStyle(.green) }
            } else {
                Text("Noch einen Moment ruhig halten", bundle: .main)
            }
        }
        .font(.subheadline.weight(.medium))
        .multilineTextAlignment(.center)
        .lineLimit(3)
        .minimumScaleFactor(0.8)
        // Feste Höhe: Wechselnde Texte (ein bis drei Zeilen) lassen die Tafel und damit das Bild nicht springen.
        .frame(maxWidth: .infinity, minHeight: 62, maxHeight: 62)
    }

    /// Die gelesenen Würfel in Lesereihenfolge, rechts die Summe. Vor dem ersten Fund: leere Plätze.
    private var wuerfelZeile: some View {
        HStack(spacing: 8) {
            if live.wuerfel.isEmpty {
                ForEach(0..<(erwartet ?? 5), id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(.secondary, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                        .frame(width: 44, height: 44)
                }
            } else {
                ForEach(live.wuerfel.prefix(8)) { w in
                    Button { waehle(w) } label: {
                        Wuerfelbild(augen: w.augen).frame(width: 44, height: 44).opacity(w.sicher ? 1 : 0.55)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("Würfel \(w.augen)", bundle: .main))
                }
                Spacer(minLength: 4)
                Text("Summe \(live.wuerfel.summe)", bundle: .main).font(.headline.monospacedDigit()).lineLimit(1).minimumScaleFactor(0.7)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 48)
        .accessibilityElement(children: .contain)
        .accessibilityHint(live.wuerfel.isEmpty ? Text("") : Text("Summe \(live.wuerfel.summe)", bundle: .main))
    }

    /// Sechs Würfelbilder zur Wahl, dazu „Kein Würfel“ für einen falschen Fund.
    private func korrekturZeile(_ w: AngezeigterWuerfel) -> some View {
        HStack(spacing: 6) {
            // Zurück: schließt die Auswahl, ohne den Wert zu ändern oder zu bestätigen.
            Button { withAnimation(.snappy) { auswahl = nil } } label: {
                Image(systemName: "chevron.backward").font(.body.weight(.semibold)).frame(width: 44, height: 44)
                    .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Zurück", bundle: .main))
            ForEach(1...6, id: \.self) { n in
                Button {
                    live.korrigiere(id: w.id, auf: n)
                    withAnimation(.snappy) { auswahl = nil }
                } label: {
                    // Darf bei schmalen Geräten schrumpfen, damit die Zeile mit Zurück-Knopf noch passt.
                    Wuerfelbild(augen: n).frame(maxWidth: 44, maxHeight: 44)
                        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(Color.yellow, lineWidth: n == w.augen ? 3 : 0))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("\(n)"))
                .accessibilityAddTraits(n == w.augen ? .isSelected : [])
            }
            Spacer(minLength: 0)
            Button {
                live.entferne(id: w.id)
                withAnimation(.snappy) { auswahl = nil }
            } label: {
                Image(systemName: "trash").font(.body.weight(.semibold)).frame(width: 44, height: 44)
                    .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Kein Würfel", bundle: .main))
        }
        .frame(maxWidth: .infinity, minHeight: 48)
    }

    private var knoepfe: some View {
        HStack(spacing: 10) {
            Button { angehalten ? neuScannen() : live.anhalten() } label: {
                Label { Text(angehalten ? "Neu scannen" : "Anhalten", bundle: .main) } icon: { Image(systemName: angehalten ? "arrow.counterclockwise" : "pause.fill") }
                    .font(.body.weight(.semibold)).frame(maxWidth: .infinity, minHeight: 48)
                    .background(.white.opacity(0.14), in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(!angehalten && live.wuerfel.isEmpty)
            .opacity(!angehalten && live.wuerfel.isEmpty ? 0.5 : 1)
            if let onUebernehmen {
                Button {
                    live.bestaetige(erwartet: erwartet)
                    onUebernehmen(live.wuerfel.map(\.augen))
                } label: {
                    Label { Text("Übernehmen", bundle: .main) } icon: { Image(systemName: "checkmark") }
                        .font(.body.weight(.semibold)).frame(maxWidth: .infinity, minHeight: 48)
                        .background(Color.accentColor, in: Capsule()).foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .disabled(live.wuerfel.isEmpty)
                .opacity(live.wuerfel.isEmpty ? 0.5 : 1)
            }
        }
    }

    private func hinweis(_ titel: LocalizedStringKey, _ text: LocalizedStringKey, knopf: Bool) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "camera.fill").font(.largeTitle).foregroundStyle(.secondary)
            Text(titel, bundle: .main).font(.headline)
            Text(text, bundle: .main).foregroundStyle(.secondary).multilineTextAlignment(.center)
            if knopf, let url = URL(string: UIApplication.openSettingsURLString) {
                Button { openURL(url) } label: { Text("Einstellungen öffnen", bundle: .main).fontWeight(.semibold).padding(.horizontal, 20).padding(.vertical, 10).background(Color.accentColor, in: Capsule()).foregroundStyle(.white) }.buttonStyle(.plain)
            }
            if let onAbbrechen {
                Button { onAbbrechen() } label: { Text("Schließen", bundle: .main).frame(minHeight: 44) }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Eine Würfelseite als Bild: weißes Feld mit schwarzen Augen (unabhängig von der Farbe der echten Würfel).
struct Wuerfelbild: View {
    let augen: Int
    var body: some View {
        Canvas { ctx, groesse in
            let s = min(groesse.width, groesse.height)
            ctx.fill(Path(roundedRect: CGRect(x: 0, y: 0, width: s, height: s), cornerRadius: s * 0.22, style: .continuous), with: .color(.white))
            let r = s * 0.095
            for (x, y) in Augenmuster.lagen[augen] ?? [] {
                ctx.fill(Path(ellipseIn: CGRect(x: (0.5 + x * 1.08) * s - r, y: (0.5 + y * 1.08) * s - r, width: 2 * r, height: 2 * r)), with: .color(.black))
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

/// Die Kamera-Seite als eigenes Vollbild fürs Spiel (z. B. „Mit Kamera lesen“ in Yacht).
public struct LiveWuerfelVollbild: View {
    let erwartet: Int?
    let hoechstens: Int?
    let fertig: ([Int]?) -> Void
    public init(erwartet: Int? = nil, hoechstens: Int? = nil, fertig: @escaping ([Int]?) -> Void) { self.erwartet = erwartet; self.hoechstens = hoechstens; self.fertig = fertig }
    public var body: some View {
        LiveWuerfelSeite(erwartet: erwartet, hoechstens: hoechstens, onUebernehmen: { fertig($0) }, onAbbrechen: { fertig(nil) })
    }
}
#endif
