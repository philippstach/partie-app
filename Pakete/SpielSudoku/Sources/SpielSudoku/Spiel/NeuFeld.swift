// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// design:spielinhalt-datei

import SwiftUI
import KlarGlas
import SudokuKern

/// Das Spielfeld von „Sudoku“ für alle Spielarten (9×9, 6×6, X-Sudoku): quadratisch, dünne Linien innen, dicke zwischen den Kästchen,
/// bei X-Sudoku die Diagonalen leicht getönt. Wird auch vom Eingabemodus für eigene Rätsel benutzt.
struct NeuFeld: View {
    let form: SudokuForm
    let werte: [UInt8]
    let notizen: [UInt16]
    /// Feste Zahlen (Vorgaben, im Eingabemodus alles Eingetragene)
    let fest: (Int) -> Bool
    let seite: CGFloat
    var gewaehlt: Int?
    var rot: Set<Int> = []
    var gleicheZiffern = true
    var tipp: NeuBruecke.Tipp?
    /// Tinte, helles Gerät: das Gitter liegt als helles Blatt auf dem Filz (`raetselBlatt()`), die Zellen sind dann durchsichtig
    var imBlatt = false
    let tippen: (Int) -> Void
    @Environment(\.designArt) private var art   // Designwechsel D.4
    private var klar: Bool { art == .klar }
    /// Tinte: Linien auf Papier, Ziffern in Serife. Salon: Papier ohne Kasten, Blocklinien 2 pt Espresso. klar: wie bisher.
    private var tinte: Color { klar ? Color.primary : Color.schrift }

    var body: some View {
        let g = form.geometrie
        let n = form.n
        let z = seite / CGFloat(n)
        let gewaehlteZiffer: Int = gewaehlt.map { Int(werte[$0]) } ?? 0
        ZStack {
            VStack(spacing: 0) {
                ForEach(0..<n, id: \.self) { r in
                    HStack(spacing: 0) {
                        ForEach(0..<n, id: \.self) { c in
                            zelle(r * n + c, g: g, groesse: z, ziffer: gewaehlteZiffer)
                        }
                    }
                }
            }
            Linien(form: form, art: art).allowsHitTesting(false)
        }
        .frame(width: seite, height: seite)
        .clipShape(.rect(cornerRadius: klar ? 6 : 0))
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private func zelle(_ i: Int, g: SudokuGeometrie, groesse z: CGFloat, ziffer: Int) -> some View {
        let wert = Int(werte[i])
        let ausgewaehlt = gewaehlt == i
        let nachbar = gewaehlt.map { $0 != i && g.teilen($0, i) } ?? false
        let gleich = gleicheZiffern && ziffer != 0 && wert == ziffer && !ausgewaehlt
        let istTipp = tipp?.zelle == i
        let imMuster = tipp?.muster.contains(i) ?? false
        let inEinheit = tipp?.einheit.contains(i) ?? false
        Button { tippen(i) } label: {
            ZStack {
                Rectangle().fill(imBlatt ? Color.clear : (klar ? Color(.systemBackground) : Color.seitenGrund))
                if g.aufDiagonale(i) { Rectangle().fill(Color.secondary.opacity(0.10)) }
                if inEinheit { Rectangle().fill(Color.appFlaeche.opacity(0.14)) }
                if nachbar { Rectangle().fill(Color.appFlaeche.opacity(0.10)) }
                if gleich { Rectangle().fill(Color.appFlaeche.opacity(0.22)) }
                if ausgewaehlt { Rectangle().fill(Color.appFlaeche.opacity(0.34)) }
                if istTipp { Rectangle().fill(Color.appFlaeche.opacity(0.30)) }
                if wert != 0 {
                    Text(verbatim: "\(wert)")
                        .font(.system(size: z * 0.56, weight: fest(i) ? .bold : .medium, design: Design.zahlDesign).monospacedDigit())
                        .foregroundStyle(rot.contains(i) ? Color.meldungRot : (fest(i) ? tinte : Color.accentText))
                        .minimumScaleFactor(0.6)
                } else if notizen[i] != 0 {
                    notizenAnsicht(notizen[i], groesse: z, markiert: gleicheZiffern ? ziffer : 0)
                }
                if istTipp || imMuster {
                    Rectangle().strokeBorder(Color.appFlaeche, lineWidth: istTipp ? 2.5 : 1.5).padding(1)
                }
            }
            .frame(width: z, height: z)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(beschriftung(i, wert: wert, g: g))
        .accessibilityAddTraits(ausgewaehlt ? .isSelected : [])
        .accessibilityIdentifier("sudoku-neu-zelle-\(i)")
    }

    private func notizenAnsicht(_ maske: UInt16, groesse z: CGFloat, markiert: Int) -> some View {
        let zeilen = form == .kinder ? 2 : 3
        return VStack(spacing: 0) {
            ForEach(0..<zeilen, id: \.self) { r in
                HStack(spacing: 0) {
                    ForEach(0..<3, id: \.self) { c in
                        let d = r * 3 + c + 1
                        Text(verbatim: maske & SudokuForm.bit(d) != 0 ? "\(d)" : " ")
                            .font(.system(size: z * (form == .kinder ? 0.27 : 0.22), weight: d == markiert ? .heavy : .semibold, design: Design.zahlDesign))
                            .foregroundStyle(d == markiert ? Color.accentText : Color.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
        }
        .padding(z * 0.07)
    }

    private func beschriftung(_ i: Int, wert: Int, g: SudokuGeometrie) -> Text {
        let ort = String(localized: "Zeile \(g.zeile(i) + 1), Spalte \(g.spalte(i) + 1)")
        if wert != 0 {
            return Text(verbatim: ort + ", " + (fest(i) ? String(localized: "Vorgabe \(wert)") : "\(wert)"))
        }
        let notiz = form.ziffern(notizen[i])
        if notiz.isEmpty { return Text(verbatim: ort + ", " + String(localized: "leer")) }
        return Text(verbatim: ort + ", " + String(localized: "leer, Notizen: \(notiz.map(String.init).joined(separator: " "))"))
    }
}

/// Gitterlinien: dünn zwischen allen Zellen, dick zwischen den Kästchen
private struct Linien: View {
    let form: SudokuForm
    var art: DesignArt = .klar
    var body: some View {
        Canvas { ctx, size in
            let n = form.n
            let z = size.width / CGFloat(n)
            var duenn = Path(), dick = Path()
            for k in 1..<n {
                let p = CGFloat(k) * z
                let senkrechtDick = k % form.boxSpalten == 0
                let waagerechtDick = k % form.boxZeilen == 0
                if senkrechtDick { dick.move(to: CGPoint(x: p, y: 0)); dick.addLine(to: CGPoint(x: p, y: size.height)) }
                else { duenn.move(to: CGPoint(x: p, y: 0)); duenn.addLine(to: CGPoint(x: p, y: size.height)) }
                if waagerechtDick { dick.move(to: CGPoint(x: 0, y: p)); dick.addLine(to: CGPoint(x: size.width, y: p)) }
                else { duenn.move(to: CGPoint(x: 0, y: p)); duenn.addLine(to: CGPoint(x: size.width, y: p)) }
            }
            if art == .klar {
                ctx.stroke(duenn, with: .color(.secondary.opacity(0.35)), lineWidth: 0.5)
                ctx.stroke(dick, with: .color(.primary.opacity(0.55)), lineWidth: 1.8)
                ctx.stroke(Path(CGRect(origin: .zero, size: size)), with: .color(.primary.opacity(0.55)), lineWidth: 2)
            } else {   // Tinte: Blocklinien 1,5 pt; Salon: 2 pt Espresso (Auftrag D.3)
                let block: CGFloat = art == .tinte ? 1.5 : 2
                ctx.stroke(duenn, with: .color(Color.linie), lineWidth: 1)
                ctx.stroke(dick, with: .color(Color.linieStark), lineWidth: block)
                ctx.stroke(Path(CGRect(origin: .zero, size: size)), with: .color(Color.linieStark), lineWidth: block)
            }
        }
    }
}

/// Ziffernblock: eine Reihe (zwei bei großer Schrift), unter jeder Ziffer steht, wie oft sie noch fehlt. Raster 3-spaltig für iPad quer.
struct NeuZiffern: View {
    let n: Int
    /// Wie oft eine Ziffer noch fehlt (`nil`: keine Zähler, z. B. im Eingabemodus)
    var fehlt: ((Int) -> Int)?
    var hoehe: CGFloat = 56
    var raster = false
    var gesperrt = false
    var hervorgehoben: Int?
    let tippen: (Int) -> Void
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        Group {
            if raster {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                    ForEach(1...n, id: \.self) { taste($0) }
                }
            } else if typeSize.isAccessibilitySize && n > 6 {
                VStack(spacing: 6) {
                    HStack(spacing: 6) { ForEach(1...5, id: \.self) { taste($0) } }
                    HStack(spacing: 6) { ForEach(6...n, id: \.self) { taste($0) } }
                }
            } else {
                HStack(spacing: n > 6 ? 3 : 8) { ForEach(1...n, id: \.self) { taste($0) } }
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }

    private func taste(_ d: Int) -> some View {
        let rest = fehlt?(d)
        let fertig = rest.map { $0 <= 0 } ?? false
        return Button { tippen(d) } label: {
            VStack(spacing: 1) {
                Text(verbatim: "\(d)").font(.system(.title2, design: Design.zahlDesign, weight: .medium))
                if let rest {
                    if rest > 0 {
                        Text(verbatim: "\(rest)").font(.system(.caption2, design: Design.zahlDesign).monospacedDigit()).tischHinweis(zeilen: 1)
                    } else {
                        Image(systemName: "checkmark").font(.caption2.weight(.bold))
                    }
                }
            }
            .frame(minWidth: n > 6 ? 30 : 40, maxWidth: .infinity, minHeight: hoehe)
            .foregroundStyle(hervorgehoben == d ? Color.onAccent : Color.accentText)
            .background(hervorgehoben == d ? Color.appFlaeche : Color.clear, in: .rect(cornerRadius: Theme.feldRadius))
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .disabled(fertig || gesperrt)
        .opacity(fertig || gesperrt ? 0.35 : 1)
        .accessibilityLabel(Text(verbatim: "\(d)"))
        .accessibilityValue(rest.map { $0 > 0 ? Text("noch \($0) mal") : Text("komplett") } ?? Text(verbatim: ""))
        .accessibilityIdentifier("sudoku-neu-ziffer-\(d)")
    }
}
