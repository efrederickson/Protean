#import <Preferences/Preferences.h>

@interface PRIconSelectorController : PSViewController <UITableViewDelegate, UITableViewDataSource>
{
	NSString* _appName;
	NSString* _identifier;
	UITableView* _tableView;
}
-(id)initWithAppName:(NSString*)appName identifier:(NSString*)identifier;
@end
