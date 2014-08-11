#import "PRStatusApps.h"
#import <libstatusbar/LSStatusBarItem.h>
#import <objc/runtime.h>
#import "Protean.h"
#import <flipswitch/Flipswitch.h>
@interface BluetoothManager
+ (id)sharedInstance;
- (void)_connectedStatusChanged;
@end
@interface PRFSTimer
+(void) updateTimer;
@end


NSMutableDictionary *icons = [[NSMutableDictionary dictionary] retain];
NSMutableDictionary *cachedBadgeCounts = [[NSMutableDictionary dictionary] retain];

int totalBadgeCount = 0;

@implementation PRStatusApps
+(LSStatusBarItem*)getOrCreateItemForIdentifier:(NSString*)identifier
{
    if (icons[identifier])
        return icons[identifier];
    
    LSStatusBarItem *item = [[objc_getClass("LSStatusBarItem") alloc] initWithIdentifier:[NSString stringWithFormat:@"%@%@", @"com.efrederickson.protean-",identifier] alignment:StatusBarAlignmentLeft];
    
    icons[identifier] = item;
    return icons[identifier];
}

+(void) showIconFor:(NSString*)identifier badgeCount:(int)count
{
    CHECK_ENABLED();
    if (identifier == nil)
        return;
    
    if ([Protean imageNameForIdentifier:identifier withBadgeCount:count] == nil || [[Protean imageNameForIdentifier:identifier withBadgeCount:count] isEqual:@""])
        return;
    
    LSStatusBarItem *item = [PRStatusApps getOrCreateItemForIdentifier:identifier];
    item.visible = YES;
    item.imageName = [Protean imageNameForIdentifier:identifier withBadgeCount:count];
    cachedBadgeCounts[identifier] = [NSNumber numberWithInt:count];
}

+(void) hideIconFor:(NSString*)identifier
{
    if (icons[identifier] == nil || identifier == nil)
        return;
    
    LSStatusBarItem *item = [PRStatusApps getOrCreateItemForIdentifier:identifier];
    item.visible = NO;
    item.imageName = @"";
    [item release];
    //[item dealloc];
    item = nil;
    [icons removeObjectForKey:identifier];
    cachedBadgeCounts[identifier] = @0; // badge was cleared
}

+(void) showIconForFlipswitch:(NSString*)identifier
{
    CHECK_ENABLED();
    if (identifier == nil)
        return;
    
    LSStatusBarItem *item = [PRStatusApps getOrCreateItemForIdentifier:identifier];
    item.visible = YES;
    item.imageName = identifier;
}

+(void) showIconForBluetooth:(NSString*)identifier
{
    CHECK_ENABLED();
    if (identifier == nil)
        return;
    
    if ([Protean imageNameForIdentifier:identifier] == nil || [[Protean imageNameForIdentifier:identifier] isEqual:@""])
        return;
    
    LSStatusBarItem *item = [PRStatusApps getOrCreateItemForIdentifier:identifier];
    item.visible = YES;
    item.imageName = [Protean imageNameForIdentifier:identifier];
}

+(void) reloadAllImages
{
    CHECK_ENABLED();
    if ([[[NSBundle mainBundle] bundleIdentifier] isEqual:@"com.apple.springboard"] == NO)
        return;
    
    // Status Apps
    totalBadgeCount = 0;
    for (NSString *identifier in [[[objc_getClass("SBIconViewMap") homescreenMap] iconModel] visibleIconIdentifiers]) {
        SBIcon *icon = (SBIcon *)[[[objc_getClass("SBIconViewMap") homescreenMap] iconModel] applicationIconForDisplayIdentifier:identifier];
        if (icon && [icon badgeNumberOrString]) {
            if (icon.badgeValue > 0)
            {
                [PRStatusApps showIconFor:identifier badgeCount:icon.badgeValue];
                totalBadgeCount += icon.badgeValue;
            }
        }
    }
    
    for (NSString* key in icons.allKeys)
    {
        LSStatusBarItem *item = ((LSStatusBarItem*)icons[key]);
        if ([cachedBadgeCounts.allKeys containsObject:key])
            item.imageName = [Protean imageNameForIdentifier:key withBadgeCount:[cachedBadgeCounts[key] intValue]] ?: key;
        else
            item.imageName = [Protean imageNameForIdentifier:key] ?: key;
        
        if (cachedBadgeCounts[key] && [cachedBadgeCounts[key] intValue] > 0)
            item.visible = YES;
        
        if (item.imageName == nil || [item.imageName isEqual:@""])
        {
            [item release];
            item = nil;
            [icons removeObjectForKey:key];
        }
    }
    [PRStatusApps updateTotalNotificationCountIcon];
    
    // Flipswitches
    for (id key in [Protean getOrLoadSettings][@"flipswitches"])
    {
        [[FSSwitchPanel sharedPanel] stateForSwitchIdentifier:key];
    }
    [objc_getClass("PRFSTimer") updateTimer];
    
    // Bluetooth
    [[objc_getClass("BluetoothManager") sharedInstance] _connectedStatusChanged];
}

+(void) updateTotalNotificationCountIcon
{
    if (totalBadgeCount > 0)
    {
        [PRStatusApps showIconFor:@"TOTAL_NOTIFICATION_COUNT" badgeCount:totalBadgeCount];
    }
    else
    {
        [PRStatusApps hideIconFor:@"TOTAL_NOTIFICATION_COUNT"];
    }
}

@end

