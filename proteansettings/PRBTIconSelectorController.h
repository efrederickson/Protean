#import <Preferences/Preferences.h>

@interface PSViewController (SettingsKit)
-(UINavigationController*)navigationController;
-(void)viewWillAppear:(BOOL)animated;
-(void)viewWillDisappear:(BOOL)animated;
@end

@interface PRBTIconSelectorController : PSViewController <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UISearchDisplayDelegate>
{
	NSString* _appName;
	NSString* _identifier;
	UITableView* _tableView;
	UISearchBar* _searchBar;
    BOOL isSearching;
    UISearchDisplayController *searchDisplayController;
}
-(id)initWithAppName:(NSString*)appName identifier:(NSString*)identifier;
@end
