#import "KlarFangen.h"

BOOL KlarVergleichVersuche(void (NS_NOESCAPE ^block)(void)) {
    @try { block(); return YES; }
    @catch (NSException *ausnahme) { return NO; }
}
