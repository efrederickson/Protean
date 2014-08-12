#import "PROrganizationController.h"
#import <AppList/AppList.h>
#import <objcipc/objcipc.h>
#import <flipswitch/Flipswitch.h>
#define PLIST_NAME @"/var/mobile/Library/Preferences/com.efrederickson.protean.settings.plist"
#define isPad() ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
#define iPhoneTemplatePath @"/Library/Protean/FlipswitchTemplates/IconTemplate.bundle"
#define iPadTemplatePath @"/Library/Protean/FlipswitchTemplates/IconTemplate~iPad.bundle"
#define TemplatePath (isPad() ? iPadTemplatePath : iPhoneTemplatePath)
extern "C" CFNotificationCenterRef CFNotificationCenterGetDistributedCenter(void);

@interface PSViewController ()
-(void) setView:(id)view;
@end
@interface UIApplication (Protean)
-(id) statusBar;
@end
@interface UIStatusBar
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
@interface UIImage (Protean)
+ (UIImage*)imageNamed:(NSString *)imageName inBundle:(NSBundle*)bundle;
- (UIImage*) _flatImageWithColor: (UIColor*) color;
@end

NSString *nameForDescription(NSString *desc)
{
    static __strong NSDictionary *map;
    if (!map) {
        map = @{
                @"MSNowPlayingItem": @"Now Playing",
                @"SignalStrength": @"Signal Strength",
                @"RotationLock": @"Rotation Lock",
                @"BatteryPercent": @"Battery Percent",
                @"BluetoothBattery": @"Bluetooth Battery",
                @"NotCharging": @"Not Charging (iPad)",
                @"Activity": @"Loading Indicator",
                @"com.rabih96.macvolume": @"Volume Status",
                @"TOTAL_NOTIFICATION_COUNT": @"Total Notification Count"
                };
    }
    
    if ([desc hasPrefix:@"com.efrederickson.protean-"])
    {
        NSString *identifier = [desc substringFromIndex:26];
        
        if ([identifier isEqual:@"TOTAL_NOTIFICATION_COUNT"])
            return @"Total Notification Count";
        
        if ([[FSSwitchPanel sharedPanel].switchIdentifiers containsObject:identifier])
            return [[FSSwitchPanel sharedPanel] titleForSwitchIdentifier:identifier];
        
        ALApplicationList *al = [ALApplicationList sharedApplicationList];
        return [al.applications objectForKey:identifier] ?: identifier;
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
    
    return map[desc] ?: desc;
}

UIImage *resizeFSImage(UIImage *icon)
{
	float maxWidth = 30.0f;
	float maxHeight = 30.0f;
    
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

UIImage *iconForDescription(NSString *desc)
{
    static __strong NSBundle *templateBundle;
    if (!templateBundle)
        templateBundle = [NSBundle bundleWithPath:TemplatePath];
    
    if ([desc hasPrefix:@"com.efrederickson.protean-"])
    {
        NSString *identifier = [desc substringFromIndex:26];
        
        ALApplicationList *al = [ALApplicationList sharedApplicationList];
        if ([al.applications.allKeys containsObject:identifier])
            return [al iconOfSize:ALApplicationIconSizeSmall forDisplayIdentifier:identifier];
        if ([[FSSwitchPanel sharedPanel].switchIdentifiers containsObject:identifier])
            return resizeFSImage([[[FSSwitchPanel sharedPanel] imageOfSwitchState:[[FSSwitchPanel sharedPanel] stateForSwitchIdentifier:identifier] controlState:UIControlStateNormal forSwitchIdentifier:identifier usingTemplate:templateBundle] _flatImageWithColor:[UIColor blackColor]]);
        
        if ([identifier hasPrefix:@"Pebble"])
            desc = @"Pebble";
        
        if ([identifier isEqual:@"TOTAL_NOTIFICATION_COUNT"])
            desc = @"TotalNotificationCount";
    }
    
    if ([desc hasPrefix:@"Indicator:"])
        desc = [desc substringFromIndex:10];
    
    if ([desc hasPrefix:@"QuietMode"])
        desc = @"DND";
    if ([desc hasPrefix:@"AirplaneMode"])
        desc = @"AirplaneMode";
    
    if ([desc hasPrefix:@"opennotifier."])
    {
        //return [desc substringFromIndex:13];
        return nil;
    }
    
    if ([desc isEqual:@"com.rabih96.macvolume"])
        desc = @"Volume Status";
    
    static __strong NSBundle *imageBundle = nil;
    if (imageBundle == nil)
        imageBundle = [NSBundle bundleWithPath:@"/Library/Protean/OrganizeIcons.bundle"];
    
    return [UIImage imageNamed:desc inBundle:imageBundle] ?: [UIImage imageNamed:@"Unknown" inBundle:imageBundle];
}

void updateStatusBar()
{
    UIStatusBar *statusBar = (UIStatusBar *)[[UIApplication sharedApplication] statusBar];
    
	UIView *fakeStatusBar;
    
    fakeStatusBar = [statusBar snapshotViewAfterScreenUpdates:NO];
    
	[statusBar.superview addSubview:fakeStatusBar];
    
    //[statusBar setShowsOnlyCenterItems:YES];
    //[statusBar setShowsOnlyCenterItems:NO];

	CGRect upwards = statusBar.frame;
	upwards.origin.y -= upwards.size.height;
	statusBar.frame = upwards;
    
    //statusBar.alpha = 0;
    
	CGFloat shrinkAmount = 5.0;
	[UIView animateWithDuration:0.6 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^(void){
		CGRect shrinkFrame = fakeStatusBar.frame;
		shrinkFrame.origin.x += shrinkAmount;
		shrinkFrame.origin.y += shrinkAmount;
		shrinkFrame.size.width -= shrinkAmount;
		shrinkFrame.size.height -= shrinkAmount;
		fakeStatusBar.frame = shrinkFrame;
		fakeStatusBar.alpha = 0.0;
        //statusBar.alpha = 1;
        
		CGRect downwards = statusBar.frame;
		downwards.origin.y += downwards.size.height;
		statusBar.frame = downwards;
	} completion: ^(BOOL finished) {
		[fakeStatusBar removeFromSuperview];
	}];
}

NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];

NSDictionary *mapSettings()
{
    static NSArray *systemItems = @[@0, @1, @2, @3, @4, @5, @7, @8, @9, @10, @11, @12, @13, @16, @17, @19, @20, @21, @22, @23, @24, @28];
    
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
            order = [NSNumber numberWithInt:[order intValue] + 1];
        mapped[alignment][order] = d;
    }
    
    return mapped;
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
    
    NSString *desc = [mapSettings() objectForKey:[NSNumber numberWithInt:indexPath.section]][[NSNumber numberWithInt:indexPath.row]][@"identifier"];
    
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
    
    NSMutableDictionary *prefs = [NSMutableDictionary
                                  dictionaryWithContentsOfFile:PLIST_NAME];
    
    //prefs[dict[@"key"]][@"order"] = [NSNumber numberWithInt:destinationIndexPath.row];
    prefs[dict[@"key"]][@"alignment"] = [NSNumber numberWithInt:destinationIndexPath.section];
        
    int old_order = sourceIndexPath.row;
    int new_order = destinationIndexPath.row;
        
    int i = 0;
    [mapped[[NSNumber numberWithInt:sourceIndexPath.section]] removeObjectForKey:[NSNumber numberWithInt:sourceIndexPath.row]];
    for (id obj_ in mapped[[NSNumber numberWithInt:sourceIndexPath.section]])
    {
        id obj = mapped[[NSNumber numberWithInt:sourceIndexPath.section]][obj_];
        
        if (prefs[obj[@"key"]][@"order"])
        {
            if ([prefs[obj[@"key"]][@"order"] intValue] > old_order)
                prefs[obj[@"key"]][@"order"] = [NSNumber numberWithInt:[prefs[obj[@"key"]][@"order"] intValue] - 1];
        }
        else
            prefs[obj[@"key"]][@"order"] = [NSNumber numberWithInt:i++];
    }
        
    i = 0;
        
    for (id obj_ in mapped[[NSNumber numberWithInt:destinationIndexPath.section]])
    {
        id obj = mapped[[NSNumber numberWithInt:destinationIndexPath.section]][obj_];
        
        if (prefs[obj[@"key"]][@"order"])
        {
            if ([prefs[obj[@"key"]][@"order"] intValue] >= new_order)
                prefs[obj[@"key"]][@"order"] = [NSNumber numberWithInt:[prefs[obj[@"key"]][@"order"] intValue] + 1];
        }
        else
            prefs[obj[@"key"]][@"order"] = [NSNumber numberWithInt:i++];
    }
        
    prefs[dict[@"key"]][@"order"] = [NSNumber numberWithInt:destinationIndexPath.row];
    
    [prefs writeToFile:PLIST_NAME atomically:YES];
    [tableView deselectRowAtIndexPath:sourceIndexPath animated:YES];
    [tableView reloadData];
    CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), CFSTR("com.efrederickson.protean/reloadSettings"), nil, nil, YES);
    if ([dict[@"key"] intValue] < 33 && sourceIndexPath != destinationIndexPath)
        updateStatusBar();
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
@end
