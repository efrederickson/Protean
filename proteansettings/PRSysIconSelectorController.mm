#import "PRSysIconSelectorController.h"
#import <AppList/AppList.h>
#import <libactivator/libactivator.h>
#define PLIST_NAME @"/var/mobile/Library/Preferences/com.efrederickson.protean.settings.plist"

NSString* const iconPath = @"/Library/Protean/Images.bundle";
static NSMutableDictionary* cachedIcons;
static UIImage* defaultIcon;
static NSMutableArray* statusIcons;
NSString* const SilverIconRegexPattern = @"PR_(.*?)(?:@.*|)(?:~.*|).png";

@interface PSViewController (Protean)
-(void) viewDidLoad;
-(void) viewWillDisappear:(BOOL)animated;
-(void) setView:(id)view;
-(void) setTitle:(NSString*)title;
@end
@interface UIImage (Protean)
+ (UIImage*)imageNamed:(NSString *)imageName inBundle:(NSBundle*)bundle;
- (UIImage*) _flatImageWithColor: (UIColor*) color;
@end

@interface PRSysIconSelectorController () {
    NSString *checkedIcon;
    int tapAction;
}
@end

extern UIImage *imageFromName(NSString *name);
extern NSString *nameForDescription(NSString *desc);
extern UIImage *iconForDescription(NSString *desc);
UIImage *resizeImage(UIImage *icon)
{
	float maxWidth = 20.0f;
	float maxHeight = 20.0f;
    
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


@implementation PRSysIconSelectorController

-(id)initWithAppName:(NSString*)appName identifier:(NSString*)identifier id:(int)id_
{
	_appName = appName;
	_identifier = identifier;
    _id = [NSString stringWithFormat:@"%d",id_]; // amazing names, right?
	return [self init];
}

-(void) updateSavedData
{
    NSMutableDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:PLIST_NAME];
    prefs = prefs ?: [NSMutableDictionary dictionary];
    
    prefs[@"images"] = prefs[@"images"] ? [prefs[@"images"] mutableCopy]: [NSMutableDictionary dictionary];
    prefs[@"images"][_id] = [checkedIcon isEqual:@"Default"] ? @"" : checkedIcon;
    
    prefs[@"tapActions"] = prefs[@"tapActions"] ? [prefs[@"tapActions"] mutableCopy]: [NSMutableDictionary dictionary];
    prefs[@"tapActions"][_id] = [NSNumber numberWithInt:tapAction == 1?2:0] ?: @0;
    
    [prefs writeToFile:PLIST_NAME atomically:YES];
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.efrederickson.protean/reloadSettings"), nil, nil, YES);
}

-(id)init
{
    checkedIcon = @"";
    tapAction = 0;
    
	if ((self = [super init]) == nil) return nil;
	
	if (!defaultIcon)
        defaultIcon = [[ALApplicationList sharedApplicationList] iconOfSize:ALApplicationIconSizeSmall forDisplayIdentifier:@"com.apple.WebSheet"];
	if (!cachedIcons)
        cachedIcons = [[NSMutableDictionary alloc] init];
	if (!statusIcons)
	{
		statusIcons = [[NSMutableArray alloc] init];
		NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:SilverIconRegexPattern
                                                                               options:NSRegularExpressionCaseInsensitive error:nil];
        
		for (NSString* path in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:iconPath error:nil])
		{
			NSTextCheckingResult* match = [regex firstMatchInString:path options:0 range:NSMakeRange(0, path.length)];
			if (!match) continue;
			NSString* name = [path substringWithRange:[match rangeAtIndex:1]];
			if (![statusIcons containsObject:name]) [statusIcons addObject:name];
		}
		
	}
    
    
    NSMutableDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:PLIST_NAME];
    prefs = prefs ?: [NSMutableDictionary dictionary];
    
    checkedIcon = ([prefs[@"images"] mutableCopy] ?: [NSMutableDictionary dictionary])[_id] ?: @"";
    tapAction = [([prefs[@"tapActions"] mutableCopy] ?: [NSMutableDictionary dictionary])[_id] intValue] == 2 ? 1 : 0;
    
    CGRect bounds = [[UIScreen mainScreen] bounds];
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, bounds.size.width, bounds.size.height) style:UITableViewStyleGrouped];
	_tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	_tableView.delegate = self;
	_tableView.dataSource = self;
    [_tableView setEditing:NO];
    [_tableView setAllowsSelection:YES];
    [_tableView setAllowsMultipleSelection:NO];
    [_tableView setAllowsSelectionDuringEditing:YES];
    [_tableView setAllowsMultipleSelectionDuringEditing:NO];
    
    [self setView:_tableView];
    
    [self setTitle:_appName];
    
	return self;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
        return 2;
    else
        return statusIcons.count + 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0)
        return @"Icon Tap";
    else
        return @"Icons";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    
    if (indexPath.section == 0)
    {
        NSString *alignmentText = @"";
        if (indexPath.row == 0)
            alignmentText = @"Nothing";
        else if (indexPath.row == 1)
            alignmentText = @"Activator Action";
        
        cell.textLabel.text = alignmentText;
        cell.accessoryType = indexPath.row == tapAction ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }
    else
    {
        if (indexPath.row == 0)
        {
            cell.textLabel.text = @"Default";
            cell.imageView.image = resizeImage(iconForDescription(_identifier));
            cell.accessoryType = [checkedIcon isEqual:@""] || [checkedIcon isEqual:@"Default"] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        }
        else
        {
            cell.textLabel.text = statusIcons[indexPath.row - 1];
            cell.imageView.image = imageFromName(statusIcons[indexPath.row - 1]);
            cell.accessoryType = [cell.textLabel.text isEqual:checkedIcon] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        }
    }
    return cell;
}

-(void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
	UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
    
    if (indexPath.section == 0)
    {
        tapAction = indexPath.row;
        
        if (tapAction == 1) // Activator
        {
            LAEventSettingsController *vc = [[LAEventSettingsController alloc] initWithModes:@[LAEventModeSpringBoard,LAEventModeApplication, LAEventModeLockScreen] eventName:[NSString stringWithFormat:@"%@%@", @"com.efrederickson.protean-",_id]];
            [self.rootController pushViewController:vc animated:YES];
        }
    }
    else
        checkedIcon = cell.textLabel.text;
    
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    [self updateSavedData];
    [_tableView reloadData];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 5, [UIScreen mainScreen].bounds.size.width, 80)];
    footer.backgroundColor = [UIColor clearColor];
    
    UILabel *lbl = [[UILabel alloc] initWithFrame:footer.frame];
    lbl.backgroundColor = [UIColor clearColor];
    lbl.text = @"Most system icons can be\nthemed via Winterboard.\nTry ayeris for a great example.";
    lbl.textAlignment = NSTextAlignmentCenter;
    lbl.numberOfLines = 3;
    lbl.font = [UIFont fontWithName:@"HelveticaNueue-UltraLight" size:5];
    lbl.textColor = [UIColor darkGrayColor];
    lbl.lineBreakMode = NSLineBreakByWordWrapping;
    [footer addSubview:lbl];
    
    return footer;
}


- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 80.0;
}

@end
