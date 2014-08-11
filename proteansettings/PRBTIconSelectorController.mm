#import "PRBTIconSelectorController.h"
#import <AppList/AppList.h>
#import <libactivator/libactivator.h>
#define PLIST_NAME @"/var/mobile/Library/Preferences/com.efrederickson.protean.settings.plist"

extern "C" CFNotificationCenterRef CFNotificationCenterGetDistributedCenter(void);

NSString* const iconPath = @"/Library/Protean/Images.bundle";
static NSMutableDictionary* cachedIcons;
static UIImage* defaultIcon;
static NSMutableArray* statusIcons;
NSString* const SilverIconRegexPattern = @"PR_(.*?)(_Count_(Large)?\\d\\d?)?(?:@.*|)(?:~.*|).png";

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

@interface PRBTIconSelectorController () {
    NSString *checkedIcon;
    int tapAction;
}
@end

extern UIImage *imageFromName(NSString *name);

@implementation PRBTIconSelectorController

-(id)initWithAppName:(NSString*)appName identifier:(NSString*)identifier
{
	_appName = appName;
	_identifier = identifier;
	return [self init];
}

-(void) updateSavedData
{
    NSMutableDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:PLIST_NAME];
    prefs = prefs ?: [NSMutableDictionary dictionary];
    
    prefs[@"images"] = prefs[@"images"] ? [prefs[@"images"] mutableCopy]: [NSMutableDictionary dictionary];
    prefs[@"images"][_identifier] = [checkedIcon isEqual:@"None"] ? @"" : checkedIcon;
    
    prefs[@"tapActions"] = prefs[@"tapActions"] ? [prefs[@"tapActions"] mutableCopy]: [NSMutableDictionary dictionary];
    prefs[@"tapActions"][_identifier] = [NSNumber numberWithInt:tapAction==1?2:0] ?: @0;
    
    [prefs writeToFile:PLIST_NAME atomically:YES];
    CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), CFSTR("com.efrederickson.protean/reloadSettings"), nil, nil, YES);
}

-(id)init
{
    tapAction = 0;
    checkedIcon = @"";
    
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
        
        regex = [NSRegularExpression regularExpressionWithPattern:@"Black_ON_(.*?)(?:@.*|)(?:~.*|).png"
                                                          options:NSRegularExpressionCaseInsensitive error:nil];
        
        for (NSString* path in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/System/Library/Frameworks/UIKit.framework" error:nil])
		{
			NSTextCheckingResult* match = [regex firstMatchInString:path options:0 range:NSMakeRange(0, path.length)];
			if (!match) continue;
			NSString* name = [path substringWithRange:[match rangeAtIndex:1]];
            
            if ([name hasPrefix:@"Count"])
                continue;
            
			if (![statusIcons containsObject:name]) [statusIcons addObject:name];
		}
	}
    
    
    NSMutableDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:PLIST_NAME];
    prefs = prefs ?: [NSMutableDictionary dictionary];
    
    checkedIcon = ([prefs[@"images"] mutableCopy] ?: [NSMutableDictionary dictionary])[_identifier] ?: @"";
    tapAction = [([prefs[@"tapActions"] mutableCopy] ?: [NSMutableDictionary dictionary])[_identifier] intValue] == 2 ? 1 : 0;
    
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
    return 2;
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
            cell.textLabel.text = @"None";
            cell.imageView.image = imageFromName(@"None");
            cell.accessoryType = [checkedIcon isEqual:@""] || [checkedIcon isEqual:@"None"] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
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
            LAEventSettingsController *vc = [[LAEventSettingsController alloc] initWithModes:@[LAEventModeSpringBoard,LAEventModeApplication, LAEventModeLockScreen] eventName:[NSString stringWithFormat:@"%@%@", @"com.efrederickson.protean-",_identifier]];
            [self.rootController pushViewController:vc animated:YES];
        }
    }
    else
        checkedIcon = cell.textLabel.text;
    
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    [self updateSavedData];
    [tableView reloadData];
}

@end
