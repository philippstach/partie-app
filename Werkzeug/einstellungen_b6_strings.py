#!/usr/bin/env python3
"""einstellungen_b6_strings.py (Testliste Build 6, Einstellungen): ergänzt en/es/fr-Texte der neuen Einstellungs-Funktionen
in App/Ressourcen/Localizable.xcstrings. Überschreibt nie Vorhandenes; beliebig oft wiederholbar.
Aufruf aus dem Projektordner: python3 Werkzeug/einstellungen_b6_strings.py"""
import json
KAT = 'App/Ressourcen/Localizable.xcstrings'
U = {
"App-Symbol anpassen": ("Match app icon", "Adaptar el icono de la app", "Adapter l’icône de l’app"),
"Das Bild von Partie auf dem Home-Bildschirm zeigt dann das Symbol dieses Spiels.": (
    "The Partie icon on your Home Screen then shows this game’s icon.",
    "El icono de Partie en la pantalla de inicio mostrará entonces el icono de este juego.",
    "L’icône de Partie sur l’écran d’accueil affichera alors celle de ce jeu."),
"Sprache": ("Language", "Idioma", "Langue"),
"Mitteilungen": ("Notifications", "Notificaciones", "Notifications"),
"In iOS-Einstellungen erlauben": ("Allow in iOS Settings", "Permitir en Ajustes de iOS", "Autoriser dans les réglages iOS"),
"Tagesrätsel-Erinnerung": ("Daily puzzle reminder", "Recordatorio del acertijo del día", "Rappel de l’énigme du jour"),
"Die Uhrzeit stellst du im Wortpfeil ein.": ("You set the time in Word Arrow.", "La hora se ajusta en Flecha de palabras.", "Tu règles l’heure dans Mots fléchés."),
"Im Ruhe-Modus sind Mitteilungen aus.": ("Notifications are off in Quiet mode.", "Las notificaciones están desactivadas en el modo tranquilo.", "Les notifications sont désactivées en mode calme."),
"Partie meldet sich nur mit den Arten, die du hier angeschaltet lässt. Ausschalten löscht alle geplanten Mitteilungen.": (
    "Partie only sends the kinds you leave switched on here. Switching off removes all scheduled notifications.",
    "Partie solo envía los tipos que dejes activados aquí. Al desactivar se eliminan todas las notificaciones programadas.",
    "Partie n’envoie que les types que tu laisses activés ici. Désactiver supprime toutes les notifications prévues."),
"Blendet die Spiele aus, die du unter „Spiele für Kinder“ abwählst. Ausschalten und Ändern der Auswahl verlangt Face ID oder den Gerätecode.": (
    "Hides the games you deselect under “Games for kids”. Switching it off or changing the selection requires Face ID or the device passcode.",
    "Oculta los juegos que desmarques en «Juegos para niños». Desactivarlo o cambiar la selección requiere Face ID o el código del dispositivo.",
    "Masque les jeux que tu décoches sous « Jeux pour enfants ». Le désactiver ou modifier la sélection demande Face ID ou le code de l’appareil."),
"Zeitlimit über iOS-Bildschirmzeit einstellen:": ("Set a time limit with iOS Screen Time:", "Ajustar un límite de tiempo con Tiempo en pantalla de iOS:", "Régler une limite de temps avec Temps d’écran iOS :"),
"1. Einstellungen öffnen > Bildschirmzeit": ("1. Open Settings > Screen Time", "1. Abre Ajustes > Tiempo en pantalla", "1. Ouvre Réglages > Temps d’écran"),
"2. App-Limits > Limit hinzufügen": ("2. App Limits > Add Limit", "2. Límites de apps > Añadir límite", "2. Limites d’app > Ajouter une limite"),
"3. Partie wählen und die Zeit festlegen": ("3. Choose Partie and set the time", "3. Elige Partie y fija el tiempo", "3. Choisis Partie et règle la durée"),
"Kinder-Modus ausschalten": ("Switch off Kids mode", "Desactivar el modo infantil", "Désactiver le mode enfants"),
"Spiele für Kinder ändern": ("Change games for kids", "Cambiar los juegos para niños", "Modifier les jeux pour enfants"),
"Gesperrt": ("Locked", "Bloqueado", "Verrouillé"),
"Entsperren": ("Unlock", "Desbloquear", "Déverrouiller"),
"Die Auswahl ändern geht nur mit Face ID oder dem Gerätecode.": (
    "Changing the selection needs Face ID or the device passcode.",
    "Cambiar la selección requiere Face ID o el código del dispositivo.",
    "Modifier la sélection demande Face ID ou le code de l’appareil."),
"Spiel suchen": ("Search game", "Buscar juego", "Rechercher un jeu"),
"Open Source": ("Open source", "Código abierto", "Open source"),
"Partie ist Open Source: Den Quelltext kann jede und jeder lesen, prüfen und verbessern.": (
    "Partie is open source: anyone can read, check and improve the source code.",
    "Partie es de código abierto: cualquiera puede leer, revisar y mejorar el código fuente.",
    "Partie est open source : tout le monde peut lire, vérifier et améliorer le code source."),
"Partie auf GitHub": ("Partie on GitHub", "Partie en GitHub", "Partie sur GitHub"),
"Der Quelltext und der Baukasten für eigene Spiele liegen auf GitHub. Wer mitbauen will, reicht Spiele ein und wird als Entwickler genannt.": (
    "The source code and the toolkit for your own games are on GitHub. If you want to help build, submit games and you’ll be credited as a developer.",
    "El código fuente y el kit para juegos propios están en GitHub. Quien quiera colaborar envía juegos y se le menciona como desarrollador.",
    "Le code source et la boîte à outils pour tes propres jeux sont sur GitHub. Qui veut participer propose des jeux et est cité comme développeur."),
"Entwickler": ("Developer", "Desarrollador", "Développeur"),
"Partie zurücksetzen": ("Reset Partie", "Restablecer Partie", "Réinitialiser Partie"),
"Partie zurücksetzen?": ("Reset Partie?", "¿Restablecer Partie?", "Réinitialiser Partie ?"),
"Alles zurücksetzen": ("Reset everything", "Restablecer todo", "Tout réinitialiser"),
"Entwicklermodus beenden": ("Exit developer mode", "Salir del modo desarrollador", "Quitter le mode développeur"),
"Zum Testen: setzt Partie auf den Zustand nach der Installation zurück.": (
    "For testing: resets Partie to its state right after installation.",
    "Para pruebas: restablece Partie al estado posterior a la instalación.",
    "Pour les tests : remet Partie dans l’état suivant l’installation."),
"Statistik, Spieler, Favoriten, Spielstände, Einstellungen und das App-Symbol werden gelöscht. Danach startet Partie wie neu installiert; beende die App und öffne sie neu.": (
    "Statistics, players, favourites, saved games, settings and the app icon will be deleted. Partie then starts as if newly installed; quit the app and open it again.",
    "Se borrarán las estadísticas, los jugadores, los favoritos, las partidas guardadas, los ajustes y el icono de la app. Después Partie arranca como recién instalada; cierra la app y ábrela de nuevo.",
    "Les statistiques, joueurs, favoris, parties en cours, réglages et l’icône de l’app seront supprimés. Partie redémarre ensuite comme neuve ; quitte l’app et rouvre-la."),
"Face ID schützt den Kinder-Modus, damit Kinder ihn nicht selbst ausschalten.": (
    "Face ID protects Kids mode so children can’t switch it off themselves.",
    "Face ID protege el modo infantil para que los niños no puedan desactivarlo.",
    "Face ID protège le mode enfants afin que les enfants ne puissent pas le désactiver."),
}
d = json.load(open(KAT)); st = d["strings"]; neu = 0
for k, (en, es, fr) in U.items():
    e = st.setdefault(k, {"extractionState": "manual", "localizations": {}})
    loc = e.setdefault("localizations", {})
    for l, v in (("de", k), ("en", en), ("es", es), ("fr", fr)):
        if l not in loc: loc[l] = {"stringUnit": {"state": "translated", "value": v}}; neu += 1
json.dump(d, open(KAT, "w"), ensure_ascii=False, indent=2); open(KAT, "a").write("\n")
print("ergänzt:", neu)
