#import <Foundation/Foundation.h>

/// Führt den Block aus und fängt eine Objective-C-Ausnahme ab (Swift kann das nicht). Rückgabe: YES, wenn keine Ausnahme kam.
/// Nur für die Bildaufnahme: Das erste Anzeigen eines Fensters ohne laufende App wirft unter Mac Catalyst einmal eine Ausnahme.
BOOL KlarVergleichVersuche(void (NS_NOESCAPE ^_Nonnull block)(void));
