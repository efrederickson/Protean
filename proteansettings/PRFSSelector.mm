#import "PRFSSelector.h"
#import <AppList/AppList.h>
#import <libactivator/libactivator.h>
#define PLIST_NAME @"/var/mobile/Library/Preferences/com.efrederickson.protean.settings.plist"

extern "C" CFNotificationCenterRef CFNotificationCenterGetDistributedCenter(void);

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

@interface PRFSSelector () {
    int tapAction;
    BOOL enabled;
}
@end

@implementation PRFSSelector

-(id)initWithFSName:(NSString*)appName identifier:(NSString*)identifier
{
    tapAction = 0;
    
	_appName = appName;
	_identifier = identifier;
	return [self init];
}

-(void) updateSavedData
{
    NSMutableDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:PLIST_NAME];
    prefs = prefs ?: [NSMutableDictionary dictionary];
    
    prefs[@"tapActions"] = prefs[@"tapActions"] ? [prefs[@"tapActions"] mutableCopy]: [NSMutableDictionary dictionary];
    prefs[@"tapActions"][_identifier] = [NSNumber numberWithInt:tapAction==1?2:0] ?: @0;
    
    prefs[@"flipswitches"] = prefs[@"flipswitches"] ? [prefs[@"flipswitches"] mutableCopy]: [NSMutableDictionary dictionary];
    prefs[@"flipswitches"][_identifier] = enabled ? @YES : @NO;
    
    [prefs writeToFile:PLIST_NAME atomically:YES];
    CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), CFSTR("com.efrederickson.protean/reloadSettings"), nil, nil, YES);
}

-(id)init
{
	if ((self = [super init]) == nil) return nil;
	
    NSMutableDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:PLIST_NAME];
    prefs = prefs ?: [NSMutableDictionary dictionary];
    
    tapAction = [([prefs[@"tapActions"] mutableCopy] ?: [NSMutableDictionary dictionary])[_identifier] intValue] == 2 ? 1 : 0 ?: 0;
    enabled = [([prefs[@"flipswitches"] mutableCopy] ?: [NSMutableDictionary dictionary])[_identifier] boolValue] ?: NO;
    
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
    
	return self;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
        return 1;
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0)
        return @"Enabled";
    return @"Icon Tap";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    
    if (indexPath.section == 0)
    {
        cell.textLabel.text = @"Enabled";
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
        cell.accessoryView = switchView;
        [switchView setOn:enabled animated:NO];
        [switchView addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    }
    else
    {
        NSString *alignmentText = @"";
        if (indexPath.row == 0)
            alignmentText = @"Nothing";
        //else if (indexPath.row == 1)
        //    alignmentText = @"Open Settings Panel";
        else if (indexPath.row == 1)
            alignmentText = @"Activator Action";
        
        cell.textLabel.text = alignmentText;
        cell.accessoryType = indexPath.row == tapAction ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }
    return cell;
}

- (void) switchChanged:(id)sender {
    UISwitch* switchControl = sender;
    enabled = switchControl.on;
    [self updateSavedData];
}

-(void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
	UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
    
    if (indexPath.section == 1)
    {
        tapAction = indexPath.row;
        
        if (tapAction == 1) // Activator
        {
            LAEventSettingsController *vc = [[LAEventSettingsController alloc] initWithModes:@[LAEventModeSpringBoard,LAEventModeApplication, LAEventModeLockScreen] eventName:[NSString stringWithFormat:@"%@%@", @"com.efrederickson.protean-",_identifier]];
            [self.rootController pushViewController:vc animated:YES];
        }
    }
    
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    [self updateSavedData];
    [tableView reloadData];
}

@end
