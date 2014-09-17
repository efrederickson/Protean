#import "PRSysIconSelectorController.h"
#import <AppList/AppList.h>
#import <libactivator/libactivator.h>
#define PLIST_NAME @"/var/mobile/Library/Preferences/com.efrederickson.protean.settings.plist"

NSString* const iconPath = @"/Library/Protean/Images.bundle";
static NSMutableDictionary* cachedIcons;
static UIImage* defaultIcon;
static NSMutableArray* statusIcons;
NSString* const SilverIconRegexPattern = @"PR_(.*?)(_Count_(Large)?\\d\\d?)?(?:@.*|)(?:~.*|).png";
static NSMutableArray *searchedIcons;
NSArray *canHaveImages = @[ @1, @2, @11, @12, @13, @16, @17, @19, @20, @21, @22];

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
    int _raw_id;
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
    _raw_id = id_;
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

    if ([canHaveImages containsObject:[NSNumber numberWithInt:_raw_id]])
    {
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

    }
    searchedIcons = [NSMutableArray array];    
    isSearching = NO;

	return self;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if ([canHaveImages containsObject:[NSNumber numberWithInt:_raw_id]])
        return isSearching ? 1 : 2;
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (isSearching)
        return searchedIcons.count;

    if (section == 0)
        return 2;
    else
        return statusIcons.count + 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (isSearching)
        return @"Icons";

    if (section == 0)
        return @"Tap Action";
    else
        return @"Icons";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    
    if (indexPath.section == 0 && isSearching == NO)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
        if (cell == nil)
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];

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
        cell = [tableView dequeueReusableCellWithIdentifier:@"IconCell"];
        if (cell == nil)
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"IconCell"];

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
    
    if (indexPath.section == 0 && !isSearching)
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
    if ([canHaveImages containsObject:[NSNumber numberWithInt:_raw_id]])
    {
        if (section == 0)
            return nil;
    }

    UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 5, [UIScreen mainScreen].bounds.size.width, 80)];
    footer.backgroundColor = [UIColor clearColor];
    
    UILabel *lbl = [[UILabel alloc] initWithFrame:footer.frame];
    lbl.backgroundColor = [UIColor clearColor];
    if (_raw_id == 7)
        lbl.text = @"Sorry, this icon cannot be\nthemed with Protean.";
    else
        lbl.text = section == 1 ? @"\nRespring to apply changes\nto System Icons." : @"Sorry, this icon cannot be\nthemed with Protean.";
    lbl.textAlignment = NSTextAlignmentCenter;
    lbl.numberOfLines = 3;
    lbl.font = [UIFont fontWithName:@"HelveticaNueue-UltraLight" size:5];
    lbl.textColor = [UIColor darkGrayColor];
    lbl.lineBreakMode = NSLineBreakByWordWrapping;
    [footer addSubview:lbl];
    
    return footer;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if ([canHaveImages containsObject:[NSNumber numberWithInt:_raw_id]])
        return section == 2 ? 80 : 0;
    return 80.0;
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
