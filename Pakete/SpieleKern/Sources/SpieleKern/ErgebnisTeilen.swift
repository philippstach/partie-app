// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import UIKit

/// Öffnet das Teilen-Blatt von iOS mit einer Ergebnis-Bildkarte (und dem Text als Zugabe) (iPhone: von unten, iPad: als Popover in der Mitte).
public enum ErgebnisTeilen {
    @MainActor
    public static func zeigen(_ text: String) {
        guard TeilenFreigabe.erlaubt() else { return }
        let szenen = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        guard let szene = szenen.first(where: { $0.activationState == .foregroundActive }) ?? szenen.first,
              var oben = szene.keyWindow?.rootViewController else { return }
        while let p = oben.presentedViewController { oben = p }
        let bild = ErgebnisBild.erzeugen(text: text)
        let blatt = UIActivityViewController(activityItems: bild.map { [$0, text] } ?? [text], applicationActivities: nil)
        if let pop = blatt.popoverPresentationController {
            pop.sourceView = oben.view
            pop.sourceRect = CGRect(x: oben.view.bounds.midX, y: oben.view.bounds.midY, width: 0, height: 0)
            pop.permittedArrowDirections = []
        }
        oben.present(blatt, animated: true)
    }
}
#endif
