// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Verbindet die Regeln einer Variante mit ihrem Oberflächen-Layout (früher `associatedtype Layout` in `SolitaireRules`,
/// dadurch hing `Model/` an `Views/`). Nur die Tischansicht braucht das Layout.
protocol SolitaireRulesMitLayout: SolitaireRules {
    associatedtype Layout: SolitaireLayout where Layout.State == State
}

extension KlondikeRules: SolitaireRulesMitLayout { typealias Layout = KlondikeLayout }
extension SpiderRules: SolitaireRulesMitLayout { typealias Layout = SpiderLayout }
extension FreeCellRules: SolitaireRulesMitLayout { typealias Layout = FreeCellLayout }
extension YukonRules: SolitaireRulesMitLayout { typealias Layout = YukonLayout }
extension PyramidRules: SolitaireRulesMitLayout { typealias Layout = PyramidLayout }
extension GolfRules: SolitaireRulesMitLayout { typealias Layout = GolfLayout }
extension TriPeaksRules: SolitaireRulesMitLayout { typealias Layout = TriPeaksLayout }
