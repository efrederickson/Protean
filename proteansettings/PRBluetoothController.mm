#import <Preferences/Preferences.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "PRBTIconSelectorController.h"

@interface PSViewController (Protean)
-(UINavigationController*)navigationController;
-(void)viewWillAppear:(BOOL)animated;
-(void) viewDidLoad;
-(void) viewWillDisappear:(BOOL)animated;
-(void) setView:(id)view;
-(void) setTitle:(NSString*)title;
- (void)viewDidDisappear:(BOOL)animated;
@end
@interface UIImage (Protean)
+ (UIImage*)imageNamed:(NSString *)imageName inBundle:(NSBundle*)bundle;
- (UIImage*) _flatImageWithColor: (UIColor*) color;
@end
@interface BluetoothManager
+ (id)sharedInstance;
- (NSArray*)pairedDevices;
@end
@interface BluetoothDevice
-(id) name;
@end

@interface PRBluetoothController : PSViewController <UITableViewDelegate, UITableViewDataSource>
{
	UITableView* _tableView;
}
@end

@implementation PRBluetoothController

-(id)init
{
	if (!(self = [super init])) return nil;
	
	CGRect bounds = [[UIScreen mainScreen] bounds];
	
	_tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, bounds.size.width, bounds.size.height) style:UITableViewStyleGrouped];
	_tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	_tableView.delegate = self;
	_tableView.dataSource = self;
    
	return self;
}

-(void)viewDidLoad
{
	((UIViewController *)self).title = @"Bluetooth Devices";
	
	[self setView:_tableView];
    
	[super viewDidLoad];
}

-(void) viewWillAppear:(BOOL) animated
{
    [_tableView reloadData]; 
    ((UIView*)self.view).tintColor = self.tintColor;
    self.navigationController.navigationBar.tintColor = self.tintColor;

    [super viewWillAppear:animated];
}

-(UIColor*) tintColor { return [UIColor colorWithRed:79/255.0f green:176/255.0f blue:136/255.0f alpha:1.0f]; }

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    ((UIView*)self.view).tintColor = nil;
    self.navigationController.navigationBar.tintColor = nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [[BluetoothManager sharedInstance] pairedDevices].count > 0 ? @"Connected Devices" : @"";
}

-(void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
	UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
    
	// Need to mimic what PSListController does when it handles didSelectRowAtIndexPath
	// otherwise the child controller won't load
	PRBTIconSelectorController* controller = [[PRBTIconSelectorController alloc]
                                initWithAppName:cell.textLabel.text
                                identifier:cell.textLabel.text
                                ];
	controller.rootController = self.rootController;
	controller.parentController = self;
	
	[self pushController:controller];
     
	[tableView deselectRowAtIndexPath:indexPath animated:true];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[BluetoothManager sharedInstance] pairedDevices].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    
    cell.textLabel.text = ((BluetoothDevice*)[[BluetoothManager sharedInstance] pairedDevices][indexPath.row]).name; //.identifier.UUIDString;
    cell.imageView.image = nil;
    
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
	if ([[BluetoothManager sharedInstance] pairedDevices].count > 0)
		return nil;

    UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 5, [UIScreen mainScreen].bounds.size.width, 80)];
    footer.backgroundColor = [UIColor clearColor];
    
    UILabel *lbl = [[UILabel alloc] initWithFrame:footer.frame];
    lbl.backgroundColor = [UIColor clearColor];
    lbl.text = @"Please connect to a Bluetooth device\n to use this feature.";
    lbl.textAlignment = NSTextAlignmentCenter;
    lbl.numberOfLines = 2;
    lbl.font = [UIFont fontWithName:@"HelveticaNueue-UltraLight" size:5];
    lbl.textColor = [UIColor darkGrayColor];
    lbl.lineBreakMode = NSLineBreakByWordWrapping;
    [footer addSubview:lbl];
    
    return footer;
}
@end