# Ansage der Würfelaugen (Yacht, Wurf eintragen): trägt die neuen Strings in App/Ressourcen/Localizable.xcstrings und die Berechtigungstexte in InfoPlist.xcstrings ein. Bestehende Schlüssel bleiben unberührt.
import json, pathlib
W = pathlib.Path(__file__).resolve().parent.parent / "App/Ressourcen"
def trage(datei, T):
    P = W / datei
    d = json.loads(P.read_text(encoding="utf-8")); neu = 0
    for k, (de, en, es, fr) in T.items():
        if k in d["strings"]: continue
        d["strings"][k] = {"localizations": {l: {"stringUnit": {"state": "translated", "value": v}} for l, v in (("de", de or k), ("en", en), ("es", es), ("fr", fr))}}
        neu += 1
    P.write_text(json.dumps(d, ensure_ascii=False, indent=2, separators=(",", ": ")) + "\n", encoding="utf-8")
    print(datei, "neu:", neu)
trage("Localizable.xcstrings", {
"Ansagen": (None, "Say it", "Decirlo", "Dicter"),
"Sag die Augen deiner Würfel der Reihe nach, zum Beispiel: drei, fünf, eins.": (None, "Say the pips of your dice one after another, for example: three, five, one.", "Di los puntos de tus dados uno tras otro, por ejemplo: tres, cinco, uno.", "Dis les points de tes dés l’un après l’autre, par exemple : trois, cinq, un."),
"Ich höre zu. Sag die Augen, zum Beispiel: drei, fünf, eins.": (None, "Listening. Say the pips, for example: three, five, one.", "Te escucho. Di los puntos, por ejemplo: tres, cinco, uno.", "J’écoute. Dis les points, par exemple : trois, cinq, un."),
"Fertig": (None, "Done", "Listo", "Terminé"),
"Kein Zugriff auf Mikrofon oder Spracherkennung. Erlaube beides in den iOS-Einstellungen unter Partie.": (None, "No access to the microphone or speech recognition. Allow both in iOS Settings under Partie.", "Sin acceso al micrófono o al reconocimiento de voz. Permite ambos en Ajustes de iOS, en Partie.", "Pas d’accès au micro ou à la reconnaissance vocale. Autorise les deux dans les Réglages iOS, sous Partie."),
"Die Ansage ist auf diesem Gerät gerade nicht verfügbar. Tippe die Augen ein.": (None, "Voice entry is not available on this device right now. Type in the pips.", "La entrada por voz no está disponible ahora en este dispositivo. Escribe los puntos.", "La dictée n’est pas disponible sur cet appareil pour le moment. Saisis les points."),
"Nichts verstanden. Sag die Augen einzeln und deutlich, oder tippe sie ein.": (None, "Nothing understood. Say the pips one by one and clearly, or type them in.", "No se entendió nada. Di los puntos uno a uno y con claridad, o escríbelos.", "Rien compris. Dis les points un par un et clairement, ou saisis-les."),
"Nicht alle Würfel verstanden. Ergänze die fehlenden mit den Zifferntasten.": (None, "Not all dice understood. Fill in the missing ones with the number keys.", "No se entendieron todos los dados. Completa los que faltan con las teclas numéricas.", "Tous les dés n’ont pas été compris. Complète les manquants avec les touches numériques."),
})
trage("InfoPlist.xcstrings", {
"NSMicrophoneUsageDescription": ("Über das Mikrofon kannst du die Augen deiner echten Würfel ansagen. Der Ton wird auf deinem Gerät ausgewertet und weder gespeichert noch gesendet.", "Use the microphone to say the pips of your real dice. Audio is processed on your device and is neither saved nor sent.", "Con el micrófono puedes decir los puntos de tus dados reales. El audio se procesa en tu dispositivo y no se guarda ni se envía.", "Le micro te permet de dicter les points de tes vrais dés. Le son est traité sur ton appareil et n’est ni enregistré ni envoyé."),
"NSSpeechRecognitionUsageDescription": ("Die Spracherkennung versteht die angesagten Augenzahlen. Sie läuft auf deinem Gerät, es wird nichts gesendet.", "Speech recognition understands the numbers you say. It runs on your device and nothing is sent.", "El reconocimiento de voz entiende los números que dices. Funciona en tu dispositivo y no se envía nada.", "La reconnaissance vocale comprend les nombres que tu dictes. Elle fonctionne sur ton appareil et rien n’est envoyé."),
})
