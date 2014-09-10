#import "PRStatusApps.h"
#import <libstatusbar/LSStatusBarItem.h>
#import <objc/runtime.h>
#import "Protean.h"
#import <flipswitch/Flipswitch.h>

@interface PRFSTimer
+(void) updateTimer;
@end

NSMutableDictionary *icons = [[NSMutableDictionary dictionary] retain]; // probably should use alloc] init] retain] instead
NSMutableDictionary *cachedBadgeCounts = [[NSMutableDictionary dictionary] retain];
NSMutableDictionary *ncData = [[NSMutableDictionary dictionary] retain];
NSMutableArray *showWhenOff = [[NSMutableArray array] retain];
BOOL isScreenOff = NO;
int totalBadgeCount = 0;

StatusBarAlignment getDefaultAlignment()
{
    id right_ = [Protean getOrLoadSettings][@"defaultAlignToRight"];
    if (!right_ || [right_ boolValue] == NO)
        return StatusBarAlignmentLeft;
    else
        return StatusBarAlignmentRight;
}

@implementation PRStatusApps
+(LSStatusBarItem*)getOrCreateItemForIdentifier:(NSString*)identifier
{
    if (icons[identifier])
        return icons[identifier];
    
    LSStatusBarItem *item = [[objc_getClass("LSStatusBarItem") alloc] initWithIdentifier:[NSString stringWithFormat:@"%@%@", @"com.efrederickson.protean-",identifier] alignment:getDefaultAlignment()];
    item = [item retain];

    if (!item)
        return nil;
    
    icons[identifier] = item;
    return icons[identifier];
}

+(void) showIconFor:(NSString*)identifier badgeCount:(int)count
{
    CHECK_ENABLED();
    if (identifier == nil)
        return;
    
    NSString *imageName = [Protean imageNameForIdentifier:identifier withBadgeCount:count];
    if (imageName == nil || [imageName isEqual:@""])
        return;
    
    LSStatusBarItem *item = [PRStatusApps getOrCreateItemForIdentifier:identifier];
    if (!item)
        return;
    if (isScreenOff)
    {
    	item.visible = NO;
    	[showWhenOff addObject:item];
    }
    else
    	item.visible = YES;
    item.imageName = imageName;
}

+(void) updateCachedBadgeCount:(NSString*)identifier count:(int) count
{
    cachedBadgeCounts[identifier] = [NSNumber numberWithInt:count];
    [PRStatusApps updateTotalNotificationCountIcon];
}

+(void) hideIconFor:(NSString*)identifier
{
    if (icons[identifier] == nil || identifier == nil)
        return;
    
    LSStatusBarItem *item = [PRStatusApps getOrCreateItemForIdentifier:identifier];
    if (!item)
        return;
    item.visible = NO;
    item.imageName = @"";
    [item release];
    //[item dealloc];
    item = nil;
    [icons removeObjectForKey:identifier];
}

+(void) showIconForFlipswitch:(NSString*)identifier
{
    CHECK_ENABLED();
    if (identifier == nil)
        return;
    
    LSStatusBarItem *item = [PRStatusApps getOrCreateItemForIdentifier:identifier];
    if (!item)
        return;
    if (isScreenOff)
    {
    	item.visible = NO;
    	[showWhenOff addObject:item];
    }
    else
    	item.visible = YES;
    NSString *imageName = [Protean imageNameForIdentifier:identifier];
    
    item.imageName = [imageName isEqual:@""] ? identifier : imageName;
}

+(void) showIconForBluetooth:(NSString*)identifier
{
    CHECK_ENABLED();
    if (identifier == nil)
        return;
    
    if ([Protean imageNameForIdentifier:identifier] == nil || [[Protean imageNameForIdentifier:identifier] isEqual:@""])
        return;
    
    LSStatusBarItem *item = [PRStatusApps getOrCreateItemForIdentifier:identifier];
    if (!item)
        return;
    if (isScreenOff)
    {
    	item.visible = NO;
    	[showWhenOff addObject:item];
    }
    else
    	item.visible = YES;
    item.imageName = [Protean imageNameForIdentifier:identifier];
}

+(void) reloadAllImages
{
    if ([[[NSBundle mainBundle] bundleIdentifier] isEqual:@"com.apple.springboard"] == NO)
        return;
    
    id _enabled = [Protean getOrLoadSettings][@"enabled"];
    if ((_enabled ? [_enabled boolValue] : YES) == NO)
    {
        for (id key in icons.allKeys)
            [PRStatusApps hideIconFor:key];
        return;
    }
    
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

    for (NSString *key in [ncData copy])
    {
        [PRStatusApps updateNCStatsForIcon:key count:[ncData[key] intValue]];
    }

    [PRStatusApps updateTotalNotificationCountIcon];
    
    // Flipswitches
    for (id key in [Protean getOrLoadSettings][@"flipswitches"])
    {
        [[FSSwitchPanel sharedPanel] stateForSwitchIdentifier:key];
    }
    [objc_getClass("PRFSTimer") updateTimer];
    
    // Bluetooth
    id bt = objc_getClass("BluetoothManager");
    [[bt sharedInstance] _connectedStatusChanged];
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

+(void) updateNCStatsForIcon:(NSString*)section count:(int)count
{
    if (count < 0) count = 0;
    
    //NSLog(@"[Protean] updating nc stats for icon %@", section);
    ncData[section] = [NSNumber numberWithInt:count];

    id nc_ = [Protean getOrLoadSettings][@"useNC"];
    if (nc_ && [nc_ boolValue] == NO)
        return;

    if (count > 0)
    {
        NSLog(@"[Protean] showing NC icon for %@", section);
        [PRStatusApps showIconFor:section badgeCount:count];
    }
    else
    {
        NSLog(@"[Protean] not showing NC icon for %@", section);
        if ([cachedBadgeCounts[section] intValue] < 1)
            [PRStatusApps hideIconFor:section];
    }
}

+(int) ncCount:(NSString*)identifier
{
    return [ncData.allKeys containsObject:identifier] ? [ncData[identifier] intValue] : 0;
}


+(void) updateLockState:(BOOL)locked
{
	isScreenOff = !locked;

	if (isScreenOff)
	{

	}
	else // screen is on
	{
		for (LSStatusBarItem *item in showWhenOff)
			item.visible = YES;
		[showWhenOff removeAllObjects];
	}
}

@end

