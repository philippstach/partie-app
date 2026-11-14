// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import SpielSchocken

@Suite("Ergebnisseite Zähler")
struct EndeZaehlerTests {
    private func neu() -> Spielzustand {
        Spielzustand(namen: ["A", "B"], strategien: [.mensch, .mensch], optionen: .standard, beginner: 0)
    }

    /// (a) Der erste Wurf zählt drei Würfel für den, der dran ist; eingetippte Würfel zählen auch als eingetippt.
    @Test func wuerfeZaehlenFuerDenSpieler() {
        var q = SeedQuelle(seed: 3)   // App-Würfel: nichts davon ist eingetippt
        var z = neu()
        z.wuerfeln(&q)
        #expect(z.wuerfelAugen?[0].reduce(0, +) == 3)
        #expect(z.wuerfelAugen?[1] == [0, 0, 0, 0, 0, 0])
        #expect(z.wuerfelGetippt == [0, 0])
        var e = neu()
        e.wuerfeln(eingabe: [6, 6, 1])
        #expect(e.wuerfelAugen?[0] == [1, 0, 0, 0, 0, 2])
        #expect(e.wuerfelGetippt == [3, 0])
        #expect(e.wuerfelBilanz?.wuerfe(0) == 3)
    }

    /// (b) Ein Stand ohne die neuen Schlüssel lädt, die Zählung ist nil, es gibt kein Bild und nichts stürzt ab.
    @Test func alterStandLaedtOhneZaehlung() throws {
        var q = SeedQuelle(seed: 3)
        var z = neu()
        z.wuerfeln(&q)
        var json = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(z)) as? [String: Any])
        json.removeValue(forKey: "wuerfelAugen"); json.removeValue(forKey: "wuerfelGetippt")
        let alt = try JSONDecoder().decode(Spielzustand.self, from: JSONSerialization.data(withJSONObject: json))
        #expect(alt.wuerfelAugen == nil && alt.wuerfelGetippt == nil)
        #expect(alt.wuerfelBilanz == nil)
        var weiter = alt
        var q2 = ListenQuelle([1, 1, 1])
        _ = weiter.fuehreAus(.stehen, &q2)   // weiterspielen zählt nichts und stürzt nicht ab
        #expect(weiter.wuerfelAugen == nil)
    }
}
