#import <Preferences/Preferences.h>

@interface PSViewController (SettingsKit)
-(UINavigationController*)navigationController;
-(void)viewWillAppear:(BOOL)animated;
-(void)viewWillDisappear:(BOOL)animated;
@end

@interface PRSysIconSelectorController : PSViewController <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UISearchDisplayDelegate, UITextFieldDelegate>
{
	NSString* _appName;
	NSString* _identifier;
	UITableView* _tableView;
    NSString* _id;
	UISearchBar* _searchBar;
    BOOL isSearching;
    UISearchDisplayController *searchDisplayController;
}
-(id)initWithAppName:(NSString*)appName identifier:(NSString*)identifier id:(int)id_;
@end
