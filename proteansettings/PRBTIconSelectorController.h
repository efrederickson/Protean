#import <Preferences/Preferences.h>

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
