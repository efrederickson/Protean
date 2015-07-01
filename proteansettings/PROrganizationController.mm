#import "PROrganizationController.h"
#import <AppList/AppList.h>
#import <objcipc/objcipc.h>
#import <flipswitch/Flipswitch.h>

#define PLIST_NAME @"/var/mobile/Library/Preferences/com.efrederickson.protean.settings.plist"
#define TemplatePath @"/Library/Protean/FlipswitchTemplates/IconTemplate.bundle"
#define BUNDLE_PATH @"/Library/Protean/OrganizeIcons.bundle"

#import "../common.h"

BOOL showedAlert = NO;

@interface PSViewController ()
-(void) setView:(id)view;
-(void) setTitle:(NSString*)title;
@end
@interface UIStatusBar (Protean)
- (void)_setStyle:(id)arg1;
- (int)legibilityStyle;
- (id)initWithFrame:(CGRect)arg1 showForegroundView:(BOOL)arg2 inProcessStateProvider:(id)arg3;
- (id)initWithFrame:(CGRect)arg1 showForegroundView:(BOOL)arg2;
- (id)initWithFrame:(CGRect)arg1;

- (void)_crossfadeToNewBackgroundView;
- (void)_crossfadeToNewForegroundViewWithAlpha:(float)arg1;
- (void)crossfadeTime:(BOOL)arg1 duration:(double)arg2;
- (void)setShowsOnlyCenterItems:(BOOL)arg1;

- (UIView *)snapshotViewAfterScreenUpdates:(BOOL)afterUpdates;
-(id) superview;
-(CGRect)frame;
-(void) setFrame:(CGRect)frame;
@end

NSMutableDictionary *nameCache = [NSMutableDictionary dictionary];
NSString *nameForDescription(NSString *desc)
{
    if (desc == nil)
        desc = @"";

    if (nameCache[desc]) return nameCache[desc];

    static __strong NSDictionary *map;
    if (!map) {
        map = @{
                @"MSNowPlayingItem": @"Now Playing",
                @"SignalStrength": @"Signal Strength",
                @"RotationLock": @"Rotation Lock",
                @"BatteryPercent": @"Battery Percent",
                @"BluetoothBattery": @"Bluetooth Battery",
                @"NotCharging": @"Not Charging (iPad)",
                @"Activity": @"Loading/Sync Indicator",
                @"com.rabih96.macvolume": @"Volume Status",
                @"TOTAL_NOTIFICATION_COUNT": @"Total Notification Count",
                @"CallForward": @"Call Forwarding",
                @"Service": @"Carrier",
                @"jzplusplus.OkSiri": @"OkSiri",
                @"phantom.coke": @"Phantom",
                @"com.lablabla.muteicon": @"MuteIcon",
                @"ws.hbang.typestatus.icon": @"TypeStatus (Typing)",
                @"ws.hbang.typestatus.readicon": @"TypeStatus (Read)",
                @"com.sassoty.bulb": @"Bulb",
                @"statusmodifier.mute": @"Mute (StatusModifier)",
                @"com.malcolmhall.insomnia": @"Insomnia",
                @"com.malcolmhall.insomniapro": @"Insomnia Pro",
                @"TetherStatus.icon": @"TetherStatus"
                };
    }
    
    if ([desc hasPrefix:@"com.efrederickson.protean-"])
    {
        NSString *identifier = [desc substringFromIndex:26];
        
        if ([identifier isEqual:@"TOTAL_NOTIFICATION_COUNT"])
            return @"Total Notification Count";

        if ([identifier hasPrefix:@"spacer-"])
        {
            return [NSString stringWithFormat:@"Spacer %@",[identifier substringFromIndex:7]];
        }
        
        if ([[FSSwitchPanel sharedPanel].switchIdentifiers containsObject:identifier])
        {
            nameCache[desc] = [NSString stringWithFormat:@"%@ (Flipswitch)",[[FSSwitchPanel sharedPanel] titleForSwitchIdentifier:identifier]];
            return nameCache[desc];
        }
        
        ALApplicationList *al = [ALApplicationList sharedApplicationList];
        nameCache[desc] = [al.applications objectForKey:identifier] ?: identifier;
        return nameCache[desc];
    }

    if ([desc hasPrefix:@"spacer-"])
    {
        NSString *num = [desc substringFromIndex:7];
        return [NSString stringWithFormat:@"Spacer %d",[num intValue] + 1];
    }
    
    if ([desc hasPrefix:@"opennotifier."])
    {
        return [desc substringFromIndex:13];
    }
    
    if ([desc isEqual:@"DataNetwork"])
        return @"Data/Wifi";
    
    if ([desc hasPrefix:@"AirplaneMode"])
        return @"Airplane Mode";
    
    if ([desc hasSuffix:@"~1"])
        return [desc substringToIndex:desc.length - 2];
    
    if ([desc hasPrefix:@"QuietMode"])
        return @"Do Not Disturb";
    
    if ([desc hasPrefix:@"Indicator:"])
        desc = [desc substringFromIndex:10];
    
    nameCache[desc] = map[desc] ?: desc;
    return nameCache[desc];
}

UIImage *resizeFSImage(UIImage *icon, CGFloat max = 30.0f)
{
	CGFloat maxWidth = max;
	CGFloat maxHeight = max;
    
	CGSize size = CGSizeMake(maxWidth, maxHeight);
	CGFloat scale = 1.0f;
    
	// the scale logic below was taken from
	// http://developer.appcelerator.com/question/133826/detecting-new-ipad-3-dpi-and-retina
	if ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)])
	{
		if ([UIScreen mainScreen].scale > 1.0f) scale = [[UIScreen mainScreen] scale];
		UIGraphicsBeginImageContextWithOptions(size, false, scale);
	}
	else UIGraphicsBeginImageContext(size);
    
	// Resize image to status bar size and center it
	// make sure the icon fits within the bounds
	CGFloat width = MIN(icon.size.width, maxWidth);
	CGFloat height = MIN(icon.size.height, maxHeight);
    
	CGFloat left = MAX((maxWidth-width)/2, 0);
	left = left > (maxWidth/2) ? maxWidth-(maxWidth/2) : left;
    
	CGFloat top = MAX((maxHeight-height)/2, 0);
	top = top > (maxHeight/2) ? maxHeight-(maxHeight/2) : top;
    
	[icon drawInRect:CGRectMake(left, top, width, height)];
	icon = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
    
	return icon;
}

NSMutableDictionary *cachedImages = [NSMutableDictionary dictionary];
UIImage *iconForDescription(NSString *desc)
{
	static __strong NSDictionary *map;
    if (!map) {
        map = @{
                @"MSNowPlayingItem": @"now playing",
                @"SignalStrength": @"signal",
                @"RotationLock": @"rotation lock",
                @"BatteryPercent": @"battery percent",
                @"BluetoothBattery": @"bluetooth battery",
                @"NotCharging": @"not charging",
                @"Activity": @"load",
                @"com.rabih96.macvolume": @"volume status",
                @"TOTAL_NOTIFICATION_COUNT": @"total notification count",
                @"CallForward": @"call forwarding",
                @"Service": @"carrier",
                @"jzplusplus.OkSiri": @"siri",
                @"phantom.coke": @"phantom",
                @"com.lablabla.muteicon": @"mute icon",
                @"ws.hbang.typestatus.icon": @"type status",
                @"ws.hbang.typestatus.readicon": @"type status",
                @"com.sassoty.bulb": @"bulb",
                @"statusmodifier.mute": @"mute",
                @"com.malcolmhall.insomnia": @"insomnia",
                @"com.malcolmhall.insomniapro": @"insomnia",
                @"TetherStatus.icon": @"TetherStatus",
                @"Time": @"time",
                @"Bluetooth": @"bluetooth",
                @"AirPlay": @"airplay",
                @"PersonalHotspot": @"personal hotspot",
                @"AirplaneMode": @"airplane mode",
                @"Alarm": @"alarm",
                @"Battery": @"battery",
                @"TTY": @"tty",
				@"DND": @"do not disturb",
				@"DataNetwork": @"wifi",
				@"Location": @"location",
				@"VPN": @"vpn",

                };
    }


    if (desc == nil)
        desc = @"";

    if (cachedImages[desc])
    {
        return cachedImages[desc];
    }
    static __strong NSBundle *templateBundle;
    if (!templateBundle)
        templateBundle = [NSBundle bundleWithPath:TemplatePath];
    
    if ([desc hasPrefix:@"com.efrederickson.protean-"])
    {
        NSString *identifier = [desc substringFromIndex:26];

        
        ALApplicationList *al = [ALApplicationList sharedApplicationList];
        if ([al.applications.allKeys containsObject:identifier])
        {
            cachedImages[desc] = [al iconOfSize:ALApplicationIconSizeSmall forDisplayIdentifier:identifier];
            return cachedImages[desc];
        }
        if ([[FSSwitchPanel sharedPanel].switchIdentifiers containsObject:identifier])
        {
        	UIImage *img = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/flipswitches/%@/Icon.png",BUNDLE_PATH,identifier]];
        	if (!img && ![map.allKeys containsObject:identifier])
        		img = resizeFSImage([[[FSSwitchPanel sharedPanel] imageOfSwitchState:[[FSSwitchPanel sharedPanel] stateForSwitchIdentifier:identifier] controlState:UIControlStateNormal forSwitchIdentifier:identifier usingTemplate:templateBundle] _flatImageWithColor:[UIColor blackColor]]);
            cachedImages[desc] = img;
            return cachedImages[desc];
        }
        
        if ([identifier hasPrefix:@"Pebble"])
            desc = @"pebble";
        
        if ([identifier isEqual:@"TOTAL_NOTIFICATION_COUNT"])
            desc = @"total notification count";
    }
    
    if ([desc hasPrefix:@"spacer-"])
        desc = @"spacer";

    if ([desc hasPrefix:@"Indicator:"])
        desc = [desc substringFromIndex:10];
    
    if ([desc hasPrefix:@"QuietMode"])
        desc = @"do not disturb";
    if ([desc hasPrefix:@"AirplaneMode"])
        desc = @"airplane mode";
    
    if ([desc isEqual:@"com.rabih96.macvolume"])
        desc = @"volume status";
    else if ([desc isEqual:@"jzplusplus.OkSiri"])
        desc = @"siri";
    else if ([desc isEqual:@"phantom.coke"])
        desc = @"phantom";
    else if ([desc isEqual:@"com.lablabla.muteicon"])
        desc = @"mute icon";
    else if ([desc isEqual:@"com.sassoty.bulb"])
        desc = @"bulb";
    else if ([desc isEqual:@"ws.hbang.typestatus.icon"])
        desc = @"type status";

    desc = [map.allKeys containsObject:desc] ? map[desc] : desc;

    cachedImages[desc] = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/icons/%@/Icon.png",BUNDLE_PATH,desc]] ?: [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/icons/unknown/Icon.png",BUNDLE_PATH]]; 
    return cachedImages[desc];
}

NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];

static NSDictionary *cachedSettings = nil;
NSDictionary *mapSettings()
{
    if (cachedSettings) return cachedSettings;
    static NSArray *systemItems = @[@0, @1, @2, @3, @4, @5, @7, @8, @9, @10, @11, @12, @13, @16, @17, @19, @20, @21, @22, @23, @28];
    
    NSMutableDictionary *mapped = [NSMutableDictionary dictionary];
    
    NSDictionary *prefs = [NSDictionary
                           dictionaryWithContentsOfFile:PLIST_NAME];
    if (prefs == nil)
        prefs = [NSDictionary dictionary];
    
    for (id key in prefs)
    {
        NSNumber *num = [numberFormatter numberFromString:key];
        if (num == nil)
            continue;
        
        if ([systemItems containsObject:num] == NO && [num intValue] < 33)
            continue; // Not an allowed/actual system item
        
        NSMutableDictionary *d = prefs[key];
        if (d[@"identifier"] == nil || [d[@"identifier"] isEqual:@""])
            continue;
        
        NSNumber *alignment = d[@"alignment"] == nil ? @4 : d[@"alignment"];
        
        if (mapped[alignment] == nil)
            [mapped setObject:[NSMutableDictionary dictionary] forKey:alignment];
        
        NSNumber *defaultOrder = [NSNumber numberWithInt:[mapped[alignment] count]];
        NSNumber *order = d[@"order"] == nil ? defaultOrder : d[@"order"];
        while (mapped[alignment][order] != nil)
            order = @(order.intValue + 1);
        //while ([mapped[alignment] objectForKey:@(order.intValue - 1)] == nil && order.intValue > 0)
        //    order = @(order.intValue - 1);
        mapped[alignment][order] = d;
    }
    
    cachedSettings = mapped;
    return cachedSettings;
}

@implementation PROrganizationController
-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section)
    {
        case 0:
            return @"Left";
        case 1:
            return @"Right";
        case 2:
            return @"Center";
        case 3:
            return @"Hidden";
        case 4:
            return @"Default";
            
        default:
            return @"Header";
    }
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        [cell setSelectionStyle:UITableViewCellSelectionStyleBlue];
    }

    if (!cachedSettings)
        cachedSettings = mapSettings();
    NSString *desc = [cachedSettings objectForKey:@(indexPath.section)][@(indexPath.row)][@"identifier"];

    cell.textLabel.text = nameForDescription(desc);
    cell.imageView.image = iconForDescription(desc);
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 5;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return ((NSDictionary*)[mapSettings() objectForKey:[NSNumber numberWithInt:section]]).count;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    NSDictionary *mapped = mapSettings();
    
    NSDictionary *dict = [mapped objectForKey:[NSNumber numberWithInt:sourceIndexPath.section]][[NSNumber numberWithInt:sourceIndexPath.row]];

    if (destinationIndexPath.section == 2 && // center
        [dict[@"key"] intValue] > 32) // non-system item
    {
        if (!LIBSTATUSBAR8)
        {
            cachedSettings = nil;
            [tableView reloadData];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops" 
                    message:@"Unfortunately, libstatusbar icons cannot be aligned to the center." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alert show];
            return;
        }
    }

    NSMutableDictionary *prefs = [NSMutableDictionary
                                  dictionaryWithContentsOfFile:PLIST_NAME] ?: [NSMutableDictionary dictionary];
    
    prefs[dict[@"key"]][@"alignment"] = [NSNumber numberWithInt:destinationIndexPath.section];
        
    int old_order = sourceIndexPath.row;
    int new_order = destinationIndexPath.row;
        
    int i = 0;
    NSMutableArray *counts = [NSMutableArray array];
    [mapped[[NSNumber numberWithInt:sourceIndexPath.section]] removeObjectForKey:[NSNumber numberWithInt:sourceIndexPath.row]];
    for (id obj_ in mapped[[NSNumber numberWithInt:sourceIndexPath.section]])
    {
        id obj = mapped[[NSNumber numberWithInt:sourceIndexPath.section]][obj_];
        
        if (prefs[obj[@"key"]][@"order"])
        {
            if ([prefs[obj[@"key"]][@"order"] intValue] > old_order)
            {
                [counts addObject:[NSNumber numberWithInt:[prefs[obj[@"key"]][@"order"] intValue] - 1]];
                prefs[obj[@"key"]][@"order"] = [NSNumber numberWithInt:[prefs[obj[@"key"]][@"order"] intValue] - 1];
            }
            else
                [counts addObject:[NSNumber numberWithInt:[prefs[obj[@"key"]][@"order"] intValue]]];
        }
        else
        {
            while ([counts containsObject:[NSNumber numberWithInt:i]])
                i++;
            [counts addObject:[NSNumber numberWithInt:i]];
            prefs[obj[@"key"]][@"order"] = [NSNumber numberWithInt:i++];
        }
    }
        
    i = 0;
    counts = [NSMutableArray array];
    for (id obj_ in mapped[[NSNumber numberWithInt:destinationIndexPath.section]])
    {
        id obj = mapped[[NSNumber numberWithInt:destinationIndexPath.section]][obj_];
        
        if (prefs[obj[@"key"]][@"order"])
        {
            if ([prefs[obj[@"key"]][@"order"] intValue] >= new_order)
            {
                [counts addObject:[NSNumber numberWithInt:[prefs[obj[@"key"]][@"order"] intValue] + 1]];
                prefs[obj[@"key"]][@"order"] = [NSNumber numberWithInt:[prefs[obj[@"key"]][@"order"] intValue] + 1];
            }
            else
                [counts addObject:[NSNumber numberWithInt:[prefs[obj[@"key"]][@"order"] intValue]]];
        }
        else
        {
            while ([counts containsObject:[NSNumber numberWithInt:i]])
                i++;
            [counts addObject:[NSNumber numberWithInt:i]];
            prefs[obj[@"key"]][@"order"] = [NSNumber numberWithInt:i++];
        }
    }
        
    prefs[dict[@"key"]][@"order"] = [NSNumber numberWithInt:destinationIndexPath.row];
    
    [prefs writeToFile:PLIST_NAME atomically:YES];
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.efrederickson.protean/reloadSettings"), nil, nil, YES);
    if ([dict[@"key"] intValue] < 32 || sourceIndexPath.section == destinationIndexPath.section)
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.efrederickson.protean/refreshStatusBar"), nil, nil, YES);
    else
    {
        if (!showedAlert)
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Respring needed" 
                message:@"Unfortunately, to apply changes to custom (libstatusbar) icons, a respring is necessary." delegate:self cancelButtonTitle:@"Later" otherButtonTitles:@"Respring",nil];
            [alert show];
            showedAlert = YES;
        }
    }
    cachedSettings = nil;
    [tableView reloadData];
}

- (id)initForContentSize:(CGSize)size
{
    if ((self = [super initForContentSize:size]))
    {
        self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height) style:UITableViewStyleGrouped];
        
        [self.tableView setDelegate:self];
        [self.tableView setDataSource:self];
        [self.tableView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
        [self.tableView setEditing:YES];
        [self.tableView setAllowsSelection:NO];
        
        [self setView:self.tableView];

        [self setTitle:@"Organization"];
    }

    return self;
}

- (UITableViewCellEditingStyle)tableView:(UITableView*)tableView editingStyleForRowAtIndexPath:(NSIndexPath*)indexPath
{
    return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

-(UIColor*) tintColor { return [UIColor colorWithRed:79/255.0f green:176/255.0f blue:136/255.0f alpha:1.0f]; }

- (void)viewWillAppear:(BOOL)animated {
    ((UIView*)self.view).tintColor = self.tintColor;
    self.navigationController.navigationBar.tintColor = self.tintColor;
    showedAlert = NO;
    cachedSettings = nil;

    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {   
    ((UIView*)self.view).tintColor = nil;
    self.navigationController.navigationBar.tintColor = nil;
    [super viewWillDisappear:animated];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        system("killall -9 SpringBoard");
    }
}
@end
