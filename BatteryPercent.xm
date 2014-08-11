#import "Protean.h"

struct RAWDATA {
        BOOL itemIsEnabled[25]; 
        BOOL timeString[64]; 
        int gsmSignalStrengthRaw; 
        int gsmSignalStrengthBars; 
        BOOL serviceString[100]; 
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
} RAWDATA;

@interface UIStatusBarComposedData : NSObject <NSCopying> {
     struct RAWDATA *_rawData;
}

@property(readonly) struct RAWDATA* rawData;

- (void)dealloc;
- (id)doubleHeightStatus;
- (BOOL)isItemEnabled:(int)arg1;
- (struct RAWDATA*)rawData;
- (void)setItem:(int)arg1 enabled:(BOOL)arg2;

@end

NSNumberFormatter *stringFormatter = [[NSNumberFormatter alloc] init];
NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];

%hook UIStatusBarBatteryPercentItemView
- (BOOL)updateForNewData:(UIStatusBarComposedData*)arg1 actions:(int)arg2
{
    CHECK_ENABLED(%orig);

    char oldBattery[150];
    
    strcpy(oldBattery, arg1.rawData->batteryDetailString);
    
    NSString *batteryStr = [NSString stringWithUTF8String:oldBattery];
    
    int changedBatteryStyle = [Protean getOrLoadSettings][@"batteryStyle"] ? [[Protean getOrLoadSettings][@"batteryStyle"] intValue] : 0;
    // 0: default
    // 1: remove percent
    // 2: textual
    
    if (changedBatteryStyle == 1)
    {
        if ([batteryStr hasSuffix:@"%"])
            batteryStr = [batteryStr substringToIndex:batteryStr.length - 1];
    }
    else if (changedBatteryStyle == 2)
    {
        if ([batteryStr hasSuffix:@"%"])
            batteryStr = [batteryStr substringToIndex:batteryStr.length - 1];

        [stringFormatter setNumberStyle: NSNumberFormatterSpellOutStyle];
        NSNumber *num = [numberFormatter numberFromString:batteryStr];
        if (num)
            batteryStr = [stringFormatter stringFromNumber:num];
    }

    strlcpy(arg1.rawData->batteryDetailString, [batteryStr UTF8String], sizeof(arg1.rawData->batteryDetailString));

    return %orig(arg1, arg2);
}
%end