#import <Preferences/Preferences.h>
#import <SettingsKit/SKListControllerProtocol.h>
#import <SettingsKit/SKTintedListController.h>
#import <objc/runtime.h>
#import "IconSelectorController.h"
#import <MessageUI/MFMailComposeViewController.h>

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

@interface PRAdvancedSettingsListController : SKTintedListController<SKListControllerProtocol>
@end

@interface PSViewController ()
-(void) setView:(id)view;
-(void) setTitle:(NSString*)title;
@end
@interface PRDocumentationListController : PSViewController <UIWebViewDelegate>
@end

@implementation ProteanSettingsListController
-(NSString*) headerText { return @"Protean"; }
-(NSString*) headerSubText { return NO ? @"Your status bar, your way" : @"By Elijah and Andrew\nYour status bar, your way."; }
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
                 @"cellClass": @"SKTintedSwitchCell",
                 @"icon": @"enabled.png",
                 },

             @{ @"cell": @"PSGroupCell",
                //@"footerText": @"Items do not show up until they have appeared in your status bar. Libstatusbar items cannot be in the center, and a respring will be needed to apply changes to them."
                @"footerText": @"Modify the arrangement of status bar items.",
                },
             @{
                 @"cell": @"PSLinkListCell",
                 @"cellClass": @"SKTintedCell",
                 @"detail": @"PROrganizationController",
                 @"label": @"Organization",
                 @"icon": @"organization.png"
                 },
             
             @{ @"cell": @"PSGroupCell",
                @"footerText": @"Select applications, flipswitches, and others to be represented by a glyph in the status bar."
                },
             @{
                 @"cell": @"PSLinkListCell",
                 @"cellClass": @"SKTintedCell",
                 @"action": @"pushTotalNotificationCountController",
                 @"label": @"Total Notification Count",
                 @"icon": @"tnc.png"
                 },
             @{
                 @"cell": @"PSLinkListCell",
                 @"cellClass": @"SKTintedCell",
                 @"detail": @"ProteanAppsController",
                 @"label": @"Applications",
                 @"icon": @"applications.png"
                 },
             @{
                 @"cell": @"PSLinkListCell",
                 @"cellClass": @"SKTintedCell",
                 @"detail": @"PRSystemIconsController",
                 @"label": @"System Icons",
                 @"icon": @"sysicons.png"
                 },
             @{
               @"cell": @"PSLinkListCell",
                 @"cellClass": @"SKTintedCell",
               @"detail": @"PRFlipswitchController",
               @"label": @"Flipswitches",
               @"icon": @"flipswitches.png"
               },
             @{
                 @"cell": @"PSLinkListCell",
                 @"cellClass": @"SKTintedCell",
                 @"detail": @"PRBluetoothController",
                 @"label": @"Bluetooth Devices",
                 @"icon": @"bluetooth.png"
                 },


            @{ },
            @{
                @"cell": @"PSLinkListCell",
                @"cellClass": @"SKTintedCell",
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
                 @"cellClass": @"SKTintedCell",
                 },

             @{ @"cell": @"PSGroupCell" },
             @{
                 @"cell": @"PSLinkCell",
                 @"detail": @"PRDocumentationListController",
                 @"label": @"Documentation",
                 @"icon": @"documentation.png",
                 @"cellClass": @"SKTintedCell",
                 },
             
             @{ @"cell": @"PSGroupCell",
                @"footerText": @"© 2014 Elijah Frederickson & Andrew Abosh" },
             @{
                 @"cell": @"PSLinkCell",
                 @"action": @"showSupportDialog",
                 @"label": @"Support",
                 @"icon": @"support.png",
                 @"cellClass": @"SKTintedCell",
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
        [mailViewController setMessageBody:@"" isHTML:NO];
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
    [super setPreferenceValue:value specifier:specifier];
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.efrederickson.protean/refreshStatusBar"), nil, nil, YES);
}

@end

@implementation PRAdvancedSettingsListController
-(BOOL) showHeartImage { return NO; }
-(UIColor*) navigationTintColor { return [UIColor colorWithRed:79/255.0f green:176/255.0f blue:136/255.0f alpha:1.0f]; }
-(UIColor*) switchOnTintColor { return self.navigationTintColor; }
-(UIColor*) iconColor { return self.navigationTintColor; }
-(UIColor*) headerColor { return [UIColor colorWithRed:74/255.0f green:74/255.0f blue:74/255.0f alpha:1.0f]; }

-(NSArray*) customSpecifiers {
             return @[
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
                 @"cellClass": @"SKTintedSwitchCell",
                 @"icon": @"normalizeLS.png"
                 },
                 @{},
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @NO,
                 @"defaults": @"com.efrederickson.protean.settings",
                 @"key": @"showSignalRSSI",
                 @"label": @"Show Signal RSSI",
                 @"PostNotification": @"com.efrederickson.protean/reloadSettings",
                 @"cellClass": @"SKTintedSwitchCell",
                 @"icon": @"signalrssi.png"
                 },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @NO,
                 @"defaults": @"com.apple.springboard",
                 @"key": @"SBShowRSSI",
                 @"label": @"Show Wifi/Data RSSI",
                 @"PostNotification": @"",
                 @"cellClass": @"SKTintedSwitchCell",
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
                 @"cellClass": @"SKTintedSwitchCell",
                 @"icon": @"showLSTime.png"
                 },
             @{ @"cell": @"PSGroupCell",
                @"footerText": @"Include notification counts from the Notification Center in addition to badge counts for applications."
                },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @YES,
                 @"defaults": @"com.efrederickson.protean.settings",
                 @"key": @"useNC",
                 @"label": @"Use Notification Center Data",
                 @"PostNotification": @"com.efrederickson.protean/reloadSettings",
                 @"cellClass": @"SKTintedSwitchCell",
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
                 @"cellClass": @"SKTintedSwitchCell",
                 @"icon": @"defaulttoright.png"
                 },

             @{ @"cell": @"PSGroupCell",
                @"footerText": @"Change the battery percentage and carrier to custom string types. Space for carrier string hides it, empty is original carrier name. A time formatting guide is available in the documentation."
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
                 @"validTitles": @[ @"Default", @"Hide '%' sign", @"Textual", @"mAh charge", @"Actual percentage (mAh/capacity)", @"Longer actual percentage" ],
                 @"validValues": @[ @0,         @1,               @2,         @3,            @4,                 @5]
                 },
             @{
                 @"cell": @"PSEditTextCell",
                 @"default": @"",
                 @"defaults": @"com.efrederickson.protean.settings",
                 @"key": @"serviceString",
                 @"label": @"Custom Carrier:",
                 @"PostNotification": @"com.efrederickson.protean/reloadSettings",
                 @"icon": @"carriername.png",
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
                 @"cellClass": @"SKTintedSwitchCell",
                 @"icon": @"lowercaseampm.png"
                 },

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
                 @"cellClass": @"SKTintedSwitchCell",
                 @"icon": @"allowOverlap.png"
                 },

            @{ },
             @{
                 @"cell": @"PSButtonCell",
                 @"action": @"respring",
                 @"label": @"Respring",
                 @"icon": @"respring.png"
                 }

             ]; 
}

-(void)respring
{
    system("killall -9 SpringBoard");
}

-(void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier
{
    [super setPreferenceValue:value specifier:specifier];
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
    return YES; 
}
@end

#define WBSAddMethod(_class, _sel, _imp, _type) \
if (![[_class class] instancesRespondToSelector:@selector(_sel)]) \
class_addMethod([_class class], @selector(_sel), (IMP)_imp, _type)
void $PSViewController$hideNavigationBarButtons(PSRootController *self, SEL _cmd) {
}

id $PSViewController$initForContentSize$(PSRootController *self, SEL _cmd, CGRect contentSize) {
    return [self init];
}
static __attribute__((constructor)) void __wbsInit() {
    WBSAddMethod(PSViewController, hideNavigationBarButtons, $PSViewController$hideNavigationBarButtons, "v@:");
    WBSAddMethod(PSViewController, initForContentSize:, $PSViewController$initForContentSize$, "@@:{ff}");
}

