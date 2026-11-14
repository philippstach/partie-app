#!/usr/bin/env python3
"""scanner_strings.py: de/en/es/fr für den Scanner-Modus (Branch scanner-multipeer). Überschreibt nie vorhandene Übersetzungen, mehrfach aufrufbar.
Aufruf aus dem Projektordner."""
import json
KAT = 'App/Ressourcen/Localizable.xcstrings'
U = {
"Als Würfelscanner nutzen": ("Use as dice scanner", "Usar como escáner de dados", "Utiliser comme scanner de dés"),
"Würfel vom Scanner empfangen": ("Receive dice from scanner", "Recibir dados del escáner", "Recevoir les dés du scanner"),
"Vom Scanner": ("From scanner", "Del escáner", "Du scanner"),
"Ein zweites Gerät mit Partie liest die Würfel und schickt den Wurf hierher.": ("A second device with Partie reads the dice and sends the roll here.", "Un segundo dispositivo con Partie lee los dados y envía la tirada aquí.", "Un deuxième appareil avec Partie lit les dés et envoie le lancer ici."),
"Spielgeräte in der Nähe": ("Game devices nearby", "Dispositivos de juego cercanos", "Appareils de jeu à proximité"),
"Suche Spielgerät …": ("Looking for a game device …", "Buscando dispositivo de juego …", "Recherche d’un appareil de jeu …"),
"Öffne auf dem Spielgerät „Würfel vom Scanner empfangen“. Dort musst du die Verbindung bestätigen. Es werden nur die Augen übertragen, keine Bilder.": (
    "On the game device, open “Receive dice from scanner”. You have to confirm the connection there. Only the pips are sent, no images.",
    "En el dispositivo de juego, abre «Recibir dados del escáner». Allí debes confirmar la conexión. Solo se envían los puntos, no imágenes.",
    "Sur l’appareil de jeu, ouvre « Recevoir les dés du scanner ». Tu dois y confirmer la connexion. Seuls les points sont envoyés, pas d’images."),
"Keine Kamera verfügbar": ("No camera available", "Cámara no disponible", "Aucune caméra disponible"),
"Lege die Würfel unter die Kamera.": ("Place the dice under the camera.", "Coloca los dados bajo la cámara.", "Place les dés sous la caméra."),
"%lld Würfe gesendet": ("%lld rolls sent", "%lld tiradas enviadas", "%lld lancers envoyés"),
"Warte auf den ersten Wurf …": ("Waiting for the first roll …", "Esperando la primera tirada …", "En attente du premier lancer …"),
"Warte auf den Scanner. Öffne auf dem anderen Gerät „Als Würfelscanner nutzen“.": ("Waiting for the scanner. On the other device, open “Use as dice scanner”.", "Esperando al escáner. En el otro dispositivo, abre «Usar como escáner de dados».", "En attente du scanner. Sur l’autre appareil, ouvre « Utiliser comme scanner de dés »."),
"Scanner verbinden?": ("Connect scanner?", "¿Conectar escáner?", "Connecter le scanner ?"),
"Verbinden": ("Connect", "Conectar", "Connecter"),
"Ablehnen": ("Decline", "Rechazar", "Refuser"),
"„%@“ möchte als Würfelscanner Würfe an dieses Gerät senden.": ("“%@” wants to send rolls to this device as a dice scanner.", "«%@» quiere enviar tiradas a este dispositivo como escáner de dados.", "« %@ » souhaite envoyer des lancers à cet appareil comme scanner de dés."),
"Abbrechen": ("Cancel", "Cancelar", "Annuler"),
}
cat = json.load(open(KAT)); s = cat['strings']
n = 0
for k, t in U.items():
    loc = s.setdefault(k, {}).setdefault('localizations', {})
    loc.setdefault('de', {"stringUnit": {"state": "translated", "value": k}})
    for sp, v in zip(('en', 'es', 'fr'), t):
        if sp in loc: continue
        loc[sp] = {"stringUnit": {"state": "translated", "value": v}}; n += 1
orig = open(KAT).read()
open(KAT, 'w').write(json.dumps(cat, ensure_ascii=False, indent=2, separators=(',', ': ')) + ('\n' if orig.endswith('\n') else ''))
print('eingetragen:', n)

# InfoPlist: Hinweis für das lokale Netzwerk (Multipeer/Bonjour)
IP = 'App/Ressourcen/InfoPlist.xcstrings'
K = 'NSLocalNetworkUsageDescription'
V = {
 "de": "Partie verbindet dein iPhone und dein iPad direkt miteinander, damit ein Gerät als Würfelscanner dienen kann. Es werden nur die Augen der Würfel übertragen, keine Bilder.",
 "en": "Partie connects your iPhone and iPad directly so that one device can serve as a dice scanner. Only the pips are sent, no images.",
 "es": "Partie conecta tu iPhone y tu iPad directamente para que un dispositivo sirva de escáner de dados. Solo se envían los puntos, no imágenes.",
 "fr": "Partie relie directement ton iPhone et ton iPad pour qu’un appareil serve de scanner de dés. Seuls les points sont envoyés, pas d’images.",
}
c = json.load(open(IP)); loc = c['strings'].setdefault(K, {}).setdefault('localizations', {})
m = 0
for sp, v in V.items():
    if sp not in loc: loc[sp] = {"stringUnit": {"state": "translated", "value": v}}; m += 1
orig = open(IP).read()
open(IP, 'w').write(json.dumps(c, ensure_ascii=False, indent=2, separators=(',', ': ')) + ('\n' if orig.endswith('\n') else ''))
print('InfoPlist eingetragen:', m)
