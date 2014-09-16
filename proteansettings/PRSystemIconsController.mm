#import <Preferences/Preferences.h>
#import <AppList/AppList.h>
#import <objcipc/objcipc.h>
#import "PRSysIconSelectorController.h"
#define PLIST_NAME @"/var/mobile/Library/Preferences/com.efrederickson.protean.settings.plist"


@interface PSViewController ()
-(void) setView:(id)view;
-(UINavigationController*)navigationController;
-(void)viewWillAppear:(BOOL)animated;
-(void)viewWillDisappear:(BOOL)animated;
@end
@interface UIApplication (Protean)
-(id) statusBar;
@end
@interface UIStatusBar
- (void)_setStyle:(id)arg1;
- (int)legibilityStyle;
- (id)initWithFrame:(CGRect)arg1 showForegroundView:(BOOL)arg2 inProcessStateProvider:(id)arg3;
- (id)initWithFrame:(CGRect)arg1 showForegroundView:(BOOL)arg2;
- (id)initWithFrame:(CGRect)arg1;

- (void)_crossfadeToNewBackgroundView;
- (void)_crossfadeToNewForegroundViewWithAlpha:(float)arg1;
- (void)crossfadeTime:(BOOL)arg1 duration:(double)arg2;
- (void)setShowsOnlyCenterItems:(BOOL)arg1;

- (UIView *)snapshotViewAfterScreenUpdates:(BOOL)afterUpdates;
-(id) superview;
-(CGRect)frame;
-(void) setFrame:(CGRect)frame;
@end
@interface UIImage (Protean)
+ (UIImage*)imageNamed:(NSString *)imageName inBundle:(NSBundle*)bundle;
@end

extern NSString *nameForDescription(NSString *desc);
extern UIImage *iconForDescription(NSString *desc);
extern NSNumberFormatter *numberFormatter;

NSMutableArray *mapSettingsForSysIcons()
{
    static NSArray *systemItems = @[@0, @1, @2, @3, @4, @5, @7, @8, @9, @10, @11, @12, @13, @16, @17, @19, @20, @21, @22, @23, @24, @28];
    
    NSMutableArray *mapped = [NSMutableArray array];
    
    NSDictionary *prefs = [NSDictionary
                           dictionaryWithContentsOfFile:PLIST_NAME];
    if (prefs == nil)
        prefs = [NSDictionary dictionary];
    
    for (id key in prefs)
    {
        NSNumber *num = [numberFormatter numberFromString:key];
        if (num == nil)
            continue;
        
        if ([systemItems containsObject:num] == NO)
            continue; // Not an allowed/actual system item
        
        NSMutableDictionary *d = prefs[key];
        
        [mapped addObject:d];
    }
    
    return mapped;
}

@interface PRSystemIconsController : PSViewController<UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView * tableView;
@end

@implementation PRSystemIconsController
-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        [cell setSelectionStyle:UITableViewCellSelectionStyleBlue];
    }
    
    NSString *desc = [mapSettingsForSysIcons() objectAtIndex:indexPath.row][@"identifier"];
    
    cell.textLabel.text = nameForDescription(desc);
    cell.imageView.image = iconForDescription(desc);
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return mapSettingsForSysIcons().count;
}

- (id)initForContentSize:(CGSize)size
{
    if ((self = [super initForContentSize:size]))
    {
        self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height) style:UITableViewStyleGrouped];
        
        [self.tableView setDelegate:self];
        [self.tableView setDataSource:self];
        [self.tableView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
        [self.tableView setEditing:NO];
        [self.tableView setAllowsSelection:YES];
        
        [self setView:self.tableView];
    }

    ((UIViewController *)self).title = @"System Icons";
    
    return self;
}

-(void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
	UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
    
	// Need to mimic what PSListController does when it handles didSelectRowAtIndexPath
	// otherwise the child controller won't load
	PRSysIconSelectorController* controller = [[PRSysIconSelectorController alloc]
                                            initWithAppName:cell.textLabel.text
                                               identifier:[mapSettingsForSysIcons() objectAtIndex:indexPath.row][@"identifier"]
                                               id:[[mapSettingsForSysIcons() objectAtIndex:indexPath.row][@"key"] intValue]
                                            ];
	controller.rootController = self.rootController;
	controller.parentController = self;
	
	[self pushController:controller];
	[tableView deselectRowAtIndexPath:indexPath animated:true];
}

-(UIColor*) tintColor { return [UIColor colorWithRed:79/255.0f green:176/255.0f blue:136/255.0f alpha:1.0f]; }

- (void)viewWillAppear:(BOOL)animated {
    ((UIView*)self.view).tintColor = self.tintColor;
    self.navigationController.navigationBar.tintColor = self.tintColor;

    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    ((UIView*)self.view).tintColor = nil;
    self.navigationController.navigationBar.tintColor = nil;
}
@end
