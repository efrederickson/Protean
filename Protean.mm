#import "Protean.h"
#import "headers.h"
#import <UIKit/UIKit.h>
#import <libactivator/libactivator.h>
#import <notify.h>
#import "PRStatusApps.h"
#import <dispatch/dispatch.h>
#import <stdio.h>

@interface BBServer (Protean_private)
+(id) PR_sharedInstance;
@end

extern "C" CFNotificationCenterRef CFNotificationCenterGetDistributedCenter(void);
#define PLIST_NAME @"/var/mobile/Library/Preferences/com.efrederickson.protean.settings.plist"

//based on http://iphonedevwiki.net/index.php/Libactivator#Dispatching_Events
inline LAEvent *LASendEventWithName(NSString *eventName) {
	LAEvent *event = [LAEvent eventWithName:eventName mode:[LASharedActivator currentEventMode]];
	[LASharedActivator sendEventToListener:event];
	return event;
}
inline LAEvent *LASendEventToListener(NSString *listener) {
	LAEvent *event = [LAEvent eventWithName:@"com.efrederickson.protean.dummy_event" mode:[LASharedActivator currentEventMode]];
	[LASharedActivator sendEvent:event toListenerWithName:listener];
	return event;
}

NSMutableDictionary *LSBitems = [NSMutableDictionary dictionary];
NSMutableArray *mappedIdentifiers = [NSMutableArray array];
int LSBitems_index = 33;

NSMutableDictionary *prefs = nil;
NSMutableDictionary *storedBulletins = [NSMutableDictionary dictionary];

@implementation Protean
+(NSMutableDictionary*) getOrLoadSettings
{
    if (!prefs)
    {
        prefs = [[NSMutableDictionary dictionaryWithContentsOfFile:PLIST_NAME] retain];
        if (prefs == nil)
            prefs = [[NSMutableDictionary dictionary] retain];
    }
    return prefs;
}

+(BOOL) canHandleTapForItem:(UIStatusBarItem*)item
{
    int type = MSHookIvar<int>(item, "_type");
    
    if (type <= 32) // System item
    {
        NSString *ident = [NSString stringWithFormat:@"%d", type];
        
        id mode1 = [Protean getOrLoadSettings][@"tapActions"][ident];
        int mode = mode1 ? [mode1 intValue] : 0;
        
        if (mode == 0)
            return NO;
        else if (mode == 2)
        {
            return YES;
        }
        else
            NSLog(@"[Protean] invalid IconTap action for system item: %d", mode);
    }
    else
    {
        NSString *ident = [Protean getOrLoadSettings][[NSString stringWithFormat:@"%d",type]][@"identifier"]; //[Protean mappedIdentifierForItem:type];
        if ([ident hasPrefix:@"com.efrederickson.protean-"])
            ident = [ident substringFromIndex:26];
        
        id mode1 = [Protean getOrLoadSettings][@"tapActions"][ident];
        int mode = mode1 ? [mode1 intValue] : 0;
        if (mode == 1 || mode == 2 || mode == 3)
            return YES;
    }
    
    return NO;
}

+(id) HandlerForTapOnItem:(UIStatusBarItem*)item
{
    //NSLog(@"[Protean] HandlerForTapOnItem");
    int type = MSHookIvar<int>(item, "_type");
    
    if (type <= 32) // System item
    {
        NSString *ident = [NSString stringWithFormat:@"%d", type];
        
        id mode1 = [Protean getOrLoadSettings][@"tapActions"][ident];
        int mode = mode1 ? [mode1 intValue] : 0;
        
        if (mode == 0)
            return nil;
        else if (mode == 2)
        {
            // Activator
            LASendEventWithName([NSString stringWithFormat:@"com.efrederickson.protean-%@",ident]);
        }
        else
            NSLog(@"[Protean] invalid IconTap action for system item: %d", mode);
    }
    else
    {
        NSString *ident = [Protean getOrLoadSettings][[NSString stringWithFormat:@"%d",type]][@"identifier"]; //[Protean mappedIdentifierForItem:type];
        if ([ident hasPrefix:@"com.efrederickson.protean-"])
            ident = [ident substringFromIndex:26];
        
        id mode1 = [Protean getOrLoadSettings][@"tapActions"][ident];
        int mode = mode1 ? [mode1 intValue] : 0;

        if (mode == 0)
        {
            return nil;
        }
        else if (mode == 1)
        {
            // Open application
            
            __strong NSDictionary *userInfo = @{@"appId": ident};
            CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), CFSTR("com.efrederickson.protean/launchApp"), nil, (__bridge CFDictionaryRef)userInfo, YES);
        }
        else if (mode == 2)
        {
            // Activator
            LASendEventWithName([NSString stringWithFormat:@"com.efrederickson.protean-%@",ident]);
        }
        else if (mode == 3)
        {
            // Quick Reply
            
            if ([[[NSBundle mainBundle] bundleIdentifier] isEqual:@"com.apple.springboard"] == NO)
                CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), CFSTR("com.efrederickson.protean/launchQR"), nil, (__bridge CFDictionaryRef)@{ @"appId":ident}, YES);
            else
                [Protean launchQR:ident];
        }
        else
            NSLog(@"[Protean] invalid IconTap action: %d", mode);
    }
    
    return nil;
}


+(void) mapIdentifierToItem:(NSString*)identifier
{
    if ([mappedIdentifiers containsObject:identifier])
        return;

    LSBitems[[NSNumber numberWithInt:LSBitems_index++]] = [identifier retain];
    [mappedIdentifiers addObject:identifier];
}

+(void) mapIdentifierToItem:(NSString*)identifier item:(int)type
{
    if ([mappedIdentifiers containsObject:identifier])
        return;
    LSBitems[[NSNumber numberWithInt:type]] = [identifier retain];
    [mappedIdentifiers addObject:identifier];
}

+(NSString*) mappedIdentifierForItem:(int)type
{
    return LSBitems[[NSNumber numberWithInt:type]];
}

+(NSString*)imageNameForIdentifier:(NSString*)identifier
{    
    NSDictionary *dict = [Protean getOrLoadSettings];
    NSString *ret = dict[@"images"][identifier];
    if (ret == nil || ret.length == 0) return nil;
    
    if ([UIImage kitImageNamed:[NSString stringWithFormat:@"PR_%@",ret]])
        return [NSString stringWithFormat:@"PR_%@",ret];
    //if ([UIImage kitImageNamed:[NSString stringWithFormat:@"Black_ON_%@",ret]])

    if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/System/Library/Frameworks/UIKit.framework/Black_ON_%@.png",ret]])
        return [NSString stringWithFormat:@"ON_%@",ret];
    if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/System/Library/Frameworks/UIKit.framework/Black_ON_%@@2x.png",ret]])
        return [NSString stringWithFormat:@"ON_%@",ret];
    if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/System/Library/Frameworks/UIKit.framework/Black_ON_%@@3x.png",ret]])
        return [NSString stringWithFormat:@"ON_%@",ret];
        
    return ret;
}

+(NSString*)imageNameForIdentifier:(NSString*)identifier withBadgeCount:(int)count
{
    static NSBundle *imageBundle;
    if (!imageBundle) imageBundle = [[NSBundle bundleWithPath:@"/Library/Protean/Images.bundle"] retain];
    
    NSString *baseName = [Protean imageNameForIdentifier:identifier];
    if (!baseName)
        return nil;
    
    if ([UIImage imageNamed:[NSString stringWithFormat:@"%@_Count_%d",baseName,count] inBundle:imageBundle])
        return [NSString stringWithFormat:@"%@_Count_%d",baseName,count];
    else if ([UIImage imageNamed:[NSString stringWithFormat:@"%@_Count_Large",baseName] inBundle:imageBundle])
        return [NSString stringWithFormat:@"%@_Count_Large",baseName];
    else if ([UIImage kitImageNamed:[NSString stringWithFormat:@"Black_ON_Count%d_%@",count>9?10:count,baseName]])
        return [NSString stringWithFormat:@"ON_Count%d_%@",count>9?10:count,baseName];
        
    return baseName;
}

+(void) launchQR:(NSString*)app
{
    if (app == nil) return;
    
    NSSet *bulletins = [[objc_getClass("BBServer") PR_sharedInstance] _allBulletinsForSectionID:app];
    if (bulletins.count == 0)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Protean" message:[NSString stringWithFormat:@"No bulletins found for app %@",app] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];

        return;
    }
    
    __strong BBBulletin *bulletin = [bulletins anyObject];
        //[storedBulletins[app] objectAtIndex:[storedBulletins[app] count] - 1];
    if (!bulletin)
        return;

    BOOL success = NO;
    
    if ([app isEqual:@"com.apple.MobileSMS"])
    {
        // Auki
        id auki = objc_getClass("KJUARR");
        if (auki)
        {
            [auki doUrThing:bulletin];
            return;
        }
        
        // BiteSMS
        id bitesms = objc_getClass("BSQRController");
        if (bitesms)
        {
            success = [bitesms maybeLaunchQRFromBulletin:bulletin];
            if (success)
                return;
        }
    }
    else if ([app isEqual:@"com.atebits.Tweetie2"] || [app isEqual:@"com.tapbots.Tweetbot3"])
    {
        id twitkafly = objc_getClass("LibTwitkaFly");
        if (twitkafly)
        {
            BOOL success = [[twitkafly sharedTwitkaFly] showQRForBulletin:bulletin];
            if (success)
                return;
        }
    }
    
    BOOL imn = [[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/InteractiveMessageNotifications.dylib"];
    if (imn)
    {
        // https://www.reddit.com/r/jailbreak/comments/2fgne7/update_interactive_message_notifications_now_with/ck94m81
        bulletin.publisherBulletinID = @"iOS8"; // or @"iOS8::QC"
        [(SBBulletinBannerController*)[objc_getClass("SBBulletinBannerController") sharedInstance] _queueBulletin:bulletin];
        return;
    }

    id couria = NSClassFromString(@"Couria");
    if (couria)
    {
        [[couria sharedInstance] handleBulletin:bulletin];
        return;
    }
    
    BOOL hermes = [[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/Hermes.dylib"];
    if (hermes)
    {
        notify_post("com.phillipt.hermes.responding");
        notify_post("com.phillipt.hermes.received");
        return;
    }
    
    BOOL messageHeads = [[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/MessageHeads.dylib"];
    if (messageHeads)
    {
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.ianb821.messageheads.quickCompose"), nil, nil, YES);
        return;
    }

    NSString *messagesText = @"";
    if ([app isEqual:@"com.apple.MobileSMS"])
        messagesText = @". A recommended QuickReply for Messages is BiteSMS.";

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Protean" message:[NSString stringWithFormat:@"No associated Quick-Reply for app %@%@",app,messagesText] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

static BOOL first = YES;
+(void) reloadSettings
{
    if (prefs)
        [prefs release];
    prefs = nil;
    [Protean getOrLoadSettings];
    if (!first)
    {
        [PRStatusApps reloadAllImages];
    }
    else
        first = NO;

}
@end

BOOL isRefreshing = NO;
void refreshStatusBar(CFNotificationCenterRef center,
                      void *observer,
                      CFStringRef name,
                      const void *object,
                      CFDictionaryRef userInfo)
{
    if (isRefreshing)
        return;
    
    isRefreshing = YES;
    
    UIStatusBar *statusBar = (UIStatusBar *)[[UIApplication sharedApplication] statusBar];
    if (!statusBar)
        return;
	UIView *fakeStatusBar;
    
    fakeStatusBar = [statusBar snapshotViewAfterScreenUpdates:NO];
	[statusBar.superview addSubview:fakeStatusBar];
    
    // LOLWUT
    [statusBar setShowsOnlyCenterItems:YES];
    [statusBar setShowsOnlyCenterItems:NO];

    if ([NSBundle.mainBundle.bundleIdentifier isEqual:@"com.apple.springboard"])
    {
        SBStatusBarStateAggregator *stateAggregator = [objc_getClass("SBStatusBarStateAggregator") sharedInstance];
        [stateAggregator _resetTimeItemFormatter];
        [stateAggregator _updateTimeItems];
        
        // Welp.
        [stateAggregator _setItem:11 enabled:NO];
        [stateAggregator updateStatusBarItem:11];
        [stateAggregator _setItem:1 enabled:NO];
        [stateAggregator updateStatusBarItem:1];
        [stateAggregator _setItem:2 enabled:NO];
        [stateAggregator updateStatusBarItem:2];
        [stateAggregator _setItem:12 enabled:NO];
        [stateAggregator updateStatusBarItem:12];
        [stateAggregator _setItem:13 enabled:NO];
        [stateAggregator updateStatusBarItem:13];
        [stateAggregator _setItem:16 enabled:NO];
        [stateAggregator updateStatusBarItem:16];
        [stateAggregator _setItem:17 enabled:NO];
        [stateAggregator updateStatusBarItem:17];
        [stateAggregator _setItem:19 enabled:NO];
        [stateAggregator updateStatusBarItem:19];
        [stateAggregator _setItem:20 enabled:NO];
        [stateAggregator updateStatusBarItem:20];
        [stateAggregator _setItem:21 enabled:NO];
        [stateAggregator updateStatusBarItem:21];
        [stateAggregator _setItem:22 enabled:NO];
        [stateAggregator updateStatusBarItem:22];
    }
    
	CGRect upwards = statusBar.frame;
	upwards.origin.y -= upwards.size.height;
	statusBar.frame = upwards;
    
	CGFloat shrinkAmount = 5.0;
	[UIView animateWithDuration:0.6 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^(void){
		CGRect shrinkFrame = fakeStatusBar.frame;
		shrinkFrame.origin.x += shrinkAmount;
		shrinkFrame.origin.y += shrinkAmount;
		shrinkFrame.size.width -= shrinkAmount;
		shrinkFrame.size.height -= shrinkAmount;
		fakeStatusBar.frame = shrinkFrame;
		fakeStatusBar.alpha = 0.0;
        
		CGRect downwards = statusBar.frame;
		downwards.origin.y += downwards.size.height;
		statusBar.frame = downwards;
	} completion: ^(BOOL finished) {
		[fakeStatusBar removeFromSuperview];
        isRefreshing = NO;
	}];
}

void reloadSettings(CFNotificationCenterRef center,
                    void *observer,
                    CFStringRef name,
                    const void *object,
                    CFDictionaryRef userInfo)
{
    [Protean reloadSettings];
}

void launchQR(CFNotificationCenterRef center,
                    void *observer,
                    CFStringRef name,
                    const void *object,
                    CFDictionaryRef userInfo)
{
    NSString *app = ((__bridge NSDictionary*)userInfo)[@"appId"];
    [Protean launchQR:app];
}

static __attribute__((constructor)) void __protean_init()
{
    if ([[[NSBundle mainBundle] bundleIdentifier] isEqual:@"com.apple.springboard"] == NO)
    {
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, &refreshStatusBar, CFSTR("com.efrederickson.protean/refreshStatusBar"), NULL, 0);
    }
    else
    {
        CFNotificationCenterAddObserver(CFNotificationCenterGetDistributedCenter(), NULL, &launchQR, CFSTR("com.efrederickson.protean/launchQR"), NULL, 0);
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, &refreshStatusBar, CFSTR("com.efrederickson.protean/refreshStatusBar"), NULL, 0);
    }
    
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, &reloadSettings, CFSTR("com.efrederickson.protean/reloadSettings"), NULL, 0);

    // Testing preference loader... 
    // GCD instead of (or in addition to?) CFNotifications for iOS 8+
/*
    int fdes = open(PLIST_NAME.UTF8String, O_RDONLY);
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    void (^eventHandler)(void);
    void (^cancelHandler)(void) = ^{ }; // silence warnings by dummy value as default.
    unsigned long mask = DISPATCH_VNODE_DELETE | DISPATCH_VNODE_WRITE | DISPATCH_VNODE_EXTEND | DISPATCH_VNODE_ATTRIB | DISPATCH_VNODE_LINK | DISPATCH_VNODE_RENAME | DISPATCH_VNODE_REVOKE;
    __block dispatch_source_t source;

    eventHandler = ^{
        unsigned long l = dispatch_source_get_data(source);
        if (l & DISPATCH_VNODE_DELETE) {
            printf("watched file deleted!  cancelling source\n");
            dispatch_source_cancel(source);
        }
        else {
            // handle the file has data case
            printf("watched file has data\n");
            [Protean reloadSettings];
        }
    };
    cancelHandler = ^{
        int fdes = dispatch_source_get_handle(source);
        close(fdes);
        // Wait for new file to exist.
        //while ((fdes = open(PLIST_NAME.UTF8String, O_RDONLY)) == -1)
        //    sleep(1);
        printf("re-opened target file in cancel handler\n");
        source = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE, fdes, mask, queue);
        dispatch_source_set_event_handler(source, eventHandler);
        dispatch_source_set_cancel_handler(source, cancelHandler);
        dispatch_resume(source);
    };

  source = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE,fdes, mask, queue);
  dispatch_source_set_event_handler(source, eventHandler);
  dispatch_source_set_cancel_handler(source, cancelHandler);
  dispatch_resume(source);
  dispatch_main();
*/
    reloadSettings(NULL, NULL, NULL, NULL, NULL);
}