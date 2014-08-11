#import "PRStatusApps.h"
#import "Protean.h"

@interface BluetoothDevice
- (_Bool)connected;
- (_Bool)paired;
- (id)description;
- (int)type;
- (id)address;
- (id)name;
@end
@interface BluetoothManager
+ (id)sharedInstance;
- (_Bool)connected;
- (id)connectedDevices;
- (id)connectingDevices;
- (id)pairedDevices;
- (void)unpairDevice:(id)arg1;
- (void)resetDeviceScanning;
- (_Bool)deviceScanningInProgress;
- (_Bool)deviceScanningEnabled;
- (_Bool)wasDeviceDiscovered:(id)arg1;
- (void)_removeDevice:(id)arg1;
- (id)addDeviceIfNeeded:(struct BTDeviceImpl *)arg1;
- (void)_connectedStatusChanged;
@end

%group SpringBoard

%hook BluetoothManager

- (id)addDeviceIfNeeded:(struct BTDeviceImpl *)arg1
{
    BluetoothDevice *device = %orig;
    CHECK_ENABLED(device);
    
    if (device.connected)
    {
        [PRStatusApps showIconForBluetooth:device.name];
    }
    else
        [PRStatusApps hideIconFor:device.name];

    return device;
}

- (void)_connectedStatusChanged
{
    %orig;
    CHECK_ENABLED();
    
    for (BluetoothDevice* device in [[%c(BluetoothManager) sharedInstance] pairedDevices])
    {
        NSString *name = device.name;
        
        if ([[[%c(BluetoothManager) sharedInstance] connectedDevices] containsObject:device])
        {
            [PRStatusApps showIconForBluetooth:name];
        }
        else
            [PRStatusApps hideIconFor:name];
    }
}
%end
%end

%ctor
{
    if ([[[NSBundle mainBundle] bundleIdentifier] isEqual:@"com.apple.springboard"])
    {
        %init(SpringBoard);
    }
}