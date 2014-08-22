#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "Protean.h"
#import <libactivator/libactivator.h>
#define PLIST_NAME @"/var/mobile/Library/Preferences/com.efrederickson.protean.settings.plist"

@interface PRRSSIPeek : NSObject <LAListener>
@property BOOL acceptEvent;
@end

static PRRSSIPeek *sharedInstance;
static BOOL oldShowRSSI;

@implementation PRRSSIPeek

- (id)init
{
    self = [super init];
    if (self) {
        _acceptEvent = YES;
    }
    return self;
}

- (void)showRSSI
{
    oldShowRSSI = [[Protean getOrLoadSettings][@"showSignalRSSI"] boolValue];
    NSMutableDictionary *prefs = [[Protean getOrLoadSettings] mutableCopy];
    prefs[@"showSignalRSSI"] = @YES;
    [prefs writeToFile:PLIST_NAME atomically:YES];
    [Protean reloadSettings];
    [[objc_getClass("SBStatusBarStateAggregator") sharedInstance] _setItem:3 enabled:NO];
    [[objc_getClass("SBStatusBarStateAggregator") sharedInstance] _setItem:3 enabled:YES];
    
    _acceptEvent = NO;
}

- (void)hideRSSI
{
    NSMutableDictionary *prefs = [[Protean getOrLoadSettings] mutableCopy];
    prefs[@"showSignalRSSI"] = oldShowRSSI ? @YES : @NO;
    [prefs writeToFile:PLIST_NAME atomically:YES];
    [Protean reloadSettings];
    [[objc_getClass("SBStatusBarStateAggregator") sharedInstance] _setItem:3 enabled:NO];
    [[objc_getClass("SBStatusBarStateAggregator") sharedInstance] _setItem:3 enabled:YES];
    
    _acceptEvent = YES;
}

- (void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event
{
    if (_acceptEvent)
    {
        [self showRSSI];
        [self performSelector:@selector(hideRSSI) withObject:nil afterDelay:/*1.5*/2.5];
    }
    [event setHandled:YES];
}

@end

static __attribute__((constructor)) void __rssi_peek_init()
{
    if ([[[NSBundle mainBundle] bundleIdentifier] isEqual:@"com.apple.springboard"])
    {
        sharedInstance = [[PRRSSIPeek alloc] init];
        [[NSClassFromString(@"LAActivator") sharedInstance] registerListener:sharedInstance forName:@"com.efrederickson.protean.rssipeek"];
    }
}