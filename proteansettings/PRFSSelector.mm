#import "PRFSSelector.h"
#import <AppList/AppList.h>
#import <libactivator/libactivator.h>
#import <objc/runtime.h>
#import <flipswitch/Flipswitch.h>
#define PLIST_NAME @"/var/mobile/Library/Preferences/com.efrederickson.protean.settings.plist"
#define isPad ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
#define iPhoneTemplatePath @"/Library/Protean/FlipswitchTemplates/IconTemplate.bundle"
#define iPadTemplatePath @"/Library/Protean/FlipswitchTemplates/IconTemplate~iPad.bundle"
#define TemplatePath (isPad ? iPadTemplatePath : iPhoneTemplatePath)

NSString* const vectorIconPath = @"/Library/Protean/TranslatedVectors~cache/";
NSString* const iconPath = @"/Library/Protean/Images.bundle";
NSString* const ONIconPath = @"/System/Library/Frameworks/UIKit.framework";
static UIImage* defaultIcon;
static NSMutableArray* statusIcons;
//NSString* const SilverIconRegexPattern = @"PR_(.*?)(?:@.*|)(?:~.*|).png";
NSString* const SilverIconRegexPattern = @"PR_(.*?)(_Count_(Large)?\\d\\d?\\d?)?(?:@.*|)(?:~.*|).png";
static NSMutableArray* searchedIcons;
extern UIImage *imageFromName(NSString *name);
extern UIImage *resizeFSImage(UIImage *icon, float max = 30.0f);

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

@interface PRFSSelector () {
    int tapAction;
    BOOL enabled;
    NSString *checkedIcon;
    BOOL alwaysEnabled;
    BOOL showWhenOff;
}
@end

@implementation PRFSSelector

-(id)initWithFSName:(NSString*)appName identifier:(NSString*)identifier
{
    tapAction = 0;
    checkedIcon = @"Default";
    
	_appName = appName;
	_identifier = identifier;
	return [self init];
}

-(void) updateSavedData
{
    NSMutableDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:PLIST_NAME];
    prefs = prefs ?: [NSMutableDictionary dictionary];
    
    prefs[@"tapActions"] = prefs[@"tapActions"] ? [prefs[@"tapActions"] mutableCopy]: [NSMutableDictionary dictionary];
    prefs[@"tapActions"][_identifier] = [NSNumber numberWithInt:tapAction==1?2:0] ?: @0;
    
    prefs[@"flipswitches"] = prefs[@"flipswitches"] ? [prefs[@"flipswitches"] mutableCopy]: [NSMutableDictionary dictionary];
    prefs[@"flipswitches"][_identifier] = enabled ? @YES : @NO;

    prefs[@"alwaysShowFlipswitches"] = prefs[@"alwaysShowFlipswitches"] ? [prefs[@"alwaysShowFlipswitches"] mutableCopy]: [NSMutableDictionary dictionary];
    prefs[@"alwaysShowFlipswitches"][_identifier] = alwaysEnabled ? @YES : @NO;

    prefs[@"showWhenOffFlipswitches"] = prefs[@"showWhenOffFlipswitches"] ? [prefs[@"showWhenOffFlipswitches"] mutableCopy]: [NSMutableDictionary dictionary];
    prefs[@"showWhenOffFlipswitches"][_identifier] = showWhenOff ? @YES : @NO;

    prefs[@"images"] = prefs[@"images"] ? [prefs[@"images"] mutableCopy]: [NSMutableDictionary dictionary];
    prefs[@"images"][_identifier] = [checkedIcon isEqual:@"Default"] ? @"" : checkedIcon;
    
    [prefs writeToFile:PLIST_NAME atomically:YES];
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.efrederickson.protean/reloadSettings"), nil, nil, YES);
}

-(id)init
{
	if ((self = [super init]) == nil) return nil;
	
    NSMutableDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:PLIST_NAME];
    prefs = prefs ?: [NSMutableDictionary dictionary];

    if (!defaultIcon)
        defaultIcon = [[ALApplicationList sharedApplicationList] iconOfSize:ALApplicationIconSizeSmall forDisplayIdentifier:@"com.apple.WebSheet"];
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
        
        for (NSString* path in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:vectorIconPath error:nil])
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
    
    tapAction = [([prefs[@"tapActions"] mutableCopy] ?: [NSMutableDictionary dictionary])[_identifier] intValue] == 2 ? 1 : 0 ?: 0;
    enabled = [([prefs[@"flipswitches"] mutableCopy] ?: [NSMutableDictionary dictionary])[_identifier] boolValue] ?: NO;
    checkedIcon = ([prefs[@"images"] mutableCopy] ?: [NSMutableDictionary dictionary])[_identifier] ?: @"";
    alwaysEnabled = [([prefs[@"alwaysShowFlipswitches"] mutableCopy] ?: [NSMutableDictionary dictionary])[_identifier] boolValue] ?: NO;
    showWhenOff = [([prefs[@"showWhenOffFlipswitches"] mutableCopy] ?: [NSMutableDictionary dictionary])[_identifier] boolValue] ?: NO;
    
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

    [statusIcons sortUsingComparator: ^(NSString* a, NSString* b) {
        bool e1 = [checkedIcon isEqual:a];
        bool e2 = [checkedIcon isEqual:b];
        if (e1 && e2) {
            return [a caseInsensitiveCompare:b];
        } else if (e1) {
            return (NSComparisonResult)NSOrderedAscending;
        } else if (e2) {
            return (NSComparisonResult)NSOrderedDescending;
        }
        return [a caseInsensitiveCompare:b];
    }];

    _searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    _searchBar.delegate = self;
    _searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    searchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:_searchBar contentsController:(UIViewController*)self];
    searchDisplayController.delegate = self;
    searchDisplayController.searchResultsDataSource = self;
    searchDisplayController.searchResultsDelegate = self;
    
    UIView *tableHeaderView = [[UIView alloc] initWithFrame:searchDisplayController.searchBar.frame];
    [tableHeaderView addSubview:searchDisplayController.searchBar];
    [_tableView setTableHeaderView:tableHeaderView];

    searchedIcons = [NSMutableArray array];    
    isSearching = NO;

    [UISwitch appearanceWhenContainedIn:self.class, nil].onTintColor = self.tintColor;
    
	return self;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return isSearching ? 1 : 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (isSearching)
        return searchedIcons.count;

    if (section == 0)
        return 2; // 3 for Show Always
    else if (section == 1)
        return 2;
    return statusIcons.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (isSearching)
        return @"Icons";

    if (section == 0)
        return @"Options";
    else if (section == 1)
        return @"Tap Action";
    return @"Icons";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    if (indexPath.section == 0 && isSearching == NO)
    {
    	cell = [tableView dequeueReusableCellWithIdentifier:@"SwitchCell"];
    	if (cell == nil)
        	cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SwitchCell"];

        if (indexPath.row == 0)
        {
        	cell.textLabel.text = @"Enabled";
        	cell.selectionStyle = UITableViewCellSelectionStyleNone;
        	UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
        	cell.accessoryView = switchView;
        	[switchView setOn:enabled animated:NO];
        	[switchView addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
        }
        else if (indexPath.row == 1)
        {
            cell.textLabel.text = @"Display When Off Instead";
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
            cell.accessoryView = switchView;
            [switchView setOn:showWhenOff animated:NO];
            [switchView addTarget:self action:@selector(showWhenOffSwitchChanged:) forControlEvents:UIControlEventValueChanged];
        }
        else
        {
        	cell.textLabel.text = @"Always Show";
        	cell.selectionStyle = UITableViewCellSelectionStyleNone;
        	UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
        	cell.accessoryView = switchView;
        	[switchView setOn:alwaysEnabled animated:NO];
        	[switchView addTarget:self action:@selector(alwaysEnabledSwitchChanged:) forControlEvents:UIControlEventValueChanged];
        }
    }
    else if (indexPath.section == 1)
    {
    	cell = [tableView dequeueReusableCellWithIdentifier:@"TextCell"];
    	if (cell == nil)
        	cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"TextCell"];
        NSString *alignmentText = @"";
        if (indexPath.row == 0)
            alignmentText = @"Nothing";
        //else if (indexPath.row == 1)
        //    alignmentText = @"Open Settings Panel";
        else if (indexPath.row == 1)
            alignmentText = @"Activator Action";
        
        cell.textLabel.text = alignmentText;
        cell.accessoryType = indexPath.row == tapAction ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }
    else
    {
    	cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    	if (cell == nil)
        	cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];

        if (isSearching)
        {
            NSString *name = searchedIcons.count < indexPath.row ? @"" : searchedIcons[indexPath.row];
            cell.textLabel.text = name;
            cell.imageView.image = imageFromName(name);
            cell.accessoryType = [name isEqual:checkedIcon] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        }
        else if (indexPath.row == 0)
        {
            cell.textLabel.text = @"Default";
            NSBundle *templateBundle = [NSBundle bundleWithPath:TemplatePath];
            cell.imageView.image = resizeFSImage([[[FSSwitchPanel sharedPanel] imageOfSwitchState:[[FSSwitchPanel sharedPanel] stateForSwitchIdentifier:_identifier] controlState:UIControlStateNormal forSwitchIdentifier:_identifier usingTemplate:templateBundle] _flatImageWithColor:[UIColor blackColor]], 20.0f);
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

- (void) switchChanged:(id)sender {
    UISwitch* switchControl = sender;
    enabled = switchControl.on;
    [self updateSavedData];
}

- (void) alwaysEnabledSwitchChanged:(id)sender {
    UISwitch* switchControl = sender;
    alwaysEnabled = switchControl.on;
    [self updateSavedData];
}

- (void) showWhenOffSwitchChanged:(id)sender {
    UISwitch* switchControl = sender;
    showWhenOff = switchControl.on;
    [self updateSavedData];
}

-(void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
	UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];

    if (isSearching || indexPath.section == 2)
    {
        checkedIcon = cell.textLabel.text;
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.efrederickson.protean/refreshStatusBar"), nil, nil, YES);
    }
    else if (indexPath.section == 1)
    {
        tapAction = indexPath.row;
        
        if (tapAction == 1) // Activator
        {
            id activator = objc_getClass("LAEventSettingsController");
            if (!activator)
            {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Protean" message:@"Activator must be installed to use this feature." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alert show];
            }
            LAEventSettingsController *vc = [[objc_getClass("LAEventSettingsController") alloc] initWithModes:@[LAEventModeSpringBoard,LAEventModeApplication, LAEventModeLockScreen] eventName:[NSString stringWithFormat:@"com.efrederickson.protean-%@", _identifier]];
            [self.rootController pushViewController:vc animated:YES];
        }
    }
    
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    [self updateSavedData];
    [tableView reloadData];
}

-(void)searchBar:(UISearchBar*)searchBar textDidChange:(NSString*)searchText
{
    searchedIcons = [NSMutableArray array];

    for (NSString* name in statusIcons)
    {
        if ([name rangeOfString:searchText options:NSCaseInsensitiveSearch].location != NSNotFound)
            [searchedIcons addObject:name];
    }

    [_tableView reloadData];
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    UISearchBar *searchBar = searchDisplayController.searchBar;
    CGRect searchBarFrame = searchBar.frame;
    
    searchBarFrame.origin.y = 0;
    searchDisplayController.searchBar.frame = searchBarFrame;
}

- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller {
    isSearching = YES;
}

-(void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller {
    isSearching = NO;
    [_tableView reloadData];
}

-(UIColor*) tintColor { return [UIColor colorWithRed:79/255.0f green:176/255.0f blue:136/255.0f alpha:1.0f]; }

- (void)viewWillAppear:(BOOL)animated {
    ((UIView*)self.view).tintColor = self.tintColor;
    self.navigationController.navigationBar.tintColor = self.tintColor;

    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    ((UIView*)self.view).tintColor = nil;
    self.navigationController.navigationBar.tintColor = nil;
}
@end
