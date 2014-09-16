#import "common.h"
#import "Protean.h"
#import "PRStatusApps.h"
#import <flipswitch/Flipswitch.h>

extern "C" CFNotificationCenterRef CFNotificationCenterGetDistributedCenter(void);

#define PLIST_NAME @"/var/mobile/Library/Preferences/com.efrederickson.protean.settings.plist"

NSObject *lockObject = [[NSObject alloc] init];

void updateItem(int key, NSString *identifier)
{
    if ([[[NSBundle mainBundle] bundleIdentifier] isEqual:@"com.apple.springboard"]) return;

    NSString *nKey = [NSString stringWithFormat:@"%d",key];

    NSMutableDictionary *prefs = [NSMutableDictionary
        dictionaryWithContentsOfFile:PLIST_NAME];
    if (prefs == nil)
        prefs = [NSMutableDictionary dictionary];

    NSMutableDictionary *properties = [prefs objectForKey:nKey];
    if (!properties)
        properties = [NSMutableDictionary dictionary];
    
    if ([[properties objectForKey:@"identifier"] isEqual:identifier] == NO)
        properties = [NSMutableDictionary dictionary];

    [properties setObject:identifier forKey:@"identifier"];
    [properties setObject:nKey forKey:@"key"];

    [prefs setObject:properties forKey:nKey];

    @synchronized (lockObject) {
        [prefs writeToFile:PLIST_NAME atomically:YES];
        [Protean reloadSettings];
    }
}

void updateItem2(int key, NSString *identifier)
{
    //NSLog(@"[Protean] %@", identifier);
    if (identifier == nil || key < 33)
        return;

    NSString *nKey = [NSString stringWithFormat:@"%d",key];

    NSMutableDictionary *prefs = [NSMutableDictionary
        dictionaryWithContentsOfFile:PLIST_NAME];
    if (prefs == nil)
        prefs = [NSMutableDictionary dictionary];
    
    int maxKey = 33;

    for (id key2 in prefs)
    {
        if ([prefs[key2] isKindOfClass:[NSDictionary class]] == NO)
            continue;

        if (prefs[key2][@"identifier"] == nil)
            continue;

        if ([prefs[key2][@"identifier"] isEqual:identifier] && key != [key2 intValue])
        {
            NSMutableDictionary *tmp = [prefs[key2] mutableCopy]; // same identifier
            tmp[@"key"] = nKey;
            
            NSMutableDictionary *tmp2 = [prefs[nKey] mutableCopy]; // different identifier?
            if (tmp2 == nil || [tmp2[@"identifier"] isEqual:identifier])
            {
                [prefs removeObjectForKey:key2];
            }
            else
            {
                tmp2[@"key"] = [key2 copy];
                prefs[key2] = tmp2;
            }

            [prefs setObject:tmp forKey:nKey];

            @synchronized (lockObject) {
                [prefs writeToFile:PLIST_NAME atomically:YES];
                [Protean reloadSettings];
            }
            return;
        }
        else if ([prefs[key2][@"identifier"] isEqual:identifier] && key == [key2 intValue])
            return;
            
        if (maxKey < [key2 intValue])
            maxKey = [key2 intValue];
    }

    NSMutableDictionary *properties = [prefs objectForKey:nKey];
    if (!properties)
        properties = [NSMutableDictionary dictionary];

    if ([properties[@"identifier"] isEqual:identifier] == NO)
    {
        id _key = [NSNumber numberWithInt:maxKey + 1];
        properties[@"key"] = _key;
        prefs[[NSString stringWithFormat:@"%d",maxKey+1]] = [properties mutableCopy];

        properties = [NSMutableDictionary dictionary];
    }

    properties[@"identifier"] = identifier;
    properties[@"key"] = nKey;
    prefs[nKey] = properties;

    @synchronized (lockObject) {
        [prefs writeToFile:PLIST_NAME atomically:YES];
        [Protean reloadSettings];
    }
}

NSString *nameFromItem(UIStatusBarItem *item)
{
	NSRange range = [[item description] rangeOfString:@"[" options:NSLiteralSearch];
    if (range.location == NSNotFound)
        return item.description;
	NSRange iconNameRange;
	iconNameRange.location = range.location + 1;
    iconNameRange.length =  ((NSString *)[item description]).length - range.location - 2;
	NSString *part1 = [[item description] substringWithRange:iconNameRange];

    NSRange range2 = [part1 rangeOfString:@"(" options:NSLiteralSearch];
    if (range2.location == NSNotFound || range2.location == 0)
        return part1;
    else
    {
        NSRange parenRange;
        parenRange.location = 0;
        parenRange.length = range2.location - 1;
        return [part1 substringWithRange:parenRange];
    }
}

NSMutableArray *itemTypes = [NSMutableArray array];
NSDictionary *settingsForItem(UIStatusBarItem *item)
{
    int key = MSHookIvar<int>(item, "_type");

    if (key < 33) // System item
    {
        NSString *nKey = [NSString stringWithFormat:@"%d", key];

        NSDictionary *prefs = [Protean getOrLoadSettings];

        NSMutableDictionary *properties = [prefs objectForKey:nKey];
        if (!properties)
            properties = [NSMutableDictionary dictionary];

        return properties;
    }
    else // Custom Item
    {
        NSString *identifier = [Protean mappedIdentifierForItem:MSHookIvar<int>(item, "_type")];

        NSDictionary *prefs = [Protean getOrLoadSettings];
            
        for (id key in prefs)
        {
            if (prefs[key] && [prefs[key] isKindOfClass:[NSDictionary class]] && [prefs[key][@"identifier"] isEqual:identifier])
            {
                return prefs[key];
            }
        }

        return [NSMutableDictionary dictionary];
    }
}

%hook UIStatusBarItem
+ (UIStatusBarItem*)itemWithType:(int)arg1 idiom:(long long)arg2
{
    UIStatusBarItem* item = %orig;
 
    CHECK_ENABLED(item)

    if ([itemTypes containsObject:[NSNumber numberWithInt:arg1]] == NO)
    {
        NSString *name = @"";

        if ([item isKindOfClass:[%c(UIStatusBarCustomItem) class]])
        {
            //name = [%c(Protean) mappedIdentifierForItem:(arg1 - 33)]; // 32 is number of default items (LSB starts from there)
            name = nil;
        }
        else
            name = nameFromItem(item);

        [itemTypes addObject:[NSNumber numberWithInt:arg1]];
        if (name != nil)
            updateItem(arg1, name);
    }

    return item;
}

- (_Bool)appearsInRegion:(int)arg1
{
    CHECK_ENABLED(%orig);

    id _alignment = settingsForItem(self)[@"alignment"];
    int alignment = _alignment == nil ? 4 : [_alignment intValue];

    if (alignment == arg1) // 0, 1, 2 :: left, right, ?center
        return YES;
    else if (alignment == 3) // hide
        return NO;
    else if (alignment == 4) // default
        return %orig;
    else
        return NO;
}

-(int) centerOrder
{
    CHECK_ENABLED(%orig);

    id _alignment = settingsForItem(self)[@"alignment"];
    int alignment = _alignment == nil ? 4 : [_alignment intValue];

    id _centerOrder = settingsForItem(self)[@"order"];
    
    if (alignment != 2)
        return %orig;

    int centerOrder = _centerOrder == nil ? %orig : [_centerOrder intValue];
    return centerOrder;
}

-(int) rightOrder
{
    CHECK_ENABLED(%orig);

    id _alignment = settingsForItem(self)[@"alignment"];
    int alignment = _alignment == nil ? 4 : [_alignment intValue];

    id _rightOrder = settingsForItem(self)[@"order"];
    
    if (alignment != 1)
        return %orig;

    int rightOrder = _rightOrder == nil ? %orig : [_rightOrder intValue];

    return rightOrder;
}
-(int) leftOrder
{
    CHECK_ENABLED(%orig);

    id _alignment = settingsForItem(self)[@"alignment"];
    int alignment = _alignment == nil ? 4 : [_alignment intValue];

    if (alignment != 0)
        return %orig;

    id _leftOrder = settingsForItem(self)[@"order"];
    int leftOrder = _leftOrder == nil ? %orig : [_leftOrder intValue];

    return leftOrder;
}

-(BOOL) appearsOnRight
{
    CHECK_ENABLED(%orig);

    id _alignment = settingsForItem(self)[@"alignment"];
    int alignment = _alignment == nil ? 4 : [_alignment intValue];
    if (alignment == 0 || alignment == 2 || alignment == 3) // left, center, hidden
        return NO;
    else if (alignment == 1)
        return YES;
    return %orig;
}

-(BOOL) appearsOnLeft
{
    CHECK_ENABLED(%orig);

    id _alignment = settingsForItem(self)[@"alignment"];
    int alignment = _alignment == nil ? 4 : [_alignment intValue];
    if (alignment == 1 || alignment == 2 || alignment == 3) // left, center, hidden
        return NO;
    else if (alignment == 0)
        return YES;
    return %orig;
}

- (int)priority
{
    CHECK_ENABLED(%orig);

    return 2;
}
%end

NSMutableDictionary *cachedAlignments = [NSMutableDictionary dictionary];
%hook LSStatusBarItem
- (id) initWithIdentifier:(NSString*) identifier alignment:(StatusBarAlignment) orig_alignment
{
    CHECK_ENABLED(%orig);
    StatusBarAlignment new_alignment = orig_alignment;

    if (cachedAlignments[identifier])
    {
        new_alignment = (StatusBarAlignment)[cachedAlignments[identifier] intValue];
    }
    else
    {
        NSDictionary *prefs = [Protean getOrLoadSettings];
        for (id key in prefs)
        {
            if (prefs[key] && [prefs[key] isKindOfClass:[NSDictionary class]] && [prefs[key][@"identifier"] isEqual:identifier])
            {
                id _alignment = prefs[key][@"alignment"];
                int alignment = _alignment == nil ? 4 : [_alignment intValue];
                if (alignment == 0)
                    new_alignment = StatusBarAlignmentLeft;
                else if (alignment == 1)
                    new_alignment = StatusBarAlignmentRight;

                break;
            }
        }
        cachedAlignments[identifier] = [NSNumber numberWithInt:(int)new_alignment];
    }

    // 0 = left, 1 = right
    //else if (alignment == 2) // wait can't have image LSB items in the center (WHY?!?!?!)
    //    new_alignment = orig_alignment;
    // 3 = hidden, 4 = default
    
    if ([[[NSBundle mainBundle] bundleIdentifier] isEqual:@"com.apple.springboard"])
    {
        [Protean mapIdentifierToItem:identifier];
    }

    return %orig(identifier, new_alignment);
}

-(BOOL) isVisible
{
    CHECK_ENABLED(%orig);

    int alignment;
    NSDictionary *prefs = [Protean getOrLoadSettings];

    for (id key in prefs)
    {
        if (prefs[key] && [prefs[key] isKindOfClass:[NSDictionary class]] && [prefs[key][@"identifier"] isEqual:MSHookIvar<NSString*>(self, "_identifier")])
        {
            id _alignment = prefs[key][@"alignment"];
            alignment = _alignment == nil ? 4 : [_alignment intValue];
            break;
        }
    }

    if (alignment == 3)
        return NO;
    return %orig;
}
%end

%hook UIStatusBarCustomItemView
-(id)initWithItem:(UIStatusBarCustomItem*)arg1 data:(id)arg2 actions:(int)arg3 style:(id)arg4
{
    id _self = %orig;
    
    CHECK_ENABLED(_self);

    updateItem2(MSHookIvar<int>(arg1, "_type"), [Protean mappedIdentifierForItem:MSHookIvar<int>(arg1, "_type")]);
    
    return _self;
}
%end

@interface UIStatusBarLayoutManager (Protean)
- (CGRect)_frameForItemView:(id)arg1 startPosition:(float)arg2 firstView:(BOOL)arg3;
@end

NSMutableDictionary *storedStarts = [NSMutableDictionary dictionary];

BOOL o = NO;

%hook UIStatusBarItemView
-(void)setUserInteractionEnabled:(BOOL)enabled
{ 
    CHECK_ENABLED2(%orig);

    if ([Protean canHandleTapForItem:self.item])
        %orig(YES); 
    else
        %orig;
}

- (id)initWithItem:(id)arg1 data:(id)arg2 actions:(int)arg3 style:(id)arg4
{
    id _self = %orig;

    if ([Protean canHandleTapForItem:self.item])
    {
        CHECK_ENABLED(_self);
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(prTap:)];
        [self addGestureRecognizer:tap];
    }

    return _self;
}

%new
- (void)prTap:(UITapGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateEnded)
    {
        [Protean HandlerForTapOnItem:self.item];
    }
}

-(CGRect) frame
{
    CGRect ret = %orig;

    CHECK_ENABLED(ret);

    if (!self.item)
        return ret;


    if (ret.origin.x == 0 && ret.origin.y == 0)
    {
        id overlap_ = [Protean getOrLoadSettings][@"allowOverlap"];
        if (!overlap_ || [overlap_ boolValue])
        {
            ret = (CGRect) { { [storedStarts[[NSNumber numberWithInt:MSHookIvar<int>(self.item, "_type")]] floatValue], 0}, ret.size };
        }
    }

    int type = MSHookIvar<int>(self.item, "_type");
    if (type < 33)
        return ret;

    static NSArray *switchIdentifiers;
    if (!switchIdentifiers) switchIdentifiers = [[[FSSwitchPanel sharedPanel].switchIdentifiers copy] retain];

    NSString *name = [Protean mappedIdentifierForItem:type];
    if (name)
        if ([name hasPrefix:@"com.efrederickson.protean-"])
            if ([switchIdentifiers containsObject:[name substringFromIndex:26]])
                ret.size.width = 13;

    return ret;
}

- (void)setVisible:(BOOL)arg1 
{
    BOOL force = o;
    
    id overlap_ = [Protean getOrLoadSettings][@"allowOverlap"];
    if ((!overlap_ || [overlap_ boolValue]) == NO)
    {
        %orig;
        return;
    }

    int type = MSHookIvar<int>(self.item, "_type");
    if (type >= 33)
    {
        NSString *name = [Protean mappedIdentifierForItem:type];
        NSDictionary *d = [[%c(LSStatusBarClient) sharedInstance] currentMessage][name];
        if (d)
        {
            id visible = d[@"visible"];
            if (!visible || [visible boolValue])
                force = YES;
        }
    }

    %orig(force ? YES : arg1);
}

%end

%hook UIStatusBarLayoutManager
- (CGRect)_frameForItemView:(UIStatusBarItemView*)arg1 startPosition:(float)arg2 firstView:(BOOL)arg3
{
    CGRect r = %orig;
    CHECK_ENABLED(r);
    
    if (arg1.item)
    {
        if (storedStarts[[NSNumber numberWithInt:MSHookIvar<int>(arg1.item, "_type")]])
        {
            if (o)
            {
                if ([[[NSBundle mainBundle] bundleIdentifier] isEqual:@"com.apple.springboard"])
                {
                    // hmmm
                    // layout gets screwey here, in SpringBoard...
                    
                    if ([arg1.item appearsOnRight])
                    {
                    
                    }
                    else
                    {
                        if ([storedStarts[[NSNumber numberWithInt:MSHookIvar<int>(arg1.item, "_type")]] floatValue] < r.origin.x / 2);
                        else
                            return r;
                    }
                }

                storedStarts[[NSNumber numberWithInt:MSHookIvar<int>(arg1.item, "_type")]] = [NSNumber numberWithFloat:r.origin.x];
            }
        }
        else
        {
            storedStarts[[NSNumber numberWithInt:MSHookIvar<int>(arg1.item, "_type")]] = [NSNumber numberWithFloat:r.origin.x];
        }
    }
    return r;
}

- (BOOL)prepareEnabledItems:(BOOL*)arg1 withData:(id)arg2 actions:(int)arg3
{
    CHECK_ENABLED(%orig);

    o = YES;
    BOOL r = %orig;
    o = NO;
    return r;
}
%end
%hook UIStatusBarForegroundView
- (id)_computeVisibleItemsPreservingHistory:(_Bool)arg1
{
    CHECK_ENABLED(%orig);

    o = YES;
    id r = %orig;
    o = NO;
    return r;
}
%end

%hook SBApplication
- (void)setBadge:(id)arg1
{
    %orig;
    CHECK_ENABLED();
    
    int badgeCount = [self.badgeNumberOrString intValue];

    if (badgeCount > 0)
    {
        [PRStatusApps showIconFor:self.bundleIdentifier badgeCount:badgeCount];
        [PRStatusApps updateCachedBadgeCount:self.bundleIdentifier count:badgeCount];
    }
    else
    {    
        id nc_ = [Protean getOrLoadSettings][@"useNC"];
        if (!nc_ || [nc_ boolValue])
        {
            if ([PRStatusApps ncCount:self.bundleIdentifier] > 0)
                ; // ignore
            else
                [PRStatusApps hideIconFor:self.bundleIdentifier];
        }
        else
            [PRStatusApps hideIconFor:self.bundleIdentifier];
        [PRStatusApps updateCachedBadgeCount:self.bundleIdentifier count:0];
    }
    [PRStatusApps updateTotalNotificationCountIcon];
}
%end

%hook BBServer
- (void)publishBulletin:(BBBulletin*)arg1 destinations:(unsigned long long)arg2 alwaysToLockScreen:(_Bool)arg3
{
    %orig;
    
    NSString *section = arg1.sectionID;
    [Protean addBulletin:arg1 forApp:section]; // Add bulletin for QR
    NSArray *bulletins = [self noticesBulletinIDsForSectionID:section];
    [PRStatusApps updateNCStatsForIcon:section count:bulletins.count]; // Update stats for Notification center icons
}


- (void)_sendRemoveBulletins:(NSSet*)arg1 toFeeds:(unsigned long long)arg2 shouldSync:(_Bool)arg3
{
    %orig;
    
    BBBulletin *bulletin = [arg1 anyObject];
    if (!bulletin)
        return;

    NSString *section = bulletin.sectionID;
    [PRStatusApps updateNCStatsForIcon:section count:[PRStatusApps ncCount:section] - arg1.count];
}
%end

%hook SpringBoard
-(void)applicationDidFinishLaunching:(id)application
{
    %orig;

    CHECK_ENABLED();
    [PRStatusApps reloadAllImages];
}
%end

void launchApp(CFNotificationCenterRef center,
                    void *observer,
                    CFStringRef name,
                    const void *object,
                    CFDictionaryRef userInfo)
{
    [(SpringBoard*)[UIApplication sharedApplication] launchApplicationWithIdentifier:((__bridge NSDictionary*)userInfo)[@"appId"] suspended:NO];
}

%hook SBLockScreenViewController
-(void) _handleDisplayTurnedOn
{
    %orig;

    [PRStatusApps updateLockState:YES];
}

-(void)_handleDisplayTurnedOff
{
    %orig;

    [PRStatusApps updateLockState:NO];
}
%end

%ctor
{
    dlopen("/Library/MobileSubstrate/DynamicLibraries/libstatusbar.dylib", RTLD_NOW | RTLD_GLOBAL);
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/bars.dylib"])
        dlopen("/Library/MobileSubstrate/DynamicLibraries/bars.dylib", RTLD_NOW | RTLD_GLOBAL);

    if ([[[NSBundle mainBundle] bundleIdentifier] isEqual:@"com.apple.springboard"])
    {
        CFNotificationCenterAddObserver(CFNotificationCenterGetDistributedCenter(), NULL, &launchApp, CFSTR("com.efrederickson.protean/launchApp"), NULL, 0);
    }
}
