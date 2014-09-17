#import "IconSelectorController.h"
#import <AppList/AppList.h>
#import <libactivator/libactivator.h>
#define PLIST_NAME @"/var/mobile/Library/Preferences/com.efrederickson.protean.settings.plist"

NSString* const iconPath = @"/Library/Protean/Images.bundle";
NSString* const ONIconPath = @"/System/Library/Frameworks/UIKit.framework";
static NSMutableDictionary* cachedIcons;
static UIImage* defaultIcon;
static NSMutableArray* statusIcons;
//NSString* const SilverIconRegexPattern = @"PR_(.*?)(?:@.*|)(?:~.*|).png";
NSString* const SilverIconRegexPattern = @"PR_(.*?)(_Count_(Large)?\\d\\d?\\d?)?(?:@.*|)(?:~.*|).png";
static NSMutableArray* searchedIcons;

@interface PSViewController (Protean)
-(void) viewDidLoad;
-(void) viewWillDisappear:(BOOL)animated;
-(void) setView:(id)view;
-(void) setTitle:(NSString*)title;
@end
@interface UIImage (Protean)
+ (UIImage*)imageNamed:(NSString *)imageName inBundle:(NSBundle*)bundle;
- (UIImage*) _flatImageWithColor: (UIColor*) color;
+ (UIImage*) kitImageNamed: (NSString*) name;
@end

NSString *checkedIcon = @"";
int tapAction = 0;
extern void PR_AppsControllerNeedsToReload();

UIImage *imageFromName(NSString *name)
{
    if (cachedIcons[name])
        return cachedIcons[name];
    
    static __strong NSBundle *imageBundle = nil;
    if (imageBundle == nil)
        imageBundle = [NSBundle bundleWithPath:iconPath];
    
    UIImage *icon = nil;
    if (!icon && [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@/PR_%@@2x.png",iconPath,name]])
        //icon = [UIImage imageNamed:[NSString stringWithFormat:@"PR_%@", name] inBundle:imageBundle];
        icon =  [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/PR_%@.png", iconPath, name]];
    if (!icon && [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@/Black_ON_%@@2x.png",ONIconPath,name]])
        //icon = [UIImage kitImageNamed:[NSString stringWithFormat:@"Black_ON_%@",name]];
        icon = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/Black_ON_%@@2x.png", ONIconPath, name]];
    if (!icon && [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@/Black_ON_Count1_%@@2x.png",ONIconPath,name]])
        icon = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/Black_ON_Count1_%@@2x.png", ONIconPath, name]];
    
    BOOL wasDefault = NO;
    if (!icon)
    {
        icon = defaultIcon;
        wasDefault = YES;
    }
    
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
    
    if (!wasDefault)
        icon = [icon _flatImageWithColor:[UIColor blackColor]];
    
	cachedIcons[name] = icon;
    
	return icon;
}

@implementation PRIconSelectorController

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
    prefs[@"tapActions"][_identifier] = [NSNumber numberWithInt:tapAction] ?: @0;
    
    [prefs writeToFile:PLIST_NAME atomically:YES];
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.efrederickson.protean/reloadSettings"), nil, nil, YES);
}

-(id)init
{
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
        
        NSRegularExpression *numRegex = [NSRegularExpression regularExpressionWithPattern:@"(Count\\d?\\d?_?)?(.*)"
                                                                                  options:NSRegularExpressionCaseInsensitive error:nil];
        
        for (NSString* path in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/System/Library/Frameworks/UIKit.framework" error:nil])
		{
			NSTextCheckingResult* match = [regex firstMatchInString:path options:0 range:NSMakeRange(0, path.length)];
			if (!match) continue;
			NSString* name = [path substringWithRange:[match rangeAtIndex:1]];
            
            NSTextCheckingResult *match2 = [numRegex firstMatchInString:name options:0 range:NSMakeRange(0, name.length)];
            if (!match2)
                // wut
                continue;
            
            if ([match2 rangeAtIndex:2].length != 0)
                name = [name substringWithRange:[match2 rangeAtIndex:2]];
            
			if (![statusIcons containsObject:name])
                [statusIcons addObject:name];
		}
        
	}
    
    
    NSMutableDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:PLIST_NAME];
    prefs = prefs ?: [NSMutableDictionary dictionary];
    
    checkedIcon = ([prefs[@"images"] mutableCopy] ?: [NSMutableDictionary dictionary])[_identifier] ?: @"";
    tapAction = [([prefs[@"tapActions"] mutableCopy] ?: [NSMutableDictionary dictionary])[_identifier] intValue];
    
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
    
    //[statusIcons sort];
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
    //if ([_searchBar respondsToSelector:@selector(setUsesEmbeddedAppearance:)])
    //    [_searchBar setUsesEmbeddedAppearance:true];
    
    searchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:_searchBar contentsController:(UIViewController*)self];
    searchDisplayController.delegate = self;
    searchDisplayController.searchResultsDataSource = self;
    searchDisplayController.searchResultsDelegate = self;
    
    UIView *tableHeaderView = [[UIView alloc] initWithFrame:searchDisplayController.searchBar.frame];
    [tableHeaderView addSubview:searchDisplayController.searchBar];
    [_tableView setTableHeaderView:tableHeaderView];

    searchedIcons = [NSMutableArray array];    
    isSearching = NO;
    
	return self;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return isSearching ? 1 : 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (isSearching)
    {
        return searchedIcons.count;
    }

    if (section == 0)
    {
        if ([_identifier isEqual:@"com.apple.MobileSMS"] || [_identifier isEqual:@"net.whatsapp.WhatsApp"] || 
            [_identifier isEqual:@"com.skype.skype"] || [_identifier isEqual:@"com.kik.chat"] ||
            [_identifier isEqual:@"com.viber"])
            return 4;
        else
            return 3;
    }
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
        [tableView dequeueReusableCellWithIdentifier:@"Cell"];
        if (cell == nil)
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    

        NSString *alignmentText = @"";
        if (indexPath.row == 0)
            alignmentText = @"Nothing";
        else if (indexPath.row == 1)
            alignmentText = @"Launch Application";
        else if (indexPath.row == 2)
            alignmentText = @"Activator Action";
        else if (indexPath.row == 3)
            alignmentText = @"Launch Associated Quick-Reply";
        
        cell.textLabel.text = alignmentText;
        cell.accessoryType = indexPath.row == tapAction ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        cell.imageView.image = nil;
    }
    else
    {
        [tableView dequeueReusableCellWithIdentifier:@"IconCell"];
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
    
    if (indexPath.section == 0 && !isSearching)
    {
        tapAction = indexPath.row;
        
        if (tapAction == 2) // Activator
        {
            LAEventSettingsController *vc = [[LAEventSettingsController alloc] initWithModes:@[LAEventModeSpringBoard,LAEventModeApplication, LAEventModeLockScreen] eventName:[NSString stringWithFormat:@"%@%@", @"com.efrederickson.protean-",_identifier]];
            [self.rootController pushViewController:vc animated:YES];
        }
    }
    else
    {
        checkedIcon = cell.textLabel.text;
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.efrederickson.protean/refreshStatusBar"), nil, nil, YES);
        PR_AppsControllerNeedsToReload();
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
        NSRange range = [name rangeOfString:searchText options:NSCaseInsensitiveSearch];
        if (range.location != NSNotFound)
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
