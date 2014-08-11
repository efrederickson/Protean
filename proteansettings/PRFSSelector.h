#import <Preferences/Preferences.h>

@interface PRFSSelector : PSViewController <UITableViewDelegate, UITableViewDataSource>
{
	NSString* _appName;
	NSString* _identifier;
	UITableView* _tableView;
}
-(id)initWithFSName:(NSString*)appName identifier:(NSString*)identifier;
@end
