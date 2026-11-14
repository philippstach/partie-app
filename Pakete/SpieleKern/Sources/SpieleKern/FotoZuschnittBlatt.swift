// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import UIKit
import KlarGlas

/// Foto anpassen: Bild mit zwei Fingern zoomen, mit einem verschieben; der runde Ausschnitt wird quadratisch gesichert.
/// `fertig` bekommt den zugeschnittenen Ausschnitt als JPEG (höchstens `SpielerBilder.kante` Pixel).
public struct FotoZuschnittBlatt: View {
    let daten: Data
    let fertig: (Data) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var zoom: CGFloat = 1
    @State private var zoomStart: CGFloat = 1
    @State private var versatz: CGSize = .zero
    @State private var versatzStart: CGSize = .zero
    private let kasten: CGFloat = 280

    public init(daten: Data, fertig: @escaping (Data) -> Void) { self.daten = daten; self.fertig = fertig }

    private var bild: UIImage? { UIImage(data: daten) }
    private var rechnung: FotoZuschnitt? { bild.flatMap { FotoZuschnitt(bild: $0.size, kasten: kasten) } }

    public var body: some View {
        NavigationStack {
            VStack(spacing: Theme.kartenAbstand) {
                if let b = bild, let r = rechnung {
                    let g = r.anzeigeGroesse(zoom: zoom)
                    ZStack {
                        Image(uiImage: b).resizable().frame(width: g.width, height: g.height).offset(r.versatzBegrenzen(versatz, zoom: zoom))
                    }
                    .frame(width: kasten, height: kasten).clipped()
                    .overlay { Circle().strokeBorder(.white, lineWidth: 2).shadow(radius: 2) }
                    .overlay { Rectangle().strokeBorder(Color.secondary.opacity(0.4), lineWidth: 1) }
                    .contentShape(.rect)
                    .gesture(
                        DragGesture()
                            .onChanged { versatz = r.versatzBegrenzen(CGSize(width: versatzStart.width + $0.translation.width, height: versatzStart.height + $0.translation.height), zoom: zoom) }
                            .onEnded { _ in versatzStart = versatz }
                            .simultaneously(with:
                                MagnifyGesture()
                                    .onChanged { zoom = FotoZuschnitt.zoomBegrenzen(zoomStart * $0.magnification); versatz = r.versatzBegrenzen(versatz, zoom: zoom) }
                                    .onEnded { _ in zoomStart = zoom; versatzStart = versatz }
                            )
                    )
                    .accessibilityElement()
                    .accessibilityLabel(Text("Foto-Ausschnitt"))
                    .accessibilityHint(Text("Mit dem Regler vergrößern, mit Ziehen verschieben"))

                    Text("Zum Anpassen ziehen und zoomen.").font(.footnote).foregroundStyle(.secondary)

                    HStack(spacing: Design.Abstand.m) {
                        Image(systemName: "minus.magnifyingglass").foregroundStyle(.secondary).accessibilityHidden(true)
                        Slider(value: Binding(get: { zoom }, set: { zoom = FotoZuschnitt.zoomBegrenzen($0); zoomStart = zoom; versatz = r.versatzBegrenzen(versatz, zoom: zoom); versatzStart = versatz }),
                               in: 1...FotoZuschnitt.hoechsterZoom)
                            .accessibilityLabel(Text("Zoom"))
                        Image(systemName: "plus.magnifyingglass").foregroundStyle(.secondary).accessibilityHidden(true)
                    }
                    .padding(.horizontal, Theme.seitenRand)

                    Button("Übernehmen") { uebernehmen(b, r) }.buttonStyle(HauptKnopfStil()).padding(.horizontal, Theme.seitenRand)
                } else {
                    Text("Dieses Bild kann nicht verwendet werden.").foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            .padding(.top, Theme.seitenRand)
            .background(Color.seitenGrund)
            .navigationTitle("Foto anpassen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { BlattSchliessenKnopf("Abbrechen") { dismiss() } } }
        }
    }

    /// Schneidet den gewählten Ausschnitt (mit korrekter Ausrichtung) als quadratisches JPEG aus.
    private func uebernehmen(_ b: UIImage, _ r: FotoZuschnitt) {
        let q = r.quelle(zoom: zoom, versatz: versatz)
        let ziel = min(SpielerBilder.kante, q.width)
        let format = UIGraphicsImageRendererFormat(); format.scale = 1; format.opaque = true
        let f = ziel / q.width
        let neu = UIGraphicsImageRenderer(size: CGSize(width: ziel, height: ziel), format: format).image { _ in
            b.draw(in: CGRect(x: -q.minX * f, y: -q.minY * f, width: b.size.width * f, height: b.size.height * f))
        }
        if let jpg = neu.jpegData(compressionQuality: 0.85) { fertig(jpg); dismiss() }
    }
}
#endif
