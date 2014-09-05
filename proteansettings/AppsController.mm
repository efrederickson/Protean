#import <Preferences/Preferences.h>
#import <AppList/AppList.h>
#import <UIKit/UISearchBar2.h>
#import "IconSelectorController.h"
#import <substrate.h>

@interface ALApplicationTableDataSource (Private)
- (void)sectionRequestedSectionReload:(id)section animated:(BOOL)animated;
@end

#define PLIST_NAME @"/var/mobile/Library/Preferences/com.efrederickson.protean.settings.plist"

@interface ALLinkCell : ALValueCell
@end

@implementation ALLinkCell
-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	if (!(self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) return nil;
	self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	return self;
}
@end

@interface PSViewController (Protean)
-(void) viewDidLoad;
-(void) viewWillDisappear:(BOOL)animated;
- (void)viewDidAppear:(BOOL)animated;
@end

BOOL reload = NO;
void PR_AppsControllerNeedsToReload()
{
    reload = YES;
}

@interface ProteanAppsController : PSViewController <UITableViewDelegate, UISearchBarDelegate, UISearchDisplayDelegate>
{
	UITableView* _tableView;
	ALApplicationTableDataSource* _dataSource;
	UISearchBar* _searchBar;
    BOOL isSearching;
    UISearchDisplayController *searchDisplayController;
}
@end

@implementation ProteanAppsController

-(void)updateDataSource:(NSString*)searchText
{
	NSNumber *iconSize = [NSNumber numberWithUnsignedInteger:ALApplicationIconSizeSmall];
    
	NSString* excludeList = @
	"and not displayName in {"
    "'DataActivation', "
    "'DemoApp', "
    "'DDActionsService', "
    "'FacebookAccountMigrationDialog', "
    "'FieldTest', "
    "'iAd', "
    "'iAdOptOut', "
    "'iOS Diagnostics', "
    "'iPodOut', "
    "'kbd', "
    "'MailCompositionService', "
    "'MessagesViewService', "
    "'quicklookd', "
    "'Setup', "
    "'ShoeboxUIService', "
    "'SocialUIService', "
    "'TrustMe', "
    "'WebSheet', "
    "'WebViewService'"
	"} "
	"and not bundleIdentifier in {"
    "'com.apple.ios.StoreKitUIService', "
    "'com.apple.gamecenter.GameCenterUIService'"
	"} ";
	
	NSString* enabledList = @"";
    NSMutableDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:PLIST_NAME];
    prefs = prefs ?: [NSMutableDictionary dictionary];
    
	for (NSString* identifier in prefs[@"images"])
	{
        if ([prefs[@"images"][identifier] isEqual:@""] == NO)
            enabledList = [enabledList stringByAppendingString:[NSString stringWithFormat:@"'%@',", identifier]];
	}
    enabledList = [enabledList stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@","]];
	NSString* filter = (searchText && searchText.length > 0) ? [NSString stringWithFormat:@"displayName beginsWith[cd] '%@' %@", searchText, excludeList] : nil;
    
	if (filter)
	{
        //_dataSource.loadsAsynchronously = NO;
		_dataSource.sectionDescriptors = [NSArray arrayWithObjects:
                                          [NSDictionary dictionaryWithObjectsAndKeys:
                                           @"Search Results", ALSectionDescriptorTitleKey,
                                           @"ALLinkCell", ALSectionDescriptorCellClassNameKey,
                                           iconSize, ALSectionDescriptorIconSizeKey,
                                           (id)kCFBooleanTrue, ALSectionDescriptorSuppressHiddenAppsKey,
                                           filter, ALSectionDescriptorPredicateKey
                                           , nil]
                                          , nil];
	}
	else
	{
        //_dataSource.loadsAsynchronously = YES;
        if ([enabledList isEqual:@""])
        {
            _dataSource.sectionDescriptors = [NSArray arrayWithObjects:
                                          [NSDictionary dictionaryWithObjectsAndKeys:
                                           @"User Applications", ALSectionDescriptorTitleKey,
                                           @"ALLinkCell", ALSectionDescriptorCellClassNameKey,
                                           iconSize, ALSectionDescriptorIconSizeKey,
                                           (id)kCFBooleanTrue, ALSectionDescriptorSuppressHiddenAppsKey,
                                           [NSString stringWithFormat:@"containerPath contains[cd] 'var/mobile/Applications' %@ and not bundleIdentifier in {%@}", excludeList, enabledList],
                                           ALSectionDescriptorPredicateKey
                                           , nil],
                                          [NSDictionary dictionaryWithObjectsAndKeys:
                                           @"System Applications", ALSectionDescriptorTitleKey,
                                           @"ALLinkCell", ALSectionDescriptorCellClassNameKey,
                                           iconSize, ALSectionDescriptorIconSizeKey,
                                           (id)kCFBooleanTrue, ALSectionDescriptorSuppressHiddenAppsKey,
                                           [NSString stringWithFormat:@"containerPath = '/Applications' and bundleIdentifier matches 'com.apple.*' %@ and not bundleIdentifier in {%@}", excludeList, enabledList],
                                           ALSectionDescriptorPredicateKey
                                           , nil],
                                          [NSDictionary dictionaryWithObjectsAndKeys:
                                           @"Cydia Applications", ALSectionDescriptorTitleKey,
                                           @"ALLinkCell", ALSectionDescriptorCellClassNameKey,
                                           iconSize, ALSectionDescriptorIconSizeKey,
                                           (id)kCFBooleanTrue, ALSectionDescriptorSuppressHiddenAppsKey,
                                           [NSString stringWithFormat:@"containerPath = '/Applications' and not bundleIdentifier matches 'com.apple.*' %@ and not bundleIdentifier in {%@}", excludeList, enabledList],
                                           ALSectionDescriptorPredicateKey
                                           , nil],
                                          nil];
        }
        else
        {
            _dataSource.sectionDescriptors = [NSArray arrayWithObjects:
                                          [NSDictionary dictionaryWithObjectsAndKeys:
                                           @"Enabled Applications", ALSectionDescriptorTitleKey,
                                           @"ALLinkCell", ALSectionDescriptorCellClassNameKey,
                                           iconSize, ALSectionDescriptorIconSizeKey,
                                           (id)kCFBooleanTrue, ALSectionDescriptorSuppressHiddenAppsKey,
                                           [NSString stringWithFormat:@"bundleIdentifier in {%@}", enabledList],
                                           ALSectionDescriptorPredicateKey
                                           , nil],
                                          [NSDictionary dictionaryWithObjectsAndKeys:
                                           @"User Applications", ALSectionDescriptorTitleKey,
                                           @"ALLinkCell", ALSectionDescriptorCellClassNameKey,
                                           iconSize, ALSectionDescriptorIconSizeKey,
                                           (id)kCFBooleanTrue, ALSectionDescriptorSuppressHiddenAppsKey,
                                           [NSString stringWithFormat:@"containerPath contains[cd] 'var/mobile/Applications' %@ and not bundleIdentifier in {%@}", excludeList, enabledList],
                                           ALSectionDescriptorPredicateKey
                                           , nil],
                                          [NSDictionary dictionaryWithObjectsAndKeys:
                                           @"System Applications", ALSectionDescriptorTitleKey,
                                           @"ALLinkCell", ALSectionDescriptorCellClassNameKey,
                                           iconSize, ALSectionDescriptorIconSizeKey,
                                           (id)kCFBooleanTrue, ALSectionDescriptorSuppressHiddenAppsKey,
                                           [NSString stringWithFormat:@"containerPath = '/Applications' and bundleIdentifier matches 'com.apple.*' %@ and not bundleIdentifier in {%@}", excludeList, enabledList],
                                           ALSectionDescriptorPredicateKey
                                           , nil],
                                          [NSDictionary dictionaryWithObjectsAndKeys:
                                           @"Cydia Applications", ALSectionDescriptorTitleKey,
                                           @"ALLinkCell", ALSectionDescriptorCellClassNameKey,
                                           iconSize, ALSectionDescriptorIconSizeKey,
                                           (id)kCFBooleanTrue, ALSectionDescriptorSuppressHiddenAppsKey,
                                           [NSString stringWithFormat:@"containerPath = '/Applications' and not bundleIdentifier matches 'com.apple.*' %@ and not bundleIdentifier in {%@}", excludeList, enabledList],
                                           ALSectionDescriptorPredicateKey
                                           , nil],
                                          nil];
        }
	}
    [_tableView reloadData];
}

-(id)init
{
	if (!(self = [super init])) return nil;
	
	CGRect bounds = [[UIScreen mainScreen] bounds];
	
	_dataSource = [[ALApplicationTableDataSource alloc] init];
    
	_tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, bounds.size.width, bounds.size.height) style:UITableViewStyleGrouped];
	_tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	_tableView.delegate = self;
	_tableView.dataSource = _dataSource;
	_dataSource.tableView = _tableView;
	[self updateDataSource:nil];
	
    _searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    _searchBar.delegate = self;
    _searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	if ([_searchBar respondsToSelector:@selector(setUsesEmbeddedAppearance:)])
		[_searchBar setUsesEmbeddedAppearance:true];

    
    searchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:_searchBar contentsController:(UIViewController*)self];
    searchDisplayController.delegate = self;
    searchDisplayController.searchResultsDataSource = _dataSource;
    searchDisplayController.searchResultsDelegate = self;
    
    UIView *tableHeaderView = [[UIView alloc] initWithFrame:searchDisplayController.searchBar.frame];
    [tableHeaderView addSubview:searchDisplayController.searchBar];
    [_tableView setTableHeaderView:tableHeaderView];
    
    isSearching = NO;
    
	return self;
}

-(void)viewDidLoad
{
	((UIViewController *)self).title = @"Applications";
	
	[self.view addSubview:_tableView];
    
	[super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated
{
    if (reload)
    {
        [self updateDataSource:nil];
        reload = NO;
    }
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

-(void)searchBar:(UISearchBar*)searchBar textDidChange:(NSString*)searchText
{
	[self updateDataSource:searchText];
    [_tableView reloadData];
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    UISearchBar *searchBar = searchDisplayController.searchBar;
    CGRect searchBarFrame = searchBar.frame;
    
    if (isSearching) {
        searchBarFrame.origin.y = 0;
    } else {
        searchBarFrame.origin.y = 0; //MAX(0, scrollView.contentOffset.y + scrollView.contentInset.top);
    }
    
    searchDisplayController.searchBar.frame = searchBarFrame;
}

- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller {
    isSearching = YES;
    _dataSource.tableView = searchDisplayController.searchResultsTableView;
}

-(void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller {
    isSearching = NO;
	[self updateDataSource:nil];
    _dataSource.tableView = _tableView;
}

-(void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
	UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
    
	// Need to mimic what PSListController does when it handles didSelectRowAtIndexPath
	// otherwise the child controller won't load
	PRIconSelectorController* controller = [[PRIconSelectorController alloc]
                                                initWithAppName:cell.textLabel.text
                                                identifier:[_dataSource displayIdentifierForIndexPath:indexPath]
                                                ];
	controller.rootController = self.rootController;
	controller.parentController = self;
	
	[self pushController:controller];
	[tableView deselectRowAtIndexPath:indexPath animated:true];
}

@end