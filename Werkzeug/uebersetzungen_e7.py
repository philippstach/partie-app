#!/usr/bin/env python3
"""E7 iCloud-Abgleich: Texte der App (App/Ressourcen/Localizable.xcstrings). Aufruf im Repo-Wurzelordner."""
import json
P = "App/Ressourcen/Localizable.xcstrings"
T = {
"Mit iCloud abgleichen": ("Mit iCloud abgleichen", "Sync with iCloud", "Sincronizar con iCloud", "Synchroniser avec iCloud"),
"iCloud": ("iCloud", "iCloud", "iCloud", "iCloud"),
"Jetzt abgleichen": ("Jetzt abgleichen", "Sync now", "Sincronizar ahora", "Synchroniser maintenant"),
"Aus": ("Aus", "Off", "Desactivado", "Désactivé"),
"Gleicht ab …": ("Gleicht ab …", "Syncing …", "Sincronizando …", "Synchronisation …"),
"Zuletzt abgeglichen: %@": ("Zuletzt abgeglichen: %@", "Last synced: %@", "Última sincronización: %@", "Dernière synchronisation : %@"),
"Kein iCloud-Konto angemeldet": ("Kein iCloud-Konto angemeldet", "Not signed in to iCloud", "Sin sesión en iCloud", "Aucun compte iCloud connecté"),
"Abgleich fehlgeschlagen, wird später erneut versucht": ("Abgleich fehlgeschlagen, wird später erneut versucht", "Sync failed, will try again later", "Error al sincronizar; se reintentará más tarde", "Échec de la synchronisation, nouvel essai plus tard"),
"Deine Daten liegen auf deinem Gerät und, solange der iCloud-Abgleich an ist, in deinem privaten iCloud-Speicher. Partie hat keine Konten, keine eigenen Server und kein Tracking.":
 ("Deine Daten liegen auf deinem Gerät und, solange der iCloud-Abgleich an ist, in deinem privaten iCloud-Speicher. Partie hat keine Konten, keine eigenen Server und kein Tracking.",
  "Your data is stored on your device and, while iCloud sync is on, in your private iCloud storage. Partie has no accounts, no servers of its own and no tracking.",
  "Tus datos están en tu dispositivo y, mientras la sincronización con iCloud esté activada, en tu almacenamiento privado de iCloud. Partie no tiene cuentas, servidores propios ni seguimiento.",
  "Tes données se trouvent sur ton appareil et, tant que la synchronisation iCloud est activée, dans ton espace iCloud privé. Partie n’a ni compte, ni serveur propre, ni suivi."),
"Gleicht Spieler, Fotos und Statistik zwischen deinen Geräten mit derselben Apple-ID ab, im privaten iCloud-Speicher. Es wird nur hinzugefügt: Löschen auf einem Gerät löscht nichts auf dem anderen.":
 ("Gleicht Spieler, Fotos und Statistik zwischen deinen Geräten mit derselben Apple-ID ab, im privaten iCloud-Speicher. Es wird nur hinzugefügt: Löschen auf einem Gerät löscht nichts auf dem anderen.",
  "Syncs players, photos and statistics between your devices with the same Apple ID, in your private iCloud storage. Items are only added: deleting on one device deletes nothing on the other.",
  "Sincroniza jugadores, fotos y estadísticas entre tus dispositivos con el mismo ID de Apple, en tu almacenamiento privado de iCloud. Solo se añade: borrar en un dispositivo no borra nada en el otro.",
  "Synchronise joueurs, photos et statistiques entre tes appareils avec le même identifiant Apple, dans ton espace iCloud privé. Les données sont seulement ajoutées : supprimer sur un appareil ne supprime rien sur l’autre."),
}
d = json.load(open(P))
for k, v in T.items():
    if k in d["strings"] and "localizations" in d["strings"][k]: continue   # vorhandene Übersetzungen nicht antasten
    d["strings"][k] = {"localizations": {l: {"stringUnit": {"state": "translated", "value": x}} for l, x in zip(["de", "en", "es", "fr"], v)}}
open(P, "w").write(json.dumps(d, ensure_ascii=False, indent=2) + "\n")
print("ok", len(T))
