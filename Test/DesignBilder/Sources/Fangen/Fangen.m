#import "Fangen.h"

BOOL DesignBilderVersuche(void (NS_NOESCAPE ^block)(void)) {
    @try { block(); return YES; }
    @catch (NSException *ausnahme) { return NO; }
}
