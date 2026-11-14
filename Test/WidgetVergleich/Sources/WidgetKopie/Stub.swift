// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import WidgetKit

// `\.widgetFamily` ist nur lesbar; die kopierten Widget-Quellen lesen stattdessen `\.testFamilie`, das der Test setzt.
struct TestFamilieSchluessel: EnvironmentKey { static let defaultValue: WidgetFamily = .systemSmall }
extension EnvironmentValues { var testFamilie: WidgetFamily { get { self[TestFamilieSchluessel.self] } set { self[TestFamilieSchluessel.self] = newValue } } }
