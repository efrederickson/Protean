#import "Protean.h"

struct StatusBarData {
        BOOL itemIsEnabled[25]; 
        BOOL timeString[64]; 
        int gsmSignalStrengthRaw; 
        int gsmSignalStrengthBars; 
        char serviceString[100]; 
        BOOL serviceCrossfadeString[100]; 
        BOOL serviceImages[2][100]; 
        BOOL operatorDirectory[1024]; 
        unsigned int serviceContentType; 
        int wifiSignalStrengthRaw; 
        int wifiSignalStrengthBars; 
        unsigned int dataNetworkType; 
        int batteryCapacity; 
        unsigned int batteryState; 
        char batteryDetailString[150];
        int bluetoothBatteryCapacity; 
        int thermalColor; 
        unsigned int thermalSunlightMode : 1; 
        unsigned int slowActivity : 1; 
        unsigned int syncActivity : 1; 
        BOOL activityDisplayId[256]; 
        unsigned int bluetoothConnected : 1; 
        unsigned int displayRawGSMSignal : 1; 
        unsigned int displayRawWifiSignal : 1; 
        unsigned int locationIconType : 1; 
        unsigned int quietModeInactive : 1; 
        unsigned int tetheringConnectionCount; 
    NSString *_doubleHeightStatus;
    BOOL _itemEnabled[30];
} StatusBarData;

@interface UIStatusBarComposedData : NSObject <NSCopying> {
     struct StatusBarData *_rawData;
}

@property(readonly) struct StatusBarData* rawData;

- (void)dealloc;
- (id)doubleHeightStatus;
- (BOOL)isItemEnabled:(int)arg1;
- (struct StatusBarData*)rawData;
- (void)setItem:(int)arg1 enabled:(BOOL)arg2;

@end

%hook UIStatusBarServiceItemView
- (BOOL)updateForNewData:(UIStatusBarComposedData*)arg1 actions:(int)arg2
{
    CHECK_ENABLED(%orig);

    char oldService[150];
    
    strcpy(oldService, arg1.rawData->serviceString);
    
    NSString *serviceStr = [NSString stringWithUTF8String:oldService];
    
    NSString *customService = [Protean getOrLoadSettings][@"serviceString"] ?: serviceStr;

    if ([customService isEqual:@" "])
        serviceStr = @"";
    else if ([customService isEqual:@""])
        ;
    else
        serviceStr = customService;

    strlcpy(arg1.rawData->serviceString, [serviceStr UTF8String], sizeof(arg1.rawData->serviceString));

    return %orig(arg1, arg2);
}
%end