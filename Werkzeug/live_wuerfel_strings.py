# Live-Würfelerkennung: trägt die neuen Strings in App/Ressourcen/Localizable.xcstrings und InfoPlist.xcstrings ein. Bestehende Schlüssel bleiben unberührt.
import json, pathlib
R = pathlib.Path(__file__).resolve().parent.parent / "App/Ressourcen"
T = {
"Würfel mit Kamera erkennen": ("Recognise dice with camera", "Reconocer dados con la cámara", "Reconnaître les dés avec l’appareil photo"),
"Im Kinder-Modus nicht verfügbar": ("Not available in Kids mode", "No disponible en el modo infantil", "Indisponible en mode enfant"),
"Würfel mit Kamera": ("Dice with camera", "Dados con cámara", "Dés avec l’appareil photo"),
"Kein Kamerazugriff": ("No camera access", "Sin acceso a la cámara", "Pas d’accès à l’appareil photo"),
"Erlaube Partie in den iOS-Einstellungen den Zugriff auf die Kamera. Die Bilder bleiben auf deinem Gerät.": ("Allow Partie to use the camera in iOS Settings. The images stay on your device.", "Permite que Partie use la cámara en los ajustes de iOS. Las imágenes permanecen en tu dispositivo.", "Autorise Partie à utiliser l’appareil photo dans les réglages iOS. Les images restent sur ton appareil."),
"Keine Kamera gefunden": ("No camera found", "No se encontró ninguna cámara", "Aucun appareil photo trouvé"),
"Dieses Gerät hat keine Kamera, die Partie nutzen kann.": ("This device has no camera Partie can use.", "Este dispositivo no tiene una cámara que Partie pueda usar.", "Cet appareil n’a pas d’appareil photo utilisable par Partie."),
"Einstellungen öffnen": ("Open Settings", "Abrir ajustes", "Ouvrir les réglages"),
"Augenzahl korrigieren": ("Correct the pips", "Corregir los puntos", "Corriger les points"),
"Würfel %lld": ("Die %lld", "Dado %lld", "Dé %lld"),
"Lege Würfel von oben auf einen einfarbigen Tisch.": ("Place dice on a plain surface, seen from above.", "Coloca los dados sobre una superficie lisa, vistos desde arriba.", "Pose les dés sur une surface unie, vus d’en haut."),
"Summe %lld": ("Total %lld", "Suma %lld", "Total %lld"),
"Sicher erkannt": ("Reliably recognised", "Reconocido con seguridad", "Reconnu avec certitude"),
"Noch unsicher: kurz ruhig halten": ("Not sure yet: hold still for a moment", "Aún no seguro: mantén quieto un momento", "Pas encore sûr : ne bouge pas un instant"),
"Tippe auf einen Würfel, um die Zahl zu korrigieren.": ("Tap a die to correct its number.", "Toca un dado para corregir su número.", "Touche un dé pour corriger son chiffre."),
}
P = R / "Localizable.xcstrings"
d = json.loads(P.read_text(encoding="utf-8")); neu = 0
for k, (en, es, fr) in T.items():
    if k in d["strings"]: continue
    d["strings"][k] = {"localizations": {l: {"stringUnit": {"state": "translated", "value": v}} for l, v in (("de", k), ("en", en), ("es", es), ("fr", fr))}}
    neu += 1
P.write_text(json.dumps(d, ensure_ascii=False, indent=2, separators=(",", ": ")) + "\n", encoding="utf-8")
print("neu:", neu)

# Kamera-Hinweis (Info.plist-Text) de/en/es/fr
I = R / "InfoPlist.xcstrings"
de = "Die Kamera erkennt live die Augen deiner echten Würfel. Die Bilder bleiben auf deinem Gerät und werden weder gespeichert noch gesendet."
v = {"de": de,
     "en": "The camera recognises the pips of your real dice live. Images stay on your device and are neither saved nor sent.",
     "es": "La cámara reconoce en directo los puntos de tus dados reales. Las imágenes permanecen en tu dispositivo y no se guardan ni se envían.",
     "fr": "L’appareil photo reconnaît en direct les points de tes vrais dés. Les images restent sur ton appareil et ne sont ni enregistrées ni envoyées."}
doc = json.loads(I.read_text(encoding="utf-8")) if I.exists() else {"sourceLanguage": "de", "strings": {}, "version": "1.0"}
doc["strings"]["NSCameraUsageDescription"] = {"localizations": {l: {"stringUnit": {"state": "translated", "value": t}} for l, t in v.items()}}
I.write_text(json.dumps(doc, ensure_ascii=False, indent=2, separators=(",", ": ")) + "\n", encoding="utf-8")
