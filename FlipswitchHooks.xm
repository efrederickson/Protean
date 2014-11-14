#import "PRStatusApps.h"
#import "Protean.h"
#import <flipswitch/Flipswitch.h>

%group SpringBoard
%hook FSSwitchMainPanel

- (FSSwitchState)stateForSwitchIdentifier:(NSString *)switchIdentifier
{
    FSSwitchState ret = %orig;
    CHECK_ENABLED(ret);

    id enabled_ = [Protean getOrLoadSettings][@"flipswitches"][switchIdentifier];
    BOOL enabled = enabled_ ? [enabled_ boolValue] : NO;
    id alwaysShow_ = [Protean getOrLoadSettings][@"alwaysShowFlipswitches"][switchIdentifier];
    BOOL alwaysShow = alwaysShow_ ? [alwaysShow_ boolValue] : NO;
    id showWhenOff_ = [Protean getOrLoadSettings][@"showWhenOffFlipswitches"][switchIdentifier];
    BOOL showWhenOff = showWhenOff_ ? [showWhenOff_ boolValue] : NO;

    if (enabled && ((ret == FSSwitchStateOn && showWhenOff == NO) || alwaysShow || (ret == FSSwitchStateOff && showWhenOff)))
    {
        [PRStatusApps showIconForFlipswitch:switchIdentifier];
    }
    else
        [PRStatusApps hideIconFor:switchIdentifier];

    return ret;
}

- (void)setState:(FSSwitchState)state forSwitchIdentifier:(NSString *)switchIdentifier
{
    %orig;
    CHECK_ENABLED();

    id enabled_ = [Protean getOrLoadSettings][@"flipswitches"][switchIdentifier];
    BOOL enabled = enabled_ ? [enabled_ boolValue] : NO;
    id alwaysShow_ = [Protean getOrLoadSettings][@"alwaysShowFlipswitches"][switchIdentifier];
    BOOL alwaysShow = alwaysShow_ ? [alwaysShow_ boolValue] : NO;
    id showWhenOff_ = [Protean getOrLoadSettings][@"showWhenOffFlipswitches"][switchIdentifier];
    BOOL showWhenOff = showWhenOff_ ? [showWhenOff_ boolValue] : NO;

    if (enabled && ((state == FSSwitchStateOn && showWhenOff == NO) || alwaysShow || (state == FSSwitchStateOff && showWhenOff)))
    {
        [PRStatusApps showIconForFlipswitch:switchIdentifier];
    }
    else
        [PRStatusApps hideIconFor:switchIdentifier];

}

- (void)stateDidChangeForSwitchIdentifier:(NSString *)switchIdentifier
{
    %orig;
    CHECK_ENABLED();

    FSSwitchState state = [[objc_getClass("FSSwitchMainPanel") sharedPanel] stateForSwitchIdentifier:switchIdentifier];
    id enabled_ = [Protean getOrLoadSettings][@"flipswitches"][switchIdentifier];
    BOOL enabled = enabled_ ? [enabled_ boolValue] : NO;
    id alwaysShow_ = [Protean getOrLoadSettings][@"alwaysShowFlipswitches"][switchIdentifier];
    BOOL alwaysShow = alwaysShow_ ? [alwaysShow_ boolValue] : NO;
    id showWhenOff_ = [Protean getOrLoadSettings][@"showWhenOffFlipswitches"][switchIdentifier];
    BOOL showWhenOff = showWhenOff_ ? [showWhenOff_ boolValue] : NO;

    if (enabled && ((state == FSSwitchStateOn && showWhenOff == NO) || alwaysShow || (state == FSSwitchStateOff && showWhenOff)))
    {
        [PRStatusApps showIconForFlipswitch:switchIdentifier];
    }
    else
        [PRStatusApps hideIconFor:switchIdentifier];

    %orig;
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