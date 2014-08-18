#import <Preferences/Preferences.h>
#import <SettingsKit/SKListControllerProtocol.h>
#import <SettingsKit/SKTintedListController.h>
#import <objc/runtime.h>
#import "IconSelectorController.h"

@interface ProteanSettingsListController : SKTintedListController<SKListControllerProtocol>
@end

@implementation ProteanSettingsListController
-(NSString*) headerText { return @"Protean"; }
-(NSString*) headerSubText { return @"Your status bar, your way"; }
-(NSString*) customTitle { return @"Protean"; }

-(NSString*) shareMessage { return @"I'm using #Protean by @daementor and @drewplex: your status bar, your way."; }

//-(UIColor*) navigationTintColor { return [UIColor colorWithRed:11/255.0f green:234/255.0f blue:241/255.0f alpha:1.0f]; }
//-(UIColor*) switchOnTintColor { return self.navigationTintColor; }
//-(UIColor*) headerColor { return self.navigationTintColor; }
-(UIColor*) iconColor { return [UIColor colorWithRed:11/255.0f green:234/255.0f blue:241/255.0f alpha:1.0f]; }

-(NSArray*) customSpecifiers
{
    return @[
             
             @{ @"cell": @"PSGroupCell",
                @"footerText": @"A respring may be required to fully apply changes."
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
             
             @{ @"cell": @"PSGroupCell" },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @YES,
                 @"defaults": @"com.efrederickson.protean.settings",
                 @"key": @"normalizeLS",
                 @"label": @"Normalize LS StatusBar",
                 @"PostNotification": @"com.efrederickson.protean/reloadSettings",
                 @"cellClass": @"SKTintedSwitchCell",
                 @"icon": @"normalizeLS.png"
                 },
             
             @{ @"cell": @"PSGroupCell",
                @"footerText": @"Enabled by default if time is not aligned in the center. Unlike many other tweaks, it is compatible with LockInfo7 and Forecast."
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
                @"footerText": @"Change the battery percentage display to custom string types."
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
                 @"validTitles": @[ @"Default", @"Hide '%' sign", @"Textual" ],
                 @"validValues": @[ @0,         @1,               @2         ]
                 },
             
             @{ @"cell": @"PSGroupCell",
                @"footerText": @"This may cause minor spacing or overlap issues if items extend pass the midline of the status bar. It is, of course, libstatusbar's fault ;P. Requires a respring to fully apply."
                },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @YES,
                 @"defaults": @"com.efrederickson.protean.settings",
                 @"key": @"allowOverlap",
                 @"label": @"Don't cut off items",
                 @"PostNotification": @"com.efrederickson.protean/reloadSettings",
                 @"cellClass": @"SKTintedSwitchCell",
                 @"icon": @"allowOverlap.png"
                 },
             
             
             @{ @"cell": @"PSGroupCell",
                @"footerText": @"Items do not show up until they have appeared in your status bar. Also, due to the way iOS works, if there are multiple items in the Center, they will not all show up. If you change an item that is from libstatusbar and not a stock item, you will need to respring to apply changes (that is a libstatusbar limitation); another libstatusbar limitation is that libstatusbar items cannot be in the center."
                },
             @{
                 @"cell": @"PSLinkListCell",
                 @"detail": @"PROrganizationController",
                 @"label": @"Organization"
                 },
             
             
             
             @{ @"cell": @"PSGroupCell",
                @"footerText": @"Select applications, flipswitches, etc and glyphs to show in the status bar (similar to OpenNotifier)"
                },
             @{
                 @"cell": @"PSLinkListCell",
                 @"action": @"pushTotalNotificationCountController",
                 @"label": @"Total Notification Count"
                 },
             @{
                 @"cell": @"PSLinkListCell",
                 @"detail": @"ProteanAppsController",
                 @"label": @"Status Apps"
                 },
             @{
                 @"cell": @"PSLinkListCell",
                 @"detail": @"PRSystemIconsController",
                 @"label": @"System Icons"
                 },
             @{
               @"cell": @"PSLinkListCell",
               @"detail": @"PRFlipswitchController",
               @"label": @"Flipswitches"
               },
             @{
                 @"cell": @"PSLinkListCell",
                 @"detail": @"PRBluetoothController",
                 @"label": @"Bluetooth Devices"
                 },
             
             @{ @"cell": @"PSGroupCell" },
             @{
                 @"cell": @"PSLinkCell",
                 @"detail": @"PRMakersListController",
                 @"label": @"Makers",
                 @"icon": @"makers.png",
                 @"cellClass": @"SKTintedCell",
                 },
             
             @{ @"cell": @"PSGroupCell",
                @"footerText": @"Copyright (C) 2014 Elijah Frederickson & Andrew Abosh"},
             @{
                 @"cell": @"PSButtonCell",
                 @"action": @"respring",
                 @"label": @"Respring"
                 },
             
             ];
}

-(void)respring
{
    system("killall -9 SpringBoard");
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

