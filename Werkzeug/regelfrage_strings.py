#!/usr/bin/env python3
"""regelfrage_strings.py (KI-3, Blatt 12 „Frag nach den Regeln“): en/es/fr für die neuen Texte. Überschreibt nie
vorhandene Übersetzungen. Aufruf aus dem Projektordner (Partie/Haupt)."""
import json
KAT = 'App/Ressourcen/Localizable.xcstrings'
U = {
"Frag nach den Regeln": ("Ask about the rules", "Pregunta sobre las reglas", "Poser une question sur les règles"),
"Apple Intelligence · auf dem Gerät, ohne Internet": ("Apple Intelligence · on the device, no internet", "Apple Intelligence · en el dispositivo, sin internet", "Apple Intelligence · sur l’appareil, sans internet"),
"Zum Beispiel": ("For example", "Por ejemplo", "Par exemple"),
"Frage zu den Regeln": ("Question about the rules", "Pregunta sobre las reglas", "Question sur les règles"),
"Antworten können falsch sein. Es gelten die Regeln.": ("Answers can be wrong. The rules apply.", "Las respuestas pueden ser incorrectas. Valen las reglas.", "Les réponses peuvent être fausses. Ce sont les règles qui comptent."),
"Aus den Regeln": ("From the rules", "De las reglas", "Des règles"),
"Ich schaue in den Regeln nach …": ("Looking it up in the rules …", "Miro en las reglas …", "Je regarde dans les règles …"),
"Apple Intelligence ist aus": ("Apple Intelligence is off", "Apple Intelligence está desactivado", "Apple Intelligence est désactivé"),
"Einstellungen öffnen": ("Open Settings", "Abrir ajustes", "Ouvrir les réglages"),
"Einen Moment noch": ("One moment", "Un momento", "Un instant"),
"Senden": ("Send", "Enviar", "Envoyer"),
"Für Regel-Fragen braucht die App Apple Intelligence. Du schaltest es in den Einstellungen deines iPhones ein.": ("For rule questions the app needs Apple Intelligence. You turn it on in your iPhone’s settings.", "Para las preguntas sobre las reglas la app necesita Apple Intelligence. Lo activas en los ajustes de tu iPhone.", "Pour les questions sur les règles, l’app a besoin d’Apple Intelligence. Tu l’actives dans les réglages de ton iPhone."),
"Für Regel-Fragen braucht die App Apple Intelligence. Du schaltest es in den Einstellungen deines iPads ein.": ("For rule questions the app needs Apple Intelligence. You turn it on in your iPad’s settings.", "Para las preguntas sobre las reglas la app necesita Apple Intelligence. Lo activas en los ajustes de tu iPad.", "Pour les questions sur les règles, l’app a besoin d’Apple Intelligence. Tu l’actives dans les réglages de ton iPad."),
"Das Sprachmodell wird noch geladen. Versuch es gleich noch einmal.": ("The language model is still loading. Try again in a moment.", "El modelo de lenguaje aún se está cargando. Inténtalo de nuevo enseguida.", "Le modèle de langage est encore en cours de chargement. Réessaie dans un instant."),
"Stell eine Frage zu %@, so wie ihr gerade spielt. Die Antwort kommt von Apple Intelligence, auf dem Gerät und ohne Internet.": ("Ask a question about %@, the way you are playing right now. The answer comes from Apple Intelligence, on the device and without internet.", "Haz una pregunta sobre %@, tal como estáis jugando ahora. La respuesta viene de Apple Intelligence, en el dispositivo y sin internet.", "Pose une question sur %@, comme vous jouez en ce moment. La réponse vient d’Apple Intelligence, sur l’appareil et sans internet."),
"Stell eine Frage zu %@, so wie ihr gerade spielt. Eure Hausregeln zählen mit. Die Antwort kommt von Apple Intelligence, auf dem Gerät und ohne Internet.": ("Ask a question about %@, the way you are playing right now. Your house rules count. The answer comes from Apple Intelligence, on the device and without internet.", "Haz una pregunta sobre %@, tal como estáis jugando ahora. Vuestras reglas de la casa cuentan. La respuesta viene de Apple Intelligence, en el dispositivo y sin internet.", "Pose une question sur %@, comme vous jouez en ce moment. Vos règles maison comptent. La réponse vient d’Apple Intelligence, sur l’appareil et sans internet."),
}
cat = json.load(open(KAT)); s = cat['strings']
n = 0
for k, t in U.items():
    loc = s.setdefault(k, {}).setdefault('localizations', {})
    if 'en' in loc and 'es' in loc and 'fr' in loc: continue
    for sp, v in zip(('en', 'es', 'fr'), t): loc.setdefault(sp, {"stringUnit": {"state": "translated", "value": v}})
    n += 1
orig = open(KAT).read()
open(KAT, 'w').write(json.dumps(cat, ensure_ascii=False, indent=2, separators=(',', ': ')) + ('\n' if orig.endswith('\n') else ''))
print('eingetragen:', n)
