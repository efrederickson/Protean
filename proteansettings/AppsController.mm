#import <Preferences/Preferences.h>
#import <AppList/AppList.h>
#import <UIKit/UISearchBar2.h>
#import "IconSelectorController.h"

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

@interface ProteanAppsController : PSViewController <UITableViewDelegate, UISearchBarDelegate>
{
	UITableView* _tableView;
	ALApplicationTableDataSource* _dataSource;
	UISearchBar* _searchBar;
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
		_dataSource.sectionDescriptors = [NSArray arrayWithObjects:
                                          [NSDictionary dictionaryWithObjectsAndKeys:
                                           @"ALLinkCell", ALSectionDescriptorCellClassNameKey,
                                           iconSize, ALSectionDescriptorIconSizeKey,
                                           (id)kCFBooleanTrue, ALSectionDescriptorSuppressHiddenAppsKey,
                                           filter, ALSectionDescriptorPredicateKey
                                           , nil]
                                          , nil];
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
	
	// Search Bar
	_searchBar = [[UISearchBar alloc] initWithFrame:CGRectZero];
	_searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	if ([_searchBar respondsToSelector:@selector(setUsesEmbeddedAppearance:)])
		[_searchBar setUsesEmbeddedAppearance:true];
	_searchBar.delegate = self;
	
	NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(keyboardWillShowWithNotification:) name:UIKeyboardWillShowNotification object:nil];
	[nc addObserver:self selector:@selector(keyboardWillHideWithNotification:) name:UIKeyboardWillHideNotification object:nil];
	
	return self;
}

-(void)viewDidLoad
{
	((UIViewController *)self).title = @"Applications";
	
	UIEdgeInsets insets = UIEdgeInsetsMake(44.0f, 0, 0, 0);
	_tableView.contentInset = insets;
	_tableView.contentOffset = CGPointMake(0, 12.0f);
	insets.top = 0;
	_tableView.scrollIndicatorInsets = insets;
	_searchBar.frame = CGRectMake(0, -44.0f, _tableView.bounds.size.width, 44.0f);
	
	[_tableView addSubview:_searchBar];
	[self.view addSubview:_tableView];
	[super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self updateDataSource:nil];
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	[_searchBar resignFirstResponder];
}

-(void)keyboardWillShowWithNotification:(NSNotification*)notification
{
	[UIView beginAnimations:nil context:nil];
	NSDictionary* userInfo = notification.userInfo;
	[UIView setAnimationDuration:[[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
	[UIView setAnimationCurve:(UIViewAnimationCurve)[[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue]];
	CGRect keyboardFrame = CGRectZero;
	[[userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardFrame];
	UIEdgeInsets insets = UIEdgeInsetsMake(110.0f, 0, keyboardFrame.size.height, 0);
	_tableView.contentInset = insets;
	insets.top = 0;
	_tableView.scrollIndicatorInsets = insets;
	[UIView commitAnimations];
}

- (void)keyboardWillHideWithNotification:(NSNotification *)notification
{
	[UIView beginAnimations:nil context:nil];
	NSDictionary* userInfo = notification.userInfo;
	[UIView setAnimationDuration:[[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
	[UIView setAnimationCurve:(UIViewAnimationCurve)[[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue]];
    UIEdgeInsets insets = UIEdgeInsetsMake(110.0f, 0, 0, 0);
	_tableView.contentInset = insets;
    insets.top = 0.0f;
    _tableView.scrollIndicatorInsets = insets;
	[UIView commitAnimations];
}

-(void)searchBarTextDidBeginEditing:(UISearchBar*)searchBar
{
	[_searchBar setShowsCancelButton:true animated:true];
}

-(void)searchBarTextDidEndEditing:(UISearchBar*)searchBar
{
	[_searchBar setShowsCancelButton:false animated:true];
}

-(void)searchBarSearchButtonClicked:(UISearchBar*)searchBar
{
	[_searchBar resignFirstResponder];
}

-(void)searchBarCancelButtonClicked:(UISearchBar*)searchBar
{
	_searchBar.text = nil;
	[self updateDataSource:nil];	
	[_searchBar resignFirstResponder];
	_tableView.contentOffset = CGPointMake(0, -44.0f);
}

-(void)searchBar:(UISearchBar*)searchBar textDidChange:(NSString*)searchText
{
	[self updateDataSource:searchText];
    //	_tableView.contentOffset = CGPointMake(0, -44.0f);
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