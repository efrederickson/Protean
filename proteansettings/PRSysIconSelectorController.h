#import <Preferences/Preferences.h>

@interface PRSysIconSelectorController : PSViewController <UITableViewDelegate, UITableViewDataSource>
{
	NSString* _appName;
	NSString* _identifier;
	UITableView* _tableView;
    NSString* _id;
}
-(id)initWithAppName:(NSString*)appName identifier:(NSString*)identifier id:(int)id_;
@end
