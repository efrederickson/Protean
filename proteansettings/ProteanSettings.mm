#import <Preferences/Preferences.h>
#import <SettingsKit/SKListControllerProtocol.h>
#import <SettingsKit/SKTintedListController.h>
#import <objc/runtime.h>
#import "IconSelectorController.h"
#import <MessageUI/MFMailComposeViewController.h>
#import <notify.h>
#import "UIDiscreteSlider.h"
#import "../Protean.h"
#include <sys/sysctl.h>
#include <sys/utsname.h>

extern NSString *const PSControlMinimumKey;
extern NSString *const PSControlMaximumKey;

@interface PSListController (SettingsKit)
-(UIView*)view;
-(UINavigationController*)navigationController;
-(void)viewWillAppear:(BOOL)animated;
-(void)viewWillDisappear:(BOOL)animated;
-(void)viewDidDisappear:(BOOL)animated;

- (void)presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion;
- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion;
-(UINavigationController*)navigationController;

-(void)loadView;
@end

@interface ProteanSettingsListController : SKTintedListController<SKListControllerProtocol, MFMailComposeViewControllerDelegate>
@end

@interface PRAdvancedSettingsListController : SKTintedListController<SKListControllerProtocol, UIAlertViewDelegate>
@end

@interface PSViewController ()
-(void) setView:(id)view;
-(void) setTitle:(NSString*)title;
@end
@interface PRDocumentationListController : PSViewController <UIWebViewDelegate>
@end

@interface PSSliderTableCell : PSControlTableCell
@end

@interface PRButtonPlusMinusThingCell : PSControlTableCell
@property (nonatomic) UIStepper *stepper;
@end
@implementation PRButtonPlusMinusThingCell
- (void)prepareForReuse {
    [super prepareForReuse];
    self.stepper.value = 0;
    self.stepper.minimumValue = 0;
    self.stepper.maximumValue = 1;
}

- (void)refreshCellContentsWithSpecifier:(PSSpecifier *)specifier {
    [super refreshCellContentsWithSpecifier:specifier];
    self.stepper.minimumValue = ((NSNumber *)specifier.properties[PSControlMinimumKey]).doubleValue;
    self.stepper.maximumValue = ((NSNumber *)specifier.properties[PSControlMaximumKey]).doubleValue;
    [self updateUI];
}

- (UIStepper *)newControl {
    UIStepper *stepper = [[UIStepper alloc] init];
    stepper.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    stepper.continuous = NO;
    stepper.center = CGPointMake(stepper.center.x, self.frame.size.height / 2);
    CGRect frame = stepper.frame;
    frame.origin.x = self.contentView.frame.size.width - frame.size.width - 10;
    stepper.frame = frame;
    self.stepper = stepper;
    return stepper;
}

- (NSNumber *)controlValue {
    return @(self.stepper.value);
}

- (void)setValue:(NSNumber *)value {
    [super setValue:value];
    self.stepper.value = value.doubleValue;
}

- (void)controlChanged:(UIStepper *)stepper {
    [super controlChanged:stepper];
    [self updateUI];
}

- (void)updateUI {
    if (!self.stepper) {
        return;
    }

    if ((int)self.stepper.value == 1)
        self.textLabel.text = [NSString stringWithFormat:@"%d Spacer", (int)self.stepper.value];
    else
        self.textLabel.text = [NSString stringWithFormat:@"%d Spacers", (int)self.stepper.value];
    [self setNeedsLayout];
}
@end

@interface PRDiscreteSliderCell : PSSliderTableCell
@end
@implementation PRDiscreteSliderCell
- (id)initWithStyle:(UITableViewCellStyle)arg1 reuseIdentifier:(id)arg2 specifier:(id)arg3 
{
    self = [super initWithStyle:arg1 reuseIdentifier:arg2 specifier:arg3];
    
    if (self) 
    {     
        UIDiscreteSlider *actual = [[UIDiscreteSlider alloc] initWithFrame:self.control.frame];
        [actual addTarget:self action:@selector(saveValue) forControlEvents:UIControlEventTouchUpInside];
        actual.increment = [([self.specifier propertyForKey:@"increment"] ?: @1) floatValue];

        [self setControl:actual];
    }

    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    NSNumber *value = [objc_getClass("Protean") getOrLoadSettings][[self.specifier propertyForKey:@"key"]];
    UIDiscreteSlider *slider = (UIDiscreteSlider*)self.control;
    slider.value = value ? [value floatValue] : [[self.specifier propertyForKey:@"default"] floatValue];
}

- (void)saveValue
{
    UIDiscreteSlider *slider = (UIDiscreteSlider*)self.control;
    NSNumber *value = @(slider.value);

    NSString *plistName = [NSString stringWithFormat:@"/User/Library/Preferences/%@.plist",[self.specifier propertyForKey:@"defaults"]];
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:plistName];
    [dict setObject:value forKey:@"numSpacers"];
    [dict writeToFile:plistName atomically:YES];
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.efrederickson.protean/reloadSettings"), nil, nil, YES);
}
@end
@interface PRDiscreteSliderCell2 : PSSliderTableCell
@end
@implementation PRDiscreteSliderCell2
- (id)initWithStyle:(UITableViewCellStyle)arg1 reuseIdentifier:(id)arg2 specifier:(id)arg3 
{
    self = [super initWithStyle:arg1 reuseIdentifier:arg2 specifier:arg3];
    
    if (self) 
    {     
        UIDiscreteSlider *actual = [[UIDiscreteSlider alloc] initWithFrame:self.control.frame];
        [actual addTarget:self action:@selector(saveValue) forControlEvents:UIControlEventTouchUpInside];
        actual.increment = 0.5;

        [self setControl:actual];
    }

    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    NSNumber *value = [objc_getClass("Protean") getOrLoadSettings][[self.specifier propertyForKey:@"key"]];
    UIDiscreteSlider *slider = (UIDiscreteSlider*)self.control;
    slider.value = value ? [value floatValue] : [[self.specifier propertyForKey:@"default"] floatValue];
}

- (void)saveValue
{
    UIDiscreteSlider *slider = (UIDiscreteSlider*)self.control;
    NSNumber *value = @(slider.value);

    NSString *plistName = [NSString stringWithFormat:@"/User/Library/Preferences/%@.plist",[self.specifier propertyForKey:@"defaults"]];
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:plistName];
    [dict setObject:value forKey:@"padding"];
    [dict writeToFile:plistName atomically:YES];
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.efrederickson.protean/reloadSettings"), nil, nil, YES);
}
@end

@implementation ProteanSettingsListController
-(NSString*) headerText { return @"Protean"; }
-(NSString*) headerSubText 
{
    NSArray *choices = @[ 
        @"Your status bar, your way",
        @"The ultimate status bar customizer",
        @"By Elijah and Andrew",
        @"Status bar is looking splendid today!",
    ]; 

    NSUInteger randomIndex = arc4random() % [choices count];
    return choices[randomIndex];
}
-(NSString*) customTitle { return @""; }

-(NSString*) shareMessage { return @"I'm using #Protean by @daementor and @drewplex: your status bar, your way."; }

-(UIColor*) navigationTintColor { return [UIColor colorWithRed:79/255.0f green:176/255.0f blue:136/255.0f alpha:1.0f]; }
-(UIColor*) switchOnTintColor { return self.navigationTintColor; }
-(UIColor*) iconColor { return self.navigationTintColor; }
-(UIColor*) headerColor { return [UIColor colorWithRed:74/255.0f green:74/255.0f blue:74/255.0f alpha:1.0f]; }
//-(UIColor*) tintColor { return self.navigationTintColor; }

-(NSArray*) customSpecifiers
{
    return @[
             
             @{ @"cell": @"PSGroupCell"
                },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @YES,
                 @"defaults": @"com.efrederickson.protean.settings",
                 @"key": @"enabled",
                 @"label": @"Enabled",
                 @"PostNotification": @"com.efrederickson.protean/reloadSettings",
                 //@"cellClass": @"SKTintedSwitchCell",
                 @"icon": @"enabled.png",
                 },

             @{ @"cell": @"PSGroupCell",
                @"footerText": @"Items do not show up until they have appeared in your status bar.",// Libstatusbar items cannot be in the center, and a respring will be needed to apply changes to them."
                @"footerText": @"Modify the arrangement of status bar items.",
                },
             @{
                 @"cell": @"PSLinkListCell",
                 //@"cellClass": @"SKTintedCell",
                 @"detail": @"PROrganizationController",
                 @"label": @"Organization",
                 @"icon": @"organization.png"
                 },
             
             @{ @"cell": @"PSGroupCell",
                @"footerText": @"Select applications, flipswitches, and others to be represented by a glyph in the status bar."
                },
             @{
                 @"cell": @"PSLinkListCell",
                 //@"cellClass": @"SKTintedCell",
                 @"action": @"pushTotalNotificationCountController",
                 @"label": @"Total Notification Count",
                 @"icon": @"tnc.png"
                 },
             @{
                 @"cell": @"PSLinkListCell",
                 //@"cellClass": @"SKTintedCell",
                 @"detail": @"ProteanAppsController",
                 @"label": @"App Notifications",
                 @"icon": @"applications.png"
                 },
             @{
                 @"cell": @"PSLinkListCell",
                 //@"cellClass": @"SKTintedCell",
                 @"detail": @"PRSystemIconsController",
                 @"label": @"System Icons",
                 @"icon": @"sysicons.png"
                 },
             @{
               @"cell": @"PSLinkListCell",
               //@"cellClass": @"SKTintedCell",
               @"detail": @"PRFlipswitchController",
               @"label": @"Flipswitches",
               @"icon": @"flipswitches.png"
               },
             @{
                 @"cell": @"PSLinkListCell",
                 //@"cellClass": @"SKTintedCell",
                 @"detail": @"PRBluetoothController",
                 @"label": @"Bluetooth Devices",
                 @"icon": @"bluetooth.png"
                 },


            @{ },
            @{
                @"cell": @"PSLinkListCell",
                //@"cellClass": @"SKTintedCell",
                @"detail": @"PRAdvancedSettingsListController",
                @"label": @"Advanced Options",
                @"icon": @"settings.png"
            },
             
             @{ @"cell": @"PSGroupCell" },
             @{
                 @"cell": @"PSLinkCell",
                 @"detail": @"PRMakersListController",
                 @"label": @"Credits & Recommendations",
                 @"icon": @"makers.png",
                 //@"cellClass": @"SKTintedCell",
                 },

             @{ @"cell": @"PSGroupCell" },
             @{
                 @"cell": @"PSLinkCell",
                 @"detail": @"PRDocumentationListController",
                 @"label": @"Documentation",
                 @"icon": @"documentation.png",
                 //@"cellClass": @"SKTintedCell",
                 },
             
             @{ @"cell": @"PSGroupCell",
                @"footerText": [NSString stringWithFormat:@"© 2014-2015 Elijah Frederickson & Andrew Abosh.%@%@", 
                    LIBSTATUSBAR8 ? @"\nLibStatusBar8 support is in use." : @"",
                    [objc_getClass("LibStatusBar8") respondsToSelector:@selector(getCurrentExtensions)] ? [NSString stringWithFormat:@"\n%ld Current LibStatusBar8 extension(s) in use.",(unsigned long)[objc_getClass("LibStatusBar8") getCurrentExtensions].count] : @"" ] },
             @{
                 @"cell": @"PSLinkCell",
                 @"action": @"showSupportDialog",
                 @"label": @"Support",
                 @"icon": @"support.png",
                 },
             ];
}

-(void) showSupportDialog
{
    MFMailComposeViewController *mailViewController;
    if ([MFMailComposeViewController canSendMail])
    {
        mailViewController = [[MFMailComposeViewController alloc] init];
        mailViewController.mailComposeDelegate = self;
        [mailViewController setSubject:@"Protean"];
        
        struct utsname systemInfo;
        uname(&systemInfo);
        NSString *sysInfo = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
        
        NSString *msg = [NSString stringWithFormat:@"\n\n%@ %@\nModel: %@\nProtean version: %@\nLibstatusbar8: %@", [UIDevice currentDevice].systemName, [UIDevice currentDevice].systemVersion, sysInfo, 
            PROTEAN_VERSION, LIBSTATUSBAR8 ? @"Yes" : @"No"];
        [mailViewController setMessageBody:msg isHTML:NO];
        [mailViewController setToRecipients:@[@"elijahandandrew@gmail.com"]];
            
        [self.rootController presentViewController:mailViewController animated:YES completion:nil];
    }

}

-(void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

-(void) pushTotalNotificationCountController
{
	PRIconSelectorController* controller = [[PRIconSelectorController alloc]
                                            initWithAppName:@"Total Notification Count"
                                            identifier:@"TOTAL_NOTIFICATION_COUNT"
                                            ];
	controller.rootController = self.rootController;
	controller.parentController = self;
	
	[self pushController:controller];
}

-(void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier
{
    //[super setPreferenceValue:value specifier:specifier];
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.efrederickson.protean.settings.plist"];
    [dict setObject:value forKey:[specifier propertyForKey:@"key"]];
    [dict writeToFile:@"/var/mobile/Library/Preferences/com.efrederickson.protean.settings.plist" atomically:YES];
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.efrederickson.protean/reloadSettings"), nil, nil, YES);
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.efrederickson.protean/refreshStatusBar"), nil, nil, YES);
}

 -(id)readPreferenceValue:(PSSpecifier*)specifier
 {
    NSString *plistName = [NSString stringWithFormat:@"/User/Library/Preferences/%@.plist",[specifier propertyForKey:@"defaults"]];
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:plistName];
    return dict[[specifier propertyForKey:@"key"]]; 
 }

-(void) viewWillAppear:(BOOL) animated
{
    [super viewWillAppear:animated];
    self.title = @"";
}

-(void) viewWillDisappear:(BOOL) animated
{
    [super viewWillDisappear:animated];
    self.title = @"Protean";
}
@end

@implementation PRAdvancedSettingsListController
-(BOOL) showHeartImage { return NO; }
-(UIColor*) navigationTintColor { return [UIColor colorWithRed:79/255.0f green:176/255.0f blue:136/255.0f alpha:1.0f]; }
-(UIColor*) switchOnTintColor { return self.navigationTintColor; }
-(UIColor*) iconColor { return self.navigationTintColor; }
-(UIColor*) headerColor { return [UIColor colorWithRed:74/255.0f green:74/255.0f blue:74/255.0f alpha:1.0f]; }

-(NSArray*) customSpecifiers {
    BOOL supportsExtendedBattery = YES; // objc_getClass("PLBatteryPropertiesEntry") != nil; /* This would happen after BatteryPercent maybe-loads PowerlogLoggerSupport.framework on process initialization. */
    NSNumber *defaultPadding = ((NSDictionary*)[objc_getClass("Protean") performSelector:@selector(getOrLoadSettings)])[@"defaultPadding"] ?: @6;

    return @[
                @{ 
                 @"cell": @"PSGroupCell",
                 @"label": @"Item Spacing",
                 @"footerText": @"Change the spacing between items."
                 },
                @{
                 @"cell": @"PSSliderCell",
                 @"cellClass": @"PRDiscreteSliderCell2",
                 @"default": defaultPadding,
                 @"defaults": @"com.efrederickson.protean.settings",
                 @"key": @"padding",
                 @"PostNotification": @"com.efrederickson.protean/reloadSettings",
                 @"min": @0,
                 @"max": @10,
                 @"increment": @0.5,
                 @"showValue": @YES,
                 },

                @{ 
                 @"cell": @"PSGroupCell",
                 @"label": @"Number of Spacers",
                 @"footerText": @"Change the number of spacers available."
                 },
                @{
                 @"cell": @"PSSliderCell",
                 @"cellClass": @"PRButtonPlusMinusThingCell",
                 @"default": @0,
                 @"defaults": @"com.efrederickson.protean.settings",
                 @"key": @"numSpacers",
                 @"PostNotification": @"com.efrederickson.protean/reloadSettings",
                 @"min": @0,
                 @"max": @50,
                 //@"increment": @1,
                 //@"showValue": @YES,
                 @"label": @"%d Spacer(s)"
                 },

             	@{ 
        		 @"cell": @"PSGroupCell",
                 @"footerText": @"Equalizes the height of the lock screen and home screen status bar."
                 },
                @{
                 @"cell": @"PSSwitchCell",
                 @"default": @YES,
                 @"defaults": @"com.efrederickson.protean.settings",
                 @"key": @"normalizeLS",
                 @"label": @"Normalize Lock Screen",
                 @"PostNotification": @"com.efrederickson.protean/reloadSettings",
                 @"icon": @"normalizeLS.png"
                 },
                
                /*@{},
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @NO,
                 @"defaults": @"com.efrederickson.protean.settings",
                 @"key": @"showSignalRSSI",
                 @"label": @"Show Signal RSSI",
                 @"PostNotification": @"com.efrederickson.protean/reloadSettings",
                 @"icon": @"signalrssi.png"
                 },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @NO,
                 @"defaults": @"com.apple.springboard",
                 @"key": @"SBShowRSSI",
                 @"label": @"Show Wifi/Data RSSI",
                 @"PostNotification": @"com.apple.springboard/Prefs",
                 @"icon": @"wifirssi.png"
                 },
             
             @{ @"cell": @"PSGroupCell",
                @"footerText": @"Enabled by default if the time is not aligned in the center. Unlike many other tweaks, it is compatible with LockInfo7 and Forecast."
                },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @YES,
                 @"defaults": @"com.efrederickson.protean.settings",
                 @"key": @"showLSTime",
                 @"label": @"Show LS Time",
                 @"PostNotification": @"com.efrederickson.protean/reloadSettings",
                 @"icon": @"showLSTime.png"
                 },*/
             @{ @"cell": @"PSGroupCell",
                @"footerText": @"Include notification counts from the Notification Center in addition to badge counts for applications."
                },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @NO,
                 @"defaults": @"com.efrederickson.protean.settings",
                 @"key": @"useNC",
                 @"label": @"Use Notification Center Data",
                 @"PostNotification": @"com.efrederickson.protean/reloadSettings",
                 @"icon": @"usenc.png"
                 },

             @{ @"cell": @"PSGroupCell",
                 @"footerText": @"Rather than glyphs defaulting to the left, this will have them default to the right."
                },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @NO,
                 @"defaults": @"com.efrederickson.protean.settings",
                 @"key": @"defaultAlignToRight",
                 @"label": @"Default Glyphs to the Right",
                 @"PostNotification": @"com.efrederickson.protean/reloadSettings",
                 @"icon": @"defaulttoright.png"
                 },

             @{ @"cell": @"PSGroupCell",
                @"footerText": @"Change the battery percentage (and its color) and carrier to custom string types.",
                //" Space for carrier string hides it, empty is original carrier name. A time formatting guide is available in the documentation."
                },
             @{
                 @"cell": @"PSLinkListCell",
                 @"default": @0,
                 @"defaults": @"com.efrederickson.protean.settings",
                 @"key": @"batteryStyle",
                 @"label": @"Battery Percentage Style",
                 @"PostNotification": @"com.efrederickson.protean/reloadSettings",
                 @"detail": @"SKListItemsController",
                 @"icon": @"batteryStyle.png",
                 @"validTitles": 
                    supportsExtendedBattery ? @[ @"Default", @"Hide '%' sign", @"Textual", @"mAh charge", @"Actual percentage (mAh/capacity)", @"Longer actual percentage", @"Longer actual percentage with no '%'", @"Textual with Percent", @"Actual with no percent" ]
                    : @[ @"Default", @"Hide '%' sign", @"Textual", @"Textual with Percent" ],
                 @"validValues": 
                    supportsExtendedBattery ? @[ @0,         @1,               @2,         @3,            @4,                                @5,                             @6, 									 @7, @8 ]
                    : @[ @0, @1, @2, @7 ],
                 },

                 @{
                    @"cell": @"PSLinkCell",
                    @"cellClass": @"PFColorCell",
                    @"label": @"Battery Percentage Color (charging)",
                    @"color_defaults": @"com.efrederickson.protean.settings",
                    @"color_key": @"chargingPercentageColor",
                    @"title": @"Charging Color",
                    @"color_fallback": @"#000000",
                    @"usesRGB": @YES,
                    @"usesAlpha": @NO,
                    @"color_postNotification": @"com.efrederickson.protean/reloadSettings"
                 },
                 @{
                    @"cell": @"PSLinkCell",
                    @"cellClass": @"PFColorCell",
                    @"label": @"Battery Percentage Color (not charging)",
                    @"color_defaults": @"com.efrederickson.protean.settings",
                    @"color_key": @"notChargingPercentageColor",
                    @"title": @"Charging Color",
                    @"color_fallback": @"#000000",
                    @"usesRGB": @YES,
                    @"usesAlpha": @NO,
                    @"color_postNotification": @"com.efrederickson.protean/reloadSettings"
                 },

             /*@{
                 @"cell": @"PSEditTextCell",
                 @"default": @"",
                 @"defaults": @"com.efrederickson.protean.settings",
                 @"key": @"serviceString",
                 @"label": @"Custom Carrier:",
                 @"PostNotification": @"com.efrederickson.protean/reloadSettings",
                 @"icon": @"carriername.png",
                 },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @NO,
                 @"defaults": @"com.efrederickson.protean.settings",
                 @"key": @"serviceIsTimeString",
                 @"label": @"Use carrier as time format",
                 @"PostNotification": @"com.efrederickson.protean/reloadSettings",
                 },
             @{
                 @"cell": @"PSEditTextCell",
                 @"default": @"h:mm a",
                 @"defaults": @"com.efrederickson.protean.settings",
                 @"key": @"timeFormat",
                 @"label": @"Custom Time Format:",
                 @"PostNotification": @"com.efrederickson.protean/reloadSettings",
                 @"icon": @"timeformat.png",
                 },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @NO,
                 @"defaults": @"com.efrederickson.protean.settings",
                 @"key": @"lowercaseAMPM",
                 @"label": @"Lowercase AM/PM",
                 @"PostNotification": @"com.efrederickson.protean/reloadSettings",
                 @"icon": @"lowercaseampm.png"
                 },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @NO,
                 @"defaults": @"com.efrederickson.protean.settings",
                 @"key": @"spellOut",
                 @"label": @"Spell Out Time (12h)",
                 @"PostNotification": @"com.efrederickson.protean/reloadSettings",
                 @"icon": @"lowercaseampm.png"
                 },*/

             @{ @"cell": @"PSGroupCell",
                @"footerText": @"This may cause minor spacing or overlap issues if items extend pass the midline of the status bar. It is, of course, libstatusbar's fault ;P. Requires a respring to fully apply."
                },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @NO,
                 @"defaults": @"com.efrederickson.protean.settings",
                 @"key": @"allowOverlap",
                 @"label": @"Don't Cut Off Items",
                 @"PostNotification": @"com.efrederickson.protean/reloadSettings",
                 @"icon": @"allowOverlap.png"
                 },

            @{ },

             @{
                 @"cell": @"PSButtonCell",
                 @"action": @"resetData",
                 @"label": @"Reset All Settings & Respring",
                 @"icon": @"respring.png"
                 },
             @{
                 @"cell": @"PSButtonCell",
                 @"action": @"respring",
                 @"label": @"Respring",
                 @"icon": @"respring.png"
                 }

             ]; 
}

-(void)viewWillAppear:(BOOL)animated 
{
    //[self clearCache];
    [self reload];
    [super viewWillAppear:animated]; 
}

-(void) resetData
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Protean" message:@"Please confirm your choice to reset all settings." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
    [alert addButtonWithTitle:@"Yes"];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex 
{
    if (buttonIndex == 1) 
    {
        [NSFileManager.defaultManager removeItemAtPath:@"/User/Library/Preferences/com.efrederickson.protean.settings.plist" error:nil];
        [self respring];
    }
}

-(void)respring
{
    // pffft who cares if it's deprecated
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    system("killall -9 SpringBoard");
#pragma clang diagnostic pop
}

 -(id)readPreferenceValue:(PSSpecifier*)specifier
 {
    NSString *plistName = [NSString stringWithFormat:@"/User/Library/Preferences/%@.plist",[specifier propertyForKey:@"defaults"]];
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:plistName];
    return dict[[specifier propertyForKey:@"key"]]; 
 }

-(void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier
{
    //[super setPreferenceValue:value specifier:specifier];

    if ([[specifier propertyForKey:@"defaults"] isEqual:@"com.apple.springboard"])
    {
        [super setPreferenceValue:value specifier:specifier];
        return;
    }

    NSString *plistName = [NSString stringWithFormat:@"/User/Library/Preferences/%@.plist",[specifier propertyForKey:@"defaults"]];
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:plistName];
    [dict setObject:value forKey:[specifier propertyForKey:@"key"]];
    [dict writeToFile:plistName atomically:YES];
    
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge CFStringRef)[specifier propertyForKey:@"PostNotification"], nil, nil, YES);
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.efrederickson.protean/refreshStatusBar"), nil, nil, YES);
}
@end


@interface PRDocumentationListController () 
{
	UIWebView *webView;
}
@end

@implementation PRDocumentationListController
- (id)initForContentSize:(CGSize)size
{
    if ((self = [super initForContentSize:size]))
    {
        webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
        
        [self setView:webView];
        webView.delegate = self;
        webView.backgroundColor = [UIColor whiteColor];

        NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:@"file:///Library/Protean/Documentation/index.html"]];
        [webView loadRequest:req];

        [self setTitle:@"Documentation"];
    }

    return self;
}

-(void) showDoc
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://proteantweak.com/manual/"]];
}

-(UIColor*) tintColor { return [UIColor colorWithRed:79/255.0f green:176/255.0f blue:136/255.0f alpha:1.0f]; }

- (void)viewWillAppear:(BOOL)animated {
    ((UIView*)self.view).tintColor = self.tintColor;
    self.navigationController.navigationBar.tintColor = self.tintColor;
    [self.navigationController setNavigationBarHidden:YES animated:YES];

    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
[self.navigationController setNavigationBarHidden:NO animated:YES];

    [super viewWillDisappear:animated];
    
    ((UIView*)self.view).tintColor = nil;
    self.navigationController.navigationBar.tintColor = nil;
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType; 
{
    NSURL *requestURL = request.URL; 
    if (([requestURL.scheme isEqualToString:@"http"] || [requestURL.scheme isEqualToString:@"https"] || [requestURL.scheme isEqualToString:@"mailto"]) && (navigationType == UIWebViewNavigationTypeLinkClicked)) 
    { 
        return ![[UIApplication sharedApplication] openURL:requestURL]; 
    }
    if ([requestURL.absoluteString isEqual:@"internal://back-to-settings"])
    {
        [[self navigationController] popViewControllerAnimated:YES];
    }
    if ([[requestURL.absoluteString substringToIndex:16] isEqual:@"internal://open?"])
    {
        return ![[UIApplication sharedApplication] openURL:[NSURL URLWithString:[requestURL.absoluteString substringFromIndex:16]]]; 
    }
    return YES; 
}
@end

#define WBSAddMethod(_class, _sel, _imp, _type) \
if (![[_class class] instancesRespondToSelector:@selector(_sel)]) \
class_addMethod([_class class], @selector(_sel), (IMP)_imp, _type)
void $PSViewController$hideNavigationBarButtons(PSRootController *self, SEL _cmd) { }

id $PSViewController$initForContentSize$(PSRootController *self, SEL _cmd, CGRect contentSize) {
    return [self init];
}
static __attribute__((constructor)) void __wbsInit() {
    WBSAddMethod(PSViewController, hideNavigationBarButtons, $PSViewController$hideNavigationBarButtons, "v@:");
    WBSAddMethod(PSViewController, initForContentSize:, $PSViewController$initForContentSize$, "@@:{ff}");
}

