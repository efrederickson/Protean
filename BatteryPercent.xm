#import "Protean.h"
#import "proteansettings/libcolorpicker/UIColor+PFColor.h"

@interface UIColor (Private)
- (BOOL)_isSimilarToColor:(UIColor *)color withinPercentage:(CGFloat)percentage;
@end

@interface PLBatteryPropertiesEntry// : PLEntry
+(instancetype) batteryPropertiesEntry;
@property(readonly, nonatomic) BOOL draining;
@property(readonly, nonatomic) BOOL isPluggedIn;
@property(readonly, nonatomic) NSString *chargingState;
@property(readonly, nonatomic) int batteryTemp;
@property(readonly, nonatomic) NSNumber *connectedStatus;
@property(readonly, nonatomic) NSNumber *adapterInfo;
@property(readonly, nonatomic) int chargingCurrent;
@property(readonly, nonatomic) BOOL fullyCharged;
@property(readonly, nonatomic) BOOL isCharging;
@property(readonly, nonatomic) int cycleCount;
@property(readonly, nonatomic) int designCapacity;
@property(readonly, nonatomic) double rawMaxCapacity;
@property(readonly, nonatomic) double maxCapacity;
@property(readonly, nonatomic) double rawCurrentCapacity;
@property(readonly, nonatomic) double currentCapacity;
@property(readonly, nonatomic) int current;
@property(readonly, nonatomic) int voltage;
@property(readonly, nonatomic) BOOL isCritical;
@property(readonly, nonatomic) double rawCapacity;
@property(readonly, nonatomic) double capacity;
- (void)dealloc;
- (id)humanReadableChargingStateFromIORegistryEntryDictionary:(id)arg1;
- (id)initEntryWithIORegistryEntry:(unsigned int)arg1;
- (id)init;
@end

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
unsigned int batteryState; 


%hook UIStatusBarBatteryPercentItemView
- (BOOL)updateForNewData:(UIStatusBarComposedData*)arg1 actions:(int)arg2
{
    CHECK_ENABLED(%orig);
    batteryState = arg1.rawData->batteryState;

    char oldBattery[150];
    
    strcpy(oldBattery, arg1.rawData->batteryDetailString);
    
    NSString *batteryStr = [NSString stringWithUTF8String:oldBattery];
    
    int changedBatteryStyle = [Protean getOrLoadSettings][@"batteryStyle"] ? [[Protean getOrLoadSettings][@"batteryStyle"] intValue] : 0;
    // 0: default
    // 1: remove percent
    // 2: textual
    // 3. mAh charge
    // 4. Real battery charge
    // 5. Real charge with 2 decimals
    // 6. Real charge with decimals and no percent
    // 7. Textual with "percent"
    
    if (changedBatteryStyle == 1)
    {
        if ([batteryStr hasSuffix:@"%"]) // remove percent sign
            batteryStr = [batteryStr substringToIndex:batteryStr.length - 1];
    }
    else if (changedBatteryStyle == 2)
    {
        if ([batteryStr hasSuffix:@"%"]) // remove percent sign, for the formatter
            batteryStr = [batteryStr substringToIndex:batteryStr.length - 1];

        [stringFormatter setNumberStyle: NSNumberFormatterSpellOutStyle];
        NSNumber *num = [numberFormatter numberFromString:batteryStr];
        if (num)
            batteryStr = [stringFormatter stringFromNumber:num];
    }
    else if (changedBatteryStyle == 3)
    {
        // mAh charge
        if (%c(PLBatteryPropertiesEntry))
            batteryStr = [NSString stringWithFormat:@"%.0f mAh", ((PLBatteryPropertiesEntry*)[%c(PLBatteryPropertiesEntry) batteryPropertiesEntry]).rawCurrentCapacity];
        else
        {
            int rawCurrentCapacity = -100;
            io_service_t powerSource = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPMPowerSource"));

            CFNumberRef rawCurrentCapacityNum = (CFNumberRef)IORegistryEntryCreateCFProperty(powerSource, CFSTR("AppleRawCurrentCapacity"), kCFAllocatorDefault, 0);
            CFNumberGetValue(rawCurrentCapacityNum, kCFNumberIntType, &rawCurrentCapacity);
            CFRelease(rawCurrentCapacityNum);
            batteryStr = [NSString stringWithFormat:@"%.0d mAh", rawCurrentCapacity];
        }
    }
    else if (changedBatteryStyle == 4)
    {
        // "real" battery charge

        if (%c(PLBatteryPropertiesEntry))
        {
            CGFloat rawCurrent = ((PLBatteryPropertiesEntry*)[%c(PLBatteryPropertiesEntry) batteryPropertiesEntry]).rawCurrentCapacity;
            CGFloat rawMax = ((PLBatteryPropertiesEntry*)[%c(PLBatteryPropertiesEntry) batteryPropertiesEntry]).rawMaxCapacity;
            CGFloat rawActual = floor((rawCurrent / rawMax) * 100);
            if (rawActual > 100) // uhh, what?
                rawActual = 100;
            else if (rawActual < 0)
            	rawActual = 0;
            batteryStr = [NSString stringWithFormat:@"%.0f%%", rawActual];
        }
        else
        {
            CGFloat rawCurrentCapacity = -100;
            CGFloat rawMaxCapacity = -100;
            io_service_t powerSource = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPMPowerSource"));

            CFNumberRef rawCurrentCapacityNum = (CFNumberRef)IORegistryEntryCreateCFProperty(powerSource, CFSTR("AppleRawCurrentCapacity"), kCFAllocatorDefault, 0);
            CFNumberGetValue(rawCurrentCapacityNum, kCFNumberCGFloatType, &rawCurrentCapacity);
            CFRelease(rawCurrentCapacityNum);

            CFNumberRef rawMaxCapacityNum = (CFNumberRef)IORegistryEntryCreateCFProperty(powerSource, CFSTR("AppleRawMaxCapacity"), kCFAllocatorDefault, 0);
            CFNumberGetValue(rawMaxCapacityNum, kCFNumberCGFloatType, &rawMaxCapacity);
            CFRelease(rawMaxCapacityNum);
            CGFloat rawActual = floor((rawCurrentCapacity / rawMaxCapacity) * 100);
            if (rawActual > 100)
                rawActual = 100;
            else if (rawActual < 0)
                rawActual = 0;
            if (rawCurrentCapacity == -100 || rawMaxCapacity == -100)
                rawActual = NAN;
            batteryStr = [NSString stringWithFormat:@"%.0f%%", rawActual];
        }
    }
    else if (changedBatteryStyle == 5)
    {
        // "real" battery charge with decimals

        if (%c(PLBatteryPropertiesEntry))
        {
            CGFloat rawCurrent = ((PLBatteryPropertiesEntry*)[%c(PLBatteryPropertiesEntry) batteryPropertiesEntry]).rawCurrentCapacity;
            CGFloat rawMax = ((PLBatteryPropertiesEntry*)[%c(PLBatteryPropertiesEntry) batteryPropertiesEntry]).rawMaxCapacity;
            CGFloat rawActual = (rawCurrent / rawMax) * 100;
            if (rawActual > 100)
                rawActual = 100;
            else if (rawActual < 0)
            	rawActual = 0;
            batteryStr = [NSString stringWithFormat:@"%.2f%%", rawActual];
        }
        else
        {
            CGFloat rawCurrentCapacity = -100;
            CGFloat rawMaxCapacity = -100;
            io_service_t powerSource = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPMPowerSource"));

            CFNumberRef rawCurrentCapacityNum = (CFNumberRef)IORegistryEntryCreateCFProperty(powerSource, CFSTR("AppleRawCurrentCapacity"), kCFAllocatorDefault, 0);
            CFNumberGetValue(rawCurrentCapacityNum, kCFNumberCGFloatType, &rawCurrentCapacity);
            CFRelease(rawCurrentCapacityNum);

            CFNumberRef rawMaxCapacityNum = (CFNumberRef)IORegistryEntryCreateCFProperty(powerSource, CFSTR("AppleRawMaxCapacity"), kCFAllocatorDefault, 0);
            CFNumberGetValue(rawMaxCapacityNum, kCFNumberCGFloatType, &rawMaxCapacity);
            CFRelease(rawMaxCapacityNum);
            CGFloat rawActual = floor((rawCurrentCapacity / rawMaxCapacity) * 100);
            if (rawActual > 100)
                rawActual = 100;
            else if (rawActual < 0)
                rawActual = 0;
            if (rawCurrentCapacity == -100 || rawMaxCapacity == -100)
                rawActual = NAN;
            batteryStr = [NSString stringWithFormat:@"%.2f%%", rawActual];
        }
    }
    else if (changedBatteryStyle == 6)
    {
        // "real" battery charge with decimals and no percent sign

        if (%c(PLBatteryPropertiesEntry))
        {
            CGFloat rawCurrent = ((PLBatteryPropertiesEntry*)[%c(PLBatteryPropertiesEntry) batteryPropertiesEntry]).rawCurrentCapacity;
            CGFloat rawMax = ((PLBatteryPropertiesEntry*)[%c(PLBatteryPropertiesEntry) batteryPropertiesEntry]).rawMaxCapacity;
            CGFloat rawActual = (rawCurrent / rawMax) * 100;
            if (rawActual > 100)
                rawActual = 100;
            else if (rawActual < 0)
                rawActual = 0;
            batteryStr = [NSString stringWithFormat:@"%.2f", rawActual];
        }
        else
        {
            CGFloat rawCurrentCapacity = -100;
            CGFloat rawMaxCapacity = -100;
            io_service_t powerSource = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPMPowerSource"));

            CFNumberRef rawCurrentCapacityNum = (CFNumberRef)IORegistryEntryCreateCFProperty(powerSource, CFSTR("AppleRawCurrentCapacity"), kCFAllocatorDefault, 0);
            CFNumberGetValue(rawCurrentCapacityNum, kCFNumberCGFloatType, &rawCurrentCapacity);
            CFRelease(rawCurrentCapacityNum);

            CFNumberRef rawMaxCapacityNum = (CFNumberRef)IORegistryEntryCreateCFProperty(powerSource, CFSTR("AppleRawMaxCapacity"), kCFAllocatorDefault, 0);
            CFNumberGetValue(rawMaxCapacityNum, kCFNumberCGFloatType, &rawMaxCapacity);
            CFRelease(rawMaxCapacityNum);
            CGFloat rawActual = floor((rawCurrentCapacity / rawMaxCapacity) * 100);
            if (rawActual > 100)
                rawActual = 100;
            else if (rawActual < 0)
                rawActual = 0;
            if (rawCurrentCapacity == -100 || rawMaxCapacity == -100)
                rawActual = NAN;
            batteryStr = [NSString stringWithFormat:@"%.2f", rawActual];
        }
    }
    else if (changedBatteryStyle == 7)
    {
        if ([batteryStr hasSuffix:@"%"]) // remove percent sign, for the formatter
            batteryStr = [batteryStr substringToIndex:batteryStr.length - 1];

        [stringFormatter setNumberStyle:NSNumberFormatterSpellOutStyle];
        NSNumber *num = [numberFormatter numberFromString:batteryStr];
        if (num)
            batteryStr = [[stringFormatter stringFromNumber:num] stringByAppendingString:@" percent"];
    }
    else if (changedBatteryStyle == 8)
    {
        // "real" battery charge w/ no percent sign

        if (%c(PLBatteryPropertiesEntry))
        {
            CGFloat rawCurrent = ((PLBatteryPropertiesEntry*)[%c(PLBatteryPropertiesEntry) batteryPropertiesEntry]).rawCurrentCapacity;
            CGFloat rawMax = ((PLBatteryPropertiesEntry*)[%c(PLBatteryPropertiesEntry) batteryPropertiesEntry]).rawMaxCapacity;
            CGFloat rawActual = floor((rawCurrent / rawMax) * 100);
            if (rawActual > 100) // uhh, what?
                rawActual = 100;
            else if (rawActual < 0)
                rawActual = 0;
            batteryStr = [NSString stringWithFormat:@"%.0f%%", rawActual];
        }
        else
        {
            CGFloat rawCurrentCapacity = -100;
            CGFloat rawMaxCapacity = -100;
            io_service_t powerSource = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPMPowerSource"));

            CFNumberRef rawCurrentCapacityNum = (CFNumberRef)IORegistryEntryCreateCFProperty(powerSource, CFSTR("AppleRawCurrentCapacity"), kCFAllocatorDefault, 0);
            CFNumberGetValue(rawCurrentCapacityNum, kCFNumberCGFloatType, &rawCurrentCapacity);
            CFRelease(rawCurrentCapacityNum);

            CFNumberRef rawMaxCapacityNum = (CFNumberRef)IORegistryEntryCreateCFProperty(powerSource, CFSTR("AppleRawMaxCapacity"), kCFAllocatorDefault, 0);
            CFNumberGetValue(rawMaxCapacityNum, kCFNumberCGFloatType, &rawMaxCapacity);
            CFRelease(rawMaxCapacityNum);
            CGFloat rawActual = floor((rawCurrentCapacity / rawMaxCapacity) * 100);
            if (rawActual > 100)
                rawActual = 100;
            else if (rawActual < 0)
                rawActual = 0;
            if (rawCurrentCapacity == -100 || rawMaxCapacity == -100)
                rawActual = NAN;
            batteryStr = [NSString stringWithFormat:@"%.0f", rawActual];
        }
    }

    strlcpy(arg1.rawData->batteryDetailString, [batteryStr UTF8String], sizeof(arg1.rawData->batteryDetailString));

    return %orig(arg1, arg2);
}

-(_UILegibilityImageSet*) contentsImage
{
	CHECK_ENABLED(%orig);

	BOOL charging = batteryState == 1;
	_UILegibilityImageSet *original = %orig;

	UIColor *color = [UIColor PF_colorWithHex:[Protean getOrLoadSettings][charging ? @"chargingPercentageColor" : @"notChargingPercentageColor"]];
	if (color && [color _isSimilarToColor:[UIColor blackColor] withinPercentage:0.2] == NO)
		original.image = [original.image _flatImageWithColor:color];
    
	return original;
}
%end

%ctor
{
    if ([NSFileManager.defaultManager fileExistsAtPath:@"/System/Library/PrivateFrameworks/PowerlogLoggerSupport.framework/"])
    {
        void *library = dlopen("/System/Library/PrivateFrameworks/PowerlogLoggerSupport.framework/PowerlogLoggerSupport", RTLD_LAZY);

        //Class powerlog = dlsym(handle, "OBJC_CLASS_$_PLBatteryPropertiesEntry");
        if (objc_getClass("PLBatteryPropertiesEntry") == nil)
        {
            //NSLog(@"[Protean] welp, failed to load PLBatteryPropertiesEntry. Unsupported iOS version?");
        }
        dlclose(library);
    }
}