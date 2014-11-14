#import "PRStatusApps.h"
#import "Protean.h"

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
        
        NSPredicate *namePredicate = [NSPredicate predicateWithFormat:@"name contains[c] %@", name];
        //if ([[[%c(BluetoothManager) sharedInstance] connectedDevices] containsObject:device])
        if ([[[[%c(BluetoothManager) sharedInstance] connectedDevices] filteredArrayUsingPredicate:namePredicate] count] > 0)
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